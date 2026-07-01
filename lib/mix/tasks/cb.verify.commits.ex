defmodule Mix.Tasks.Cb.Verify.Commits do
  @moduledoc """
  Verify the belief<->commit provenance loop in both directions.

  The `commit:` artifact scheme (cb:c067) makes the change-event rung of
  the audit chain structural; this task is the enforcement half that
  gives the scheme its value (cb:a545: "the scheme alone buys nothing").
  It checks:

  - **belief -> commit:** every `commit:` URI cited in the graph (a
    belief's `artifact` or an evidence entry's `artifact`) parses per
    `CB.CommitLocator` and dereferences to a real commit in the host
    repository (`git cat-file -e`).
  - **commit -> belief:** every `Belief:` trailer in the repository's
    commit history names a node present in the graph. The convention is
    one id per trailer line: `Belief: cb:a545`.
  - **done -> commit:** every todo record carrying a `commit` key (the
    cb:a563 gate's marker) dereferences to a real commit. Pre-gate
    records and explicitly `uncommitted` discharges carry no key and
    are not checked.

  Requires full history: run on a shallow CI clone with
  `fetch-depth: 0`, or the belief->commit direction reports false
  negatives.

  ## Usage

      mix cb.verify.commits
      mix cb.verify.commits --beliefs PATH   # verify an alternate collection
      mix cb.verify.commits --todos PATH     # verify an alternate todo file
      mix cb.verify.commits --repo PATH      # resolve against another checkout

  ## Exit codes

  0 = all directions clean, 1 = unresolved citations, dead trailers,
  or unresolved todo commits
  """
  @shortdoc "Verify commit: artifacts resolve and Belief: trailers name live beliefs"

  use Mix.Task

  alias CB.{CommitLocator, Commits}
  alias CB.Belief.Store, as: BeliefStore

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [beliefs: :string, todos: :string, repo: :string])

    if opts[:beliefs], do: System.put_env("CB_BELIEFS", opts[:beliefs])
    repo = opts[:repo] || "."
    resolver = &CommitLocator.resolve(&1, repo)

    case BeliefStore.read() do
      {:ok, beliefs} ->
        unresolved = Commits.unresolved(beliefs, resolver)
        dead = Commits.dead_trailer_refs(trailer_refs(repo), beliefs)
        todo_unresolved = Commits.unresolved_todo_commits(todo_records(opts[:todos]), resolver)
        report(beliefs, unresolved, dead, todo_unresolved)

      {:error, reason} ->
        IO.puts(:stderr, "cannot read belief graph: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp todo_records(path) do
    case CB.Todos.read(path || CB.Config.todos_path()) do
      {:ok, records} ->
        records

      {:error, reason} ->
        IO.puts(:stderr, "cannot read todo collection: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp trailer_refs(repo) do
    case System.cmd("git", ["log", "--format=" <> Commits.log_format()],
           cd: repo,
           stderr_to_stdout: true
         ) do
      {out, 0} ->
        Commits.trailer_refs(out)

      {out, _} ->
        IO.puts(:stderr, "git log failed (shallow clone?): #{String.trim(out)}")
        exit({:shutdown, 1})
    end
  end

  defp report(beliefs, unresolved, dead, todo_unresolved) do
    cited = length(Commits.citations(beliefs))

    if unresolved == [] do
      IO.puts("  PASS  belief -> commit: #{cited} commit: citation(s) all resolve")
    else
      IO.puts("  FAIL  belief -> commit: unresolved citations:")

      for {c, reason} <- unresolved do
        IO.puts("        #{c.belief_id} (#{c.site}) #{c.uri} - #{reason}")
      end
    end

    if dead == [] do
      IO.puts("  PASS  commit -> belief: all Belief: trailers name live beliefs")
    else
      IO.puts("  FAIL  commit -> belief: trailers naming absent beliefs:")
      for {sha, id} <- dead, do: IO.puts("        #{String.slice(sha, 0, 10)} Belief: #{id}")
    end

    if todo_unresolved == [] do
      IO.puts("  PASS  done -> commit: all recorded todo discharge commits resolve")
    else
      IO.puts("  FAIL  done -> commit: unresolved todo discharge commits:")

      for {id, sha, reason} <- todo_unresolved do
        IO.puts("        #{id} commit:#{sha} - #{reason}")
      end
    end

    if unresolved != [] or dead != [] or todo_unresolved != [], do: exit({:shutdown, 1})
  end
end
