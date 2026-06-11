# cb-schema-v2 - The Four-Type Belief Schema

**Status:** Decided and executed in full 2026-06-10 (D1-D6 resolved, plans 0-4
landed the same day). Type enum is now `primitive | compound | inference |
directive`, one per epistemic operation (attest, aggregate, infer, prescribe);
contract remains the machine-checkable grade of a directive. Shipped in
composable-beliefs `364233f` and belief-collections `16e2fe8`, both pushed.
Divergences from the design are inline in `plans/cb-schema-v2/design.md` as
execution amendments and listed in full in the co-located transcript.
**Date:** 2026-06-10
**Depends on:** the cb-eval evidence ledger (the sdl/toy collections whose
verdict split is the worked migration); the contract interpreter family
(`CB.Belief.Contract.Table` carries the new kind-type check unchanged)
**Touches:** `lib/cb/belief.ex`, `lib/cb/schema/verifier.ex`, materializer /
conflict audit / filter / formatter / graph / eval predicates / collection
loader, new `lib/mix/tasks/cb.migrate.v2.ex`, `beliefs/beliefs.json` (through
the write flow), `codepath/`, all six belief-collections graphs, README,
quickstart, the five skills
**Full record:** `plans/cb-schema-v2/` - design.md (decided), plan-0..4 (each
with its execution record), why-inference.md (the naming rationale, now the
README's centerpiece section), proposals/ (every import spec and adjudication
record), transcript-execution.md (the thread)

## Context

The v1 `implication` type meant "prescription" but said "inference," and the
two moods it conflated leaked in documented places: theory-shaped content was
homeless, method:c2 policed a type boundary in prose, sdl:a006 carried a
falsifiable generalization and a prescription in one claim, and the machinery
already sorted cleanly by the hidden boundary (materialization, conflict audit,
contract grading on the prescriptive side; staleness and
supersession-on-evidence on the descriptive side). The ecosystem was eight
small collections across two repos, all ours, pre-launch - the
do-it-before-collections-proliferate moment.

## What landed

- **The boundary, made operational.** Direction of fit as the membership test
  (falsified -> inference; violated or withdrawn -> directive), and the type
  function `type = f(mood(kind), grounding, scope(subjects))` as enforcement:
  the kind-type derivation table (`cb:c057`, `method:c10` - a verdict is
  inference-only, a policy directive-only), the grounding rule (`cb:c059`:
  non-contract directives carry deps or a stipulation artifact -
  plan/user/session/document), and subject containment (`cb:c058`: a compound's
  subjects stay inside its deps' union; scope widening is the structural
  signature of inference).
- **Code and tool.** Four-value enum; the verifier's new checks; machinery
  re-attached across the boundary; manifests gain `schema_version: 2` with a
  hard loader gate; `mix cb.migrate.v2` applies the mechanical class and
  blocks `--write` on unresolved triage, with `--resolutions` carrying
  adjudicated judgment.
- **Canon through the front door.** Seven design primitives (a470-a476), six
  contract supersessions (c026/c027/c029/c031/c032/c038 -> c051-c056), three
  new contracts, the CLAUDE.md render-belief supersessions (a477-a482,
  c048 -> c060) with the compiled file regenerated, and the migration recorded
  as cb:a483.
- **The migrations.** cb: 76 re-typed (the inference type's first framework
  members: a131/a138/a173); codepath: 5; method: 14 plus c10/c11; sdl: the
  worked split (a006 -> a008 inference + a009 directive, a3 trimmed -> a010 per
  D3); toy: a9 -> a10+a11; agent-behavior: six mood re-homes (a396-a401) plus
  a072/a123 -> inference (a123 was the one genuine containment escape);
  paradigm: three syntheses -> inference; lib: mechanical under the grounding
  rule.
- **Docs.** README rewritten: a four-types section with "Why 'inference' - the
  edges define the territory" (the deductive/ampliative boundary, the compound
  as the one stored entailment, direction of fit), every transcript
  regenerated live, the sdl worked example walking all four types. Quickstart,
  skills, and design references updated.

## Acceptance, verified

All eight collections verify under v2; sdl reproduces exactly its two teaching
method-check failures (m-runs and m-judge-validation, now against sdl:a008);
toy fully green; 261 tests; codepath suite passes; `bs stale` clean; CLAUDE.md
`--check` green; every superseded canon contract walkable via `bs history`.

## Non-goals, still standing

Kind-enum pruning (separate sweep per a397's batching discipline);
inference-conflict audit / structured dissent (consensus-thread work, designed
against v2 but not in it); runtime decision-time hooks; importer changes
(`cb.import.eval` emits primitives only, untouched).
