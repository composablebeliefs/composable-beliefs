---
type: thread
title: 2026-07-01 - structural-type vocabulary (rename + contract demotion)
description: Covers the design conversation that questioned the contract boolean and the primitive/compound/directive names, arriving at a four-type rename to nominalized epistemic acts, a demotion of the contract field to a derived predicate, the c059 carve-out that demotion exposes, and the decision to persist the work as nursery seeds rather than a separate plan. Use when revisiting the structural-type vocabulary or the seed-vs-plan question.
tags: [cb, schema, structural-types, nursery, thread]
status: active
timestamp: 2026-07-01
artifact: session:2026-07-01-structural-type-vocabulary
---

# 2026-07-01 - structural-type vocabulary (rename + contract demotion)

> **Hand-captured (2026-07-01).** No `Stop` hook was running in this web session, so this
> thread was written by hand against the still-`contested` transcript format
> ([transcript-format](../transcript-format.md)). Tool calls and reasoning are stripped;
> only what was said is kept. Produced: [structural-type-rename](../structural-type-rename.md)
> and [contract-predicate-demotion](../contract-predicate-demotion.md).

## Where we are

- **Object of study:** the four structural types (c051) and the `contract` field (c056),
  prompted by a rendered doc "A contract is just a belief with teeth."
- **Settled this far:**
  - The `contract` boolean is redundant with `rules`/`invariants` - c056 makes it a strict
    biconditional, 39 nodes carry it with **zero drift**, and it is kept honest only by a
    verifier. A a386-style stored derivation; demote it to a computed predicate.
  - The four type names mix registers: `primitive`/`compound` are shape words,
    `inference`/`directive` are act words. Renaming all four to nominalizations of c051's
    verbs (attest/aggregate/infer/prescribe) unifies the register and makes the schema
    constraints self-evident from the name.
  - `primitive` vs `compound` is largely derivable from deps; `compound` vs `inference` is
    **not** (both have deps) - it is a scope judgment (c058), the load-bearing distinction
    the framework exists for. So descriptive cannot collapse to one type.
  - There is already only one prescriptive type; "contract" and "directive" are predicates
    over it, not sibling types.
- **Decisions reached:** rename `primitive->attestation`, `compound->aggregation`,
  `inference` unchanged, `directive->prescription`; keep `prescription` over
  `actualization` (which already means materialization); demote `contract` to a derived
  predicate; collapse the c059 "contracts may stand alone" carve-out that the demotion
  exposes as arbitrary.
- **Process decision:** persist as a hand-captured thread + two nursery seeds, folding the
  migration sequencing into the rename seed. No separate plan doc - a seed *is* the brief
  (transcript-format's seeds-vs-directives resolution).

## Turn-by-turn

**User (opening):** Considers the "contract is a directive with contract: true plus
non-empty rules/invariants" definition. Asks whether needing both the `contract` flag and
the existence of rules is a code smell (redundant), and whether the descriptive/prescriptive
qualification is itself a smell - could primitive and compound collapse into one descriptive
type (the split inferred from deps), and could directive and contract collapse into one
prescriptive type?

**Claude:** Points 1 and 3 are the same observation and correct - there is no separate
contract type already; `contract: true` is provably redundant via c056's biconditional, a
a386 antipattern kept honest only by a verifier; derive it. Point 2 breaks the symmetry:
deps-presence separates primitive (leaf) from compound/inference, but both compound and
inference have deps, so it cannot separate them - and that boundary (c058 containment,
aggregate-vs-exceed) is the load-bearing one. So descriptive cannot collapse to one type.

**User:** Proposes renames - Primitive: Attestation, Compound: Aggregation, Inference stays,
Directive/Contract: Prescription.

**Claude:** Endorses as more than cosmetic. The current set mixes shape words and act words;
the rename makes all four nominalizations of c051's verbs, and makes the parenthetical gloss
in c051 redundant. Each new name pre-loads a schema constraint (attestation -> artifact,
aggregation -> containment, prescription -> adoption). Two decisions it forces: treat the
rename as a vocabulary migration not supersession (source->artifact precedent), and decide
what happens to the word "directive."

**User:** "Define predicate in your usage here."

**Claude:** The logic/CS sense - a boolean-valued function `Belief -> Bool`, computed on
read, not stored state and not an exclusive type slot. `contract?(b)` classifies without
storing; many predicates can be true of one belief at once, unlike a type. That is why
contract and directive should be predicates over prescription, not sibling types.

**User:** "Leaning towards full rename. Seeking conceptual cleanliness across the entire
surface. Spec out the migration."

**Claude:** Ran reconnaissance (220 nodes: 161 directive, 50 primitive, 9 inference, 0
compound; 39 contract:true, zero drift; 17 code files). Wrote a layered migration spec.

**User:** Is the plan committed? And how do plan documents reconcile with planning having
migrated to the DAG / directives - conflict, or complementary?

**Claude:** Complementary. `plan:` is a sanctioned c043 artifact scheme; c059 names it as a
directive grounding; c056 says artifacts are referenced, not promoted. What migrated to the
DAG was settled state (directives, obligations), not planning-as-activity. A plan is the
adoption record; a prescription grounds in it. Once decisions settle, extract them into the
graph grounded in the plan.

**User:** What is plans' relationship to the nursery? Are you seeing the nursery in the code?

**Claude:** No - zero references in `lib/` or `skills/`; it exists only as files under
`beliefs/nursery/`, hand-maintained, threads captured by a Stop hook, its architecture doc
`contested`. Nursery vs plans differ on an axis: plans are execution/intent artifacts wired
into the schema; nursery focuses are epistemic gestation for authoring beliefs of any type.

**User:** Four questions - is stipulation artifact defined as the provenance of a prescription
decision? The "contracts may stand alone" carve-out seems arbitrary now. What is a telos?
Should we consider actualization vs prescription? Agrees nursery should not be formalized
into code lest it become a shadow DAG.

**Claude:** (1) Yes - a glossary term and c059's role: the artifact that grounds a
prescription by recording an adoption event, the prescriptive counterpart to an attestation's
evidence. (2) Agreed the carve-out is now arbitrary; the demotion exposes it as conflating
internal structure with provenance; recommend collapsing it so every prescription grounds,
foundational contracts citing a document/plan charter (cost: ~39 contracts need a stipulation
artifact). (3) telos = end/purpose. (4) Keep prescription - "actualization" already means
materialization (materialize skill, actualization.md) and names carrying-out, not the
belief's act. Agreed on the shadow-DAG constraint: only format may ever harden into code.

**User:** What answers do you need, or just a green light?

**Claude:** No substantive answers needed - the nursery is pre-mint, it records the live lean.
Need authorization to write under `beliefs/` plus four shape confirmations (write, two
focuses, plan stays separate, hand-captured thread).

**User:** 1 yes, 2 yes, 4 yes. On 3, worries about source confusion across threads, thread
summaries, nursery docs, and separately-authored plans - asks why nursery docs would point to
plans at all, and what nursery docs offer that plans do not.

**Claude:** The repo already settled this in transcript-format's "seeds vs directives": a seed
*is* the brief; a directive cites it; there is no separate plan type. So collapse - the two
seeds carry the decisions and fold in the migration sequencing; the `plans/cb-schema-v3`
draft is absorbed and retired; later, minted prescriptions cite the seeds. Authored this
thread and the two seeds accordingly.

## Related
- [structural-type-rename](../structural-type-rename.md) - the rename decision and its migration spike.
- [contract-predicate-demotion](../contract-predicate-demotion.md) - dropping the boolean and the c059 carve-out.
- [transcript-format](../transcript-format.md) - the seeds-vs-directives resolution this thread applies.
