defmodule CB.Todos do
  @moduledoc """
  Store for the materialized-todo collection.

  The todo file is the materializer's default sink target: a JSON array
  of generic todo records (`id`, `action`, `source`, `created`,
  `status`, optional `notes`). This module owns its serialization -
  read, atomic write, and the status flip - so every writer goes
  through the same code and the encoding cannot drift between the
  append path (`CB.Materializer.Sink.JSON`) and the close path
  (`mix cb.todo.close`).

  Records are plain string-keyed maps; the JSON encoder emits map keys
  in sorted order, so a read-modify-write roundtrip leaves untouched
  records byte-identical.
  """

  alias CB.Config
  alias CB.JSON

  @doc """
  Read the todo array at `path`. A missing file reads as `[]`.

  Returns `{:ok, records}`, `{:error, :todos_not_a_list}` when the file
  holds something other than a JSON array, or `{:error, {:read_failed,
  reason}}`.
  """
  def read(path \\ Config.todos_path()) do
    if File.exists?(path) do
      case JSON.read(path) do
        {:ok, list} when is_list(list) -> {:ok, list}
        {:ok, _} -> {:error, :todos_not_a_list}
        {:error, reason} -> {:error, {:read_failed, reason}}
      end
    else
      {:ok, []}
    end
  end

  @doc """
  Atomically write the todo array to `path`.

  Returns `{:ok, path}` or `{:error, reason}`.
  """
  def write(records, path \\ Config.todos_path()) when is_list(records) do
    content = Jason.encode!(records, pretty: true) <> "\n"
    JSON.write_atomic_raw(path, content)
  end

  @doc """
  Flip an open record to done, recording discharge notes and the
  discharge's commit provenance. Pure - takes and returns the record
  list; persisting is the caller's `write/2`.

  `discharge` is the cb:a563 gate made explicit:

  - `{:commit, sha}` - the implementing commit; recorded as a `"commit"`
    key on the record. Validation (format and existence) is the
    caller's job (`mix cb.todo.close` runs `CB.CommitLocator`).
  - `:no_commit` - nothing in the repository implements this discharge;
    recorded as `"uncommitted": true` so a post-gate record always
    carries exactly one of the two markers. The reason belongs in the
    notes.

  A record that already carries notes (materialization-time
  traceability) keeps them; the discharge notes are appended as a new
  paragraph.

  Returns `{:ok, updated_records, closed_record}`,
  `{:error, {:not_found, id}}`, or `{:error, {:not_open, id, status}}`.
  """
  def close(records, id, notes, discharge) do
    case Enum.find(records, &(&1["id"] == id)) do
      nil ->
        {:error, {:not_found, id}}

      %{"status" => "open"} = record ->
        closed =
          record
          |> Map.put("status", "done")
          |> put_notes(notes)
          |> put_discharge(discharge)

        updated = Enum.map(records, fn r -> if r["id"] == id, do: closed, else: r end)
        {:ok, updated, closed}

      %{"status" => status} ->
        {:error, {:not_open, id, status}}
    end
  end

  defp put_discharge(record, {:commit, sha}), do: Map.put(record, "commit", sha)
  defp put_discharge(record, :no_commit), do: Map.put(record, "uncommitted", true)

  defp put_notes(record, notes) do
    case record["notes"] do
      existing when is_binary(existing) and existing != "" ->
        Map.put(record, "notes", existing <> "\n\n" <> notes)

      _ ->
        Map.put(record, "notes", notes)
    end
  end
end
