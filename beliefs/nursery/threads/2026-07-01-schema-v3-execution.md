---
type: thread
title: 2026-07-01 - schema-v3 execution (rename + demotion shipped)
description: Covers the execution session for the structural-type vocabulary migration - the code-only compat-shim phase (PR #1), the authorized beliefs/ migration (220 type rewrites, contract field stripped, contract family rewritten, evidence recorded on c051/c056), the scope calls made in flight (history untouched, c059 carve-out kept, glossary render deferred), and the two follow-up prescriptions minted at close (cb:a561, cb:a562). Use when tracing the migration commits back to their seeds and decisions.
tags: [cb, schema, structural-types, nursery, thread]
status: active
timestamp: 2026-07-01
artifact: session:2026-07-01-schema-v3-execution
---

# 2026-07-01 - schema-v3 execution (rename + contract demotion shipped)

> **Hand-captured (2026-07-01).** Written by the executing agent at session close, per
> the still-`contested` transcript format ([transcript-format](../transcript-format.md)).
> Tool calls and reasoning are stripped; only what was said is kept. This is the
> *execution* session for the decisions gestated in
> [2026-07-01-structural-type-vocabulary](2026-07-01-structural-type-vocabulary.md) and
> carried by the [structural-type-rename](../structural-type-rename.md) and
> [contract-predicate-demotion](../contract-predicate-demotion.md) seeds.

## Where we are

- **Shipped, code (PR #1, merge `1e7eafb`, commit `be4ee65`):** the enum renamed to
  `attestation | aggregation | inference | prescription`; `contract?/1` computes
  `rules != [] or invariants != []`; a compat shim keeps both vocabularies valid -
  `from_map/1` normalizes old names on read, `to_map/1` writes back the stored string
  (`_raw_type`), the CLI filter accepts old names with a warning, the verifier
  normalizes both sides of every type comparison including the c057 table rows, and
  the OKF boundary became a translation map instead of renaming OKF's published
  vocabulary. 381 tests; all verify gates green against the then-old-vocab graph.
- **Shipped, graph (commit `c4940b9`, user-authorized):** all 211 non-inference nodes'
  `type` values rewritten (161 directive->prescription, 50 primitive->attestation, 0
  compounds existed); `contract: true` stripped from all 39 carriers (zero drift
  against the former biconditional); the active contract family (c030, c051-c059)
  mechanically rewritten, with c056 restating the biconditional as the *definition* of
  `contract?` and gaining a no-stored-contract-field invariant; c059 renamed
  `prescription-grounding`, carve-out semantics unchanged; migration recorded as dated
  evidence on c051 and c056 grounded in the two seeds; CLAUDE.md-feeding claims (a477,
  a478, a481, a482, a508, a524) and c065's section title updated; CLAUDE.md
  regenerated; skills/ instructions moved to the new vocabulary.
- **Scope calls made in flight:** superseded nodes and attestations that quote prior
  schemas (a470, a115, a298, a404, a408, a409) deliberately left in the old
  vocabulary - they attest history; rewriting them would falsify the record. The c059
  "contracts may stand alone" carve-out was *not* collapsed - the demotion seed's
  option-a lean and its ~39-artifact cost remain an open decision on that seed.
- **Deferred at close, persisted as prescriptions (not plans, not seeds):**
  - `cb:a561` - regenerate docs/glossary.md where the `../belief-collections` sibling
    exists (rendering without the registry drops `method:`/`paradigm:` references).
  - `cb:a562` - retire the compat shim once every registered collection verifies clean
    under the new vocabulary; deps on c051, c056, and a559.

## Turn-by-turn

**User (task):** Execute the CODE-ONLY phase of the cb structural-type vocabulary
refactor on an isolated branch: rename the enum, demote `contract` to a derived
predicate, keep both vocabularies valid via a read-normalization + validation shim,
touch nothing under beliefs/, verify all gates against the still-old-vocab graph.

**Claude:** Shipped as `be4ee65` on `claude/schema-v3-code`. Key mechanism: `_raw_type`
preserves the stored string so a read-modify-write cycle never rewrites the graph; the
verifier's kind-type table check normalizes both sides, which is what lets the
old-vocab c057 govern new-vocab nodes and vice versa. All gates pass; byte-stability
proven against a stashed-baseline run (the only round-trip churn is the pre-existing
c039 nested-map key order, present on main too).

**User:** Merged to main.

**Claude:** Confirmed PR #1 / `1e7eafb`. Named the remaining phases needing beliefs/
authorization: contracts, data, docs.

**User:** Proceed.

**Claude:** Shipped as `c4940b9`. The scope calls above; gates green (222-node graph
verifies; CLAUDE.md check passes; store round-trip stable). Flagged two follow-ups:
glossary regeneration needs the sibling checkout, and the shim retires only after
cross-collection verification.

**User:** Not ready to address the follow-ups; how should they persist - plans, seed
docs, or prescription nodes?

**Claude:** Prescription nodes. Not plans (single completable actions, below
plan-scale per a496/a540); not seeds (nothing unsettled, and the nursery must not
become a shadow backlog); prescriptions because the graph is the index of obligation
(a489) and the session-start desk query surfaces exactly unmaterialized discrete
prescriptions.

**User:** Proceed, then commit this thread to the nursery archive. How is this work
documented and traced - from the git commit back to the thread and the intermediary
seed or plan doc? Retroactively create a plan?

**Claude:** No retroactive plan - the design thread already settled seeds-vs-plans for
this work: the seed *is* the brief. The two seeds are the intermediary docs; what was
missing was the execution record on them and this thread. Minted a561/a562 through
preflight/import (0 conflicts; one supportive match, a559, tied in as a dep), wrote
this thread, and stamped both seeds with execution records pointing at the commits.
The trace now runs both directions: commit message -> seeds -> threads, and
prescription -> seed artifact + c051/c056 deps -> evidence -> seeds -> threads.

## Related

- [structural-type-rename](../structural-type-rename.md) - the brief this session
  executed; carries the execution record.
- [contract-predicate-demotion](../contract-predicate-demotion.md) - the demotion
  brief; its c059-carve-out decision remains open.
- [2026-07-01-structural-type-vocabulary](2026-07-01-structural-type-vocabulary.md) -
  the design session that produced the seeds.
