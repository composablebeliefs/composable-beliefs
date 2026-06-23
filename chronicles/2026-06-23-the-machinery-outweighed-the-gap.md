# 2026-06-23 — The machinery outweighed the gap

**Span:** the tail of the okf-fold close - building, then removing, a transcript
finalizer. Continues [the audit repeats the lesson](2026-06-22-the-audit-repeats-the-lesson.md).
**Register:** chronicle (cb:a520); receipts in `cb:a518` (the reversal), `agent-behavior:a408`
(over-structuring) and `a108` (destructive test), commits `952c302` / `eee5641`.

## Where things stood

`/end` copies the verbatim session log into the repo. But the copy runs mid-close, so it
under-captures the session's own closing turns - the report, the commit, any work done after
`/end`. The operator noticed the persisted log was a couple percent short and asked the obvious
question: shouldn't the copy be the last thing ordered?

## The arc

It can't be truly last - the agent can't copy turns that come after its own copy. So the fix
went structural: defer the copy to the end of `/end`, and add a SessionEnd hook that re-copies
the complete log at true session end, reading a marker `/end` drops. Then the hook needs to not
fire on resume, and to survive crashes, so a SessionStart recovery sweep was added to finalize
orphaned markers. Then recovery would clobber a concurrent live session's log, so a mtime guard
was added. Four moving parts to capture one or two closing turns.

The machinery bit back twice in an hour. The recovery had a concurrency bug - it treated any
non-current marker as an orphan, including live sessions the operator runs in parallel. And the
test for it ran against the real pending directory, sweeping this very session's marker and
pushing a stray finalize commit to the live repo - a destructive operation whose precondition
(an isolated environment) did not hold (`agent-behavior:a108`).

The operator cut through it: "are you saying you can remove the need for the hook completely?"
Nearly. A snapshot taken as late as possible inside `/end` captures everything except the literal
closing exchange, which carries no decision content. So the whole apparatus came out - hook,
marker, recovery, guard - and the model is now one line: `/end` copies the transcript last, and
if you keep working you run `/end` again. The reliable, verifiable in-session copy was the answer
all along; the structure was gold-plating (`agent-behavior:a408`).

## Where things stand

No SessionEnd hook. `/end` step 7 does the late copy; `docs/operations.md` and the SKILL.md say
so. The SessionStart desk hook stays - that one earns its keep, surfacing the live desk so a
fresh agent doesn't have to remember to query. The two new agent-behavior specimens (`a108`
destructive-test, `a408` over-structuring) join the `a165` pair from the audit: four agent
self-corrections from one session, all structural records rather than chat.

## What the next session inherits

A simpler persistence model and a sharper prior: structure is not automatically better than a
small accepted limitation - weigh the failure surface it adds against the gap it closes
(`a408`). The desk (`mix bs list unlinked tag:lifecycle:discrete`) carries the pre-existing
backlog; nothing from this arc is left open.
