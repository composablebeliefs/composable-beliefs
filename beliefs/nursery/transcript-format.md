---
type: concept
title: How transcripts and proto-belief documents persist exchanges
description: Spike document for the transcript persistence pipeline - whether to commit the raw jsonl, generating metadata at /end, conforming belief-audit.md and the .sessions transcripts to one format, and proto-belief documents carrying per-topic excerpts. Self-contained; start the implementation thread here.
tags: [nursery, transcript, format, provenance, spike]
status: active
timestamp: 2026-06-26
maturity: contested
threads: [2026-06-25-belief-audit, 2026-06-26-nursery-workflow]
---

# How transcripts and proto-belief documents persist exchanges

> **Spike document.** This doc is self-contained: a new thread can start implementation from
> here without replaying the originating thread. The exchanges that ground each decision
> are excerpted at the bottom (the excerpts pattern, applied to itself).
> `contested`: it reverses parts of the shipped design (the gitignored `.sessions/`, the
> responses-only-only hook, nursery-architecture's "Layer 1 vestigial" lean).

## The matter
Settle how the conversational record persists across four layers - raw, render,
proto-belief documents, beliefs - their shared format, and what gets committed.

## Target pipeline
```
host jsonl ──(hook copies in, every turn, crash-safe)──► repo raw jsonl
          ──(hook renders)──────────────────────────────► readable render (responses-only)
          ──(/end)──────────────────────────────────────► metadata populated (frontmatter + narrative section + digest)
          ──(human + agent)─────────────────────────────► proto-belief documents (excerpts + synthesis)
          ──(mint)──────────────────────────────────────► beliefs + prescriptions
```

## Decisions
- **Single artifact at close. (2026-07-02, cb:b578.)** The thread document is the only
  persisted close artifact, and it opens with the operator-facing narrative section - the
  chronicle register folded in (where things stood, the arc as story beats, where things
  stand, what the next session inherits; narrative load-bearing, ids subordinate).
  `chronicles/` is closed to new entries, so the `/end` metadata step synthesizes the
  narrative section along with the frontmatter and digest; no separate chronicle write.
- **Persist the raw, not just the render. (Reopened 2026-06-26 → raw.)** A framework whose
  purpose is agent observability should persist exactly what lets agent behavior be
  audited - the reasoning and actions, not only the agent's self-report (the render is the
  self-report; the raw is what it actually reasoned and did). Earlier this was settled as
  "render only"; the auditability argument reversed it. Gated on the repo-weight decision
  below.
- **Metadata at `/end`.** Rich frontmatter + outcome digest + produced-links are only
  knowable at session end. `/end` synthesizes them; the hook owns the live body. Not a
  separate decision - it is part of the conformed format.
- **One format. Confirmed 2026-06-26.** belief-audit.md and the `.sessions/` transcripts
  conform to a single shape - belief-audit.md's (frontmatter + digest + turn-by-turn body)
  becomes the *prototype*, not a relic. The hook + `/end` produce docs in that shape.
- **Documents carry per-topic excerpts.** Each proto-belief document includes the selected
  turn-by-turn exchanges that support its summaries, so a fresh agent can run a spike from
  the document alone (this doc is the first instance).
- **Render must not lag a turn. (2026-06-26.)** The hook has to capture the response that
  triggered it, not stop one turn behind - the recurring `cb:a518` transcript tail-gap.
  This is a correctness fix to the hook mechanism, not a separate focus; it lands with the
  pipeline below.

## Open: repo weight (settle first in the spike)
Committing every session's jsonl grows `.git` by that size **permanently** - git never
forgets a blob. The "delete after `/end`, recover via git history" idea cleans the working
tree but does **not** shrink the repo: the blob staying in history is exactly what makes it
recoverable. So that buys a clean working tree + recoverability, but unbounded `.git`
growth. "Recoverable via history" and "no added weight" are in tension - history *is* the
weight. Real options to bound it:
- **git LFS** for the raw jsonl - tracked + recoverable, stored out-of-band, prunable.
  Keeps everything, bounds the main repo. **(Lean.)**
- **Gitignore the raw**, commit only the render - loses permanent raw audit (host jsonl
  gives ~30 days of ephemeral raw).
- **External archive** + commit a pointer.
Decision: LFS for raw, render committed inline, and the delete-from-working-tree cleanup on
top (clean tree, blobs in LFS). **Deferred 2026-07-03 (operator):** punt on persisting the
jsonl until there is a concrete reason to do so - the raw stays gitignored working-area
(the shipped /end behavior), the host retains raw ~30 days, and LFS remains the lean for
when a reason lands. Note the seed-absorption coupling below still assumed permanent raw;
graduation's win (seed-lifecycle) already dissolved that dependency.

**Now load-bearing downstream.** Fold-and-evacuate ([seed-absorption](seed-absorption.md))
deletes a losing document and keeps only a folded summary in the winner - safe *only* if the
loser's raw reasoning persists here. Render-only / gitignore-raw would force keeping
pointer-stubs instead. So the persist-raw lean is no longer local to transcripts; resolve
the two together.

## Proto-belief documents vs prescriptions (architecture)
Proto-belief documents absorbed the plan role (cb:b569) - and that **composes** with the
prescription-as-todo model rather than competing. The graph already grounds prescriptions
in `document:`/`plan:` artifacts (the session-start ritual: "follow its deps and
`document:`/`plan:` artifacts to the records that ground it"); a proto-belief document
*is* that artifact. So:
- a **prescription** is the atomic, desk-tracked, materializable "do X" (queryable, status);
- a **proto-belief document** is the fat floor-tier record it cites for context.

When a document is spike-ready, mint a prescription ("implement the conformed transcript
pipeline") that deps/cites this document. Prescriptions trace back to proto-belief
documents as provenance - two-tier (graph tracker + floor document), not a separate plan
category.

## The spike (next thread starts here)
1. **Decide repo-weight** (LFS vs gitignore-raw vs external; lean LFS).
2. **Hook:** copy the host jsonl into the repo each turn (raw, crash-safe); keep the
   responses-only render; **preserve an existing frontmatter block** on rewrite so `/end`
   metadata survives the every-turn regeneration; **fix the one-turn lag** so the render
   includes the triggering response (the `cb:a518` tail-gap).
3. **/end step:** synthesize the metadata (description, outcome digest, produced-links) and
   the operator-facing narrative section (cb:b578) onto the render; commit the final
   artifacts; optionally delete the working-tree copies. The thread document is the single
   close artifact - no chronicle write.
4. **Conform** belief-audit.md and the `.sessions/` docs to the one shape (belief-audit.md
   as prototype); un-gitignore the render lane.
5. **Documents-carry-excerpts** as standard across proto-belief documents.
6. When scheduling, **mint a prescription** that cites this document (per the architecture above).

## Thread excerpts (what grounds the decisions)
Selected turns from the originating thread (2026-06-25/26) - enough to start the spike
without replaying the whole conversation.

**User (the pivot):** "that's the only reason for why its stored in .sessions? what if we
decide that is not an issue? seems committing or not committing should relate more to
whether we decide the thread doc should be a persisted artifact or not, NOT simply git
cleanliness."

**Claude:** Owned it - the churn answer filed a design question under mechanical
convenience; the real axis is "is the full transcript a persisted artifact we stand
behind?" That mis-filing is what `agent-behavior:a412` records.

**User:** "i would lean readable render unless again you can make a case to keep jsonl... i
don't see a compelling reason to persist thinking and tool calls."

**Claude:** The one real case for raw is agent-behavior auditing - the render is the
self-report, the raw is the behavior; but the host jsonl already retains raw ~30 days, so
render is the default unless you want a *permanent* agent-behavior corpus. (Concurred with
render - then reversed below.)

**User (reversal):** "a framework which exists to add observability to agent behavior
should in fact persist everything that in its creation would allow for the same auditing of
said agent behavior... will the jsonl add too much weight to the repo itself as it builds
up? would we have the option of deleting the jsonl and readable threads after /end, but
being able to reach them later if necessary via git history?"

**Claude:** Delete-after-/end cleans the working tree but does not shrink `.git` (the blob
is permanent - that is what makes it recoverable); "recoverable" and "no weight" are in
tension. LFS is the reconciliation.

**User (open question):** "these seeds are certainly veering closer to a type of plan doc,
does this work with our current use of directives representing todos/plans? or is it just
that directive/directives trace back to these seed docs as provenance?"

**Claude:** The latter - directives stay the desk-tracked todo; seeds are the briefs they
cite (the graph already grounds directives in `document:`/`plan:` artifacts). Two-tier, not
competing.

**User (2026-06-26, hook lag):** "how to make the the thread doc update after each response
via the hook, to avoid the thread always being one response behind." (Folded in as the
hook-lag fix above; the `cb:a518` tail-gap, recurring.)

## Related
- [nursery-architecture](nursery-architecture.md) - this reverses its "Layer 1 vestigial" lean.
- [seed-absorption](seed-absorption.md) - how a planted document's deliberation folds into the belief.
- `agent-behavior:a412` - the drift-is-a-code-smell rule this session surfaced.
