defmodule Mix.Tasks.Cb.Migrate.Atomize do
  @moduledoc """
  Atomization migration, descriptive lane: apply a decomposition spec
  (plans/atomize/spec.json) to the live graph and emit the migrated
  graph as a parallel per-belief directory (default beliefs/cb-atomic).

  The live graph is never modified. The output is regenerable: rerunning
  with `--write` replaces the target directory wholesale, so the spec
  plus the live graph remain the only authorities. Swap is a separate,
  reviewed act of replacing beliefs/cb with the output.

  Dispositions (see plans/atomize/design.md):

  - `aggregate` - the node keeps its id and claim, retypes to
    aggregation, gains deps on newly minted single-sentence atom
    attestations, and appends one migration evidence entry naming them.
    Atoms inherit the parent's kind, domain, tags, subjects, and
    artifact, and carry one migration evidence entry citing the parent.
  - `trim` - an inference's claim is replaced with the spec's claim; a
    migration evidence entry records the rewrite.
  - `restate` - the prescriptive-lane disposition: the claim is rewritten
    to the norm, enumerable normative content lands in `invariants`, and
    descriptive rationale optionally extracts to atoms (kind from
    `atom_kind`, artifact from `atom_artifact` or the parent) that are
    appended to the prescription's deps. Unlike the descriptive lane,
    prescriptive entries are incremental - prescriptions without a spec
    entry pass through unchanged.
  - `keep` - passes through unchanged.

  Atom ids are allocated deterministically: aggregate nodes in ascending
  id order, then restate nodes in ascending id order (so the descriptive
  lane's atom ids stay stable as prescriptive entries accrete), numbered
  sequentially from the spec's `id_base`. The task refuses to run if an
  allocated id already exists in the graph.

  ## Usage

      mix cb.migrate.atomize                # Dry run against the default graph
      mix cb.migrate.atomize --write        # Emit beliefs/cb-atomic
      mix cb.migrate.atomize --spec plans/atomize/spec.json --target beliefs/cb-atomic --write

  ## Validation

  Refuses when: a spec node is missing from the graph or is not an
  active attestation/inference; an active attestation/inference has no
  spec entry; an aggregate entry has fewer than two atoms or a parent
  with no artifact to ground them; an allocated atom id collides with an
  existing id; or the assembled output repeats an id or contains a
  dependency cycle. On any write failure the partially written target is
  removed.
  """
  @shortdoc "Emit the atomized parallel graph from plans/atomize/spec.json"

  use Mix.Task

  alias CB.Belief
  alias CB.Belief.Store
  alias CB.Config

  @default_spec "plans/atomize/spec.json"
  @default_target "beliefs/cb-atomic"
  @descriptive_leaf_types ~w(attestation inference)

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [write: :boolean, spec: :string, target: :string, beliefs: :string]
      )

    if invalid != [] or positional != [] do
      IO.puts(
        :stderr,
        "Usage: mix cb.migrate.atomize [--spec PATH] [--target DIR] [--beliefs PATH] [--write]"
      )

      System.halt(1)
    end

    spec_path = opts[:spec] || @default_spec
    target = opts[:target] || @default_target
    beliefs_path = Path.expand(opts[:beliefs] || Config.beliefs_path())

    case atomize(spec_path, beliefs_path, target, opts[:write] || false) do
      {:ok, %{applied: true} = summary} ->
        IO.puts(
          :stderr,
          "\nAtomized graph written to #{summary.target} (#{summary.total} nodes). " <>
            "Verify with `mix cb.verify.schema --beliefs #{summary.target}` and " <>
            "query with `mix bs --beliefs #{summary.target} stats`."
        )

      {:ok, %{applied: false}} ->
        IO.puts(:stderr, "\nDry run. Pass --write to emit the target directory.")

      {:error, message} when is_binary(message) ->
        halt(message)

      {:error, why} ->
        halt(inspect(why))
    end
  end

  @doc """
  Plan (and with `write?` emit) the atomized graph. Returns
  `{:ok, %{total:, atoms:, aggregated:, trimmed:, kept:, target:, applied:}}`
  or `{:error, message}`.
  """
  def atomize(spec_path, beliefs_path, target, write?) do
    with {:ok, spec} <- read_spec(spec_path),
         {:ok, beliefs} <- read_graph(beliefs_path),
         :ok <- check_coverage(spec, beliefs),
         {:ok, allocation} <- allocate_ids(spec, beliefs),
         {:ok, output, stats} <- assemble(spec, beliefs, allocation),
         :ok <- check_output(output) do
      report(stats, beliefs_path, target)
      summary = Map.merge(stats, %{target: target, applied: write?})

      if write? do
        File.rm_rf(target)

        case Store.write(output, target) do
          {:ok, _} ->
            {:ok, summary}

          {:error, _} = err ->
            File.rm_rf(target)
            err
        end
      else
        {:ok, summary}
      end
    end
  end

  defp read_spec(path) do
    with {:ok, body} <- File.read(path),
         {:ok, %{"nodes" => nodes} = spec} when is_map(nodes) <- Jason.decode(body) do
      {:ok, spec}
    else
      {:error, %Jason.DecodeError{} = e} ->
        {:error, "spec #{path} is not valid JSON: #{Exception.message(e)}"}

      {:error, why} ->
        {:error, "cannot read spec #{path}: #{inspect(why)}"}

      {:ok, _} ->
        {:error, "spec #{path} carries no \"nodes\" object"}
    end
  end

  defp read_graph(path) do
    case Store.read(path) do
      {:ok, beliefs} -> {:ok, beliefs}
      {:error, why} -> {:error, "cannot read graph at #{path}: #{inspect(why)}"}
    end
  end

  # Spec and graph must agree on the descriptive lane: every active
  # attestation/inference has exactly one spec entry. Prescriptions are
  # the incremental lane - entries are validated but never required.
  defp check_coverage(spec, beliefs) do
    lane =
      beliefs
      |> Enum.filter(&(&1.status == "active" and &1.type in @descriptive_leaf_types))
      |> MapSet.new(& &1.id)

    active = beliefs |> Enum.filter(&(&1.status == "active")) |> MapSet.new(& &1.id)
    spec_ids = MapSet.new(Map.keys(spec["nodes"]))

    # A lane: "prescriptive" spec runs post-swap, where the descriptive
    # lane is consumed - only the entries it names are validated.
    missing =
      if spec["lane"] == "prescriptive",
        do: MapSet.new(),
        else: MapSet.difference(lane, spec_ids)

    extra = MapSet.difference(spec_ids, active)

    problems =
      Enum.map(Enum.sort(missing), &"active descriptive node #{&1} has no spec entry") ++
        Enum.map(
          Enum.sort(extra),
          &"spec entry #{&1} is not an active node in the graph"
        ) ++
        malformed_entries(spec, beliefs)

    case problems do
      [] ->
        :ok

      _ ->
        {:error, "spec does not cover the descriptive lane:\n  " <> Enum.join(problems, "\n  ")}
    end
  end

  defp malformed_entries(spec, beliefs) do
    by_id = Map.new(beliefs, &{&1.id, &1})

    Enum.flat_map(spec["nodes"], fn {id, entry} ->
      case {entry["disposition"], by_id[id]} do
        {"aggregate", %Belief{} = b} ->
          atoms = entry["atoms"] || []

          cond do
            b.type != "attestation" ->
              ["aggregate #{id} is a #{b.type}; only attestations retype to aggregation"]

            length(atoms) < 2 ->
              ["aggregate #{id} carries #{length(atoms)} atoms; minimum is 2"]

            !is_binary(b.artifact) ->
              ["aggregate #{id} has no artifact for its atoms to inherit"]

            Enum.any?(atoms, &(!is_binary(&1) or String.trim(&1) == "")) ->
              ["aggregate #{id} carries a blank atom"]

            true ->
              []
          end

        {"trim", %Belief{}} ->
          if is_binary(entry["claim"]) and String.trim(entry["claim"]) != "",
            do: [],
            else: ["trim #{id} carries no replacement claim"]

        {"restate", %Belief{} = b} ->
          atoms = entry["atoms"] || []

          cond do
            b.type != "prescription" ->
              ["restate #{id} is a #{b.type}; restate is the prescriptive-lane disposition"]

            !is_binary(entry["claim"]) or String.trim(entry["claim"]) == "" ->
              ["restate #{id} carries no replacement claim"]

            (entry["invariants"] || []) != [] and b.invariants != [] ->
              ["restate #{id} would clobber existing invariants; append is not supported"]

            atoms != [] and !is_binary(entry["atom_kind"]) ->
              ["restate #{id} mints atoms but names no atom_kind (a descriptive kind)"]

            atoms != [] and !is_binary(entry["atom_artifact"] || b.artifact) ->
              ["restate #{id} mints atoms but has no artifact for them (set atom_artifact)"]

            Enum.any?(atoms, &(!is_binary(&1) or String.trim(&1) == "")) ->
              ["restate #{id} carries a blank atom"]

            true ->
              []
          end

        {"keep", %Belief{}} ->
          []

        {other, %Belief{}} ->
          ["#{id} carries unknown disposition #{inspect(other)}"]

        {_, nil} ->
          # Already reported as extra by the caller.
          []
      end
    end)
  end

  # Deterministic: aggregate nodes ascending, atoms sequential from id_base.
  defp allocate_ids(spec, beliefs) do
    existing = MapSet.new(beliefs, & &1.id)
    base = spec["id_base"] || 700
    [ns | _] = String.split(hd(Enum.to_list(existing)) || "cb:x", ":")

    # Aggregates allocate before restates so the descriptive lane's atom
    # ids stay stable as prescriptive entries accrete incrementally.
    {allocation, _next} =
      spec["nodes"]
      |> Enum.filter(fn {_, e} -> (e["atoms"] || []) != [] end)
      |> Enum.sort_by(fn {id, e} -> {if(e["disposition"] == "aggregate", do: 0, else: 1), id} end)
      |> Enum.reduce({%{}, base}, fn {id, entry}, {acc, n} ->
        count = length(entry["atoms"])
        ids = Enum.map(n..(n + count - 1), &"#{ns}:b#{&1}")
        {Map.put(acc, id, ids), n + count}
      end)

    collisions =
      allocation |> Map.values() |> List.flatten() |> Enum.filter(&MapSet.member?(existing, &1))

    case collisions do
      [] ->
        {:ok, allocation}

      _ ->
        {:error,
         "allocated atom ids already exist in the graph: #{Enum.join(collisions, ", ")}; raise id_base"}
    end
  end

  defp assemble(spec, beliefs, allocation) do
    date = spec["date"] || "2026-07-07"

    {rewritten, minted} =
      Enum.map_reduce(beliefs, [], fn b, minted ->
        case spec["nodes"][b.id] do
          %{"disposition" => "aggregate"} = entry ->
            atom_ids = allocation[b.id]
            atoms = Enum.zip(atom_ids, entry["atoms"]) |> Enum.map(&mint_atom(&1, b, date))

            parent = %{
              b
              | type: "aggregation",
                # to_map serializes the raw stored type for round-trip
                # stability, so the retype must land on both fields.
                _raw_type: "aggregation",
                deps: atom_ids,
                evidence:
                  b.evidence ++
                    [
                      %{
                        "date" => date,
                        "detail" =>
                          "Atomization migration (plans/atomize): retyped attestation -> aggregation, id and claim unchanged; grounding decomposed into atoms #{Enum.join(atom_ids, ", ")}. Prior evidence entries remain the record of the original attestation event.",
                        "artifact" => "document:plans/atomize/design.md"
                      }
                    ]
            }

            {parent, minted ++ atoms}

          %{"disposition" => "trim"} = entry ->
            trimmed = %{
              b
              | claim: entry["claim"],
                evidence:
                  b.evidence ++
                    [
                      %{
                        "date" => date,
                        "detail" =>
                          "Atomization migration (plans/atomize): claim trimmed to its conclusion per claim discipline (cb:b402); the basis lives in deps. Previous claim: #{b.claim}",
                        "artifact" => "document:plans/atomize/design.md"
                      }
                    ]
            }

            {trimmed, minted}

          %{"disposition" => "restate"} = entry ->
            atom_ids = allocation[b.id] || []

            atoms =
              Enum.zip(atom_ids, entry["atoms"] || [])
              |> Enum.map(
                &mint_atom(&1, b, date, %{
                  kind: entry["atom_kind"],
                  artifact: entry["atom_artifact"] || b.artifact
                })
              )

            grounding =
              if atoms == [],
                do: "",
                else:
                  " Descriptive rationale extracted to atoms #{Enum.join(atom_ids, ", ")}, now deps."

            restated = %{
              b
              | claim: entry["claim"],
                invariants: entry["invariants"] || b.invariants,
                deps: b.deps ++ atom_ids,
                evidence:
                  b.evidence ++
                    [
                      %{
                        "date" => date,
                        "detail" =>
                          "Atomization migration (plans/atomize): claim restated to the norm; enumerable content moved to invariants.#{grounding} Previous claim: #{b.claim}",
                        "artifact" => "document:plans/atomize/design.md"
                      }
                    ]
            }

            {restated, minted ++ atoms}

          _ ->
            {b, minted}
        end
      end)

    output = rewritten ++ minted

    stats = %{
      total: length(output),
      atoms: length(minted),
      aggregated: Enum.count(spec["nodes"], fn {_, e} -> e["disposition"] == "aggregate" end),
      trimmed: Enum.count(spec["nodes"], fn {_, e} -> e["disposition"] == "trim" end),
      restated: Enum.count(spec["nodes"], fn {_, e} -> e["disposition"] == "restate" end),
      kept: Enum.count(spec["nodes"], fn {_, e} -> e["disposition"] == "keep" end)
    }

    {:ok, output, stats}
  end

  defp mint_atom(pair, parent, date, overrides \\ %{})

  defp mint_atom({id, claim}, %Belief{} = parent, date, overrides) do
    # Inherited keys the parent does not carry are dropped rather than
    # serialized as null/[] - the store's convention is absent keys.
    inherited =
      %{
        "kind" => overrides[:kind] || parent.kind,
        "domain" => parent.domain,
        "tags" => parent.tags,
        "subjects" => parent.subjects
      }
      |> Enum.reject(fn {_, v} -> v == nil or v == [] end)
      |> Map.new()

    Belief.from_map(
      Map.merge(inherited, %{
        "id" => id,
        "type" => "attestation",
        "claim" => claim,
        "artifact" => overrides[:artifact] || parent.artifact,
        "evidence" => [
          %{
            "date" => date,
            "detail" =>
              "Minted by the atomization migration (plans/atomize) as an atom of #{parent.id}; the source attestation event is recorded on #{parent.id}'s evidence.",
            "artifact" => overrides[:artifact] || parent.artifact
          }
        ],
        "deps" => [],
        "status" => "active",
        "created" => date
      })
    )
  end

  defp check_output(output) do
    ids = Enum.map(output, & &1.id)
    dupes = ids -- Enum.uniq(ids)

    cond do
      dupes != [] ->
        {:error, "output repeats ids: #{Enum.join(Enum.uniq(dupes), ", ")}"}

      true ->
        deps_map = Map.new(output, &{&1.id, &1.deps})
        check_acyclic(deps_map)
    end
  end

  defp check_acyclic(deps_map) do
    # Iterative peel: repeatedly drop nodes whose deps are all outside
    # the remaining set; anything left participates in a cycle.
    peel = fn remaining, peel ->
      {drop, stay} =
        Enum.split_with(remaining, fn {_, deps} ->
          Enum.all?(deps, &(!Map.has_key?(remaining, &1)))
        end)

      cond do
        stay == [] ->
          :ok

        drop == [] ->
          {:error,
           "dependency cycle among: #{stay |> Enum.map(&elem(&1, 0)) |> Enum.sort() |> Enum.join(", ")}"}

        true ->
          peel.(Map.new(stay), peel)
      end
    end

    peel.(deps_map, peel)
  end

  defp report(stats, beliefs_path, target) do
    IO.puts(:stderr, "Atomize #{beliefs_path} -> #{target}")
    IO.puts(:stderr, "  aggregated: #{stats.aggregated} nodes retyped to aggregation")
    IO.puts(:stderr, "  atoms:      #{stats.atoms} attestations minted")
    IO.puts(:stderr, "  trimmed:    #{stats.trimmed} claims")
    IO.puts(:stderr, "  restated:   #{stats.restated} prescriptions")
    IO.puts(:stderr, "  kept:       #{stats.kept} descriptive nodes unchanged")
    IO.puts(:stderr, "  total:      #{stats.total} nodes in output")
  end

  defp halt(message) do
    IO.puts(:stderr, "cb.migrate.atomize: #{message}")
    System.halt(1)
  end
end
