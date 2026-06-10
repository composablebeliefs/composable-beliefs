# cb-eval - the eval evidence ledger

This plan set makes CB the **evidence and verdict layer** for published evals: every
finding authored as a belief collection; scorer observations as primitives citing run
artifacts; cross-ruler agreement as compounds; verdicts and routing guidance as
implications; corrections and model-snapshot changes as supersessions with `--cascade`
staleness. The reader-facing artifact is a **walkable audit tree** shipped with every
published verdict.

The boundary this set holds, on purpose: **CB is the ledger, not the lab bench.** Run
orchestration, sampling, retries, variance, and cost accounting live in an external
harness (Inspect). CB ingests the harness's *output record* and never grows toward
execution. Any step that would put run orchestration inside CB is out of scope by
decision, not omission.

## Decision record

- **Eval vocabulary lives in collections, not framework canon.** The `sdl` worked
  example already proves the pattern: a collection declares its own `eval:` scheme in
  its own enum contract, and `cb:c043` stays untouched. A base `method:` collection
  carries the shared eval vocabulary (schemes, kinds, domains, subjects conventions)
  plus the methodology contracts; each published eval is its own collection that
  `depends_on` it. No `cb:` enum supersession required anywhere in this set.
- **Methodology contracts enforce themselves.** The codepath work built the exact
  machinery needed: contracts route to named predicates (`cb:c047`), and the verifier
  discovers contracts by role. One generalization - predicates that receive the
  *loaded collection* instead of taking no arguments - turns methodology contracts
  from prose into machine-checked invariants over every eval collection. Critically,
  graph-shape predicates are pure traversal: **deterministic**, so they run as a
  static verification pass, on the `verify.schema` side of the determinism boundary,
  not the `verify.codepath` side.
- **Ingestion is a manifest, not an integration.** CB stays harness-agnostic and
  Python-free: it imports a neutral **run-manifest** JSON. A thin adapter per harness
  (Inspect first) converts native logs to the manifest and lives in the eval repo,
  not in CB. Aggregation policy is explicit in the manifest: run-level aggregate
  observations always; per-case observations only for cases marked load-bearing.
- **The audit tree is the product surface.** A self-contained static HTML render of
  `bs tree` (plus evidence artifacts, supersession badges, staleness flags) is what
  readers click. No reader installs Elixir.

## The series

| Plan | What it delivers | Lib changes? | Depends on |
|---|---|---|---|
| [plan-0](plan-0-method-collection.md) | The `method:` base collection: eval vocabulary + methodology contracts v1 | no | nothing |
| [plan-1](plan-1-collection-predicates.md) | Collection-scoped predicates + the `method-check` static verification pass | **yes** | plan-0 |
| [plan-2](plan-2-run-manifest-ingest.md) | The run-manifest format + `cb.import.eval` + the Inspect adapter contract | **yes** | plan-0 |
| [plan-3](plan-3-audit-render.md) | `cb.render.audit`: the self-contained HTML/JSON audit tree | **yes** | plan-0 (plan-2 for a real fixture) |

Plans 1, 2, and 3 are independent of each other and can land in any order after
plan-0. The first published AmIEval finding needs plan-0 + plan-2 + plan-3;
plan-1 can follow within the same cycle (the methodology contracts verify as prose
invariants until it lands).

## Sequencing rule (mission gate)

Each plan ends when its acceptance criteria pass against a **real eval run**, not a
synthetic fixture, except where noted. The set as a whole is done when one actual
finding ships end to end: harness run -> manifest -> import -> verified collection ->
rendered audit tree published beside the post. Framework polish beyond that bar is a
new plan set with its own justification.

## Non-goals (whole set)

Run orchestration, model API calls, sampling, retries, or scoring inside CB; a CB
Python package; canary management or public/private split tooling (instance data
never enters CB - the graph holds observations *about* runs, and its artifacts point
at logs, not at task instances); a hosted viewer or dashboard work; changes to
`cb:c043` or any framework-canon enum; multi-harness adapters beyond Inspect.
