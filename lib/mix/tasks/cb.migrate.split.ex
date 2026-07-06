defmodule Mix.Tasks.Cb.Migrate.Split do
  @moduledoc """
  One-time migration: split a single-file belief collection into
  per-belief files (cb:b558).

  Reads a `beliefs.json` array, writes each node as its canonical
  serialization to `<collection-dir>/<ns>/<local>.json` (the layout
  cb:b554 records), verifies the directory loads back identical to the
  single-file collection, and removes the single file. The namespace
  directory lands next to the collection's `manifest.json`, so
  manifest resolution (`CB.Collection.depends_on/2`) is unchanged.

  ## Usage

      mix cb.migrate.split                          # Dry run on the default graph
      mix cb.migrate.split --write                  # Apply
      mix cb.migrate.split --beliefs okf/beliefs.json --write

  ## Options

  - `--beliefs PATH` - the single-file collection to split (defaults to
    the configured graph, `CB_BELIEFS` works too)
  - `--write` - apply; without it the plan is printed but nothing is
    written

  ## Validation

  Refuses if the path is already a directory (nothing to split), the
  file is not a JSON array, the collection carries more than one id
  namespace (local filenames strip the namespace, so mixed namespaces
  could collide), any id repeats, or - after writing - the node files
  do not decode back to exactly the raw JSON data the single file
  carried. The single file is only removed after that verification
  passes; on any write or verification failure the partially-written
  target directory is removed again, so the single file stays the
  authoritative store (CB.Config would otherwise prefer the directory
  the moment it exists).
  """
  @shortdoc "Split a single-file belief collection into per-belief files"

  use Mix.Task

  alias CB.Belief
  alias CB.Belief.Store
  alias CB.Config

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args, strict: [write: :boolean, beliefs: :string])

    if invalid != [] or positional != [] do
      IO.puts(:stderr, "Usage: mix cb.migrate.split [--beliefs PATH] [--write]")
      System.halt(1)
    end

    path = Path.expand(opts[:beliefs] || Config.beliefs_path())

    case split(path, opts[:write] || false) do
      {:ok, %{applied: true} = summary} ->
        IO.puts(
          :stderr,
          "\nSplit applied and verified (#{summary.count} nodes); removed " <>
            "#{path}.\nRun `mix cb.verify.schema` and `mix cb.generate.claude_md --check`."
        )

      {:ok, %{applied: false}} ->
        IO.puts(:stderr, "\nDry run. Pass --write to apply.")

      {:error, message} when is_binary(message) ->
        halt(message)

      {:error, why} ->
        halt(inspect(why))
    end
  end

  @doc """
  Plan (and with `write?` apply) the split of the single-file collection
  at `path`. Returns `{:ok, %{namespace:, count:, target:, applied:}}`
  or `{:error, message}`. Prints the plan to stderr.
  """
  def split(path, write?) do
    with :ok <- ensure_single_file(path),
         {:ok, beliefs} <- read(path),
         {:ok, ns} <- sole_namespace(beliefs),
         :ok <- ensure_unique_ids(beliefs),
         {:ok, target} <- target_dir(path, ns) do
      report(beliefs, ns, path, target)
      summary = %{namespace: ns, count: length(beliefs), target: target, applied: write?}

      if write? do
        case apply_split(beliefs, path, target) do
          :ok ->
            {:ok, summary}

          {:error, _} = err ->
            # A half-written or unverified target must not survive:
            # CB.Config prefers the beliefs/cb directory the moment it
            # exists, so leaving it in place would silently shadow the
            # still-authoritative single file on every subsequent read.
            File.rm_rf(target)
            err
        end
      else
        {:ok, summary}
      end
    end
  end

  defp apply_split(beliefs, path, target) do
    with {:ok, _} <- Store.write(beliefs, target),
         :ok <- verify_roundtrip(path, target) do
      File.rm!(path)
      :ok
    end
  end

  defp ensure_single_file(path) do
    cond do
      File.dir?(path) -> {:error, "#{path} is already a per-belief directory; nothing to split"}
      File.exists?(path) -> :ok
      true -> {:error, "no collection at #{path}"}
    end
  end

  defp read(path) do
    case Store.read(path) do
      {:ok, beliefs} -> {:ok, beliefs}
      {:error, :not_a_list} -> {:error, "#{path} is not a JSON array"}
      {:error, why} -> {:error, "cannot read #{path}: #{inspect(why)}"}
    end
  end

  defp sole_namespace(beliefs) do
    namespaces =
      beliefs
      |> Enum.map(fn %Belief{id: id} ->
        case String.split(id || "", ":") do
          [ns, _local] -> ns
          _ -> :unnamespaced
        end
      end)
      |> Enum.uniq()

    case namespaces do
      [ns] when is_binary(ns) -> {:ok, ns}
      [] -> {:error, "collection is empty; nothing to split"}
      _ -> {:error, "collection carries mixed id namespaces: #{inspect(namespaces)}"}
    end
  end

  defp ensure_unique_ids(beliefs) do
    ids = Enum.map(beliefs, & &1.id)

    case ids -- Enum.uniq(ids) do
      [] -> :ok
      dupes -> {:error, "duplicate ids: #{Enum.join(Enum.uniq(dupes), ", ")}"}
    end
  end

  defp target_dir(path, ns) do
    target = path |> Path.dirname() |> Path.join(ns)

    case File.ls(target) do
      {:error, :enoent} -> {:ok, target}
      {:ok, []} -> {:ok, target}
      {:ok, _} -> {:error, "target directory #{target} already exists and is not empty"}
      {:error, why} -> {:error, "cannot inspect target directory #{target}: #{inspect(why)}"}
    end
  end

  defp report(beliefs, ns, path, target) do
    IO.puts(:stderr, "Split #{path}")
    IO.puts(:stderr, "  namespace:  #{ns}")
    IO.puts(:stderr, "  nodes:      #{length(beliefs)}")
    IO.puts(:stderr, "  target:     #{target}/<local>.json")
    IO.puts(:stderr, "  then:       remove #{Path.basename(path)}")
  end

  # The node files must decode back to the same raw JSON data the
  # single file carried (order-independent; map equality, so key order
  # is irrelevant). Comparing raw-to-raw keeps the struct boundary out
  # of both sides: a lossy from_map/to_map would drop the same data
  # from both and verify clean if the structs were compared instead.
  # The single file is not removed unless this passes.
  defp verify_roundtrip(path, target) do
    with {:ok, source} <- Store.read_raw(path),
         {:ok, reloaded} <- Store.read_raw(target) do
      if by_id(source) == by_id(reloaded) do
        :ok
      else
        {:error,
         "verification failed: #{target} does not decode back identical to #{path}; " <>
           "the single file is authoritative and untouched"}
      end
    else
      {:error, why} -> {:error, "verification failed reading back: #{inspect(why)}"}
    end
  end

  defp by_id(raw_nodes), do: Map.new(raw_nodes, &{&1["id"], &1})

  defp halt(message) do
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end
end
