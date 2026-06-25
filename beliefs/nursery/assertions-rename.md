---
type: concept
title: Removing "assertions" from cb:a098
description: Covers the rename of the dead term "assertions" to "beliefs" in cb:a098 and the mood fix it forces - the proposed directive D that supersedes a098's first clause.
tags: [cb, schema, a098, nursery]
status: active
timestamp: 2026-06-25
maturity: active
threads: [2026-06-25-belief-audit]
---

# Removing "assertions" from cb:a098

## The focus
cb:a098 (directive/convention) opens: *"Assertions express extractable behavioral
patterns as beliefs, not individual occurrences..."* "Assertions" is the deprecated term
for beliefs. Rename to "beliefs."

## Where it stands
- Not an edit - a **supersession** (immutability). a098 stays; a successor is minted and
  a098 links forward via `superseded_by`.
- Don't stop at the noun: "express" is mood-ambiguous (is/ought). A directive's claim
  should read in prescriptive voice. Proposed successor clause **D**:
  > Author a belief as the extractable behavioral pattern; record each evidencing
  > incident as an evidence entry, not as its own claim.
- The dead term survives twice in a098 - the claim *and* `subjects[0].type: "assertions"`.
  Both go in the rewrite.

## Next
Mint D as a directive superseding a098. But the split of a098 into D (directive) + an
inference is gated on [atomicity-generalization](atomicity-generalization.md). Draft D
plus the inference as import specs and run `mix cb.preflight`.

## Related
- [atomicity-generalization](atomicity-generalization.md) - licenses splitting a098.
- [negative-case-field](negative-case-field.md) - "not occurrences" dissolves once D
  states the positive home (the evidence array).
