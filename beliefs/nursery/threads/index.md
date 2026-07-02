---
type: index
title: Threads (session transcripts)
description: Use when you need the raw turn-by-turn transcript of a session - the human-readable, crash-safe record. Not provenance; the nursery seeds are.
tags: [threads, transcript, index]
status: active
timestamp: 2026-07-02
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
(`.claude/hooks/transcript_hook.py`, registered in the committed `.claude/settings.json`
and pathed via `$CLAUDE_PROJECT_DIR`, so it runs in local and remote sessions alike) into
`.sessions/<date>-<session>.md`, with a raw jsonl copy beside it - a dot-dir that is
gitignored and skipped by this bundle's manifest, because it is rewritten every turn.
`.sessions/` is the working area, not the persistence: `/end` finalizes the live render
(metadata, digest, registration) into a committed thread doc below. The raw jsonl stays
working-area only until transcript-format's repo-weight/LFS decision lands. In a remote
session the working area dies with the container, so `/end` before finishing is the only
persistence there - the hook reminds on first capture.

## Contents
- [2026-06-25 - belief-by-belief audit (starting cb:a098)](2026-06-25-belief-audit.md) - the session that seeded the nursery.
- [2026-07-01 - structural-type vocabulary (rename + contract demotion)](2026-07-01-structural-type-vocabulary.md) - hand-captured; seeded the structural-type-rename and contract-predicate-demotion focuses.
- [2026-07-01 - schema-v3 execution (rename + demotion shipped)](2026-07-01-schema-v3-execution.md) - hand-captured; the execution session for those seeds: code shim (PR #1, `be4ee65`), graph migration (`c4940b9`), follow-ups minted as cb:a561/cb:a562.
- [2026-07-01 - seed lifecycle deliberation (graduate vs evacuate)](2026-07-01-seed-lifecycle.md) - hand-captured; seeded the seed-lifecycle focus and contested seed-absorption.
