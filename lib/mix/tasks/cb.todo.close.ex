defmodule Mix.Tasks.Cb.Todo.Close do
  @moduledoc """
  Flip a materialized todo item from open to done, with discharge notes.

  The sanctioned front door for the todo half of a discharge - the
  counterpart of `mix cb.evidence` on the belief half. Routes through
  `CB.Todos`, the same module the materializer's JSON sink appends
  through, so the collection's serialization is pinned by one code path
  and no flip needs a hand-rolled script.

  ## Usage

      mix cb.todo.close <todo-id> --notes "..." --commit <sha>      # Dry run
      mix cb.todo.close <todo-id> --notes "..." --commit <sha> --write
      mix cb.todo.close <todo-id> --notes "..." --no-commit --write

  ## Options

  - `--notes` (required) - the discharge notes; a record that already
    carries materialization-time notes keeps them, with the discharge
    notes appended as a new paragraph
  - `--commit <sha>` - the implementing commit, full 40-hex id; parsed
    by `CB.CommitLocator`, dereferenced against the repository, and
    recorded as a `commit` key on the record
  - `--no-commit` - explicitly record that nothing in the repository
    implements this discharge (`uncommitted: true` on the record); put
    the reason in the notes
  - `--repo PATH` - resolve `--commit` against another checkout
    (defaults to the current directory)
  - `--todos PATH` - operate on an alternate todo file (defaults to
    `CB.Config.todos_path/0`)
  - `--write` - apply; without it the flip is printed but not written

  ## Validation

  Exits non-zero before writing if the todo id is unknown, the record
  is not open (the flip is strictly open -> done), the notes are
  missing or empty, or the commit gate is unmet: exactly one of
  `--commit`/`--no-commit` is required (cb:a563 - silent omission is
  not a state), and a cited sha must parse and resolve to a real
  commit. Historical done records are untouched; the gate is
  prospective, enforced at this door.
  """
  @shortdoc "Flip a materialized todo item from open to done"

  use Mix.Task

  alias CB.Todos

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [
          notes: :string,
          todos: :string,
          write: :boolean,
          commit: :string,
          no_commit: :boolean,
          repo: :string
        ]
      )

    if invalid != [] do
      flags = Enum.map_join(invalid, ", ", fn {flag, _} -> flag end)
      halt("unknown options: #{flags}")
    end

    id =
      case positional do
        [id] ->
          id

        _ ->
          IO.puts(:stderr, usage())
          System.halt(1)
      end

    with {:ok, notes} <- validate_notes(opts[:notes]),
         {:ok, discharge} <-
           validate_discharge(opts[:commit], opts[:no_commit] || false, opts[:repo] || ".") do
      close(id, notes, discharge, opts[:todos], opts[:write] || false)
    else
      {:error, message} -> halt(message)
    end
  end

  defp close(id, notes, discharge, path, write?) do
    path = path || CB.Config.todos_path()

    with {:ok, records} <- Todos.read(path),
         {:ok, updated, closed} <- Todos.close(records, id, notes, discharge) do
      report(closed)

      if write? do
        case Todos.write(updated, path) do
          {:ok, _path} ->
            IO.puts(:stderr, "\nClosed.")

          {:error, reason} ->
            halt("error writing todo collection: #{inspect(reason)}")
        end
      else
        IO.puts(:stderr, "\nDry run. Pass --write to apply.")
      end
    else
      {:error, {:not_found, id}} ->
        halt("no todo with id: #{id}")

      {:error, {:not_open, id, status}} ->
        halt("todo #{id} is not open (status: #{status}) - the flip is strictly open -> done")

      {:error, reason} ->
        halt("error reading todo collection: #{inspect(reason)}")
    end
  end

  defp report(closed) do
    IO.puts("Todo close")
    IO.puts(String.duplicate("=", 40))
    IO.puts("\n#{closed["id"]} (source: #{closed["source"] || "-"})")
    IO.puts("  #{truncate(closed["action"], 76)}")
    IO.puts("\nStatus: open -> done")

    case closed do
      %{"commit" => sha} -> IO.puts("Commit: #{sha}")
      %{"uncommitted" => true} -> IO.puts("Commit: none (explicitly uncommitted)")
      _ -> :ok
    end

    IO.puts("Notes:  #{closed["notes"]}")
  end

  defp truncate(nil, _max), do: "-"

  defp truncate(text, max) do
    if String.length(text) > max, do: String.slice(text, 0, max - 1) <> "…", else: text
  end

  @doc """
  Validate the `--notes` value: required and non-empty.
  """
  @spec validate_notes(String.t() | nil) :: {:ok, String.t()} | {:error, String.t()}
  def validate_notes(nil), do: {:error, "--notes is required"}

  def validate_notes(notes) do
    if String.trim(notes) == "" do
      {:error, "--notes must not be empty"}
    else
      {:ok, notes}
    end
  end

  @doc """
  Validate the commit gate (cb:a563): exactly one of `--commit`/
  `--no-commit`, with a cited sha parsed by `CB.CommitLocator` and
  dereferenced against `repo`.
  """
  @spec validate_discharge(String.t() | nil, boolean(), Path.t()) ::
          {:ok, {:commit, String.t()} | :no_commit} | {:error, String.t()}
  def validate_discharge(nil, false, _repo) do
    {:error,
     "a close must cite its implementing commit (--commit <40-hex-sha>) or explicitly record that none exists (--no-commit, reason in --notes)"}
  end

  def validate_discharge(sha, true, _repo) when is_binary(sha) do
    {:error, "--commit and --no-commit are mutually exclusive"}
  end

  def validate_discharge(nil, true, _repo), do: {:ok, :no_commit}

  def validate_discharge(sha, false, repo) do
    case CB.CommitLocator.parse("commit:" <> sha) do
      {:ok, locator} ->
        case CB.CommitLocator.resolve(locator, repo) do
          :ok -> {:ok, {:commit, sha}}
          {:error, :not_found} -> {:error, "commit #{sha} not found in #{Path.expand(repo)}"}
        end

      {:error, :invalid_sha} ->
        {:error, "--commit must be a full 40-hex-char sha (got: #{sha})"}
    end
  end

  defp usage do
    "Usage: mix cb.todo.close <todo-id> --notes \"...\" (--commit <sha> | --no-commit) [--repo PATH] [--todos PATH] [--write]"
  end

  @spec halt(String.t()) :: no_return()
  defp halt(message) do
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end
end
