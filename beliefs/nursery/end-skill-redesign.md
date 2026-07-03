---
type: concept
title: Redesign /end so a thread's finalized record cannot overstate its own completeness
description: Covers the cb:a518 tail-gap as it lands on the finalized thread document - /end writes the curated body during a turn whose render only reaches the previous completed turn, so the close turn and everything after it are absent from the body while a provenance note asserts they are present. Analyzes the three operator-posed options against the finding that the decisive variable is turns, not skills, and proposes dropping the frozen transcript body in favor of a pointer to the continuously-rendered transcript. Gates the /end rewrite; the render-pointer form depends on transcript-format's open repo-weight question.
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
is the recurring cb:a518 tail-gap, now landing on the one artifact the framework treats as
the curated close record.

The tail-gap alone is a known, accepted tradeoff (cb:a518, evidence 8: the SessionEnd
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
   turns. If `/transcript` (or the substantive close work) lands in turn N and `/end`
   runs in turn N+1, then the render `/end` reads has caught up: it now includes turn N,
   so the finalized body includes the close turn. The finalizer's own turn (N+1) becomes
   the only gap, and it carries no decision content - which is precisely the tradeoff the
   house already accepted at cb:a518. Split the skills and run them in one turn and it
   fixes nothing (see option 2).

2. **A `/final` skill that runs both successively.** Does *not* close the gap. Successive
   means same turn. Two skills invoked back to back inside turn N both read the render
   frozen at turn N-1; the close turn is still absent. Same-turn is same-staleness
   regardless of how the work is packaged into skills. This is the option that proves the
   variable is turns: it changes the skill count and nothing else, and nothing else
   changes.

3. **Reorder events within `/end`.** Fixes the *honesty* of the provenance note but not
   the *structural* gap. Ordering `/end`'s own steps can make it compute and state the
   true boundary ("this body covers through turn N-1; the close turn is not transcribed"),
   which removes the overstatement. But the close turn's content is still not in the body -
   reordering cannot pull in a turn whose render does not yet exist. Honest, not complete.

The finding: a single turn's finalized artifact can only ever contain through the previous
completed turn, because the render it reads is written at turn boundaries. No arrangement
of skills changes that. Only interposing a turn boundary between the substantive close and
the finalization lets the render catch up. "Split into two skills" is the *mechanism* that
makes it natural to interpose that boundary; the boundary is the fix, and the skill shape
is downstream of it.

## The stronger proposal: stop embedding a frozen transcript body

There is a cleaner move than racing the render one turn ahead. Stop embedding a frozen
transcript body in the thread document at all.

The Stop hook already persists the render continuously and stages it to ride along with
the session's commits - a live, self-updating, committed artifact. Embedding a second copy
of those turns in the thread document, snapshotted at close, is a cached duplicate of
graph-adjacent content whose freshness depends on when `/end` happened to run. That is the
cb:b386 antipattern in miniature: a persisted copy that embeds the staleness it was meant
to remove, and here it does worse than go stale - it can misdescribe itself, as the
fold-chronicle body does.

Have the finalized thread document carry only what it *synthesizes* and nothing it merely
*copies*:

- the operator-facing **narrative section** (cb:b578) - where things stood, the arc, where
  things stand, what the next session inherits;
- the **routing ledger** (cb:b572/b582) - one row per topic, states and pointers only;
- a **pointer to the render** (`threads/.sessions/<date>-<session>.md`) as the single
  raw-turn surface, in place of the embedded body.

This dissolves the tail-gap for the raw record rather than racing it. A pointer to a
continuously-updated file is never stale: the render keeps catching up each turn (and the
ride-along commit rewrites it), so by the time any reader dereferences the pointer it
resolves to the current render, close turn included. Nothing frozen means nothing to
overstate. The narrative section stays a synthesis a human or agent scopes honestly at
close; it never claims turn-by-turn completeness, so it carries no false-completeness risk.
This also realigns the thread document with the accepted cb:a518 tradeoff instead of
fighting it: the raw record is the live render, and "turns after `/end` are captured by the
render continuing to update" replaces "turns after `/end` are lost from the frozen body."

**The snag to surface.** This makes the committed `.sessions/` render load-bearing: it
becomes the only turn-by-turn surface the thread document offers, so the pointer must
durably resolve. That is the still-open repo-weight question in
[transcript-format](transcript-format.md). Today the render lane *is* committed inline (only
the raw jsonl is gitignored and punted, per the 2026-07-03 operator deferral), so the
pointer resolves now. But any future move that bounds repo weight by pruning or
externalizing renders (the LFS lean, or a render-side equivalent) would dangle the pointer.
So the render-pointer form cannot be adopted independently of transcript-format settling
that the render is permanently retained and in-repo-resolvable. The turn-separation fix
(option 1 done right) has no such dependency and can stand alone if the render-pointer form
is held.

## Open

- **Which structural fix.** Turn-separation (option 1, finalize in a later turn than the
  close) versus the render-pointer form (drop the frozen body). They are not exclusive: the
  render-pointer form removes the body whose staleness turn-separation was racing, so if it
  lands, turn-separation of the *body* is moot and only the narrative-synthesis ordering
  remains. Lean: render-pointer, because it fixes the class rather than the instance - but
  it is gated (below).
- **The transcript-format dependency.** The render-pointer form is gated on
  transcript-format confirming the committed render is durably retained and in-repo
  resolvable. Resolve that question first, or adopt turn-separation as the unblocked
  interim and upgrade later.
- **If a frozen body is retained** (render-pointer held or rejected): does `/end` compute
  and state the true last-covered turn in the provenance note (option 3), and how does it
  read that boundary - by diffing the render's last turn against the live session, or by
  stamping the render with a turn count the note can cite?
- **Narrative honesty independent of the body.** Even with the body gone, the narrative is
  written before the close turn completes. Does the narrative disclose that its own close is
  synthesized-forward (the writer describing the close they are about to perform), and is
  that disclosure a fixed line `/end` emits?
- **Skill shape.** `/transcript` + `/end`, a single reordered `/end`, or `/final` - this is
  the mechanism, decided after the turn-boundary question, not before it. Option 2 (`/final`
  successive) is ruled out on the merits: it does not interpose a turn boundary.
- **Interaction with retro-pairing (cb:b507).** The adopted pair-then-write ordering
  already writes the `document:` pointer before `/end` creates its target in the same close.
  A render-pointer thread document changes what "its target" is; confirm the pairing still
  lands cleanly when the body is a pointer rather than an embedded transcript.

## Mint manifest

The honesty invariant is firm regardless of which structural fix wins; the structural rows
are candidates gated on the Open calls above and on the transcript-format dependency. This
document gates the `/end` rewrite - nothing here is planted until the calls resolve.

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | A finalized thread document must not assert coverage it lacks: its provenance note states the exact last turn its embedded body covers and never claims that the close turn or any later turn is present when it is absent. A finalized body is a frozen snapshot bounded by the render's previous-completed-turn horizon, so any completeness claim is scoped to that horizon. | cb:a518, cb:b386, cb:b578 | document:beliefs/nursery/end-skill-redesign.md | - |
| prescription | A finalized thread document embeds no frozen transcript body. It carries the synthesized narrative section and routing ledger, plus a pointer to the continuously-rendered threads/.sessions/ transcript as the single raw-turn surface; the embedded turn-by-turn copy is retired as a cb:b386 stale duplicate. Adoption is gated on transcript-format confirming the render is durably retained and in-repo resolvable. | cb:b386, cb:b578, cb:b582 | document:beliefs/nursery/end-skill-redesign.md | - |
| prescription | If a finalized thread document retains a frozen transcript body, its finalization runs in a later turn than the session's substantive close, so the render has advanced to include the close turn; the finalizer's own turn is then the only omitted turn and carries no decision content. Same-turn successive finalization (a /final that runs the close and the finalize in one turn) does not satisfy this and is rejected. | cb:a518, cb:b578 | document:beliefs/nursery/end-skill-redesign.md | - |

## Thread excerpts (what grounds this)

**Operator (the round-trip spike that surfaced it):** "I'm wondering if this RoundTrip
Cycle is active at this time, and to what degree ... my description here reflects reality."
The spike found the top half of the cycle pending because `/end` had never run, which set
up the first `/end` close and its tail-gap.

**cb:a518, evidence 8 (the accepted tradeoff this builds on):** "the SessionEnd hook ...
was too much fragile machinery for ~1-2 closing turns of no decision content ... Turns
after it (the close, or work done after /end) are captured by re-running /end; the operator
accepted that trade." The render-pointer form generalizes that acceptance from re-running
`/end` to a live pointer that never needs re-running.

**The fold-chronicle provenance note (the overstatement, verbatim from the finalized
body):** "the close turn is summarized here, not transcribed - the receipts end at the
retro-pair exchange." The receipts end one turn before the retro-pair; the note names a
turn the body does not contain.

## Related

- [transcript-format](transcript-format.md) - the persistence pipeline this modifies; its
  open repo-weight/LFS question gates the render-pointer form, and its "render must not lag
  a turn" decision is the same cb:a518 tail-gap at the hook layer.
- cb:b578 - the single-artifact close this redesign amends; the prescription whose body is
  the thing overstating itself.
- cb:b572 / cb:b582 - the routing ledger, which survives the redesign unchanged as
  pointers-only synthesis.
- cb:b386 - the cached-digest antipattern the frozen-body copy instantiates.
- cb:a518 - the tail-gap history and the accepted no-decision-content tradeoff this works
  with rather than against.
- cb:b507 - retro-pairing and the pair-then-write ordering the redesign must keep legal.
- [vocabulary-read-surface](vocabulary-read-surface.md) - a sibling read-surface-hygiene
  matter from the same session; the caution against echoing retired registers applies to
  this document's own vocabulary.
