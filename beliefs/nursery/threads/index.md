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

**At close, the thread document is the single persisted artifact** (cb:b578): it opens
with an operator-facing narrative section carrying the register the chronicles used to
hold - where things stood, the arc with its incidents as story beats, where things stand
now, and what the next session inherits - narrative carrying the load, ids subordinate.
The turn-by-turn body below it is the receipts register. Obligations live in the graph
and resumption state in the routing ledger (cb:b572), so no separate chronicle is
written; the chronicles shelf is closed and archived at `deprecated/chronicles/`.

Live transcripts are captured automatically by a `Stop` hook
(`.claude/hooks/transcript_hook.py`, registered in the committed `.claude/settings.json`
and pathed via `$CLAUDE_PROJECT_DIR`, so it runs in local and remote sessions alike) into
`.sessions/<date>-<session>.md`, with a raw jsonl copy beside it - a dot-dir skipped by
this bundle's manifest because its contents are unfinalized drafts, rewritten every turn.
The renders are tracked and the hook stages the current one after each rewrite, so it
rides along with whatever commit the session makes next - any push persists the
through-last-turn render, even if the session ends abruptly (the ride-along lane;
transcript-format's "un-gitignore the render lane"). `/end` remains the finalization
step: metadata, digest, and registration into a curated thread doc below. Only the raw
jsonl stays gitignored and uncommitted, until transcript-format's repo-weight/LFS
decision lands. The hook reminds on first capture.

## Contents
- [2026-06-25 - belief-by-belief audit (starting cb:a098)](2026-06-25-belief-audit.md) - the session that seeded the nursery.
- [2026-07-01 - structural-type vocabulary (rename + contract demotion)](2026-07-01-structural-type-vocabulary.md) - hand-captured; seeded the structural-type-rename and contract-predicate-demotion focuses.
- [2026-07-01 - schema-v3 execution (rename + demotion shipped)](2026-07-01-schema-v3-execution.md) - hand-captured; the execution session for those seeds: code shim (PR #1, `be4ee65`), graph migration (`c4940b9`), follow-ups minted as cb:a561/cb:a562.
- [2026-07-01 - seed lifecycle deliberation (graduate vs evacuate)](2026-07-01-seed-lifecycle.md) - hand-captured, finalized by the first /end run; seeded the seed-lifecycle focus, contested seed-absorption, and shipped the remote-capture machinery (PR #8).
- [2026-07-02 - authoring pipeline (thread-to-graph round trip)](2026-07-02-authoring-pipeline.md) - hand-captured; carries the first routing ledger; seeded routing-ledger, mint-manifest, and commit-provenance-floor, and executed the first full thread-to-graph round trip (cb:b572/cb:b567).
- [2026-07-02 - id migration (b-serials, merge policy, obligation hygiene)](2026-07-02-id-migration.md) - hand-captured; the a/c -> b-serial migration (PR #10/#11, cb:b566/cb:b573), follow-up obligations cb:b574-b577, and a thread record written in the narrative-section convention concurrently with the fold that made it law (PR #16).
- [2026-07-02 - fold the chronicle into threads (the single-artifact close ships)](2026-07-02-fold-chronicle-into-threads.md) - hook-captured, first /end-finalized close under its own cb:b578 protocol; superseded b520, archived chronicles/, executed the b570 sweep and the supersession-cost test, and seeded vocabulary-read-surface and graph-refounding.
- [2026-07-03 - the runway clearing (git-policy release + cloud toolchain)](2026-07-03-git-policy-release.md) - hook-rendered, first fully hook-captured thread; released the ask-before-commit policy (cb:b456 -> cb:b580), diagnosed the CCR stop-hook false-Unverified bugs, shipped the cloud Elixir SessionStart hook (PR #14), and staged the per-belief-files implementation for a fresh session.
- [2026-07-03 - the /end round-trip (turn-separation ships, first honest close)](2026-07-03-end-skill-round-trip.md) - hook-captured, first close run under its own cb:b583 turn-separation rule; authored end-skill-redesign, minted cb:b583/b584, refactored /end, resolved Q7 (beliefs/archive/) and graduated end-skill-redesign, spun off mint-manifest-rename, and closed the first thread-to-graph-to-code round trip honest about its own coverage.
- [2026-07-04 - route-tagging (spec authored, first retrofit demonstrated)](2026-07-04-route-tagging.md) - hook-captured; designed the route-tagging spec (per-paragraph multi-ref tags on the frozen body keyed on the routed-to artifact id, aggregating a matter's cross-thread discussion into an append-only excerpt log), drafted beliefs/nursery/route-tagging.md (three staged candidates, unminted), and retrofitted the 2026-07-03-end-skill-round-trip example as the first living instance (18 tagged regions; logs materialized into end-skill-redesign and mint-manifest-rename). Nothing minted.
- [2026-07-04 - council mechanism (review-gate designed; route-tagging audit dispositioned)](2026-07-04-council-design.md) - hook-captured, mixed-tier and deliberately partial: the dev-dev route-tagging audit half is excised to PR #20 (the tiering rule in force), leaving the council-design half. Designed /council (draft-PR medium, adjudicate close-gate, distill-not-dump, the dev-dev-round-mints-no-thread rule), authored beliefs/nursery/council-mechanism.md (staged, unminted), revised route-tagging.md with the audit dispositions, renamed /decompose to /route, and captured the git-check-hook-vs-cb:b573 rebase-hazard hand-off prompt. Nothing minted.
- [2026-07-05 - the read-surface close (history-rewrite rule minted, PR #22)](2026-07-05-provenance-read-surface.md) - hook-rendered, /end run in its own turn; minted cb:b585 (no history rewriting where commits carry provenance; disregard the git-check hook's remedy) and cb:b586 (the render-contract successor putting it on CLAUDE.md's Git Policy), recovered and merged the lost proofing branch, recorded three environment defects, merged PR #22 (253291c), status-annotated the proofing doc (handled, verification outstanding), and opened git-check-hook-upstream-fix with the agent kickoff prompt.
- [2026-07-05 - the proofing run (task proofed, environment forensics, absorbed into the read-surface close)](2026-07-05-git-rewrite-task-proofing.md) - hook-rendered, /end run in its own turn; the proofing session behind the read-surface close: verified the task's premises, found the generator a pure renderer (Git Policy = cb:b580 via cb:b065) and flipped the scope steer to the proto-belief path, reflog-dated the stale baked-in local main to the pre-warmed image, took the git-check hook's rewrite advice under fire without complying, authored the first ENVIRONMENT_DEFECTS.md + session-start fetch/fast-forward, and delivered the corrected prompt PR #22 executed. Nothing minted.
- [2026-07-05 - the upstream request and the corrected premise (cb:b587)](2026-07-05-git-check-hook-upstream.md) - hook-rendered, /end run in its own turn; re-verified the git-check hook defect and revised the diagnosis (commits SSH-signed at creation and GitHub-verified; the hook's %G? test false-positives without an allowedSignersFile), drafted the paste-ready upstream request and refiled it as a nursery proto-belief, surfaced the delivery-channel decision (operator: keep staged), and minted cb:b587 (accept_supersede of cb:b585) putting the corrected rationale on CLAUDE.md's Git Policy via the cb:b586 repoint; merged via PR #25 (df1ba30) after a union-merge resolution of the PR #24 collision.
- [2026-07-06 - route-tagging enactment (verifier built, cb:b588-b594 minted, spec graduated)](2026-07-06-route-tagging-enactment.md) - hook-rendered, /end run in its own turn; the A2 enactment for PR #20: built mix cb.verify.route_tags (five checks; first run reproduced audit F5, fixed by materializing transcript-format's log from the verifier's own derivation), minted the seven staged candidates through clean preflights (cb:b588-b590 route-tagging, cb:b591-b594 council-mechanism), and made the cb:b569 graduation call - route-tagging graduated to beliefs/archive/ with citations repointed, council-mechanism held live pending the /council build.
