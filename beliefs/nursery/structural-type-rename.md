---
type: concept
title: Rename the four structural types to nominalized epistemic acts
description: Covers renaming the type enum from primitive/compound/inference/directive to attestation/aggregation/inference/prescription - nominalizations of c051's four verbs (attest/aggregate/infer/prescribe) - fixing the mixed shape-word/act-word register, why compound and inference cannot collapse, why prescription is preferred over actualization, and the layered vocabulary migration.
tags: [cb, schema, structural-types, nursery]
status: active
timestamp: 2026-07-01
maturity: active
threads: [2026-07-01-structural-type-vocabulary]
---

# Rename the four structural types to nominalized epistemic acts

## The focus
The type enum (c051) is `primitive | compound | inference | directive`. Rename it to
`attestation | aggregation | inference | prescription` - the nominalizations of the four
epistemic verbs c051 already names (attest, aggregate, infer, prescribe).

## Where it stands
- **The names mix registers.** `primitive` and `compound` are shape words (they describe
  graph position: leaf vs made-of-parts). `inference` and `directive` are act words (they
  name what the belief does). Two of four are named after a structural fact you could read
  off the graph; only two are named after the epistemic act.
- **The rename unifies the register** on the act. It also makes c051's parenthetical gloss
  `(attest, aggregate, infer, prescribe)` redundant with the type names - when renaming lets
  you delete the sentence that explains the name, the name was underpowered.
- **Each new name pre-loads a schema constraint:** *attestation* implies provenance (c051's
  non-null `artifact`); *aggregation* implies nothing-beyond-the-inputs (c058 containment);
  *prescription* implies adoption (c059 grounding). The old names were silent about these.
- **The descriptive side does not collapse to one type.** Deps-presence separates a leaf
  (attestation) from an internal node, but *aggregation* and *inference* both carry deps -
  what separates them is whether the claim's scope escapes its deps (c058), a semantic
  judgment, not a graph-shape fact. That boundary is the whole point of the framework, so it
  stays an explicit type.
- **Prescription over actualization.** "Actualization" is already load-bearing elsewhere -
  the `materialize` skill actualizes a directive into work, and `docs/actualization.md` uses
  it for the agent-actualization project. It names the *carrying-out* (a downstream operation
  on the world), not the belief's own act. The type names the epistemic operation, which for
  the prescriptive type is *prescribe*. So keep `prescription`; reserve actualize/ation for
  materialization.
- **"directive" and "contract" become predicates, not types.** There is only one
  prescriptive type. `contract?` and (informally) "directive" describe a prescription; they
  do not partition it. (The contract half is its own focus:
  [contract-predicate-demotion](contract-predicate-demotion.md).)

## Decisions
- Rename: `primitive->attestation`, `compound->aggregation`, `inference` unchanged,
  `directive->prescription`. Enum values stay nouns (matches the `inference` convention).
- Full rename: `directive` is retired as a type value everywhere (CLI, docs, code); it may
  survive only as an informal prose register.
- This is a **vocabulary migration, not supersession** - the belief's identity and claim are
  unchanged, only the label. Precedent: `source` was renamed to `artifact` and
  `confidence`/`implication` expunged as mechanical migrations (belief.ex moduledoc). Record
  the migration in c051/c056 so it is not read as a c053 violation.

## The spike (migration, ordered enum-first)
Ground truth (2026-07-01): 220 nodes - 161 directive, 50 primitive, 9 inference, **0
compound**. Enum source of truth: `belief.ex:48`. 17 code files hard-code the strings.

1. **Enum (`belief.ex`).** `@types` -> the four new nouns; rewrite the moduledoc gloss; add
   old->new normalization in `from_map/1` (compat read for the epoch). Build a CLI shim in
   `belief/filter.ex:13` that accepts both old and new type words for one epoch and warns on
   the old ones.
2. **Code (17 files).** `schema/verifier.ex` (~7 sites), `belief/graph.ex`,
   `belief/filter.ex` (:13 filter, :30 `unlinked` hard-codes "directive", :85 sort),
   `belief/formatter.ex` (labels/glyphs), `materializer` + `sink`, `audit/conflicts` +
   `belief/conflict`, `eval/*`, `output_target`, `edit_pairs`, `adjudication`; the
   `cb.preflight`/`cb.import` templates; `bs.ex` help text. Tests.
3. **OKF boundary: translate, do not rename.** Keep OKF's published vocabulary
   (`okf/standard/types.md`); make `okf/emit.ex`/`okf/ingest.ex` a translation map.
4. **Self-describing contracts (in `beliefs/`, needs auth).** Mechanical vocabulary rewrite
   of c051, c056, c057 (kind-type table rows), c053, c058, c059.
5. **Live data (`beliefs/beliefs.json`, needs auth).** 220 `type` rewrites; round-trip via
   the serializer for byte-stability; verify.
6. **Docs.** Regenerate `CLAUDE.md`; update glossary, reference, belief-graph, mental-model,
   skills. **Do NOT rewrite the historical record** (chronicles/, plans/, dated analyses,
   nursery threads) - add one glossary entry mapping old->new so old readers are not lost.

Gates: `mix cb.verify.schema`, `mix cb.verify.collection cb`, cross-repo collection verify,
`mix cb.generate.claude_md --check`, `mix test`. Ship as a schema-epoch bump so collections
can declare which vocabulary they carry during the compat window.

## Thread excerpts (what grounds the decisions)
**User (opening):** "could we collapse primitive and compound beliefs into the same belief
category, which is descriptive ... could be inferred from the existence or lack of existence
of dependencies ... I'm also wondering if the differentiation between a directive and a
contract is necessary. Why isn't it just a prescriptive belief?"

**User (the rename):** "Primitive: Attestation / Compound: Aggregation / Inference (stays) /
Directive/Contract: Prescription"

**User (on the fourth name):** "Should we consider actualization vs prescription for the new
term?"

## Related
- [contract-predicate-demotion](contract-predicate-demotion.md) - the contract half of the same epoch.
- [assertions-rename](assertions-rename.md) - a prior rename-as-supersession focus (contrast: that one is supersession, this one is vocabulary migration).
- Thread: [2026-07-01-structural-type-vocabulary](threads/2026-07-01-structural-type-vocabulary.md).
