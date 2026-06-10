# Plan 0 - The `method:` base collection: eval vocabulary + methodology contracts v1

Author the base collection that every published eval collection depends on. Pure
authoring through the existing write flow - no lib changes. This is the
methodology-as-contracts move: the invariant container (judge validation, minimum
runs, corroboration discipline, correction protocol) becomes versioned, supersedable,
citable graph structure instead of prose policy.

**Status:** Proposed 2026-06-09. Nothing built.
**Date:** 2026-06-09
**Depends on:** nothing (uses existing collection/manifest/registry mechanics).
**Touches:** a new collection in the sibling `belief-collections` repo (`method/beliefs.json` + `manifest.json`); `collections.json` (registry entry); no `composable-beliefs` code.

## Context

The `sdl` example established the shape: an eval collection with its own `eval:`
scheme enum, subjects for `eval`/`run`/`case`/`model`/`model_version`/`ruler`, and
the primitive -> compound -> implication evidence chain. What it improvised
per-collection, this plan promotes to a shared base so every published eval borrows
one vocabulary and is verified against one set of methodology contracts. Collections
already borrow vocabulary via `depends_on` and role-based verifier discovery; this
plan only exercises that.

Namespace name (`method:` here) is the author's call - decide before import; ids are
immutable after.

## Design

### Vocabulary contracts (enum-registry kind, per `cb:c046`)

- **Artifact-scheme enum** for eval collections: `eval:` (identity URI for a scorer
  run: `eval:<eval-id>/<run>/<case>/<ruler>` and aggregate forms
  `eval:<eval-id>/<run>/<ruler>`), plus borrowed `document:`, `https:`, `session:`,
  `user:` for logs, sources, and authorship. Declared here once; eval collections
  inherit it.
- **`kind` enum** for eval work: at minimum `observation`, `verdict`, `guidance`,
  `definition`, `protocol`. Reuse `cb:` kinds where they fit; declare only what eval
  collections need.
- **`domain` enum**: `eval` plus the task domains as they accrue (additions are enum
  supersessions per the established discipline).

### Subjects conventions (primitives, citable)

One primitive per convention, so eval collections can cite them as deps:
the six-subject convention on scorer observations (`eval`, `run`, `case`, `model`,
`model_version`, `ruler`); `model-version/<model>@<snapshot>` as the staleness pivot;
`outcome:<value>` tags; "the verdict is superseded on new snapshots, observations
never are."

### Methodology contracts v1 (the container, frozen)

Contract-grade implications, each with rules/invariants stated precisely enough to
become routed predicates in plan-1 (until then they verify as prose):

- **m-corroboration**: every active `kind:verdict` implication depends (directly or
  transitively) on at least one compound tagged `cross-ruler-agreement`, or carries
  tag `single-ruler` explicitly (the escape hatch is visible, not silent).
- **m-provenance**: every active `kind:observation` primitive carries an `eval:`
  artifact and at least one evidence entry whose `artifact` points at a raw log
  (`document:` or `https:`).
- **m-subjects**: every `kind:observation` primitive carries the six conventional
  subjects; aggregates may omit `case`.
- **m-runs**: every `kind:verdict` cites (via subjects or deps) at least N distinct
  runs; N is a parameter of the contract's rule entry, set to the house minimum.
- **m-judge-validation**: any observation whose `ruler` is an LLM judge must be
  joined by a primitive citing that judge's human-agreement validation record for
  this eval (the kappa/agreement artifact).
- **m-correction**: corrections are supersessions with a `correction` tag and a
  dated evidence entry; never retractions without successor unless the finding is
  withdrawn entirely.

### Versioning

The methodology version is the supersession state of these contracts. "Methodology
v2" is a batch of adjudicated supersessions with a dated session artifact - visible,
diffable via `bs history`, citable from published posts.

## Steps

1. Decide the namespace; create `method/manifest.json` (`depends_on: ["cb"]` only if
   borrowing `cb:` kinds; otherwise self-contained) and register it in
   `collections.json`.
2. Author the enum contracts, subjects-convention primitives, and methodology
   contracts as an import spec; run `cb.preflight`, adjudicate, `cb.import --write`.
3. Re-author the `sdl` example to `depends_on: ["method"]`, dropping its local enum
   in favor of the shared one (supersession in `sdl`, the worked demonstration of
   borrowing).
4. `mix cb.verify.collection method` and `mix cb.verify.collection sdl` green.

## Acceptance criteria

- `method:` verifies green; its enum contracts are discovered by role (the `sdl`
  skips for `kind`/`domain` disappear once it depends on `method:`).
- A toy eval collection authored against `method:` verifies green with zero local
  schema contracts.
- Each methodology contract's invariants are stated in predicate-ready form (a
  named check with an unambiguous pass condition), reviewed against plan-1's
  predicate signatures.

## Risks and non-goals

- **Premature vocabulary freezing.** Kinds/domains will be wrong on first authoring;
  that is what enum supersession is for. Author minimally; grow by supersession.
- **Methodology contracts that cannot be checked.** Every invariant here must be
  decidable by pure traversal of the collection union. If an invariant needs
  off-graph data (e.g. reading the raw logs), it does not belong in v1 - rewrite it
  as a claim about graph structure or defer it.
- **Non-goal:** any predicate implementation (plan-1); any AmIEval-specific content
  beyond methodology (eval findings are their own collections).
