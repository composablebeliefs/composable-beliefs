---
type: thread
title: 2026-07-01 - seed lifecycle deliberation (graduate vs evacuate)
description: Covers the session that deliberated the seed-lifecycle brief - whether terminal seeds evacuate or persist, and whether seed and plan collapse - landing on scenario C and authoring the seed-lifecycle focus; then the thread-persistence arc it opened - diagnosing why the Stop hook could not run remotely and implementing the fix (env-agnostic hook, committed registration, raw jsonl copy, the /end skill). Use when revisiting the seed-lifecycle decision, the commit-the-threads question, or the remote-capture machinery.
tags: [cb, nursery, lifecycle, thread]
status: active
timestamp: 2026-07-02
artifact: session:2026-07-01-seed-lifecycle
---

# 2026-07-01 - seed lifecycle deliberation (graduate vs evacuate)

> **Hand-captured (2026-07-01), finalized by `/end` (2026-07-02).** No `Stop` hook was
> running when this remote session started (the hook was unregistered here and hardcoded a
> local `THREADS_DIR`), so the first arc was written by hand against the still-`contested`
> transcript format ([transcript-format](../transcript-format.md)). The session then fixed
> that: once it committed the hook registration, capture went live mid-session and the
> full render appeared in `.sessions/` retroactively - this doc's later turns are
> finalized from it, the first `/end` run. Tool calls and reasoning are stripped; only
> what was said is kept. Produced: [seed-lifecycle](../seed-lifecycle.md), the
> contested-links marking [seed-absorption](../seed-absorption.md) contested, and the
> capture machinery (hook + `.claude/settings.json` + `/end`).

## Where we are

- **Object of study:** the terminal-seed lifecycle - seed-absorption's fold-and-evacuate
  versus persist-by-graduation - opened from a self-contained seed brief carrying the
  originating thread's lean (scenario C).
- **Settled this far:**
  - Evacuation-by-deletion loses: the fold is lossy everywhere except the plant arm; the
    raw-thread substitute is gated on unbuilt machinery (persist-raw, statement-provenance);
    the `seed` prop is a worse home than a doc; and house precedent (`chronicles/`,
    `plans/done|superseded|deprecated`, the graph's supersede-and-keep) is uniformly
    graduate-don't-delete.
  - Anti-drift (`cb:a386`) does not reach archived seeds: it bans caches of current state
    with procedural freshness; a dated, forward-linked record of past deliberation is the
    opposite object. `chronicles/` is the existence proof.
  - No seed/plan distinction survives scrutiny - scheme is reference form not ontology,
    location is routing by subject, epistemic/execution interpenetrates, and the mint-gate
    vs ship-gate difference is a property of the focus, not the artifact (splitting by
    phase would violate focus-as-unit).
- **Decision reached (the lean):** scenario C, sharpened - terminal seeds graduate
  (historicize + archive), never evacuate-by-deletion; the fold survives as the graduation
  step with the `seed` prop shrinking to digest + `document:` pointer (dissolving the
  granularity question); compost may still delete true fizzles; `plan:`/`document:`
  schemes untouched; the persist-raw/statement-provenance gate on floor deletion dissolves.
- **Process decisions:** the focus authored as `contested`, with explicit contested-links
  flipping seed-absorption to `contested`; and this transcript hand-captured after the
  thread-persistence exchange below.
- **The capture arc (second half):** the persisted-per-convention question exposed that
  the Stop hook could not run remotely for three separable reasons - registration was
  local-only, the output path was hardcoded local, and the local persistence model
  (write to disk) does not survive an ephemeral container. Implemented: the hook derives
  its repo from `$CLAUDE_PROJECT_DIR` (fallback: its own location), is registered in a
  committed `.claude/settings.json`, copies the raw jsonl beside the render, and reminds
  once on first capture; an `/end` skill finalizes the live render into a committed
  thread doc (raw stays working-area pending transcript-format's LFS decision). Shipped
  as PR #8. The fix validated itself live: registration took effect mid-session and the
  full render appeared in `.sessions/` retroactively.

## Turn-by-turn

**User (opening, the seed brief):** A self-contained brief: should nursery seed docs
evacuate or persist, and do "seed" and "plan" collapse into one artifact? Four scenarios
(A status quo evacuate; B archive, keep seed/plan distinct; C collapse into one
durable-brief; D eliminate the curated middle layer), cross-cutting arguments (anti-drift
only bites on the restating part; deletion stronger than the hygiene goal; the
forcing-function survives a graduate step; the scaffolding counterposition must be beaten,
not ignored), and the originating lean (C). The ask: deliberate fresh, stress-test the
lean, land one, write it as a nursery focus contesting nursery-architecture and
seed-absorption.

**Claude:** Deliberated and concurred with C, adding sharpenings. Decisive repo evidence:
`plans/` already runs graduate-don't-delete (`done/`, `superseded/`, `deprecated/`, each
README saying "Kept as the record / for lineage / for design history"), and
seed-absorption's own safety condition for deletion (persist-raw plus statement-provenance)
is explicitly unresolved - a deletion lifecycle whose safety condition is pending is a bet,
not a settled lifecycle. The scaffolding counterposition fails on three points (lossy fold
outside the plant arm; substitute gated on unbuilt machinery; the `seed` prop loses
addressability, readability, and creates the granularity problem) but is conceded where
true: a genuine fizzle may still compost-by-delete. On the collapse: no candidate
distinction survives; "plan" survives as a role and `plans/` as a shelf, not a kind; the
safety-condition dependency inverts (graduation frees persist-raw/statement-provenance to
be about auditing behavior). Wrote [seed-lifecycle](../seed-lifecycle.md) as `contested`,
flipped seed-absorption to `contested` with explicit contested-links, registered the focus
in index and manifest, committed and pushed.

**User:** Pull and merge main into this branch.

**Claude:** Merged `origin/main` (which had gained the structural-type-rename and
contract-predicate-demotion focuses). One conflict: the manifest `count` (15 ours vs 17
main); resolved to 18 by counting the merged docs array. index.md auto-merged with both
branches' focus lines intact. Pushed the merge commit.

**User:** Merged PR into main.

**Claude:** Reset the working branch onto the latest `origin/main` (merge commit of PR #2)
and force-pushed with lease - the branch held only already-merged history, so nothing was
lost; follow-up work starts fresh.

**User:** Is this thread persisted in beliefs/threads?

**Claude:** No. There is no `beliefs/threads/`; the home is `beliefs/nursery/threads/`,
and this session is not captured there. The `Stop` hook cannot run here: no
`.claude/settings.json` registers it in this checkout, and the script hardcodes
`THREADS_DIR` to a path on the user's local machine - exactly the limitation
[thread-repo-binding](../thread-repo-binding.md) records. The durable record of the
session is the seed-lifecycle focus itself; its `threads: []` honestly reflects that only
the seed brief grounds it.

**User:** Check the last 25 commits for previous threads in beliefs/nursery/threads that
may have been deleted recently.

**User:** Did you find any?

**Claude:** No deleted transcripts. Commit `05ee41a` moved the threads dir from repo-root
`threads/` into `beliefs/nursery/threads/` - the one existing transcript
(2026-06-25-belief-audit.md) moved intact as a rename; the old location's `index.md` and
`manifest.json` were deleted-and-replaced housekeeping, not lost threads. The only other
deletion in the window was `plans/cb-schema-v3/design.md` (a plan, absorbed into the
structural-type seeds). `.sessions/` never appears in git history - gitignored by design,
so local transcripts there were never committed.

**User:** OK, I think it's that on my local. Is there a compelling reason not to commit
all threads? Why maintain .sessions and gitignore?

**Claude:** For the readable renders, no compelling reason remains - and the graph already
says so: the original gitignore rationale was "git cleanliness," the mis-filing
`agent-behavior:a412` records and the user themselves called out; transcript-format's
spike step 4 is literally "un-gitignore the render lane." The one surviving concern
applies only to the raw jsonl: permanent `.git` growth (git never forgets a blob;
delete-after-/end does not shrink history), resolved in transcript-format's lean by LFS.
`.sessions/` earns its keep only as a working area for the every-turn crash-safe rewrite -
hook writes live, `/end` finalizes and commits - not as a gitignored sole copy that dies
with one machine. This connects to seed-lifecycle's three-layer story: graph =
conclusions, briefs = synthesis, threads = behavior; the raw layer currently exists only
on the user's laptop.

**User:** OK, persist this thread.

**Claude:** Authored this doc in the hand-captured format the structural-type-vocabulary
thread established, registered it in the threads index and nursery manifest, committed and
pushed.

**User:** Yea, PR. (Then: merged to main.)

**Claude:** Opened PR #3 for the thread; on merge, restarted the branch from main.

**User:** Was this thread persisted in the repo per convention?

**Claude:** Per the convention as it exists (the hand-capture lane) - yes, exactly. Per
the target convention (hook-rendered from the jsonl, raw persisted) - only partially:
this doc is a reconstruction, not a file copy, and the raw layer existed nowhere but the
ephemeral container.

**User:** The hook was written for local agents - am I to understand it won't work for a
remote agent? What could be a workable substitute?

**Claude:** Finer-grained than that: hooks do run remotely; what breaks is registration
(local-only), the path (hardcoded local), and the persistence model (remote persistence
is push-only). Substitute in tiers: (1) env-agnostic path + committed registration; (2)
an /end commit convention with a hook reminder, raw jsonl copied in-container; (3)
per-turn pushes to a dedicated ref - recommended against, since remote sessions are
resumable host-side. Recommendation: tiers 1 + 2.

**User:** Implement all.

**Claude:** Implemented tiers 1 + 2: rewrote the hook (env-derived dir, raw copy,
first-capture reminder), committed `.claude/settings.json`, authored the `/end` skill,
updated the threads index and thread-repo-binding (the hardcoded-dir limitation is gone,
narrowing that focus to concerns-vs-ran-in routing). Tested four paths against a
synthetic jsonl: env-var resolution, script-location fallback, reminder-once-then-silent,
no-op on missing transcript. Pushed; opened PR #8 on request.

**User:** Pull main to update. Should we then run the new /end and update the PR?

**Claude:** Merged main cleanly (the schema-v3 execution had landed - the rename and
contract demotion shipped). Ran the first `/end`: found the hook's live render already
covering the whole session (registration had taken effect mid-session), finalized this
doc from it, registered main's schema-v3-execution thread in the manifest it was missing
from, and pushed - updating PR #8.

## Related
- [seed-lifecycle](../seed-lifecycle.md) - the focus this session produced.
- [seed-absorption](../seed-absorption.md) - flipped to `contested` by this session.
- [transcript-format](../transcript-format.md) - the persist-raw/commit-the-renders
  decisions the closing exchange bears on.
- [thread-repo-binding](../thread-repo-binding.md) - the hardcoded-THREADS_DIR limitation
  this session ran into, then removed.
- `.claude/hooks/transcript_hook.py`, `.claude/settings.json`, `skills/end/SKILL.md` - the
  capture machinery this session shipped (PR #8).
