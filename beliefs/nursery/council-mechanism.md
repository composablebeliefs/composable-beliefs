---
type: concept
title: Council - a disciplined review-and-converge round on a draft PR, distilled to the plan
description: Covers the /council mechanism - a structured multi-agent review round run on a draft PR (comments, never committed files), driven to convergence and distilled into the target proto-belief plan. Settles the medium (draft PR), the record (distilled decisions plus a dated rejected-because block; the raw exchange referenced by commit, never copied), the close-gate (adjudicate-style, refuses while any finding is undispositioned), and the provenance-tiering rule that keeps a dev-dev review round out of the thread listing while an operator-in-the-loop design deliberation mints a thread. The concrete form of the review gate between work-drafted and work-minted; the review analog of /end. Unminted; rows staged.
tags: [nursery, workflow, review, provenance, multi-agent]
status: active
timestamp: 2026-07-04
maturity: active
threads: [2026-07-04-council-design]
---

# Council - a disciplined review-and-converge round on a draft PR, distilled to the plan

## The matter

Multi-agent review currently happens ad hoc. The route-tagging audit is the worked example:
an auditor agent produced a findings report, a dev agent responded, and the operator ferried
each artifact between them by hand. There was no durable medium for the exchange, no
convergence gate, and no rule for what survives the round. The review reasoning - which is
what actually shapes the eventual belief - lived only in a chat transcript the operator had
to carry.

What is missing is the review analog of `/end`: a disciplined motion that runs at the gate
between **work drafted** (committed to a branch, not yet minted or merged) and **work minted
or merged**, that gives the exchange a durable home, drives it to convergence, and distills
the outcome into the target proto-belief plan - without inventing a second provenance store
alongside the graph (the shadow-graph the nursery is built to forbid, `nursery/index.md`).

## The design: a review round on a draft PR, distilled at close

`/council` is one re-invocable skill with four motions. It is the review-gate analog of
`/end`: where `/end` finalizes a session, `/council` finalizes a *deliberation*.

- **`open`** - ensure a **draft PR** exists as the chamber, then dispatch one or more
  reviewer agents with a fixed adversarial brief plus the diff. Each returns a structured
  findings report, posted as PR review comments.
- **`review`** - a fresh reviewer adds an independent pass (the auditor role) as PR comments.
- **`respond`** - the author agent reads open findings and replies to each with a
  disposition: **agree / refute (with evidence) / defer**. Nothing is silently dropped.
- **`close`** - the convergence gate (below). Distils the settled outcome into the target
  proto-belief and hands the plan to an implementer.

Only `open` spawns agents; `review`, `respond`, and `close` are single-agent motions on the
shared PR blackboard - which is what lets `/council` work whether one coordinator drives the
whole round or independent sessions take turns against the same PR.

## Two load-bearing rules

- **The medium is a draft PR; reviews are comments, never committed files.** The only thing
  that ever lands in the tree is the distilled plan plus the code. A draft PR opens the
  review channel without inviting a merge (`cb:b573` governs the eventual merge commit). This
  is what keeps a council from becoming a second store parallel to the graph. Never main,
  never a replay of a round that already happened.

- **The durable record is distilled, not dumped.** Settled decisions become the target
  proto-belief's Open items and Mint-manifest rows; rejected alternatives fold into a dated
  "rejected: X because Y" block (the existing `grafted` fold, `nursery/index.md`); the raw
  exchange stays referenced by `commit:` / PR, never copied into the document. Dumping the
  transcript into the proto-belief is the whole-region bloat route-tagging's own audit
  flagged; distilling is the cure.

## The close-gate: distillation is a gate, not a dump

`/council close` is modelled on `mix cb.adjudicate`: **dry-run by default, and it refuses to
converge while any finding is undispositioned.** Just as preflight refuses on unresolved
conflicts, close refuses while a finding is neither agreed, refuted, nor deferred. That is
what forces the every-finding-dispositioned property and prevents the silent-omission failure
mode - the same sin-of-omission the review exists to catch, turned on the review itself.

## Provenance tiering: which rounds mint a thread, and which do not

A council review round is **dev-dev by nature** (auditor and author agents, implementation
detail, no operator design call). By the thread doctrine, **a dev-dev review round mints no
thread**: threads are not provenance (`threads/index.md`: a belief grounds in a proto-belief
document, never in a transcript), so a round's raw exchange is cited by `commit:` / PR and
its decisions are distilled into the plan - and nothing pollutes the thread listing.

Only **operator-in-the-loop design deliberation** mints a thread, because that is where
decisions exist only in the exchange until distilled. The discriminator is therefore *does
this round produce operator design decisions*, not *did agents talk*.

**There is no embedded-exception clause.** A council review round is never persisted in a
thread, full stop. When review and design happen in one session (as the founding session
did - a route-tagging audit round followed by this council-design deliberation), the remedy
is to **excise** the review half to a PR comment and finalize only the design half, not to
carve out an "embedded round is acceptable" exception. Persisting a review round in a thread
is an own-goal; the rule is positive and unqualified.

## Bootstrapping

The first council is **hand-run** - there is no skill to invoke while the skill is being
designed - exactly as route-tagging was hand-retrofitted before its `/route` motion existed.
A hand-run round is a legitimate founding example only when it is labelled as hand-run and
does not manufacture receipts for machinery that was not in force (the route-tagging
freeze-backfill lesson).

## Open

- **Does `open` require the Agent / PR tools.** Spawning reviewers and posting PR comments
  makes `/council open` a heavier skill than the pure-authoring ones (`/assert`, `/end`); the
  other three motions are single-agent. Whether `open` is in-scope for the skill or a manual
  step around it is unsettled.
- **Convergence detection.** `close` refuses while a finding is undispositioned - detecting
  "every finding dispositioned" mechanically (vs. operator assertion) needs design.
- **Where the tiering rule lives.** The dev-dev-round-mints-no-thread rule may be separable
  from the council skill (it is a general thread-minting policy, grounding in
  threads-are-not-provenance, that would hold even if `/council` never shipped) - a `cb:b569`
  split into its own proto-belief, or a fold into `transcript-format`. Held here for now.
- **The audit round's PR home.** A round that reviews already-merged work has no live draft
  PR; the founding audit is posted to the route-tagging rework PR (#20) after the fact. The
  general rule for reviewing merged work (open a fresh draft PR for the rework and comment
  there) wants stating.

## Mint manifest

Candidates (unplanted) while the skill build and the tiering split firm up. Deps are
existing beliefs; grounding is this document.

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | A council review round runs on a draft PR as its medium: findings and responses are PR review comments, never files committed to the tree; the only artifacts that land in the repo are the distilled plan and the code. The medium is never `main` and never a replay of a round that already happened elsewhere. | cb:b573 | document:beliefs/nursery/council-mechanism.md | - |
| prescription | A council round is distilled at close into the target proto-belief: settled decisions become its Open items and Mint-manifest rows, rejected alternatives fold into a dated rejected-because block, and the raw exchange is referenced by `commit:`/PR and never copied into the document. The distilled plan, not the transcript, is what an implementer receives. | cb:b569, cb:b386 | document:beliefs/nursery/council-mechanism.md | - |
| prescription | `/council close` is a gate, not a dump: dry-run by default, it refuses to converge while any finding is undispositioned (agreed, refuted, or deferred), the same discipline `mix cb.adjudicate` applies to conflicts. | cb:b578 | document:beliefs/nursery/council-mechanism.md | - |
| prescription | A dev-dev review round mints no thread and is cited by `commit:`/PR; only operator-in-the-loop design deliberation mints a thread. A review round is never persisted in a thread, with no embedded-exception clause; a mixed session excises its review half to a PR comment and finalizes only the design half. | cb:b578 | document:beliefs/nursery/council-mechanism.md | - |

## Thread excerpts (what grounds this)

**Operator (the two branch proposals):** a `dev-council-discussions` branch holding review
analyses "without needing to commit it to main ... the eventual main commit would be a
finalized dev prompt, workshopped in this council branch, handed to a dev agent"; or the same
"on the branch where the work is being done ... agent A does work ... agent B reviews ...
persists as a doc on the A branch for A to review ... until a final dev prompt is reached."

**Operator (review is not thread-grade):** "the pr council discussion is not about policy or
design, and it doesn't involve the operator - its dev specifics that are Actually
implementation details."

**Operator (the own-goal, rejecting the embedded exception):** "This 'embedded case' is not
something we ever want to repeat - council discussion should NEVER be persisted in a thread.
'Capturing in b' records an exception we forced one time. Its an own goal."

**Operator (the medium):** "porting the first half of this thread to a pr comment, and then
selectively running /end over the second half."

## Related

- [route-tagging](route-tagging.md) - the audit round that motivated this; the founding
  worked example, and the source of the distill-not-dump (whole-region bloat) and
  gate-not-dump (sin-of-omission) lessons.
- [transcript-format](transcript-format.md) - the thread doctrine the provenance-tiering rule
  refines; a candidate home for that rule if it splits out.
- [end-skill-redesign](../archive/end-skill-redesign.md) - the `/end` analog; the honesty
  discipline (cb:b584) the close-gate mirrors, and the turn-separation (cb:b583) a hand-run
  close obeys.
- [routing-ledger](routing-ledger.md) - a round's decisions route into the target document
  the way a thread's strands route; the ledger vocabulary the citation reuses.
- [mint-manifest](mint-manifest.md) - the candidate-row convention this document's Mint
  manifest follows (cb:b567/b581).
