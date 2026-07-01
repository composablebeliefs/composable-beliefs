defmodule CB.CommitLocator do
  @moduledoc """
  Parse and resolve `commit:` artifact URIs - git commits cited as the
  change-events that implement or discharge beliefs.

  ## Grammar

      commit:<sha>

  - `<sha>` is the full 40-hex-char commit id, lowercase. Abbreviated
    hashes are rejected: a short hash can become ambiguous as the
    repository grows, while the full id is content-addressed and never
    drifts - the temporal analog of `code:`'s spatial anchor, without
    `code:`'s re-resolution problem.
  - Parsing is pure (the schema verifier's format check uses it);
    `resolve/2` shells out to git and is used by `mix cb.verify.commits`,
    which is where existence is enforced.

  The scheme is declared in the cb: graph's artifact-scheme enum contract
  (cb:c067); this module is the single parser the verifier and the
  resolution task share.
  """

  @type t :: %{sha: String.t()}

  @sha_pattern ~r/^[0-9a-f]{40}$/

  @doc """
  Parse a `commit:` URI into `%{sha: sha}`.

  Returns `{:error, reason}` with reason one of `:not_commit_scheme`,
  `:invalid_sha` (not 40 lowercase hex chars).
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, atom()}
  def parse("commit:" <> sha) do
    if Regex.match?(@sha_pattern, sha) do
      {:ok, %{sha: sha}}
    else
      {:error, :invalid_sha}
    end
  end

  def parse(uri) when is_binary(uri), do: {:error, :not_commit_scheme}

  @doc "True if the URI parses as a valid `commit:` locator."
  @spec valid?(term()) :: boolean()
  def valid?(uri) when is_binary(uri), do: match?({:ok, _}, parse(uri))
  def valid?(_), do: false

  @doc """
  Resolve a parsed locator against a git repository: does the commit
  exist? Returns `:ok` or `{:error, :not_found}`.

  `repo` defaults to the current working directory. Uses
  `git cat-file -e <sha>^{commit}`, which also rejects a sha that names
  a non-commit object.
  """
  @spec resolve(t(), Path.t()) :: :ok | {:error, :not_found}
  def resolve(%{sha: sha}, repo \\ ".") do
    case System.cmd("git", ["cat-file", "-e", sha <> "^{commit}"],
           cd: repo,
           stderr_to_stdout: true
         ) do
      {_, 0} -> :ok
      _ -> {:error, :not_found}
    end
  end
end
