---
type: concept
title: Redesign /end so a thread's finalized record cannot overstate its own completeness
description: Covers the cb:b518 tail-gap as it lands on the finalized thread document - /end writes the curated body during a turn whose render only reaches the previous completed turn, so the close turn is absent from the body while a provenance note asserts it is present. Analyzes the three operator-posed options against the finding that the decisive variable is turns, not skills. Chosen direction (operator, 2026-07-03): keep the self-contained embedded transcript body, run /end alone in its own turn so the render has caught up, warn on inline invocation, and keep a completeness-honesty backstop. The render-pointer alternative was considered and rejected on a duplication argument. Gates the /end rewrite.
tags: [nursery, threads, provenance, end-skill, observability]
status: active
timestamp: 2026-07-03
maturity: active
threads: [2026-07-02-fold-chronicle-into-threads]
---

# Redesign /end so a thread's finalized record cannot overstate its own completeness

## The matter

`/end` finalizes the session's thread document during a turn: it synthesizes the metadata,
the narrative section, and the routing ledger onto the live render, then commits. But the
Stop hook's render only ever contains through the *previous completed* turn - the render
for turn N is written after turn N's response lands, so an `/end` that runs *inside* turn N
reads a render frozen at turn N-1. The turn that runs `/end` (and any substantive close
work done in it), plus everything after, is therefore absent from the finalized body. This
is the recurring cb:b518 tail-gap, now landing on the one artifact the framework treats as
the curated close record.

The tail-gap alone is a known, accepted tradeoff (cb:b518, evidence 8: the SessionEnd
finalizer that tried to close it was removed as more failure surface than the one-to-two
closing turns of no-decision-content it recovered). What this document captures is the
*second* failure the single-artifact close (cb:b578) introduced on top of it: the
finalized body is a frozen snapshot that stops at turn N-1, and `/end` can attach a
provenance note asserting a completeness the body does not have. A thread that opens by
claiming to be the audited record of its session, and is wrong about where its own record
ends, corrodes the trust the close artifact exists to earn.

## The defect, with the evidence

The first `/end`-finalized close is the demonstration. Read the two files side by side:

- **`threads/2026-07-02-fold-chronicle-into-threads.md`** - the finalized body. Its last
  transcribed turn is the user turn "Add the line in the fold plan re: desk" (22 user
  turns in). The next turn, "Proceed with the close in order", is where the retro-pairing
  and the `/end` run *actually executed* - and it is not in the body at all. The PR/merge
  tail that followed is likewise absent.
- **`threads/.sessions/2026-07-02-692c6ff4.md`** - the raw hook render of the same
  session, later rewritten by the ride-along commit. It carries 23 user turns: everything
  the finalized body has, plus the "Proceed with the close in order" close turn. Diffing
  the two locates the boundary exactly - the finalized body stops one user turn short of
  the render, and that one turn is the close itself.

The overstatement is concrete. The finalized doc's provenance blockquote reads: "the
session's mints were retro-paired against this document's path before the file existed, so
the close turn is summarized here, not transcribed - the receipts end at the retro-pair
exchange." Two things are wrong with that. There is no retro-pair exchange in the receipts:
the retro-pairing ran during "Proceed with the close in order", the very turn the body
omits. And the receipts do not "end at the retro-pair exchange" - they end one topic
earlier, at the fold-plan edit. The note asserts the body reaches a turn the body never
contains. The doc overstates its own completeness by one full topic, and it does so in the
exact place a reader looks to calibrate how much to trust it.

## The options: the decisive variable is turns, not skills

The operator posed three restructurings. Tested against the mechanism, they separate
cleanly, and the separator is not how many skills there are but whether finalization runs
in a *later turn* than the substantive close.

1. **Split into `/transcript` + `/end`.** Works - but *only* if the two run in separate
   turns. If the substantive close work lands in turn N and `/end` runs in turn N+1, then
   the render `/end` reads has caught up: it now includes turn N, so the finalized body
   includes the close turn. The finalizer's own turn (N+1) becomes the only gap, and it
   carries no decision content - which is precisely the tradeoff the house already accepted
   at cb:b518. Split the skills and run them in one turn and it fixes nothing (see option
   2). The split itself is not needed: a single `/end` run in its own later turn achieves
   the same boundary (skill-shape resolved below).

2. **A `/final` skill that runs both successively.** Does *not* close the gap. Successive
   means same turn. Two skills invoked back to back inside turn N both read the render
   frozen at turn N-1; the close turn is still absent. Same-turn is same-staleness
   regardless of how the work is packaged into skills. This is the option that proves the
   variable is turns: it changes the skill count and nothing else, and nothing else
   changes. Rejected.

3. **Reorder events within `/end`.** Fixes the *honesty* of the provenance note but not
   the *structural* gap on its own. Ordering `/end`'s own steps can make it state the true
   boundary ("this body covers through turn N-1; the close turn is not transcribed"), which
   removes the overstatement - this survives as the honesty backstop below. But reordering
   alone cannot pull in a turn whose render does not yet exist. Honest, not complete;
   necessary but not sufficient.

The finding: a single turn's finalized artifact can only ever contain through the previous
completed turn, because the render it reads is written at turn boundaries. No arrangement
of skills changes that. Only interposing a turn boundary between the substantive close and
the finalization lets the render catch up - and a turn boundary is a *separate exchange*,
not a second skill call.

## Chosen direction (operator, 2026-07-03)

Keep the self-contained embedded transcript body; make it complete by running `/end` in a
later turn; back it with an honesty note. Three parts:

1. **Keep the embedded transcript body.** The thread document stays a self-contained,
   readable record - narrative section, routing ledger, and the turn-by-turn body inline -
   not a pointer to a file elsewhere. (Why not the pointer alternative: next section.)

2. **`/end` runs alone, in its own turn.** The substantive close work happens in one turn;
   `/end` is invoked in the *next* turn, as its own exchange, never inline with close work.
   By then the hook has rendered the close turn, so the embedded body includes it. The only
   omitted turn is the `/end` invocation turn itself - which is nothing but "run `/end`",
   carries no decision content, and needs no disclosure that it was dropped (operator: the
   lost turn is always just the operator running `/end`, so there is no issue to declare).

3. **Warn on inline invocation, and never overstate.** Because the turn-separation rule is
   procedural (someone must run `/end` as a follow-up turn rather than inline), it is
   guarded two ways: `/end` invoked inline emits a **warning** that the current turn will
   not be captured in the finalized body; and whatever happens, the provenance note states
   the true boundary rather than claiming completeness it lacks. The honesty note is the
   backstop that makes the artifact truthful even when the workflow rule is violated - the
   exact failure the fold-chronicle close demonstrates.

This keeps the render pointer's one real advantage (a body that actually reaches the close)
without its cost, and it leaves the raw jsonl punted (unchanged): the readable, committed
record is the embedded body in the thread document.

## Considered and rejected: the render-pointer form

The alternative was to stop embedding a body at all and have the thread document carry only
its synthesized parts (narrative, routing ledger) plus a *pointer* to the continuously
rendered `.sessions/` transcript. Its appeal was that a pointer to a live-updating file is
never stale - it self-heals to include the close turn - so it would dissolve the tail-gap
rather than race it, and it would remove a cb:b386-style frozen duplicate.

It was rejected on a duplication argument (operator, 2026-07-03):

- **The readable render exists no matter what.** The Stop hook must write it live for
  crash-safety, before `/end` ever runs, and the operator needs it readable. So there is
  always one unavoidable readable copy of the exchange. Every other copy is a *second* one.
- **The jsonl is the duplicate not worth paying for**, and it stays punted: it is mostly
  the render's information plus reasoning and tool-calls, at permanent repo-weight cost.
- **The embedded body is the second copy worth paying for.** The render lives in a hidden
  `.sessions/` *draft lane*; pointing the curated, operator-facing thread document into a
  hidden draft file makes the curated artifact *hollow* - a pointer, not a document you can
  read on its own. The duplication (live render + finalized embedded body) buys a
  self-contained, readable, curated record, which is what the thread document is for.

So the render-pointer's freshness advantage is recovered by turn-separation instead, and
the self-contained body is kept. This also **dissolves the transcript-format dependency**
the earlier draft of this document carried: because the thread document no longer relies on
the `.sessions/` render being permanently canonical, transcript-format's open
repo-weight/LFS question no longer gates this redesign.

## Open

- **How `/end` reads the boundary for the honesty note.** The note needs the last turn the
  body actually covers. Deferred deliberately (operator): under the turn-separation rule the
  boundary is predictable - the body covers through the close turn and only the `/end` turn
  is omitted - so a precise dynamic computation is not needed to get the system going. The
  mechanism (compare the render's last turn against the live session, or stamp the render
  with a turn count the note can cite) can be designed when a concrete need arises.
- **The inline-invocation warning mechanism.** The rule is that `/end` run inline warns that
  the current turn will not be captured. How the warning fires needs design: `/end`
  self-checking whether its own turn also did substantive close work, a Stop-hook check, or
  a comparison of the live turn against the render. Detecting "inline" reliably is the open
  part; the warning's *content* and *intent* are settled.

## Mint manifest

Two prescriptions. Both are candidates (unplanted) while the warning mechanism and the
`/end` rewrite are gated on this document. The type is `prescription` for both because a
`/end` redesign mints rules; a mint manifest is not limited to prescriptions (its rows can
be any of the four belief types - attestation, aggregation, inference, prescription) - this
matter simply happens to produce only rules.

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | `/end` runs alone, in its own turn, after the session's substantive close is complete; it is never invoked inline in a turn that also does close work. Run in a later turn, the render has advanced to include the close turn, so the finalized document's embedded transcript body contains it; the only omitted turn is the `/end` invocation turn, which carries no decision content and needs no disclosure. `/end` invoked inline emits a warning that the current turn will not be captured in the finalized body. Same-turn successive finalization (a `/final` running close and finalize in one turn) does not satisfy this and is rejected: a turn boundary is a separate exchange, not a second skill call. | cb:b518, cb:b578 | document:beliefs/nursery/end-skill-redesign.md | - |
| prescription | A finalized thread document's provenance note must not assert coverage the body lacks: it states the exact last turn the embedded body covers and never claims the close turn or any later turn is present when it is absent. This is the backstop that keeps the artifact truthful even when `/end` is run inline against a render frozen at the previous completed turn - the fold-chronicle overstatement is the failure it prevents. | cb:b518, cb:b386, cb:b578 | document:beliefs/nursery/end-skill-redesign.md | - |

## Thread excerpts (what grounds this)

**Operator (the round-trip spike that surfaced it):** "I'm wondering if this RoundTrip
Cycle is active at this time, and to what degree ... my description here reflects reality."
The spike found the top half of the cycle pending because `/end` had never run, which set
up the first `/end` close and its tail-gap.

**Operator (the duplication argument, rejecting the pointer form):** "if we persist and
commit the JSONL, we are stuck without a readable transcript of the exchange, which is
important for the human operator. So either way, it looks to me like we have a duplicate ...
we should move forward with the embedded transcript and forgo persisting the jsonl and
pointing to that."

**Operator (the turn-separation rule and its guard):** "The slash end skill should always be
called alone. It should never be run in line. One way this could be guarded against is a
belief that's minted in the graph to always provide a warning if end has been provided in
line that this is problematic in the last turn won't be captured." And on the dropped turn:
"the turn that is lost is always just me running /End, then I don't see the issue. It
doesn't really need to be declared that that is being dropped."

**cb:b518, evidence 8 (the accepted tradeoff this builds on):** "the SessionEnd hook ...
was too much fragile machinery for ~1-2 closing turns of no decision content ... Turns
after it (the close, or work done after /end) are captured by re-running /end; the operator
accepted that trade." Turn-separation is that same tradeoff made the default: finalize in a
later turn so only the contentless finalizer turn is lost.

**The fold-chronicle provenance note (the overstatement, verbatim from the finalized
body):** "the close turn is summarized here, not transcribed - the receipts end at the
retro-pair exchange." The receipts end one turn before the retro-pair; the note names a
turn the body does not contain.

## Related

- [transcript-format](transcript-format.md) - the persistence pipeline this modifies; its
  "render must not lag a turn" decision is the same cb:b518 tail-gap at the hook layer. Its
  repo-weight/LFS question no longer gates this redesign, since the chosen direction keeps
  the embedded body rather than pointing at the render.
- cb:b578 - the single-artifact close this redesign amends; the prescription whose body is
  the thing overstating itself.
- cb:b572 / cb:b582 - the routing ledger, which the thread document keeps alongside the
  embedded body, unchanged.
- cb:b386 - the cached-digest antipattern; the honesty backstop and the turn-separation rule
  keep the embedded body from becoming the stale, self-misdescribing copy it warns against.
- cb:b518 - the tail-gap history and the accepted no-decision-content tradeoff this makes
  the default rather than fighting.
- cb:b507 - retro-pairing and the pair-then-write ordering the redesign must keep legal; the
  embedded-body direction leaves that ordering untouched.
- [mint-manifest](mint-manifest.md) - the convention this document's Mint manifest section
  follows (cb:b567, re-issued cb:b581); see the note there on why the section is named as it
  is and carries all four belief types, not only prescriptions.
- [vocabulary-read-surface](vocabulary-read-surface.md) - a sibling read-surface-hygiene
  matter from the same session; the caution against echoing retired registers applies to
  this document's own vocabulary.
