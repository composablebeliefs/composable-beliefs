---
type: concept
title: The nursery architecture (focus-as-unit, Layer 1/2 fusion)
description: Covers the nursery model itself - focus-as-unit, conversing directly in the artifact, making the raw transcript vestigial - and its conflict with the OKF transcript-pair rule.
tags: [okf, cb, nursery, meta]
status: active
timestamp: 2026-06-25
maturity: contested
threads: [2026-06-25-belief-audit]
---

# The nursery architecture

## The focus
Replace thread-as-unit with **focus-as-unit**: a nursery of per-focus concept docs,
deliberated in place. Collapse OKF Layer 1 (source / transcript) and Layer 2 (synthesis)
by *conversing directly in the artifact* - the conversation is the synthesis being
authored live, not a transcript to be synthesized later. Goal: make the raw transcript
vestigial.

## Where it stands
- The model: a `nursery/` bundle; one concept doc per focus; the `maturity` lifecycle
  (active / contested / frozen / dropped / folded); seed -> mint; validate format not
  relations; a frozen doc serves as the belief's `cb:c059` stipulation artifact and
  forward-links it; reckless-in-nursery, deliberate-at-mint.
- The mechanism that makes Layer 1 droppable is `agent-behavior:a411`: load-bearing
  verbatim is quoted where it is used, so no separate transcript is needed. Condition -
  synthesis is live and human-reviewed each turn, so drift cannot accrue silently.

## Conflict (why this is `contested`)
The current OKF standard mandates the opposite. `okf/standard/types.md`,
§"Thread & session persistence":
> the raw conversation is a Layer-1 source and **must be kept**, not only synthesized
> ... the host's session log duplicated byte-for-byte ... a file copy, never a
> reconstruction.

That format rule is "owned by this standard," and its operational half is a CB directive
executed by `/end`. The nursery's "make Layer 1 unnecessary" thesis contests both.

Resolution paths:
1. **Chosen (2026-06-25).** Supersede the types.md transcript-pair rule and retire the
   `/end` capture directive - Layer 1 becomes the incidental host session log,
   unauthored. Safe because `agent-behavior:a411` (verbatim into evidence) plus the
   `seed` prop ([seed-absorption](seed-absorption.md)) fold everything of value into the
   graph at plant-time.
2. ~~Keep the pair, demote the nursery to a Layer-2 convenience.~~ Rejected - it
   entrenches an untested rule the stronger concept supersedes.

## Next
Execute path 1: supersede types.md §"Thread & session persistence" and retire the `/end`
transcript-pair directive in the graph.

## Related
- [seed-absorption](seed-absorption.md) - the mechanism that makes path 1 safe.
- [citation-discipline](citation-discipline.md) - the rule (a411) that lets Layer 1 drop.
