---
type: concept
title: Seed absorption - planted seeds fold into the belief
description: Covers the proposal that on planting, a seed's gestation folds into a `seed` prop on the belief and the doc evacuates the nursery - replacing lingering frozen docs - plus its open granularity and dropped-seed questions.
tags: [cb, schema, nursery, provenance]
status: active
timestamp: 2026-06-25
maturity: active
threads: [2026-06-25-belief-audit]
---

# Seed absorption

## The focus
When a seed plants, instead of leaving a frozen doc in the nursery, fold the seed's body
(the deliberation that produced the belief) into a new **`seed` prop on the belief
itself**. The doc then evacuates the nursery.

## Why it beats a lingering frozen doc
- **Evacuation.** Planted seeds leave the nursery entirely, so it only ever holds live
  work - a pure workspace, never an archive (no terminal-status bookkeeping to stay
  honest).
- **Completes CB's thesis.** The README: *"reasoning is authored ... CB records the
  derivation, keeps it walkable."* A `seed` prop makes the derivation-narrative part of
  the node: a belief becomes `claim` (what) + `evidence` (grounds) + `deps` (rests on) +
  `seed` (how it was reasoned into being).
- Immutability holds: the seed freezes at plant-time, never edited, like a dated evidence
  entry.

## Open design space
- **Atomicity / bloat - resolved by construction.** The `claim` stays one proposition;
  `seed` is drill-down payload that traversal never touches. Bigger in storage, not in
  conceptual unit.
- **Granularity.** One seed often plants several beliefs (a098 -> a directive + an
  inference). Lean: fold the same frozen seed into *each* - duplication is safe because it
  is immutable, and self-containment is the point (no node depends on chasing another to
  know its origin). Alternative: put it only on the tying node. Undecided.
- **Dropped is not always delete.** A *fizzled* seed is composted. A seed that reached
  *decided-against* is a real conclusion and plants the negative (a position or belief),
  not a deletion.

## Next
Decide granularity; then add `seed` to the belief schema (a `cb:` contract change) and
wire planting to fold-and-evacuate.

## Related
- [nursery-architecture](nursery-architecture.md) - this is what makes Layer 1 droppable.
- [citation-discipline](citation-discipline.md) - first planted seed awaiting absorption.
