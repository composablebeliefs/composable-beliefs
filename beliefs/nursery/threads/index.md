---
type: index
title: Threads (session transcripts)
description: Use when you need the raw turn-by-turn transcript of a session - the human-readable, crash-safe record. Not provenance; the nursery seeds are.
tags: [threads, transcript, index]
status: active
timestamp: 2026-06-25
---

# Threads - session transcripts

Living, turn-by-turn transcripts of sessions: each turn's user message and the response
the agent shared at the end of it - the interstitial "let me check X" narration, the
reasoning, and the tool calls are all stripped, leaving only what was actually said. They
exist for two reasons only - **crash safety** (rewritten every turn, so a crash never
loses the discussion) and **human reading** (what you scan without wading through tools).

**Transcripts are not provenance.** The nursery seeds are the sole provenance; a belief
grounds in a seed, never in a transcript. A transcript is a convenience and a safety net,
nothing the graph depends on.

Live transcripts are captured automatically by a `Stop` hook
(`.claude/hooks/transcript_hook.py`) into `.sessions/<date>-<session>.md` - a dot-dir that
is gitignored and skipped by this bundle's manifest, because it is rewritten every turn.
Read them there; they are never committed. The curated thread docs below are the hand-kept
exceptions that do get committed.

## Contents
- [2026-06-25 - belief-by-belief audit (starting cb:a098)](2026-06-25-belief-audit.md) - the session that seeded the nursery.
- [2026-07-01 - structural-type vocabulary (rename + contract demotion)](2026-07-01-structural-type-vocabulary.md) - hand-captured; seeded the structural-type-rename and contract-predicate-demotion focuses.
