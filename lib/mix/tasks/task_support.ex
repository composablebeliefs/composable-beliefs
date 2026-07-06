defmodule CB.TaskSupport do
  @moduledoc """
  Shared plumbing for the mutation-door mix tasks (`cb.evidence`,
  `cb.repoint`, `cb.retract`, `cb.supersede`, `cb.import`): option
  validation, message-bearing id resolution, and the `--beliefs`
  collection override.

  Extracted once the helper trio had been copied into a fourth task
  verbatim - one home, so a change to the date validation or the
  not-found wording lands everywhere at once. The tasks `defdelegate`
  to these where the function is part of their tested public surface.
  """

  alias CB.Belief.Graph

  @doc "Validate a required string option: present and non-empty."
  @spec require_opt(String.t() | nil, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def require_opt(nil, flag), do: {:error, "#{flag} is required"}

  def require_opt(value, flag) do
    if String.trim(value) == "" do
      {:error, "#{flag} must not be empty"}
    else
      {:ok, value}
    end
  end

  @doc """
  Validate the optional `--date` value as an ISO 8601 date. `nil`
  passes through - callers default to today.
  """
  @spec validate_date(String.t() | nil) :: {:ok, String.t() | nil} | {:error, String.t()}
  def validate_date(nil), do: {:ok, nil}

  def validate_date(date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> {:ok, date}
      {:error, _} -> {:error, "--date must be an ISO date (YYYY-MM-DD), got: #{date}"}
    end
  end

  @doc """
  Resolve a bare or namespaced id against the belief list, turning
  `CB.Belief.Graph.resolve_id/2`'s error atoms into CLI messages. The
  optional `label` names which id failed when a task resolves several
  (`"--from"`, `"--to"`, ...).
  """
  @spec resolve([CB.Belief.t()], String.t(), String.t() | nil) ::
          {:ok, String.t()} | {:error, String.t()}
  def resolve(beliefs, id, label \\ nil) do
    labeled = if label, do: "#{label} ", else: ""

    case Graph.resolve_id(beliefs, id) do
      {:ok, canonical} ->
        {:ok, canonical}

      {:error, :not_found} ->
        {:error, "no belief with #{labeled}id: #{id}"}

      {:error, {:ambiguous, ids}} ->
        {:error,
         "ambiguous #{labeled}id '#{id}' matches: #{Enum.join(ids, ", ")} - qualify the namespace"}
    end
  end

  @doc """
  Apply a `--beliefs PATH` override for the current task invocation.

  Refuses a path that does not exist: with the per-belief default store
  a mistyped override would otherwise read as an empty collection and,
  on write, fork a fresh graph beside the real one. A task that means
  to create a new collection writes the empty collection first.
  """
  @spec beliefs_override(String.t() | nil) :: :ok | {:error, String.t()}
  def beliefs_override(nil), do: :ok

  def beliefs_override(path) do
    if File.exists?(path) do
      Application.put_env(:cb, :beliefs_path, path)
      :ok
    else
      {:error, "no collection at #{path} (check the --beliefs path; to start a new collection, create it first)"}
    end
  end
end
