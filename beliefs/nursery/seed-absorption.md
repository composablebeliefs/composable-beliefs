---
type: concept
title: Seed absorption - terminal seeds fold into their successor and evacuate
description: Covers the principle that every terminal seed folds into its successor and evacuates the nursery - on planting into a `seed` prop on the belief, on losing a contest into the winning seed as dated historical evidence - so the nursery never holds a tombstone; plus the floor/graph tier split, the persist-raw safety condition, and the open granularity and field questions.
tags: [cb, schema, nursery, provenance]
status: active
timestamp: 2026-07-01
maturity: contested
threads: [2026-06-25-belief-audit, 2026-06-26-nursery-workflow]
---

# Seed absorption

> **Contested (2026-07-01)** by [seed-lifecycle](seed-lifecycle.md): terminal seeds should
> **graduate** (historicize + archive) rather than evacuate-by-deletion; the fold survives
> as the graduation step, with the `seed` prop shrinking to digest + pointer. The
> persist-raw safety condition below is what the challenge dissolves.

## The focus
When a seed plants, instead of leaving a frozen doc in the nursery, fold the seed's body
(the deliberation that produced the belief) into a new **`seed` prop on the belief
itself**. The doc then evacuates the nursery.

## Generalization (2026-06-26): every terminal seed folds and evacuates
Fold-and-evacuate is not special to planting - it is how *every* terminal seed should leave
the nursery, so the floor only ever holds live work and never a tombstone:

- **Plant (a seed wins on its merits -> a belief):** the body folds into a `seed` prop on
  the belief; the doc evacuates. (The arm detailed below.)
- **Contest (seed B beats seed A, or A grafts into B):** A folds into B as a dated
  "rejected: X because Y" block - load-bearing sentences only, per the `agent-behavior:a411`
  citation rule - and A evacuates. No lingering superseded doc, no pointer-stub.
- **Fizzle:** nothing worth folding; the doc just evacuates (a *decided-against* fizzle still
  plants its negative first, per the dropped-seed note below).

**Already house style one tier up.** `cb:a112`'s evidence reads "Considered and rejected:
per-entity belief files. The centralized graph was preserved because cross-entity
composition is the primary value..." - the rejected alternative folded into the survivor as
a dated block. The contest arm is that pattern, applied at the floor.

**Tier split - the boundary is the mint gate.**
- *Floor (nursery): fold-and-evacuate.* Curation; the primary record is the raw thread.
- *Graph (post-mint): supersede-and-keep.* Immutability; the audit tree needs the
  struck-through predecessor (`README.md`). Never fold-delete a belief.

They do not conflict because they have different systems-of-record.

**Safety condition (load-bearing).** Fold-and-delete at the floor is safe *only if* the
loser's raw reasoning survives elsewhere - which is what persist-raw
([transcript-format](transcript-format.md)) plus per-statement linkage
([statement-provenance](statement-provenance.md)) guarantee. If transcript-format settles on
render-only, keep a pointer-stub instead of deleting. So this pressures transcript-format
toward persisting raw; resolve them together. (No belief grounds in a *losing* seed, so
folding it orphans nothing.)

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

## Thread excerpts (2026-06-26)
**User:** "instead of 'supersedes' and persisting the superseeded doc, instead the
superseeded doc should immediately be folded into the blessed doc as historical evidence."

**Claude (resolution):** Yes at the floor, and it is house style - `cb:a112` already folds
its rejected alternative into its evidence. Tier split: floor folds-and-evacuates (primary
record is the raw thread), graph supersedes-and-keeps (immutability). Safe only if raw
persists, so it pressures transcript-format toward persist-raw; the three proposals compose.

## Related
- [transcript-format](transcript-format.md) - persist-raw is the safety condition for the
  contest arm.
- [statement-provenance](statement-provenance.md) - per-statement linkage keeps a folded
  loser's reasoning reachable.
- [nursery-architecture](nursery-architecture.md) - this is what makes Layer 1 droppable.
- [citation-discipline](citation-discipline.md) - first planted seed awaiting absorption.
