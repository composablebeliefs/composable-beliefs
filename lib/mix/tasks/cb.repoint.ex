defmodule Mix.Tasks.Cb.Repoint do
  @moduledoc """
  Re-point a belief's dependency from one node to another.

  The sanctioned front door for dep re-points - the move a supersession
  ceremony makes when a render-contract (or any depended-on node) is
  superseded and every dependent must be swung from the old node to its
  successor. Routes through `CB.Belief.Mutation` as a `drop-dep` +
  `add-dep` pair applied in one atomic `apply_batch/3` pass, so the two
  halves land together or not at all and each appends its own evidence
  trail through the same code every other write uses - no hand-rolled
  `.exs` around `Mutation.apply_batch` and `Store.write`.

  ## Usage

      mix cb.repoint <belief-id> --from <dep> --to <dep> --slug <slug>            # Dry run
      mix cb.repoint <belief-id> --from <dep> --to <dep> --slug <slug> --write

  Every id - the belief, the `--from` dep, the `--to` dep - may be bare
  (`a522`) or namespaced (`cb:a522`); a bare id resolves when exactly one
  belief matches.

  ## Options

  - `--from` (required) - the dep id to drop; must currently be a dep of
    the belief
  - `--to` (required) - the dep id to add; must resolve to a node in the
    graph (refusal on dangling targets)
  - `--slug` (required) - provenance handle for the move; stamped into
    each evidence entry's detail (`via dag-proposal <slug>`) and used as
    the `session:<slug>` artifact
  - `--date` - ISO date for the evidence entries; defaults to today
  - `--beliefs PATH` - operate on an alternate collection (`CB_BELIEFS`
    env var works too)
  - `--write` - apply; without it the move is printed but not written

  ## Validation

  Exits non-zero before writing if the belief id is missing, unknown, or
  ambiguous; if `--from`/`--to`/`--slug` are absent; if `--to` does not
  resolve to a node in the graph (a dangling re-point target); if
  `--from` is not currently a dep of the belief; if `--to` is already a
  dep; if `--from` and `--to` resolve to the same node; or if the date
  is not a valid ISO date.
  """
  @shortdoc "Re-point a belief's dependency from one node to its successor"

  use Mix.Task

  alias CB.Belief.Graph
  alias CB.Belief.Mutation
  alias CB.Belief.Store

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [
          from: :string,
          to: :string,
          slug: :string,
          date: :string,
          write: :boolean,
          beliefs: :string
        ]
      )

    if invalid != [] do
      flags = Enum.map_join(invalid, ", ", fn {flag, _} -> flag end)
      halt("unknown options: #{flags}")
    end

    if path = opts[:beliefs], do: Application.put_env(:cb, :beliefs_path, path)

    id =
      case positional do
        [id] ->
          id

        _ ->
          IO.puts(:stderr, usage())
          System.halt(1)
      end

    with {:ok, from} <- require_opt(opts[:from], "--from"),
         {:ok, to} <- require_opt(opts[:to], "--to"),
         {:ok, slug} <- require_opt(opts[:slug], "--slug"),
         {:ok, date} <- validate_date(opts[:date]) do
      repoint(id, from, to, slug, date, opts[:write] || false)
    else
      {:error, message} -> halt(message)
    end
  end

  defp repoint(id, from, to, slug, date, write?) do
    with {:ok, beliefs} <- Store.read(),
         {:ok, plan} <- plan(beliefs, id, from, to, slug) do
      opts = if date, do: [slug: slug, date: date], else: [slug: slug]

      {:ok, updated} = Mutation.apply_batch(plan.mutations, beliefs, opts)
      report(plan)

      if write? do
        case Store.write(updated) do
          {:ok, _path} ->
            IO.puts(:stderr, "\nRe-pointed. Run `mix cb.verify.schema` to check conformance.")

          {:error, reason} ->
            halt("error writing belief graph: #{inspect(reason)}")
        end
      else
        IO.puts(:stderr, "\nDry run. Pass --write to apply.")
      end
    else
      {:error, reason} when is_binary(reason) -> halt(reason)
      {:error, reason} -> halt(inspect(reason))
    end
  end

  @doc """
  Build the re-point plan, or refuse with a reason.

  Pure over `beliefs`: resolves the belief and both dep ids, enforces
  that `from` is a current dep, `to` resolves to a real node and is not
  already a dep, and the two differ. On success returns a map with the
  canonical ids, the before/after dep lists, and the `drop-dep` +
  `add-dep` mutation pair (in that order) carrying absolute `after.deps`
  so `apply_batch` lands the same final list regardless of how the
  clauses thread state.
  """
  @spec plan([CB.Belief.t()], String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def plan(beliefs, id, from, to, slug) do
    with {:ok, canonical} <- resolve(beliefs, id, "belief"),
         {:ok, from_dep} <- resolve(beliefs, from, "--from"),
         {:ok, to_dep} <- resolve_target(beliefs, to) do
      belief = Enum.find(beliefs, &(&1.id == canonical))
      deps = belief.deps || []

      cond do
        from_dep == to_dep ->
          {:error, "--from and --to resolve to the same node (#{from_dep}) - nothing to re-point"}

        from_dep not in deps ->
          {:error, "#{from_dep} is not a dep of #{canonical} (deps: #{deps_str(deps)})"}

        to_dep in deps ->
          {:error, "#{to_dep} is already a dep of #{canonical}"}

        true ->
          after_drop = deps -- [from_dep]
          after_final = after_drop ++ [to_dep]

          mutations = [
            %{
              type: "drop-dep",
              id: slug,
              belief_id: canonical,
              dep: from_dep,
              after: %{"deps" => after_drop}
            },
            %{
              type: "add-dep",
              id: slug,
              belief_id: canonical,
              dep: to_dep,
              after: %{"deps" => after_final}
            }
          ]

          {:ok,
           %{
             belief_id: canonical,
             from: from_dep,
             to: to_dep,
             before: deps,
             after: after_final,
             mutations: mutations
           }}
      end
    end
  end

  # Resolve an id that must already name a belief. `--to` is the one id
  # whose absence means a dangling re-point target, so it routes here for
  # a target-specific message.
  defp resolve_target(beliefs, to) do
    case Graph.resolve_id(beliefs, to) do
      {:ok, canonical} ->
        {:ok, canonical}

      {:error, :not_found} ->
        {:error, "--to target #{to} is not a node in the graph - refusing a dangling re-point"}

      {:error, {:ambiguous, ids}} ->
        {:error,
         "ambiguous --to '#{to}' matches: #{Enum.join(ids, ", ")} - qualify the namespace"}
    end
  end

  defp resolve(beliefs, id, label) do
    case Graph.resolve_id(beliefs, id) do
      {:ok, canonical} ->
        {:ok, canonical}

      {:error, :not_found} ->
        {:error, "no belief with #{label} id: #{id}"}

      {:error, {:ambiguous, ids}} ->
        {:error,
         "ambiguous #{label} id '#{id}' matches: #{Enum.join(ids, ", ")} - qualify the namespace"}
    end
  end

  defp report(plan) do
    IO.puts("Dep re-point")
    IO.puts(String.duplicate("=", 40))
    IO.puts("\n#{plan.belief_id}")
    IO.puts("  #{plan.from} -> #{plan.to}")
    IO.puts("\nDeps before: #{deps_str(plan.before)}")
    IO.puts("Deps after:  #{deps_str(plan.after)}")
  end

  defp deps_str([]), do: "-"
  defp deps_str(deps), do: Enum.join(deps, ", ")

  @doc """
  Validate a required string option: present and non-empty.
  """
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
  passes through - the evidence entries default to today.
  """
  @spec validate_date(String.t() | nil) :: {:ok, String.t() | nil} | {:error, String.t()}
  def validate_date(nil), do: {:ok, nil}

  def validate_date(date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> {:ok, date}
      {:error, _} -> {:error, "--date must be an ISO date (YYYY-MM-DD), got: #{date}"}
    end
  end

  defp usage do
    "Usage: mix cb.repoint <belief-id> --from <dep> --to <dep> --slug <slug> [--date YYYY-MM-DD] [--write]"
  end

  @spec halt(String.t()) :: no_return()
  defp halt(message) do
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end
end
