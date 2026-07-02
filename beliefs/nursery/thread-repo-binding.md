---
type: concept
title: Bind each thread to the repo it relates to (thread init)
description: Covers persisting each thread doc in the repo the work concerns rather than always in composable-beliefs - set by a thread-init step at the start of a session. The hook now derives its dir from the repo the session ran in ($CLAUDE_PROJECT_DIR), which narrows this focus to the concerns-vs-ran-in routing question.
tags: [nursery, threads, workflow, multi-repo]
status: active
timestamp: 2026-07-02
maturity: active
threads: [2026-06-26-nursery-workflow]
---

# Bind each thread to the repo it relates to

## The focus
Work in this tree spans many repos (composable-beliefs, belief-collections, the direction
repos, satellites). A thread's transcript should persist in the repo the work concerns, not
always in composable-beliefs. The transcript hook hardcodes one `THREADS_DIR`
(`.claude/hooks/transcript_hook.py`), so every session lands in composable-beliefs
regardless of subject.

## Where it stands
- **A thread-init step.** At the start of a session, declare the owning repo (and thus the
  threads dir); the hook reads that binding instead of a constant. Init is the natural home
  for anything else a thread needs stamped once - owning repo, thread slug, the session id.
- **The hardcoded constant is gone (2026-07-02).** The hook now derives its repo from
  `$CLAUDE_PROJECT_DIR` (falling back to its own location), is registered in the committed
  `.claude/settings.json`, and copies the raw jsonl beside the render - so capture runs in
  remote sessions too, and each session lands in the repo it *ran in*. That narrows this
  focus to the routing question proper (the repo the work *concerns* is not always the repo
  the session ran in), and gives the binding a single seam to hook into: the hook's
  `project_dir()`.
- **Open:** where the binding lives (a per-session state file the hook reads? a marker the
  agent writes at init?); the default when unset (the repo the session ran in); and the
  cross-repo case (a session touching several repos - primary owner, or split?).

## Related
- `cb:a543` - the global, cross-project directive graph; the same multi-repo routing problem
  one tier up.
- `cb:a500` - the cross-collection desk view; cross-repo surfacing of the same records.
- [statement-provenance](statement-provenance.md) - once threads live in the right repo,
  per-statement links can point at that repo's seeds/beliefs.

## Thread excerpts (2026-06-26)
**User:** "need to determine a workflow so that each thread doc is persisted within the repo
that it relates to, this would need to be set at the beginning of each thread as a sort of
init."
