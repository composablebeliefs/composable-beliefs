---
type: concept
title: Commit provenance at the floor tier (threads, ledgers, briefs)
description: Covers extending the graph tier's structural commit provenance (cb:c067 commit: scheme, Belief: trailers, mix cb.verify.commits, the cb:a563 todo gate) down to floor-tier lifecycle events - atomic lifecycle commits (one transition of one artifact per commit, cb:a475 transposed, adopted vs the GSD comparison and minted cb:a568), Thread:/Focus: trailers as floor analogs of Belief:, back-pointers only with git as the sole index, and merge-without-squash as the SHA-durability condition. Deliberation open: trailer vocabulary, verify extension, squash policy, and checkpoint cadence await resolution.
tags: [nursery, provenance, git, audit-chain, workflow]
status: active
timestamp: 2026-07-02
maturity: active
threads: [2026-07-02-authoring-pipeline]
---

# Commit provenance at the floor tier (threads, ledgers, briefs)

## The focus
The user's aim: every artifact transition in the authoring lifecycle - a thread capture,
a routing-ledger update, a brief edit or graduation, a mint - routes back to a git
commit, so the entire path from prose brainstorming to DAG materialization is manually
auditable and teachable to new agents. What must be added, given what already exists?

## What already exists (the graph tier is done)

The belief<->commit loop is already structural and CI-enforced, not a proposal:

- **cb:c067** added `commit:<40-hex-sha>` to the closed artifact-scheme enum, "resolving
  cb:a545 as option 1 ... the belief<->commit link becomes structural rather than prose
  convention."
- **`mix cb.verify.commits`** enforces both directions plus the todo rung: every cited
  `commit:` URI dereferences to a real commit; every `Belief: cb:aNNN` trailer in history
  names a live node; every todo close's recorded commit resolves. Per cb:a545: "the
  scheme alone buys nothing; the value is unlocked only by enforcement/resolution."
- **cb:a563** gates `mix cb.todo.close` on `--commit <sha>` or an explicit `--no-commit`,
  so "silent omission stops being possible at the door."

So the last rung of cb:a442's audit chain (code -> contract -> graph -> plan -> raw
conversation) is typed for *graph* events. The gap is the **floor**: thread captures,
ledger updates, and brief lifecycle events produce commits with no convention naming what
kind of lifecycle event they are or which floor artifact they concern.

## Design leans

1. **Atomic lifecycle commits (adopted 2026-07-02; minted cb:a568).** The auditable unit
   is the lifecycle transition - and exactly one per commit: one thread captured or
   updated, one focus brief opened/updated/graduated, one focus's manifest rows minted.
   A commit conjoining separable lifecycle events is a mis-authored bundle, split at
   commit time - cb:a475's atomicity doctrine transposed from beliefs to commits. Atomic
   means one *event*, not one file: a brief together with the index and manifest updates
   it forces is one event. The payoff is that typed trailers map one-to-one onto
   commits, so a trailer grep returns exactly that artifact's history. Periodic
   checkpoint commits of in-progress threads remain compatible; the convention requires
   that each *transition* be an identifiable - and sole - occupant of its commit. (See
   the GSD block below for the comparison that sharpened the original softer lean.)
2. **Floor trailers as analogs of `Belief:`.** `Thread: <thread-slug>` on thread-capture
   commits, `Focus: <focus-slug>` on brief commits, alongside the existing
   `Belief: cb:aNNN` on mint commits (one id per trailer line, matching the c067
   convention). Auditing becomes `git log --grep`, and a later `mix cb.verify.commits`
   extension can check floor trailers name real docs the way it checks `Belief:` names
   live nodes.
3. **Back-pointers only; git is the only index.** An artifact cites the SHA of a
   *predecessor* commit (a minted belief's evidence cites the commit that landed its
   brief; a brief may cite the commit that captured its thread) - never its own, since a
   SHA cannot self-reference. Forward lookups (which commit landed belief X?) are
   delegated to `git log`/`blame`. No cached artifact-to-commit mapping file is ever
   built: git history is the deterministic, append-only index, and a mapping file would
   be the cb:a386 digest antipattern verbatim.
4. **Durability condition: merge without squash.** A recorded SHA survives only if
   history does; squash-merging rewrites branch commits and would kill every `commit:`
   back-pointer and trailer written on a branch. De facto policy already complies (PR #1
   preserved `be4ee65` through merge; cb:a545's evidence cites its implementing sha
   through the scheme it introduced), but it is nowhere stated as policy. Lean: record
   merge-without-squash as an explicit repo policy, since the audit chain now depends
   on it.

## First instance

The 2026-07-02 authoring-pipeline cycle runs the convention end to end: the thread
capture, the brief batch, and the mint are separate commits carrying `Thread:`, `Focus:`,
and `Belief:` trailers respectively, and cb:a566/cb:a567's evidence entries cite the
brief-batch commit by `commit:` URI. Verify with `mix cb.verify.commits` and
`git log --grep='^Focus:'`.

## Atomic commits - the GSD comparison (2026-07-02)

Prompted by the operator: should the house adopt an atomic-commit policy as in the GSD
(get-shit-done) framework (gsd-build/get-shit-done - phases -> plans -> tasks, every
completed task its own atomic commit, ~59K stars)? Resolution: **yes in spirit, sharper
in letter, adopted immediately.**

- **What GSD validates.** One semantic unit per commit, with the commit message tracing
  to the planning document - the same shape as lean 1, arrived at independently by a
  system optimizing for reviewability and task-granular rollback. The atom differs by
  tier: GSD's is an execution task; the floor's is a lifecycle transition.
- **Where CB was already ahead.** GSD's task-to-commit linkage is prose in the message;
  CB's is typed (`Belief:` trailers, `commit:` URIs) and CI-enforced both directions by
  `mix cb.verify.commits`. Nothing to import there.
- **What the comparison caught.** The first round trip violated its own lean twice:
  `d7e40cb` bundled four `Focus:` events (three briefs opened plus a concurrence
  append), and `ae0e63f` bundled two focuses' mints. Under the sharpened lean both are
  mis-authored bundles - the motivating counterexamples recorded on cb:a568.
- **What is explicitly not imported.** GSD's ROADMAP/SUMMARY document apparatus: CB's
  graph and briefs already hold that state, and a per-phase SUMMARY file is the
  cb:a386 cached-digest shape verbatim.
- **Operator decision.** Split commits per focus effective immediately; present the
  discipline as explicit policy in the DAG via this brief (the intermediary document
  step) - minted as cb:a568, kind `policy`. The landing sequence of a568 itself is the
  first compliant instance: thread update, brief update, and mint as three per-focus
  commits.

## Open questions (deliberation continues here)

- **Trailer vocabulary.** Are `Thread:`/`Focus:` the right two, or is one `Artifact:`
  trailer carrying a repo path more general? Lean: the two named trailers - they mirror
  the floor's two artifact kinds and stay grep-legible.
- **Enforcement.** Extend `mix cb.verify.commits` to dereference floor trailers
  (thread/focus slug -> existing doc, allowing for graduated/renamed docs), or leave
  floor trailers advisory? Per a545's own judgment, an unenforced convention buys little;
  but the floor is mutable, so dereferencing needs a rename story first.
- **Squash policy.** Confirm merge-without-squash as stated policy (and where it is
  recorded - a belief, or repo settings plus a belief). Awaiting the user's call.
- **Checkpoint cadence.** Whether in-progress thread checkpoint commits carry the
  `Thread:` trailer too (making every ledger update addressable) or only the capture and
  `/end` commits do. Lean: every commit that touches the thread doc carries its trailer -
  cheap, and it makes ledger-update archaeology uniform.

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | Atomic lifecycle commits: every commit recording an authoring-lifecycle transition records exactly one transition of one artifact; a commit conjoining separable lifecycle events is a mis-authored bundle, split at commit time (cb:a475 transposed); atomic means one event, not one file. | cb:a475 | document:beliefs/nursery/commit-provenance-floor.md | cb:a568 |

Remaining candidates, gated on the open questions above: a prescription adopting the
floor-trailer convention and the squash policy; a possible action-item row for the
verify.commits floor extension.

## Thread excerpts (what grounds the leans)

**User (the aim):** "the question of state and persisting state via git commits ... to
trace back each artifact, whether it's a thread ... an update in the routing table, a
change in [a] mutable focus document, or ... creating a new belief in the dag ... the
entire life cycle of prose brainstorming to DAG materialization as committed within Git
would be referenceable, and I would be able to manually audit by checking all files."

**Claude (the narrowing):** "The mechanism already exists - git history is a
deterministic, append-only index - so what's missing is convention, not machinery ...
[and on discovery of c067/a545/a563] the git-traceability focus narrows to extending that
machinery down to the floor tier."

## Related
- [transcript-format](transcript-format.md) - owns the commit-the-threads and repo-weight
  decisions this composes with (LFS for raw, render inline).
- [routing-ledger](routing-ledger.md) - ledger updates are among the floor events this
  convention makes addressable.
- [seed-lifecycle](seed-lifecycle.md) - graduation events (brief archived, minted:
  recorded) are floor lifecycle transitions that would carry `Focus:` trailers.
- cb:a545, cb:c067, cb:a563 - the graph-tier loop this extends; read them live with
  `mix bs show`.
