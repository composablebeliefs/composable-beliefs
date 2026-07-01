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

  Requires full history: run on a shallow CI clone with
  `fetch-depth: 0`, or the belief->commit direction reports false
  negatives.

  ## Usage

      mix cb.verify.commits
      mix cb.verify.commits --beliefs PATH   # verify an alternate collection
      mix cb.verify.commits --repo PATH      # resolve against another checkout

  ## Exit codes

  0 = both directions clean, 1 = unresolved citations or dead trailers
  """
  @shortdoc "Verify commit: artifacts resolve and Belief: trailers name live beliefs"

  use Mix.Task

  alias CB.{CommitLocator, Commits}
  alias CB.Belief.Store, as: BeliefStore

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [beliefs: :string, repo: :string])

    if opts[:beliefs], do: System.put_env("CB_BELIEFS", opts[:beliefs])
    repo = opts[:repo] || "."

    case BeliefStore.read() do
      {:ok, beliefs} ->
        unresolved = Commits.unresolved(beliefs, &CommitLocator.resolve(&1, repo))
        dead = Commits.dead_trailer_refs(trailer_refs(repo), beliefs)
        report(beliefs, unresolved, dead)

      {:error, reason} ->
        IO.puts(:stderr, "cannot read belief graph: #{inspect(reason)}")
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

  defp report(beliefs, unresolved, dead) do
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

    if unresolved != [] or dead != [], do: exit({:shutdown, 1})
  end
end
