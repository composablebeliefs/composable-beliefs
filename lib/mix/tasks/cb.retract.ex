defmodule Mix.Tasks.Cb.Retract do
  @moduledoc """
  Retract a belief: mark it `status: retracted`, with a date and reason.

  The sanctioned front door for retiring a belief that should not have been
  asserted or no longer holds - the counterpart to `cb.repoint` for the
  `retract` mutation. Routes through `CB.Belief.Mutation` (`retract`) applied
  via `apply_batch/3` + `Store.write/2`, so the status change carries its own
  evidence trail through the same code every other write uses - no hand-rolled
  `.exs`. Per c053 a retracted node must carry a date and reason; both are
  required here.

  Retraction records "this should not stand" (it was wrong or moot). To replace
  a belief with a better one, supersede it through the adjudication flow
  instead - that records "this evolved", not "this was a mistake".

  ## Usage

      mix cb.retract <belief-id> --reason "..." --slug <slug>            # Dry run
      mix cb.retract <belief-id> --reason "..." --slug <slug> --write

  The belief id may be bare (`a548`) or namespaced (`cb:a548`); a bare id
  resolves when exactly one belief matches.

  ## Options

  - `--reason` (required) - why it is retracted; stored in `retracted_reason`
  - `--slug` (required) - provenance handle; stamped into the evidence detail
    (`via dag-proposal <slug>`) and the `session:<slug>` artifact
  - `--date` - ISO retraction date (`retracted_on`); defaults to today
  - `--beliefs PATH` - operate on an alternate collection (`CB_BELIEFS` works too)
  - `--write` - apply; without it the retraction is printed but not written

  ## Validation

  Refuses before writing if the id is missing/unknown/ambiguous, `--reason` or
  `--slug` is absent, the belief is not currently `active`, or the date is not a
  valid ISO date.
  """
  @shortdoc "Retract a belief (status -> retracted, with date + reason)"

  use Mix.Task

  alias CB.Belief.Graph
  alias CB.Belief.Mutation
  alias CB.Belief.Store

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [reason: :string, slug: :string, date: :string, write: :boolean, beliefs: :string]
      )

    if invalid != [] do
      flags = Enum.map_join(invalid, ", ", fn {flag, _} -> flag end)
      halt("unknown options: #{flags}")
    end

    if path = opts[:beliefs], do: Application.put_env(:cb, :beliefs_path, path)

    id =
      case positional do
        [only] ->
          only

        _ ->
          IO.puts(:stderr, usage())
          System.halt(1)
      end

    with {:ok, reason} <- require_opt(opts[:reason], "--reason"),
         {:ok, slug} <- require_opt(opts[:slug], "--slug"),
         {:ok, date} <- validate_date(opts[:date]) do
      on = date || Date.to_iso8601(CB.today())
      retract(id, reason, slug, on, opts[:write] || false)
    else
      {:error, message} -> halt(message)
    end
  end

  defp retract(id, reason, slug, date, write?) do
    with {:ok, beliefs} <- Store.read(),
         {:ok, plan} <- plan(beliefs, id, reason, slug, date) do
      {:ok, updated} = Mutation.apply_batch(plan.mutations, beliefs, slug: slug, date: date)
      report(plan)

      if write? do
        case Store.write(updated) do
          {:ok, _path} ->
            IO.puts(:stderr, "\nRetracted. Run `mix cb.verify.schema` to check conformance.")

          {:error, why} ->
            halt("error writing belief graph: #{inspect(why)}")
        end
      else
        IO.puts(:stderr, "\nDry run. Pass --write to apply.")
      end
    else
      {:error, why} when is_binary(why) -> halt(why)
      {:error, why} -> halt(inspect(why))
    end
  end

  @doc false
  def plan(beliefs, id, reason, slug, date) do
    with {:ok, canonical} <- resolve(beliefs, id) do
      belief = Enum.find(beliefs, &(&1.id == canonical))

      if belief.status != "active" do
        {:error, "#{canonical} is not active (status: #{belief.status}); nothing to retract"}
      else
        mutations = [
          %{
            type: "retract",
            id: slug,
            belief_id: canonical,
            after: %{"retracted_on" => date, "retracted_reason" => reason}
          }
        ]

        {:ok, %{belief_id: canonical, from_status: belief.status, reason: reason, date: date, mutations: mutations}}
      end
    end
  end

  defp resolve(beliefs, id) do
    case Graph.resolve_id(beliefs, id) do
      {:ok, canonical} ->
        {:ok, canonical}

      {:error, :not_found} ->
        {:error, "no belief with id: #{id}"}

      {:error, {:ambiguous, ids}} ->
        {:error, "ambiguous id '#{id}' matches: #{Enum.join(ids, ", ")} - qualify the namespace"}
    end
  end

  defp report(plan) do
    IO.puts("Retract")
    IO.puts(String.duplicate("=", 40))
    IO.puts("\n#{plan.belief_id}  (#{plan.from_status} -> retracted)")
    IO.puts("  on:     #{plan.date}")
    IO.puts("  reason: #{plan.reason}")
  end

  @doc false
  def require_opt(nil, flag), do: {:error, "#{flag} is required"}

  def require_opt(value, flag) do
    if String.trim(value) == "" do
      {:error, "#{flag} must not be empty"}
    else
      {:ok, value}
    end
  end

  @doc false
  def validate_date(nil), do: {:ok, nil}

  def validate_date(date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> {:ok, date}
      {:error, _} -> {:error, "--date must be an ISO date (YYYY-MM-DD), got: #{date}"}
    end
  end

  defp usage do
    "Usage: mix cb.retract <belief-id> --reason \"...\" --slug <slug> [--date YYYY-MM-DD] [--write]"
  end

  @spec halt(String.t()) :: no_return()
  defp halt(message) do
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end
end
