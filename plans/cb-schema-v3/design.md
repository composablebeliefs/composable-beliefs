# cb-schema-v3: Structural-type vocabulary rename

Status: draft spec (not yet authorized to touch `beliefs/`)
Author intent: full rename across the entire surface for conceptual cleanliness.

## What changes

The `type` enum becomes four nominalized epistemic acts, matching the verbs
c051 already names (attest, aggregate, infer, prescribe):

| Old type    | New type       | c051 verb | Live `cb:` nodes |
|-------------|----------------|-----------|------------------|
| `primitive` | `attestation`  | attest    | 50               |
| `compound`  | `aggregation`  | aggregate | 0                |
| `inference` | `inference`    | infer     | 9 (unchanged)    |
| `directive` | `prescription` | prescribe | 161              |

`contract` and `directive` cease to be nouns in the type system. They survive
only as **predicates** over a prescription:
- `contract?(b)` := `rules != [] or invariants != []` (derived, not stored)
- "directive" survives only as an informal prose register, nothing keys on it

Enum values stay nouns (matches the existing `inference` convention; reads
`type: attestation`).

## Why it is not supersession

Renaming a controlled-vocabulary term does not change any belief's identity or
claim - only its label. Precedent is in `lib/cb/belief.ex`'s own moduledoc:
`source` was **renamed** to `artifact`, and `confidence`/`implication` were
expunged, all as mechanical schema migrations, not superseding-belief events.
This migration is treated identically. c051/c056 gain a one-line note recording
the vocabulary migration so a future session does not read the in-place rewrite
as a c053 violation.

## Ground truth (measured 2026-07-01)

- 220 nodes: 161 directive, 50 primitive, 9 inference, 0 compound.
- `contract: true` on 39 nodes, **zero drift** vs the c056 biconditional - the
  field carries no information the rules/invariants do not, so demotion is safe.
- 17 code files hard-code the type strings. Enum source of truth: `belief.ex:48`.

## Locked decisions

1. **Fold in the contract demotion (Phase C).** Drop the stored `contract`
   field; make `contract?/1` compute from rules/invariants. Separable/revertible.
2. **Retire `directive` fully** as a type value everywhere (CLI, docs, code).
3. **Vocabulary migration, not supersession** (see above).
4. **OKF boundary: translate, do not rename.** Keep OKF's published vocabulary
   (`okf/standard/types.md`); make `okf/emit.ex`/`okf/ingest.ex` a translation map.
5. **Cross-repo: lockstep + one-epoch compat read.** Migrate belief-collections
   with a `from_map/1` normalization shim that accepts old type strings.

---

## Layers (by mutability, in execution order)

### Layer 1 - Enum source of truth: `lib/cb/belief.ex`
- [ ] `@types` (:48) -> `~w(attestation aggregation inference prescription)`
- [ ] Moduledoc struct summary (:36-45): rewrite the four-type gloss
- [ ] `contract?/1` (:118): compute from `rules`/`invariants`, stop trusting field
- [ ] Phase C: remove `:contract` from `@fields`/`@ordered_keys`; add `"contract"`
      to the `_keys` deletion set in `from_map/1` (:192-197), matching the existing
      `confidence`/`source`/`implication` deletions
- [ ] Add old->new type normalization in `from_map/1` (compat read for the epoch)

### Layer 7 shim (built with Layer 1) - CLI back-compat
- [ ] `belief/filter.ex:13`: accept both old and new type words for one epoch;
      warn on old words, point to the new name
- [ ] Removed at epoch close

### Layer 4 - Code surface (17 files, mechanical string swap)
Enforcement & core:
- [ ] `schema/verifier.ex` (~7 type-check sites incl. contract biconditional)
- [ ] `belief/graph.ex` (traversal predicates keyed on type)
- [ ] `belief/filter.ex` (:13 filter, :30 `unlinked` hard-codes "directive", :85 sort order map)
- [ ] `belief/formatter.ex` (per-type labels/glyphs at :25-28, :106, :117, :231, :251)
Behavior:
- [ ] `belief/materializer.ex` + `materializer/sink.ex` ("only prescriptions materialize")
- [ ] `audit/conflicts.ex` + `belief/conflict.ex` ("two active prescriptions")
- [ ] `eval/predicates.ex`, `eval/manifest.ex`
- [ ] `output_target.ex`, `belief/edit_pairs.ex`, `belief/adjudication.ex`
Authoring:
- [ ] `mix/tasks/cb.preflight.ex`, `mix/tasks/cb.import.ex` (default template type)
- [ ] `mix/tasks/bs.ex` help text (:35, :37, :470, :472)
Boundary:
- [ ] `okf/emit.ex`, `okf/ingest.ex` -> translation map (Decision 4)
Tests:
- [ ] `test/` fixtures and assertions

### Layer 2 - Self-describing schema contracts (in `beliefs/`, NEEDS AUTH)
Mechanical vocabulary rewrite of claim/rules/invariants prose:
- [ ] c051 (four-type enum + "only directives carry contracts")
- [ ] c056 (schema discipline prose; Phase C: drop the contract-boolean invariants
      or restate the biconditional as the *definition* of `contract?`)
- [ ] c057 (kind-type table: "directive" -> "prescription" every row + mood prose)
- [ ] c053 ("retired is the directive-only exit" -> prescription)
- [ ] c058 ("compound" -> "aggregation")
- [ ] c059 (directive-grounding -> prescription-grounding)

### Layer 3 - Live data: `beliefs/beliefs.json` (NEEDS AUTH)
- [ ] 220 `type` value rewrites (161+50+9; no compound)
- [ ] Phase C: strip `"contract": true` from 39 nodes
- [ ] Run through the round-trip serializer for byte-stability; verify

### Layer 5 - Normative docs
- [ ] `CLAUDE.md` (regenerate via `mix cb.generate.claude_md`)
- [ ] `docs/glossary.md`, `docs/reference.md`, `docs/belief-graph.md`, `docs/mental-model.md`
- [ ] `skills/*/SKILL.md` (assert, assertions, materialize, position, present-codepath)

### Layer 6 - Historical record: DO NOT REWRITE
`chronicles/`, `plans/` (except this dir), dated `docs/analyses/`, `beliefs/nursery/`
threads are dated artifacts. Rewriting them falsifies the record. Leave verbatim;
add ONE glossary entry mapping old->new terms so old-chronicle readers aren't lost.

---

## Verification & sequencing

Order: Layer 1 (+ shim) -> Layer 4 -> Layer 2 -> Layer 3 -> Layer 5.
The compat shim makes each step independently loadable.

Gates:
- [ ] `mix cb.verify.schema`
- [ ] `mix cb.verify.collection cb`
- [ ] cross-repo `mix cb.verify.collection lib` (and other collections)
- [ ] `mix cb.generate.claude_md --check`
- [ ] `mix test`

Ship as a schema-epoch bump (v3) so collections can declare which vocabulary
they carry during the compat window.

## Open questions

- Does any external OKF consumer depend on the current cb type names leaking
  through? (Confirms Decision 4 is safe.)
- Epoch-close date for removing the compat shim + CLI aliases.
