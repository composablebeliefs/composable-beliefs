# Plan 1 - Collection predicates: methodology contracts that enforce themselves

Generalize the codepath predicate mechanism by one notch: predicates that receive the
**loaded collection union** (and optional rule params) instead of taking no
arguments. Route them from `method:` contracts; run them as a **static** verification
pass inside `cb.verify.collection`. Graph-shape predicates are pure traversal, so
this lands on the deterministic side of the boundary - no runtime, no app, no MCP.

**Status:** Proposed 2026-06-09. Nothing built.
**Date:** 2026-06-09
**Depends on:** plan-0 (the `method:` contracts to route from).
**Touches:** `lib/cb/eval/predicates.ex` (new); `lib/cb/codepath/predicates.ex` (extract shared resolve logic or alias it); `lib/cb/schema/verifier.ex` or a sibling `lib/cb/method/checks.ex` (the discovery + run pass); `lib/mix/tasks/cb.verify.collection.ex` (invoke the pass, report rows); the `cb:c046` rule-kind catalogue **only if** the `implies` fact shape gains an optional `params` field (one adjudicated supersession); tests.

## Context

`CB.Codepath.Predicates.resolve/2` enforces the inspection-only naming invariant and
refuses anything that is not an exported predicate - exactly the right gate, built
for zero-arity functions reading app state. Methodology checks differ in two ways:
their subject is the **collection itself** (so they need the union as an argument),
and they are **deterministic** (so they belong in static verification, not the
dynamic verifier). `CB.Codepath.Assertions.run/3` already supports `:module`
injection; this plan reuses that pattern rather than inventing a new one.

## Design

### Predicate signature

`CB.Eval.Predicates` (name follows the collection's concern, not AmIEval's brand):
exported functions `name?(beliefs, params)` where `beliefs :: [Belief.t()]` is the
loaded union and `params :: map()` comes from the routing rule (default `%{}`).
Returns boolean; non-boolean/raise normalizes to fail-with-detail, exactly as
codepath assertions do. The `c050` discipline carries over verbatim: names end in
`?`/`_check`, observe-only, resolve-or-refuse.

### Routing grammar (minimal extension)

`implies` rules on `method:` contracts route as today -
`{"when": {"verify": "collection"}, "requires": "verdicts_corroborated?"}` - with one
optional addition: a `"params"` map on the rule entry, passed through to the
predicate (`{"when": ..., "requires": "min_runs_met?", "params": {"min": 3}}`).
If `cb:c046`'s `implies` row is strict about fields, supersede it once to declare
the optional `params` column; if rule entries already tolerate extra keys, document
instead of superseding - decide by reading `CB.Belief.Contract.Implies`, not by
assumption.

### Discovery and execution (role-based, like everything else)

A `method-check` pass in collection verification:

1. From the loaded union, find active contract-grade implications carrying `implies`
   rules whose `when` includes `{"verify": "collection"}` (role discovery by rule
   shape, not by namespace or id - any collection may declare such contracts).
2. Resolve each routed name through the shared resolver against
   `CB.Eval.Predicates` (with `:module` injection for tests).
3. Invoke with the union + params; collect rows
   `{contract, predicate, pass|fail, detail}`.
4. Report in `cb.verify.collection` output alongside the schema checks; failures
   set the nonzero exit code. A collection with no such contracts skips the pass -
   skip, not fail, per house convention.

### The v1 predicate library (implements plan-0's contracts)

`verdicts_corroborated?`, `observations_cite_runlogs?`, `observation_subjects_complete?`,
`min_runs_met?` (params: `min`), `llm_judges_validated?`, `corrections_are_supersessions?`.
Each is a pure function over the union; each maps one-to-one to a `method:` contract;
detail strings name the offending belief ids (the failure message is the work order).

## Steps

1. Read `CB.Belief.Contract.Implies`; settle the `params` question; supersede
   `cb:c046` only if required.
2. Extract/share the resolve gate; implement `CB.Eval.Predicates` with the six v1
   predicates and unit tests over fixture collections (one passing, one violating
   each contract).
3. Implement the `method-check` pass + wire into `cb.verify.collection`; route the
   plan-0 contracts to the predicates (supersession of the `method:` contracts to
   add routing rules, or include routing at first authoring if plan-0 and plan-1
   land together).
4. CI: the pass runs wherever `cb.verify.collection` already runs.

## Acceptance criteria

- `mix cb.verify.collection <eval-namespace>` reports a `method-check` section; a
  fixture violating each `method:` contract fails its predicate with the offending
  ids named; the compliant fixture passes all six.
- `mix cb.verify.schema` and `mix cb.verify.codepath` are byte-identical in behavior
  (no coupling); the new pass adds zero runtime dependencies.
- `sdl` (re-homed on `method:` in plan-0) passes the full pass, or its violations
  are documented as known gaps in the example.

## Risks and non-goals

- **Boundary creep.** The temptation is predicates that read run logs off disk to
  "really" check provenance. No: collection predicates traverse beliefs only.
  Off-graph verification is a different tool with a different determinism story.
- **Two predicate worlds.** Codepath (zero-arity, app-reading, dynamic) and
  collection (arity-2, graph-reading, static) must stay visibly distinct - separate
  modules, separate runners, shared resolve gate. Folding them into one runner
  re-blurs the determinism boundary the codepath work carefully drew.
- **Param injection.** `params` comes from contract data; predicates must treat it
  as untrusted shape (validate keys, no atoms from strings) - same hygiene
  `resolve/2` already applies to names.
- **Non-goal:** running method checks from the dynamic verifier; predicate-driven
  *mutation* of any kind; an AmIEval-branded module name in cb.
