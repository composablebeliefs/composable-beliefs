---
type: concept
title: How transcripts and seeds persist exchanges
description: Covers whether the full session transcript is a committed artifact, generating its metadata at /end, conforming belief-audit.md and the .sessions transcripts to one format, and the action item that seeds carry per-topic excerpted exchanges.
tags: [nursery, transcript, format, provenance]
status: active
timestamp: 2026-06-26
maturity: contested
threads: [2026-06-25-belief-audit]
---

# How transcripts and seeds persist exchanges

## The focus
Settle how the conversational record persists: the full transcript, the per-topic
excerpts in seeds, their shared format, and what gets committed. This is `contested` - it
reverses parts of the just-shipped design (the gitignored `.sessions/`, the
responses-only hook, and nursery-architecture's "Layer 1 vestigial" lean).

## Action item (operator directive, 2026-06-26)
Each seed carries, within it, a **turn-by-turn thread of excerpted exchanges** that
directly relate to its topic - the actual debate on that focus as first-class content,
not only a distilled "where it stands."

## Decisions in motion
- **Persist the full context as a committed artifact.** The earlier "store in `.sessions/`,
  gitignore it" call was filed under *git churn* - the wrong axis. The deciding question is
  whether the transcript is a persisted artifact, and it is: the seed excerpts are
  accountable to it, and the linear flow / road-not-taken lives only there. So commit it;
  churn is a mechanical detail (hook keeps a live crash-safe copy in-session, `/end`
  commits the final). Grounds the rule `agent-behavior:a412`.
- **Metadata at `/end`.** Rich frontmatter + outcome digest + produced-links are only
  knowable at session end. `/end` synthesizes them; the hook owns the live body. Conflict
  to solve: the hook rewrites the whole file each turn and would clobber `/end`'s
  frontmatter - the hook must preserve an existing frontmatter block (extra-key-preserving,
  like the OKF parser).
- **One format. Confirmed 2026-06-26.** belief-audit.md and the `.sessions/` transcripts
  conform to a single shape - belief-audit.md's (frontmatter + digest + turn-by-turn body)
  becomes the *prototype*, not a relic. The hook + `/end` produce docs in that shape. This
  also settles the metadata question: the metadata is part of this format, not a separate
  decision; only the two-writer merge and the `/end` mechanics remain as implementation.

## Pros / cons of persisting the full context
- **Pro - accountability:** seeds are interpretations; the full thread is ground truth the
  interpretation is checkable against (fair excerpting? dropped dissent?). Guards
  silent-drift (`agent-behavior:a358`).
- **Pro - situates excerpts:** topic-buckets lose ordering and cross-references; the linear
  thread preserves what-prompted-what (a411 at conversation scale).
- **Pro - the road not taken:** tangents and rejected ideas live only in the full context.
- **Con - duplication** (every excerpt also in a seed) and **noise** (dead-ends kept).
- **Resolved 2026-06-26: the readable render, committed - not the raw.** No compelling case
  to persist thinking/tool calls. The complete raw lives ephemerally as the host jsonl
  (~30-day retention) for transient audit; a *permanent* agent-behavior corpus (self-report
  vs actual reasoning/actions) would argue for raw, but that is a separate opt-in the jsonl
  already accumulates - not the thread artifact's default.

## Next
Resolve the two-writer frontmatter merge and the commit-at-/end mechanics; then conform
both docs, update the hook, and add the `/end` metadata step.

## Related
- [nursery-architecture](nursery-architecture.md) - this reverses its "Layer 1 vestigial" lean.
- [seed-absorption](seed-absorption.md)
