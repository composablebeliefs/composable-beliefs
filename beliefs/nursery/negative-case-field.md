---
type: concept
title: A negative-case schema field?
description: Covers whether CB should add a negative-case field for the "X, not Y" contrast in claims - leaning no, because the negative channel already exists as invariants.
tags: [cb, schema, nursery]
status: active
timestamp: 2026-06-25
maturity: active
threads: [2026-06-25-belief-audit]
---

# A negative-case schema field?

## The focus
Should CB carry a `negative-case` field holding the contrastive "not Y" part of a claim
(for a098: "not individual occurrences")?

## Where it stands - leaning no
- **Fails the field test.** Per `cb:c047`, a field exists so a predicate fires on it; a
  free-prose `negative-case` with no check is decoration that pretends to be structure,
  and cuts against the v2 purge of confidence / source / implication.
- **The channel already exists.** CB externalizes contrast into edges (conflict scope
  `cb:c055`, supersession), not into a node field; and where a "must NOT" is checkable,
  that slot is `invariants` (contract-scoped).
- **For a098 it dissolves.** State the positive home (the evidence array) and "not
  occurrences" is implied. Independent backing - `agent-behavior:a402`:
  > Docs and explanatory prose state what a thing is or does directly, never the den[ial].

## Open sub-question
Do you want invariants-style negatives on *non-contract* beliefs - and if so, what
predicate reads them? If no predicate, no field.

## Related
- [assertions-rename](assertions-rename.md)
