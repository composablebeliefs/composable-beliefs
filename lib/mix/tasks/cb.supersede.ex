defmodule Mix.Tasks.Cb.Supersede do
  @moduledoc """
  Supersede a belief by an existing successor: mark it
  `status: superseded` with `superseded_by` pointing at the successor.

  The sanctioned front door for the deferred-supersession flip - the
  move a plan makes when a decision node is minted first and the node it
  refines is only flipped once the code (or the world) catches up, so
  the active graph never claims a reality ahead of its implementation
  (the cb:b554 -> cb:b112 pattern). Routes through `CB.Belief.Mutation`
  (`supersede`) applied via `apply_batch/3` + `Store.write/2`, so the
  status change carries its own evidence trail through the same code
  every other write uses - no hand-rolled `.exs`.

  To replace a belief with a *new* one, use the preflight -> adjudicate
  flow instead; it mints the successor and flips the predecessor in one
  atomic outcome. This task exists for successors that already stand in
  the graph.

  ## Usage

      mix cb.supersede <belief-id> --by <successor-id> --slug <slug>            # Dry run
      mix cb.supersede <belief-id> --by <successor-id> --slug <slug> --write

  Both ids may be bare (`b112`) or namespaced (`cb:b112`); a bare id
  resolves when exactly one belief matches.

  ## Options

  - `--by` (required) - the existing successor's id; must resolve to an
    active node in the graph
  - `--slug` (required) - provenance handle; stamped into the evidence
    detail (`via dag-proposal <slug>`) and the `session:<slug>` artifact
  - `--date` - ISO date for the evidence entry; defaults to today
  - `--beliefs PATH` - operate on an alternate collection (`CB_BELIEFS`
    works too)
  - `--write` - apply; without it the flip is printed but not written

  ## Validation

  Refuses before writing if either id is missing/unknown/ambiguous, the
  belief and successor are the same node, the belief is not currently
  `active`, the successor is not `active` (a terminal node cannot stand
  behind the graph as a replacement), or the date is not a valid ISO
  date.
  """
  @shortdoc "Supersede a belief by an existing successor (status -> superseded)"

  use Mix.Task

  alias CB.Belief.Mutation
  alias CB.Belief.Store

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [by: :string, slug: :string, date: :string, write: :boolean, beliefs: :string]
      )

    if invalid != [] do
      flags = Enum.map_join(invalid, ", ", fn {flag, _} -> flag end)
      halt("unknown options: #{flags}")
    end

    with {:error, message} <- CB.TaskSupport.beliefs_override(opts[:beliefs]) do
      halt(message)
    end

    id =
      case positional do
        [only] ->
          only

        _ ->
          IO.puts(:stderr, usage())
          System.halt(1)
      end

    with {:ok, by} <- require_opt(opts[:by], "--by"),
         {:ok, slug} <- require_opt(opts[:slug], "--slug"),
         {:ok, date} <- validate_date(opts[:date]) do
      on = date || Date.to_iso8601(CB.today())
      supersede(id, by, slug, on, opts[:write] || false)
    else
      {:error, message} -> halt(message)
    end
  end

  defp supersede(id, by, slug, date, write?) do
    with {:ok, beliefs} <- Store.read(),
         {:ok, plan} <- plan(beliefs, id, by, slug, date) do
      {:ok, updated} = Mutation.apply_batch(plan.mutations, beliefs, slug: slug, date: date)
      report(plan)

      if write? do
        case Store.write(updated) do
          {:ok, _path} ->
            IO.puts(:stderr, "\nSuperseded. Run `mix cb.verify.schema` to check conformance.")

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
  def plan(beliefs, id, by, slug, date) do
    with {:ok, belief_id} <- resolve(beliefs, id),
         {:ok, successor_id} <- resolve(beliefs, by) do
      belief = Enum.find(beliefs, &(&1.id == belief_id))
      successor = Enum.find(beliefs, &(&1.id == successor_id))

      cond do
        belief_id == successor_id ->
          {:error, "#{belief_id} cannot supersede itself"}

        belief.status != "active" ->
          {:error, "#{belief_id} is not active (status: #{belief.status}); nothing to supersede"}

        successor.status != "active" ->
          {:error,
           "successor #{successor_id} is not active (status: #{successor.status}); " <>
             "a terminal node cannot replace an active one"}

        true ->
          mutations = [
            %{type: "supersede", id: slug, belief_id: belief_id, successor: successor_id}
          ]

          {:ok,
           %{
             belief_id: belief_id,
             successor_id: successor_id,
             from_status: belief.status,
             date: date,
             mutations: mutations
           }}
      end
    end
  end

  defp resolve(beliefs, id), do: CB.TaskSupport.resolve(beliefs, id)

  defp report(plan) do
    IO.puts("Supersede")
    IO.puts(String.duplicate("=", 40))
    IO.puts("\n#{plan.belief_id}  (#{plan.from_status} -> superseded)")
    IO.puts("  by:   #{plan.successor_id}")
    IO.puts("  on:   #{plan.date}")
  end

  @doc false
  defdelegate require_opt(value, flag), to: CB.TaskSupport

  @doc false
  defdelegate validate_date(date), to: CB.TaskSupport

  defp usage do
    "Usage: mix cb.supersede <belief-id> --by <successor-id> --slug <slug> [--date YYYY-MM-DD] [--write]"
  end

  @spec halt(String.t()) :: no_return()
  defp halt(message) do
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end
end
