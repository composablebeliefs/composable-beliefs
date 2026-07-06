defmodule CB.Belief.Store do
  @moduledoc """
  Reads and writes the belief graph. The sole place that knows the
  on-disk layout (cb:b555): every reader and writer goes through here.

  Two layouts are supported:

  - a single JSON array file (`beliefs.json`) - the legacy layout, kept
    as the fallback for unsplit collections;
  - a per-belief directory (`beliefs/<ns>/<local>.json`, cb:b554) where
    each file holds one node's canonical serialization. An existing
    path selects its layout by what it is on disk (`File.dir?/1`); a
    not-yet-existing path selects the directory layout unless it ends
    in `.json`.

  Reads return beliefs sorted by id (natural order, so `b1000` follows
  `b999`) for the directory layout; a single-file collection keeps its
  stored order. A node file must be a JSON object carrying a string
  `id` - anything else is a `{:error, {:bad_node, path}}`, never a
  silent skip.

  Writes are atomic per file (tmp + rename). A multi-node write to the
  directory layout is NOT one atomic transaction: it is two-phase - all
  changed nodes are staged as `.tmp` siblings first, and only when
  every stage succeeded are they renamed into place - so a failure
  before any rename leaves the store untouched, and the non-atomic
  window shrinks to the rename loop. New nodes rename before changed
  ones, so a crash inside that window leaves a duplicate-claim conflict
  the preflight detects rather than a dangling `superseded_by`. The
  deletion pass only removes files that parse as belief nodes; foreign
  `.json` files (a stray manifest, an editor artifact) are left alone.

  All entries are beliefs - contract-grade beliefs are distinguished by
  having `rules` and/or `invariants` fields.
  """

  alias CB.Belief
  alias CB.Config
  alias CB.JSON

  # A node filename is the id's local part; it must stay inside the
  # collection directory, so the local part is confined to a safe
  # character set (no separators, no leading dot).
  @safe_local ~r/^[A-Za-z0-9][A-Za-z0-9._-]*$/

  @doc """
  Read all entries from the belief graph as beliefs.

  `read/0` reads the configured collection (`CB.Config.beliefs_path/0`)
  and treats a missing location as the empty collection - a host without
  a graph yet is empty, not broken. `read/1` reads an explicit path and
  returns `{:error, :enoent}` when it does not exist, so a mistyped
  `--beliefs` override surfaces as a missing collection instead of
  silently reading as empty (and forking a fresh graph on write).
  """
  def read do
    case read(Config.beliefs_path()) do
      {:error, :enoent} -> {:ok, []}
      other -> other
    end
  end

  def read(path) do
    with {:ok, raw} <- read_raw(path) do
      {:ok, Enum.map(raw, &Belief.from_map/1)}
    end
  end

  @doc "Alias for read/0. Reads all entries."
  def read_all, do: read()

  @doc """
  Read all entries as raw decoded maps (no struct boundary).

  For callers that need source-JSON fidelity (round-trip checks, prompt
  payload extraction). Returns `{:error, :enoent}` when the path does
  not exist, `{:error, :not_a_list}` when a single-file collection is
  not a JSON array.
  """
  def read_raw(path \\ nil) do
    path = path || Config.beliefs_path()

    cond do
      File.dir?(path) -> read_dir(path)
      File.exists?(path) -> read_file(path)
      true -> {:error, :enoent}
    end
  end

  @doc "Find a belief by ID or name."
  def find(id_or_name) do
    with {:ok, all} <- read() do
      case Enum.find(all, &(&1.id == id_or_name || &1.name == id_or_name)) do
        nil -> {:error, :not_found}
        belief -> {:ok, belief}
      end
    end
  end

  def write(beliefs, path \\ nil) do
    path = path || Config.beliefs_path()

    if dir_layout?(path) do
      write_dir(beliefs, path)
    else
      ordered = Enum.map(beliefs, &Belief.to_map/1)
      content = Jason.encode!(ordered, pretty: true) <> "\n"
      JSON.write_atomic_raw(path, content)
    end
  end

  @doc """
  The filename a belief id maps to in the per-belief layout: the local
  part (namespace stripped) plus `.json` - `cb:b554` -> `b554.json`.
  """
  def node_filename(id) when is_binary(id) do
    local_part(id) <> ".json"
  end

  defp local_part(id), do: id |> String.split(":") |> List.last()

  defp safe_id?(id) do
    is_binary(id) and Regex.match?(@safe_local, local_part(id))
  end

  # An existing path is what it is on disk; only a not-yet-existing
  # path falls back to the extension heuristic (write creates it).
  # Read and write share this predicate, so a collection read one way
  # is never written the other.
  defp dir_layout?(path) do
    cond do
      File.dir?(path) -> true
      File.exists?(path) -> false
      true -> not String.ends_with?(path, ".json")
    end
  end

  # --- single-file layout ---

  defp read_file(path) do
    case JSON.read(path) do
      {:ok, data} when is_list(data) -> {:ok, data}
      {:ok, _} -> {:error, :not_a_list}
      {:error, _} = err -> err
    end
  end

  # --- per-belief directory layout ---

  defp read_dir(dir) do
    with {:ok, paths} <- JSON.list_dir(dir) do
      paths
      |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
        case JSON.read(path) do
          {:ok, %{"id" => id} = node} when is_binary(id) -> {:cont, {:ok, [node | acc]}}
          {:ok, _} -> {:halt, {:error, {:bad_node, path}}}
          {:error, reason} -> {:halt, {:error, {:node_unreadable, path, reason}}}
        end
      end)
      |> case do
        {:ok, nodes} -> {:ok, Enum.sort_by(nodes, &natural_key(&1["id"]))}
        {:error, _} = err -> err
      end
    end
  end

  defp write_dir(beliefs, dir) do
    with :ok <- check_ids(beliefs),
         :ok <- ensure_dir(dir),
         {:ok, existing} <- JSON.list_dir(dir),
         desired = Enum.map(beliefs, fn b -> {node_filename(b.id), encode_node(b)} end),
         {:ok, staged} <- stage_nodes(desired, dir),
         :ok <- rename_staged(staged, MapSet.new(existing, &Path.basename/1), dir),
         :ok <- delete_removed(existing, MapSet.new(desired, &elem(&1, 0))) do
      {:ok, dir}
    end
  end

  defp check_ids(beliefs) do
    case Enum.reject(beliefs, &safe_id?(&1.id)) do
      [] ->
        names = Enum.map(beliefs, &node_filename(&1.id))

        case names -- Enum.uniq(names) do
          [] -> :ok
          dupes -> {:error, {:duplicate_node, Enum.uniq(dupes)}}
        end

      bad ->
        {:error, {:bad_id, Enum.map(bad, & &1.id)}}
    end
  end

  defp ensure_dir(dir) do
    case File.mkdir_p(dir) do
      :ok -> :ok
      {:error, reason} -> {:error, {:mkdir_failed, dir, reason}}
    end
  end

  # Phase one: write every new or changed node's content to a .tmp
  # sibling. Nothing in the store proper changes; a failure here cleans
  # the staging files up and leaves the collection exactly as it was.
  defp stage_nodes(desired, dir) do
    desired
    |> Enum.reduce_while({:ok, []}, fn {name, content}, {:ok, staged} ->
      path = Path.join(dir, name)

      case File.read(path) do
        {:ok, ^content} ->
          {:cont, {:ok, staged}}

        _missing_or_different ->
          case File.write(path <> ".tmp", content) do
            :ok -> {:cont, {:ok, [name | staged]}}
            {:error, reason} -> {:halt, {:error, {:node_write_failed, path, reason}}}
          end
      end
    end)
    |> case do
      {:ok, staged} -> {:ok, Enum.reverse(staged)}
      {:error, _} = err -> unstage(desired, dir) && err
    end
  end

  defp unstage(desired, dir) do
    Enum.each(desired, fn {name, _} -> File.rm(Path.join(dir, name <> ".tmp")) end)
    true
  end

  # Phase two: rename the staged files into place, additions before
  # changes (see the moduledoc on the crash window).
  defp rename_staged(staged, existing_names, dir) do
    {additions, changes} =
      Enum.split_with(staged, fn name -> not MapSet.member?(existing_names, name) end)

    (additions ++ changes)
    |> Enum.reduce_while(:ok, fn name, :ok ->
      path = Path.join(dir, name)

      case File.rename(path <> ".tmp", path) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:node_write_failed, path, reason}}}
      end
    end)
    |> case do
      :ok -> :ok
      err -> Enum.each(staged, fn name -> File.rm(Path.join(dir, name <> ".tmp")) end) && err
    end
  end

  # Only delete files this store would itself have written - a JSON
  # object carrying a string id. Foreign .json files are not ours to
  # remove.
  defp delete_removed(existing_paths, desired_names) do
    existing_paths
    |> Enum.reject(&MapSet.member?(desired_names, Path.basename(&1)))
    |> Enum.reduce_while(:ok, fn path, :ok ->
      case JSON.read(path) do
        {:ok, %{"id" => id}} when is_binary(id) ->
          case File.rm(path) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, {:node_delete_failed, path, reason}}}
          end

        _not_a_node ->
          {:cont, :ok}
      end
    end)
  end

  defp encode_node(belief) do
    Jason.encode!(Belief.to_map(belief), pretty: true) <> "\n"
  end

  # Natural sort key: digit runs compare numerically, so b1000 sorts
  # after b999 rather than between b099 and b101.
  defp natural_key(id) do
    id
    |> String.split(~r/\d+/, include_captures: true)
    |> Enum.map(fn run ->
      case Integer.parse(run) do
        {n, ""} -> {1, n, ""}
        _ -> {0, 0, run}
      end
    end)
  end
end
