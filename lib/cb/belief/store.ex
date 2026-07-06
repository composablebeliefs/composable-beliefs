defmodule CB.Belief.Store do
  @moduledoc """
  Reads and writes the belief graph. The sole place that knows the
  on-disk layout (cb:b555): every reader and writer goes through here.

  Two layouts are supported:

  - a single JSON array file (`beliefs.json`) - the legacy layout, kept
    as the fallback for unsplit collections;
  - a per-belief directory (`beliefs/<ns>/<local>.json`, cb:b554) where
    each file holds one node's canonical serialization. A path that is
    an existing directory (or lacks a `.json` extension) selects this
    layout.

  Reads return beliefs sorted by id (natural order, so `b1000` follows
  `b999`) for the directory layout; a single-file collection keeps its
  stored order. Writes are atomic via tmp + rename. All entries are
  beliefs - contract-grade beliefs are distinguished by having `rules`
  and/or `invariants` fields.
  """

  alias CB.Belief
  alias CB.Config
  alias CB.JSON

  @doc """
  Read all entries from the belief graph as beliefs.

  `read/0` reads the configured collection (`CB.Config.beliefs_path/0`);
  `read/1` reads an explicit path. A missing path reads as the empty
  collection.
  """
  def read do
    read(Config.beliefs_path())
  end

  def read(path) do
    case read_raw(path) do
      {:ok, raw} -> {:ok, Enum.map(raw, &Belief.from_map/1)}
      {:error, :enoent} -> {:ok, []}
      {:error, _} = err -> err
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
  def node_filename(id) do
    (id |> String.split(":") |> List.last()) <> ".json"
  end

  # A directory selects the per-belief layout; so does a not-yet-existing
  # path without a .json extension (write creates it). An explicit .json
  # file path stays single-file.
  defp dir_layout?(path) do
    File.dir?(path) or not String.ends_with?(path, ".json")
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
          {:ok, node} when is_map(node) -> {:cont, {:ok, [node | acc]}}
          {:ok, _} -> {:halt, {:error, {:bad_node, path}}}
          {:error, reason} -> {:halt, {:error, {:node_unreadable, path, reason}}}
        end
      end)
      |> case do
        {:ok, nodes} -> {:ok, Enum.sort_by(nodes, &natural_key(&1["id"] || ""))}
        {:error, _} = err -> err
      end
    end
  end

  defp write_dir(beliefs, dir) do
    File.mkdir_p!(dir)
    desired = Enum.map(beliefs, fn b -> {node_filename(b.id), encode_node(b)} end)
    names = Enum.map(desired, &elem(&1, 0))
    dupes = names -- Enum.uniq(names)

    if dupes != [] do
      {:error, {:duplicate_node, Enum.uniq(dupes)}}
    else
      {:ok, existing} = JSON.list_dir(dir)
      existing_names = MapSet.new(existing, &Path.basename/1)

      # New nodes land before changed ones, so a crash mid-supersession
      # (successor written, predecessor not yet flipped) leaves a
      # duplicate-claim conflict the preflight detects, never a dangling
      # superseded_by reference.
      {additions, changes} =
        Enum.split_with(desired, fn {name, _} -> not MapSet.member?(existing_names, name) end)

      with :ok <- write_nodes(additions ++ changes, dir) do
        desired_names = MapSet.new(names)

        existing_names
        |> Enum.reject(&MapSet.member?(desired_names, &1))
        |> Enum.each(&File.rm!(Path.join(dir, &1)))

        {:ok, dir}
      end
    end
  end

  defp write_nodes(named_contents, dir) do
    Enum.reduce_while(named_contents, :ok, fn {name, content}, :ok ->
      path = Path.join(dir, name)

      # Skip byte-identical files so untouched nodes never churn in git.
      if File.exists?(path) and File.read!(path) == content do
        {:cont, :ok}
      else
        case JSON.write_atomic_raw(path, content) do
          {:ok, _} -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, {:node_write_failed, path, reason}}}
        end
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
