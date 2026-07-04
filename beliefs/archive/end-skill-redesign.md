---
type: concept
title: Redesign /end so a thread's finalized record cannot overstate its own completeness
description: Covers the cb:b518 tail-gap as it lands on the finalized thread document - /end writes the curated body during a turn whose render only reaches the previous completed turn, so the close turn is absent from the body while a provenance note asserts it is present. Analyzes the three operator-posed options against the finding that the decisive variable is turns, not skills. Chosen direction (operator, 2026-07-03): keep the self-contained embedded transcript body, run /end alone in its own turn so the render has caught up, warn on inline invocation, and keep a completeness-honesty backstop. The render-pointer alternative was considered and rejected on a duplication argument. Gates the /end rewrite.
tags: [nursery, threads, provenance, end-skill, observability]
status: active
timestamp: 2026-07-03
maturity: planted
minted: [cb:b583, cb:b584]
threads: [2026-07-02-fold-chronicle-into-threads, 2026-07-03-end-skill-round-trip]
---

# Redesign /end so a thread's finalized record cannot overstate its own completeness

> **Graduated 2026-07-03.** Planted as cb:b583 (turn-separation) and cb:b584 (honesty
> backstop), then moved to the archive shelf (beliefs/archive/, cb:b577). Historical record
> of a completed deliberation; the live rules are in the graph.

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
| prescription | `/end` runs alone, in its own turn, after the session's substantive close is complete; it is never invoked inline in a turn that also does close work. Run in a later turn, the render has advanced to include the close turn, so the finalized document's embedded transcript body contains it; the only omitted turn is the `/end` invocation turn, which carries no decision content and needs no disclosure. `/end` invoked inline emits a warning that the current turn will not be captured in the finalized body. Same-turn successive finalization (a `/final` running close and finalize in one turn) does not satisfy this and is rejected: a turn boundary is a separate exchange, not a second skill call. | cb:b518, cb:b578 | document:beliefs/archive/end-skill-redesign.md | cb:b583 |
| prescription | A finalized thread document's provenance note must not assert coverage the body lacks: it states the exact last turn the embedded body covers and never claims the close turn or any later turn is present when it is absent. This is the backstop that keeps the artifact truthful even when `/end` is run inline against a render frozen at the previous completed turn - the fold-chronicle overstatement is the failure it prevents. | cb:b518, cb:b386, cb:b578 | document:beliefs/archive/end-skill-redesign.md | cb:b584 |

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

## Thread excerpts - route-tagged log (route-tagging spec, retrofit)

> **Freeze backfill (2026-07-04).** This document is graduated and frozen; this log is a
> one-time backfill applied to make it the founding worked example of the route-tagging spec
> ([../nursery/route-tagging.md](../nursery/route-tagging.md)). Going forward the log is
> append-only at route-time and a frozen matter accepts no new blocks (the freeze rule the
> spec states). Generated mechanically from the `<routes ref="end-skill-redesign">` regions
> of the thread body, lifted whole - no trim - so its length is the honest cost of the
> no-editorial-selection decision. The hand-picked "what grounds this" section above is the
> pre-spec editorial form, kept for contrast.

### 2026-07-03-end-skill-round-trip (2026-07-03)

9 tagged region(s), lifted whole. Refs shown are the full ref-set of each region (this matter plus any it co-feeds).

**[`end-skill-redesign`]**

Investigate and author a proto-belief document in the composable-beliefs repo
proposing a redesign of the /end skill. Produce the document only; the actual
/end rewrite is gated on it, not part of this task.

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b518`)

/end writes the finalized thread document *during a turn*, but the Stop hook's
render only contains through the *previous completed* turn. So the turn that runs
/end (and any substantive close work done in it) and everything after are absent
from the finalized body - the cb:a518 tail-gap. Worse, /end can then assert a
completeness it does not have.

---

**[`end-skill-redesign`]**  (co-feeds: `transcript-format`)

OPTIONS TO ANALYZE (the operator posed the first three)
1. Split into /transcript + /end.
2. A /final skill that runs both successively.
3. Reorder events within /end.
Key analysis to test and record: the decisive variable is TURNS, not skills.
Option 2 (successive = same turn) does not close the gap. Option 3 fixes the
honesty of the provenance note but not the structural gap. Option 1 works ONLY
if finalization runs in a SEPARATE, LATER turn than the substantive close, so the
render has caught up and the body includes the close turn (the finalizer's own
turn is then the only gap, and it carries no decision content - the accepted
tradeoff).
Also evaluate a stronger proposal: stop embedding a frozen transcript body at all.
The hook already persists the render continuously; embedding a second, one-turn-
stale copy that can misdescribe itself is the cb:b386 duplication the framework
rejects elsewhere. Have the finalized doc carry only what it synthesizes -
narrative section + routing ledger + a pointer to the render for raw turns.
Snag to surface: this depends on the render being durably retained, which is

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b518`)

Excellent - the raw render confirms the tail-gap precisely. The `.sessions/692c6ff4.md` render includes one turn the finalized body lacks: "Proceed with the close in order" → the close response (raw lines 563-577), while the finalized body stops at "Add the line in the fold plan re: desk." Let me confirm the diff mechanically and read the mint-manifest format + graph-refounding doc as format templates.

Confirmed mechanically: the finalized body has 22 user turns (ending at "Add the line in the fold plan re: desk", line 631); the raw render has 23 (the extra being "Proceed with the close in order", line 563 → the close response). That one-turn boundary is the tail-gap exactly. And the finalized doc's provenance blockquote claims "the receipts end at the retro-pair exchange" - but the retro-pair ran in that missing 23rd turn, so the body actually stops one topic short of what it claims.

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b583`)

This is the fix that replaces the pointer, now that you've chosen the embedded body.

The tail-gap exists because **`/end` reads a render that is frozen at the previous completed turn.** When the hook renders, it renders *at the end of a turn*. So an `/end` running *inside* turn N only ever sees the render as it stood after turn N-1. The close turn (N) can't be in the body, because the render of turn N doesn't exist yet while turn N is still happening.

**Turn-separation just means: don't finalize in the same turn you do the close work.**

- Today (broken): you do the substantive close work **and** run `/end` in the *same* exchange (turn N). The render `/end` sees goes through N-1. The body misses turn N - the close itself. That's the fold-chronicle bug.
- Turn-separation (fixed): you do the close work in turn N. Then, as a **separate exchange** (turn N+1), you run `/end`. By N+1 the hook has already rendered turn N, so the embedded body now *includes* the close turn. The only turn still missing is N+1 itself - the finalization turn - and that turn contains nothing but "run /end," no decisions. Losing a no-decision turn is the tradeoff the house already accepted (cb:a518).

**Why a same-turn `/final` (the rejected option) doesn't work:** "successive" is still *one turn*. Two skills back-to-back inside turn N both read the render frozen at N-1. Only a real turn boundary - a separate user exchange - lets the render advance. That's the whole finding: the fix is a *turn boundary*, not a skill count.

**The honest catch to flag:** turn-separation is *procedural* - it depends on someone actually running `/end` as a follow-up turn rather than inline. That brushes against the cb:b386 "don't rely on remembering" concern. There's no way around it if you keep the embedded body: *some* turn is always the last one captured, and the finalizer's own no-decision turn is the least-bad one to lose. That's why row 1 (the honesty invariant) is the backstop: even when someone *does* finalize inline, the provenance note must truthfully say "body reaches turn N-1, close turn not included" rather than overstating. Row 1 makes the artifact honest always; row 3 makes it *complete* when the workflow is followed.

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b577`)

**4 - Q7 (cb:b577): the archive-shelf decision.** It's the open call for *where graduated proto-belief documents physically live once they're terminal (planted)*. The constraint is the operator's **invisibility requirement**: archived deliberation must not sit in the working hierarchy confusing fresh agents - so archive-in-place is ruled out. cb:b577's stated lean is **`beliefs/archive/` as a sibling outside `nursery/`**.

You're right that it's better to resolve now for the full lifecycle - here's why it matters and what it costs:

- **Why it's needed for the demo:** the complete arc is thread → proto-belief → mint manifest → beliefs → code → back. The *final* rung is the proto-belief document graduating (historicize + archive) once its rows are planted. Without Q7, `end-skill-redesign` can mint its beliefs but has nowhere to graduate to, so the lifecycle demo would stop one rung short.
- **My recommendation:** resolve it as **`beliefs/archive/`** (sibling outside the nursery bundle). It's the cleanest against the invisibility requirement and needs *zero tooling change* - `okf.manifest beliefs/nursery` only scans `nursery/`, so anything in `beliefs/archive/` is invisible to the live nursery surface automatically. Graduated docs move there, date-stamped with terminal maturity + minted ids + forward links, and a `cb.repoint` swings their `document:` citations to the new path.
- **What resolving it entails this session:** decide the shelf (your call), discharge cb:b577 through the sanctioned close, then graduate `end-skill-redesign` into it as the capstone - repointing the two new beliefs' `document:` grounding to `beliefs/archive/end-skill-redesign.md` and dropping it from the live nursery index. `mint-manifest-rename` stays live (execution deferred), so it does *not* graduate.

One honest caveat on graduating `end-skill-redesign` immediately: it makes the thread's routing-ledger link and the beliefs' grounding point into `beliefs/archive/` rather than the live nursery. That's *correct* lifecycle behavior, but it means the canonical example's centerpiece document lives in the archive by the time the thread doc is written. If you'd rather keep it visibly in the nursery for now and demonstrate graduation as a distinct later step, that's the one reason to hold rung-final.

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b583 cb:b584 skills/end/SKILL.md docs/operations.md`)

**Turn 1 is complete and pushed.** The full substantive close ran; here's what landed on the branch, all verified green (407 tests, schema 20/20, verify.commits, CLAUDE.md, manifest):

| Commit | What |
|---|---|
| `b15d909` | `/end` refactored (turn-separation rule, standing caution, honesty note) + `operations.md`; `a518→b518` id fix |
| `878988e` | Minted **cb:b583** (turn-separation) and **cb:b584** (honesty backstop) through the write flow - preflight clean, no supersession |
| `a77adba` | Established `beliefs/archive/` shelf, resolving **Q7** |
| `bb537d8` | Discharged **cb:b577** off the desk (materialize-then-close) |
| `6c393a5` | **Graduated** `end-skill-redesign` to the archive shelf |
| `767ba73` | Retro-paired cb:b583/b584 (cb:b507) with doc + thread pointers |

The round trip is now built end to end: thread → proto-belief document → mint manifest (`belief candidates`) → **beliefs in the graph** (cb:b583/b584) → the `/end` skill + `operations.md` implementing them → `Belief:` trailers linking commits back → retro-pair pointers closing the loop to the thread → graduation to the archive shelf.

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b584`)

Done. The `/end` close ran alone, and the round trip is closed end to end - **the first canonical example of the full pipeline under the fixed `/end`.**

**The close, verified**

- **Thread document** `2026-07-03-end-skill-round-trip.md` written and registered (index + manifest, count 34), with frontmatter, the operator-facing narrative, an eleven-strand routing ledger, and the embedded transcript.
- **It is honest about its own coverage** - the exact thing that failed before. The body runs complete through the confirmation turn (the last substantive exchange); only this contentless `/end` turn is omitted, and the capture-provenance note says precisely that (cb:b584). No overstatement.
- **Every rung resolves:** beliefs → thread pointer resolves to a real file, beliefs → graduated proto-belief doc resolves, `verify.commits` green (Belief: trailers both directions), schema 20/20.

**What this session produced**

The complete arc, now traversable in both directions:

**thread** (`2026-07-03-end-skill-round-trip`) → **proto-belief document** (`end-skill-redesign`) → **belief candidates** (its mint manifest) → **graph** (cb:b583 turn-separation, cb:b584 honesty note) → **code** (the `/end` skill + `docs/operations.md` implementing them) → **`Belief:` trailers** linking the commits → **retro-pair pointers** back to the thread → **graduation** of the source document to `beliefs/archive/`.

---

**[`end-skill-redesign`]**  (co-feeds: `cb:b583 cb:b584 docs/operations.md`)

Audit complete. Here's the honest result - I checked each claim against the actual state rather than trusting my narration.

**Verified TRUE**

| Claim | Verified |
|---|---|
| **cb:b583** minted - prescription, active, deps `cb:b518, cb:b578`, turn-separation claim, 2 `document:` evidence entries (retro-pair) | ✓ |
| **cb:b584** minted - prescription, active, deps `cb:b518, cb:b386, cb:b578`, 2 `document:` evidence | ✓ |
| **cb:b577 (Q7) discharged** - materialized 2026-07-03, off the desk (unlinked query returns 0), t0027 `done` | ✓ |
| **beliefs/archive/** shelf exists (README + graduated doc) | ✓ |
| **end-skill-redesign graduated** - absent from nursery, `maturity: planted`, `minted: [cb:b583, cb:b584]`, graduation blockquote, grounding cells repointed to archive path, this thread back-linked | ✓ |
| **/end skill refactored** - symlink resolves to `skills/end/SKILL.md`, turn-separation section, standing caution, cb:b584 honesty note, no residual "seeds/focuses" | ✓ |
| **Thread doc** - 11 routing rows (I said "eleven strands"), body ends at the confirmation turn, the `/end` command turn correctly omitted | ✓ |
| **Git** - local HEAD == `origin` (in sync, `56aa8ad`); working tree clean except the ride-along render | ✓ |
| **Verifiers** - 407 tests, schema 20/20, `verify.commits` all 3 PASS | ✓ |

Two nuances worth stating precisely, both correct-as-is:
- **cb:b577 shows `Status: active`** - that is the *right* discharged state. Status and materialization are orthogonal (a379); a discharged discrete prescription stays `active` with `materialized` set. It is off the desk.
- **The thread body is responses-only** (the hook strips tool calls/reasoning), so it carries my summary account of the close, not the raw mint commands - which the provenance note states accurately. No overstatement.

**One real finding (my narration was slightly too broad)**

I claimed an "a518→b518 id fix." That's **fully true for `end-skill-redesign.md`** (8 occurrences, the doc you flagged) - but **`docs/operations.md` is a pre-migration document carrying 14 legacy `a`-ids** (a108, a112, a165, a386, a460-a462, a467, a497, **a518**, a537, a540, a543, a548). My edits there *added* canonical `b`-ids (b518/b583/b584) but did **not** sweep the file's existing legacy ids, so line 77 still reads `cb:a518/a540` and the doc now visibly mixes forms.

This is **not a bug** - legacy `a`-ids resolve via the cb:b566 alias, and the mixed state predates my work (fold-chronicle had already added b-ids to that same section). But my summary implied more than I did: I only used `b`-form in new prose; I didn't clean the doc's legacy ids.

**Your call:** I can sweep all 14 legacy `a`-ids in `operations.md` to canonical `b`-form (mechanical, alias-safe, removes the read-surface leak entirely) - a clean separate cleanup. Or leave it, since it's a pre-migration doc and the aliases resolve. I'd lean toward the sweep since read-surface hygiene is this whole session's theme, but I didn't want to expand scope onto a whole doc without asking.

Everything else you were told is confirmed. Ready for your `/end` re-run whenever - it'll capture this audit turn into the thread and regenerate cleanly.

Render pushed. The audit stands: everything I told you is confirmed true, with the one honest correction that `docs/operations.md` retains its pre-existing legacy `a`-ids (my "id fix" was fully done in `end-skill-redesign.md` but only partial in `operations.md`).

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
