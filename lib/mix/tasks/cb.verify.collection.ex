defmodule Mix.Tasks.Cb.Verify.Collection do
  @moduledoc """
  Verify a belief collection together with the collections it depends on.

  A collection declares its `namespace` and cross-namespace `depends_on` in a
  `manifest.json` beside its `beliefs.json`. Many collections carry no schema
  vocabulary of their own - they borrow another collection's enum and lifecycle
  contracts (e.g. `agent-behavior:` and `paradigm:` lean on `cb:`'s
  `c039`/`c041`/`c029`). Verified in isolation, their `kind`/`domain`/
  `artifact-scheme` and status checks would *skip*, because the contracts that
  close those vocabularies are not present.

  This task resolves a collection's declared dependencies through a local
  registry, loads the union of all the graphs, and runs the same
  `CB.Schema.Verifier` over the union - so a dependent collection is actually
  checked against the vocabulary it borrows, and every cross-namespace dep is
  checked for resolvability. Where `mix cb.verify.schema` verifies one
  collection against the contracts it carries, this verifies a collection *in
  the context of* its declared dependencies.

  After the schema checks, the **method-check pass** (`CB.Method.Checks`)
  runs every routed methodology contract in the union: active `implies`-kind
  contracts whose rules route on `{"when": {"verify": "collection"}}` (e.g.
  the `method:` collection's m-* contracts) resolve to named predicates in
  `CB.Eval.Predicates` and execute over the union - pure traversal, fully
  deterministic. A union with no such contracts skips the pass.

  ## Usage

      mix cb.verify.collection NAMESPACE [--registry PATH] [--quiet]

      mix cb.verify.collection agent-behavior   # unions cb: + paradigm: + itself
      mix cb.verify.collection lib              # self-contained: loads only lib:

  The registry (default `../belief-collections/collections.json`, relative
  to the framework root) maps each namespace to its `beliefs.json`. Dependency
  resolution is transitive and cycle-safe - `agent-behavior:` and `paradigm:`
  depend on each other. A collection with no `manifest.json` is treated as a
  leaf (no dependencies).

  ## Exit codes

  0 = all pass (or skipped), 1 = resolution error or one or more failures
  """
  @shortdoc "Verify a collection together with its declared dependency collections"

  use Mix.Task

  alias CB.Collection
  alias CB.Schema.Verifier

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args,
        strict: [registry: :string, quiet: :boolean],
        aliases: [q: :quiet]
      )

    quiet = opts[:quiet] || false
    target = target_namespace(positional)

    registry_path = opts[:registry] || Collection.default_registry_path()
    reg = unwrap(Collection.registry(registry_path))

    # Target plus its transitive, cycle-safe depends_on closure (target first).
    %{collections: loaded, union: union} = unwrap(Collection.load_union(target, reg))

    unless quiet, do: print_context(target, loaded)

    # Cross-namespace dep resolvability over the union, then the schema
    # checks, then the method-check pass over routed methodology contracts.
    results =
      [check_dep_resolvability(union) | Verifier.check(union)] ++ method_check_results(union)

    shown = if quiet, do: Enum.filter(results, fn {_, s, _} -> s == :fail end), else: results
    Enum.each(shown, &print_result/1)

    {passes, failures, skipped} = tally(results)
    IO.puts("")

    IO.puts(
      "#{passes} passed, #{failures} failed, #{skipped} skipped (#{length(results)} checks)"
    )

    if failures > 0, do: System.halt(1)
  end

  # --- argument handling ---

  defp target_namespace([ns | _]), do: ns

  defp target_namespace([]) do
    IO.puts(:stderr, "Usage: mix cb.verify.collection NAMESPACE [--registry PATH] [--quiet]")
    System.halt(1)
  end

  # Unwrap a CB.Collection result, halting with a readable message on error so
  # the task keeps its exit-1-on-resolution-error contract.
  defp unwrap({:ok, value}), do: value
  defp unwrap({:error, reason}), do: halt_err(format_error(reason))

  defp format_error({:registry_unreadable, path, reason}),
    do: "cannot read registry #{path}: #{inspect(reason)}"

  defp format_error({:bad_registry, message}), do: message

  defp format_error({:unknown_namespace, ns}),
    do: "collection #{inspect(ns)} is not in the registry"

  defp format_error({:not_an_array, ns, path}),
    do: "collection #{ns} at #{path} is not a JSON array"

  defp format_error({:collection_unreadable, ns, path, reason}),
    do: "cannot read collection #{ns} at #{path}: #{inspect(reason)}"

  defp format_error(other), do: inspect(other)

  # --- checks ---

  # Every dep referenced anywhere in the union must resolve to a loaded node.
  # A dangling dep means a dependency collection is missing from depends_on.
  # Deps written before the b-serial id migration resolve through the
  # legacy letter-swap alias, so an unmigrated collection depending on
  # `cb:a386` still verifies against the migrated cb: graph.
  defp check_dep_resolvability(union) do
    ids = MapSet.new(union, & &1.id)

    resolves? = fn dep ->
      MapSet.member?(ids, dep) or
        MapSet.member?(ids, CB.Belief.legacy_id_alias(dep) || dep)
    end

    dangling = for b <- union, dep <- b.deps || [], not resolves?.(dep), do: {b.id, dep}

    if dangling == [] do
      {"cross-namespace deps resolve", :ok, "every dep resolves to a loaded node"}
    else
      {"cross-namespace deps resolve", :fail,
       "unresolved deps (missing dependency collection?): #{inspect(Enum.uniq(dangling))}"}
    end
  end

  # The method-check pass as result rows, one per routed rule. No routed
  # contracts in the union -> a single skip row, per house convention.
  defp method_check_results(union) do
    case CB.Method.Checks.run(union) do
      [] ->
        [{"method-check", :skip, "no contract routes on verify: collection"}]

      rows ->
        Enum.map(rows, fn row ->
          name = "method-check #{row.contract} #{row.name || row.predicate}"

          case row.result do
            "pass" -> {name, :ok, "#{row.predicate} holds over the union"}
            _ -> {name, :fail, "#{row.predicate}: #{row.detail}"}
          end
        end)
    end
  end

  # --- io ---

  defp print_context(target, loaded) do
    IO.puts("")
    IO.puts("Verifying #{target}: in context of #{length(loaded)} collection(s)")

    Enum.each(loaded, fn {ns, beliefs} ->
      role = if ns == target, do: "target", else: "dep"
      IO.puts("  #{String.pad_trailing(ns, 16)} #{length(beliefs)} beliefs (#{role})")
    end)

    IO.puts("")
  end

  defp tally(results) do
    {Enum.count(results, fn {_, s, _} -> s == :ok end),
     Enum.count(results, fn {_, s, _} -> s == :fail end),
     Enum.count(results, fn {_, s, _} -> s == :skip end)}
  end

  defp print_result({name, :ok, detail}), do: IO.puts("  PASS  #{name} - #{detail}")

  defp print_result({name, :fail, detail}) do
    IO.puts("  FAIL  #{name}")
    IO.puts("        #{detail}")
  end

  defp print_result({name, :skip, detail}), do: IO.puts("  SKIP  #{name} - #{detail}")

  defp halt_err(msg) do
    IO.puts(:stderr, "Error: #{msg}")
    System.halt(1)
  end
end
