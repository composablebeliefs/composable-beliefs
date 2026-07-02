defmodule CB.Commits do
  @moduledoc """
  The belief<->commit provenance loop (cb:a545, resolved as option 1).

  Two directions, both walked by `mix cb.verify.commits`:

  - **belief -> commit:** every `commit:` artifact cited in the graph
    (a belief's own `artifact` or an evidence entry's) must parse
    (`CB.CommitLocator`) and dereference to a real commit in the host
    repository.
  - **commit -> belief:** every `Belief:` trailer in the repository's
    commit history must name a node that exists in the graph. The
    trailer convention is one belief id per trailer line
    (`Belief: cb:a545`), the same mechanic as `Co-Authored-By:`.

  This module is pure: callers inject the resolver and the trailer
  source, so tests never need a fixture repository. The mix task wires
  in git.
  """

  alias CB.CommitLocator

  @typedoc "One commit: citation found in the graph."
  @type citation :: %{belief_id: String.t(), uri: String.t(), site: :artifact | :evidence}

  @doc "Every `commit:` URI cited across the graph, with its site."
  @spec citations([CB.Belief.t()]) :: [citation()]
  def citations(beliefs) do
    Enum.flat_map(beliefs, fn b ->
      own =
        if is_binary(b.artifact) and String.starts_with?(b.artifact, "commit:"),
          do: [%{belief_id: b.id, uri: b.artifact, site: :artifact}],
          else: []

      from_evidence =
        for e <- b.evidence || [],
            uri = e["artifact"],
            is_binary(uri) and String.starts_with?(uri, "commit:") do
          %{belief_id: b.id, uri: uri, site: :evidence}
        end

      own ++ from_evidence
    end)
  end

  @doc """
  Citations that fail to parse or to dereference.

  `resolver` takes a parsed locator and returns `:ok` or an error tuple;
  the mix task passes `&CommitLocator.resolve(&1, repo)`.
  """
  @spec unresolved([CB.Belief.t()], (CommitLocator.t() -> :ok | {:error, atom()})) ::
          [{citation(), atom()}]
  def unresolved(beliefs, resolver) do
    beliefs
    |> citations()
    |> Enum.flat_map(fn c ->
      case CommitLocator.parse(c.uri) do
        {:error, reason} ->
          [{c, reason}]

        {:ok, locator} ->
          case resolver.(locator) do
            :ok -> []
            {:error, reason} -> [{c, reason}]
          end
      end
    end)
  end

  @doc """
  Parse `Belief:` trailer references out of `git log` output produced
  with `--format=` set to `log_format/0`: one line per commit,
  `sha|id1,id2,...` (the id list empty for commits without trailers).

  Returns `[{sha, belief_id}]`.
  """
  @spec trailer_refs(String.t()) :: [{String.t(), String.t()}]
  def trailer_refs(log_output) do
    for line <- String.split(log_output, "\n", trim: true),
        [sha, ids] = String.split(line, "|", parts: 2),
        id <- String.split(ids, ",", trim: true) do
      {sha, String.trim(id)}
    end
  end

  @doc "The `git log --format=` string `trailer_refs/1` expects."
  @spec log_format() :: String.t()
  def log_format, do: "%H|%(trailers:key=Belief,valueonly,separator=%x2C)"

  @doc """
  Trailer refs naming belief ids absent from the graph.

  Refs written before the b-serial id migration resolve through the
  legacy letter-swap alias (`CB.Belief.legacy_id_alias/1`) - commit
  history is immutable, so a trailer citing `cb:a545` must keep naming
  the node now stored as `cb:b545`.
  """
  @spec dead_trailer_refs([{String.t(), String.t()}], [CB.Belief.t()]) ::
          [{String.t(), String.t()}]
  def dead_trailer_refs(refs, beliefs) do
    ids = MapSet.new(beliefs, & &1.id)

    Enum.reject(refs, fn {_sha, id} ->
      MapSet.member?(ids, id) or MapSet.member?(ids, CB.Belief.legacy_id_alias(id) || id)
    end)
  end

  @doc """
  Todo records whose recorded discharge commit (the `"commit"` key the
  cb:a563 gate writes) fails to parse or to dereference. Records
  without the key - pre-gate history, or explicitly `uncommitted` -
  are not checked.
  """
  @spec unresolved_todo_commits([map()], (CommitLocator.t() -> :ok | {:error, atom()})) ::
          [{String.t(), String.t(), atom()}]
  def unresolved_todo_commits(records, resolver) do
    for r <- records,
        sha = r["commit"],
        is_binary(sha),
        reason = check_sha(sha, resolver),
        reason != nil do
      {r["id"], sha, reason}
    end
  end

  defp check_sha(sha, resolver) do
    case CommitLocator.parse("commit:" <> sha) do
      {:error, reason} ->
        reason

      {:ok, locator} ->
        case resolver.(locator) do
          :ok -> nil
          {:error, reason} -> reason
        end
    end
  end
end
