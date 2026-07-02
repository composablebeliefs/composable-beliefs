---
type: concept
title: Demote the contract boolean to a derived predicate
description: Covers dropping the stored `contract` field - redundant with rules/invariants by c056's biconditional, zero-drift across 39 nodes, a a386-style stored derivation - so contract-grade-ness is computed on read; and collapsing the c059 "contracts may stand alone" carve-out that the demotion exposes as arbitrary, so every prescription grounds in deps or a stipulation artifact.
tags: [cb, schema, contract, grounding, nursery]
status: active
timestamp: 2026-07-01
maturity: active
threads: [2026-07-01-structural-type-vocabulary, 2026-07-01-schema-v3-execution]
---

# Demote the contract boolean to a derived predicate

## The focus
The `contract` field is a stored boolean, but c056 makes it a strict biconditional with
non-empty `rules`/`invariants`. A field provably equal to `rules != [] or invariants != []`
carries no independent information. Demote it: compute `contract?` on read, drop the stored
field. Then resolve the c059 carve-out the demotion exposes.

## Where it stands
- **Redundant by design.** c056: "contract: true is required iff rules or invariants are
  non-empty (bidirectional)." Measured: 39 nodes carry `contract: true`, **zero drift** vs
  the biconditional. The field says nothing the payload does not.
- **A a386 antipattern in miniature.** It is a materialized derivation that can drift and is
  kept honest only by `mix cb.verify.schema`. The verifier's existence is the tell. Render it
  live (compute from the payload) instead of storing it.
- **Precedent for the removal.** `confidence`, `source`, and `implication` were already
  migrated/expunged from the schema (belief.ex moduledoc); `contract` follows the same path,
  handled in `from_map/1`'s `_keys` deletion set.
- **The demotion exposes an arbitrary carve-out.** c059 exempts contract-grade directives
  from grounding ("contracts may stand alone"). Once `contract` is just a predicate, that
  reads as "a prescription needs no adoption record if it happens to carry rules" - which
  conflates two orthogonal things: *internal structure* (has a DSL payload) and *provenance*
  (was adopted). A high-stakes contract arguably needs more provenance, not an exemption.
- **The defensible residue is narrower than "has rules."** What genuinely self-stands is a
  *foundational* prescription - the schema contracts (c051 etc.) cannot cite something more
  basic than themselves without regress. "Has rules" was a loose proxy for "is foundational."

## Decisions
- **Derive, do not store.** `contract?/1` computes `rules != [] or invariants != []`; the
  stored field is dropped. c056's biconditional becomes the *definition* of `contract?`
  rather than a consistency check.
- **Collapse the c059 carve-out (lean: option a).** Every active prescription grounds in deps
  or a stipulation artifact - no exemption. Foundational contracts ground in a `document:` (or
  `plan:`) charter, which is a real adoption event, so no regress. This removes the
  arbitrariness rather than re-keying it.
- **Open / cost:** ~39 currently-standalone contract nodes would each need a stipulation
  artifact added (a `document:` charter pointer). Real migration work, touches `beliefs/`.
  Alternative (option b) - keep an exemption but key it on an honest `foundational:` marker or
  charter grounding, not on the presence of rules - is the fallback if adding 39 artifacts is
  judged not worth it.

## The spike
1. **`belief.ex`.** `contract?/1` computes from `rules`/`invariants`; remove `:contract` from
   `@fields`/`@ordered_keys`; add `"contract"` to the `from_map/1` `_keys` deletion set
   (alongside confidence/source/implication).
2. **`schema/verifier.ex`.** Drop the biconditional check (now definitional); keep the
   "rules/invariants only on the prescriptive type" check.
3. **Contracts (needs auth).** c056: restate the biconditional as the definition of
   `contract?`, drop the stored-field invariants. c059: remove "contracts may stand alone";
   state that every active prescription grounds in deps or a stipulation artifact.
4. **Data (needs auth).** Strip `"contract": true` from 39 nodes. If collapsing c059, add a
   `document:`/`plan:` charter artifact to each formerly-standalone contract.
5. Gates as per the rename spike; ships in the same schema-epoch bump.

Coupling: this rides with [structural-type-rename](structural-type-rename.md) (same epoch,
same verify pass), but is separable/revertible - the rename does not depend on the demotion.

## Execution record (2026-07-01)

The demotion shipped the same day, in the session captured as
[2026-07-01-schema-v3-execution](threads/2026-07-01-schema-v3-execution.md):

- **Spike steps 1-2 (predicate + verifier):** commit `be4ee65` (PR #1, merge
  `1e7eafb`). `contract?/1` computes from rules/invariants; the verifier's
  biconditional became a definitional check tolerating the stored field during the
  compat window.
- **Steps 3-4 (contract + data, user-authorized):** commit `c4940b9`. `contract: true`
  stripped from all 39 carriers (zero drift confirmed at execution, matching the
  measurement above); c056 restates the biconditional as the definition of
  `contract?`, adds a no-stored-contract-field invariant, and carries the migration
  as dated evidence citing this seed.
- **NOT executed: the c059 carve-out collapse.** The migration kept c059's semantics
  (renamed `prescription-grounding`, exemption intact). The option-a lean - every
  prescription grounds, foundational contracts cite a charter, ~39 stipulation
  artifacts added - remains this seed's open decision; option b stays the fallback.
  (Resolved 2026-07-02 - see the execution record below.)

## Execution record (2026-07-02): the carve-out collapse

Option a, user-confirmed. The deferred decision closed cheaper than estimated: the ~39
figure was the count of `contract: true` carriers including superseded nodes, but the
grounding invariant scopes to active nodes, and 20 of the 21 active contracts already
grounded in deps or a stipulation artifact. The migration therefore touched:

- **c059:** the "Contracts may stand alone" rule and the non-contract qualifier removed;
  every active prescription grounds in deps or a stipulation artifact. External-source
  schemes still never ground.
- **c052:** the field-presence twin collapsed in step - the "Declared contract may omit
  deps" rule dropped, the invariant widened to all active prescriptions.
- **cb:c046:** the one genuinely standalone contract gained its adoption record -
  `document:plans/cb-codepath/plan-3-assertions-runtime.md`, the plan-3 batch that minted
  it as c035's successor, promoted from its own 2026-06-09 evidence entry.
- **verifier:** `check_grounding` drops the `contract?/1` exemption; grounding now checks
  every active prescription.
- **cb:a481 -> cb:a565:** the CLAUDE.md schema-rules sentence superseded via adjudication
  (the sanctioned door), c065's Schema render re-pointed, CLAUDE.md regenerated.

Option b (the `foundational:` marker) is retired, not deferred: with one node to ground,
the exemption had nothing left to exempt.

## Thread excerpts (what grounds the decisions)
**User (opening):** "the need to have the contract prop be set to true as well as have the
existence of rules is a code smell ... should either be inferred from the existence of rules
or defined by the prop, but not both, seems redundant."

**User (the carve-out):** "Now that we are doing away with the contract difference, the idea
that 'contract grade prescriptions may stand alone without deps or stipulation' seems
arbitrary (though it seems arbitrary in general)."

## Related
- [structural-type-rename](structural-type-rename.md) - the type-rename half of the same epoch.
- Thread: [2026-07-01-structural-type-vocabulary](threads/2026-07-01-structural-type-vocabulary.md).
