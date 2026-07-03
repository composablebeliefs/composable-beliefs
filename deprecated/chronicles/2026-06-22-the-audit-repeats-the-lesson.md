# 2026-06-22 — The audit repeats the lesson

**Span:** the closing beat of the okf-fold arc — auditing the executed fold against
`plan:okf-fold`/`cb:a546`. Continues [the tooling takes the name](2026-06-22-the-tooling-takes-the-name.md).
**Register:** chronicle (cb:a520); receipts in `cb:a547`/`cb:a548`, `agent-behavior:a165`
(specimen 6), and commits 3814e80 / 0d91e54 / c90552b / dotfiles cf0e870.

## Where things stood

The fold had landed — `knowledge` decommissioned, `okf/` standing inside composable-beliefs,
the `okfx:` graph, tooling renamed to `mix okf.*`, `okf/CLAUDE.md` compiling from `okfx:c002`.
The operator asked for an audit against expectations.

## The arc

The first pass read worse than the truth. The audit flagged five residuals; on inspection
three were already handled by the fold and I had simply not looked at the current state. The
dangling `cb:` pointers were already repointed to `okf/`; `okfx:a004` was materialized and its
todo closed (I had queried `list lifecycle:discrete` instead of the `unlinked` desk); the
stale-path cleanup was done. Worse, acting on those false flags I appended four redundant
duplicate pointers and minted a convention (`cb:a547`) whose worked-example was factually
wrong, and pushed both before catching it.

The irony is the point. The session whose headline finding was `agent-behavior:a165` — the
agent asserts a defect from its memory or a partial query instead of reading the current full
state — committed that exact error twice *while auditing for it*. That is the strongest
evidence yet that a prose reminder is not enough: I had the discipline in context and still
ran a stale check. So the structural fix finally landed: a SessionStart hook
(`~/.claude/hooks/cb-desk.sh`, dotfiles) that injects the live `unlinked` desk into context
whenever a session opens in the amieval tree — the half the fold had only done in prose.

`cb:a547` survived the correction, repurposed honestly: the rule (repoint inbound
`document:`/`code:` artifacts when a repo moves, since the enum has no rebind op) is sound and
the fold followed it; the audit slip became the cautionary half of the example. Two genuine
issues did surface and got fixed: the `/end` skill still pointed at the deleted
`amieval/knowledge` path (repointed to `okf/`), and `okf/CLAUDE.md`'s compile was ungated in
CI. The CI line could not be pushed — the session's OAuth lacks GitHub `workflow` scope — so
it is parked as `cb:a548` with the one-line change recorded.

## Where things stand

The fold is sound and was executed more cleanly than the first audit pass credited; the only
real gap was the missing structural hook, now closed. `agent-behavior:a165` carries six
specimens. The graph and dotfiles are pushed.

## Postscript: the fourth over-flag, and a new door

`cb:a548` turned out to be moot, not deferred. `okf/CLAUDE.md` is already gated -
`generated_claude_md_test.exs` checks every CLAUDE.md target (framework and okf) and `mix
test` runs in CI. So the CI line I could not push was never needed, and the task change I
started building was solving nothing. That was the third over-flag of the same audit, and it
came minutes after I had written this very chronicle and a blog draft about the pattern.
Acknowledgment in writing did not buy a single Tuesday of immunity.

Retracting the moot `a548` then surfaced a real gap: the write flow had no front door for
retraction. The `retract` mutation existed in `CB.Belief.Mutation`, but only `cb.evidence` and
`cb.repoint` applied mutations, and supersede was reachable only through adjudication. So
`mix cb.retract` now exists (mirroring `cb.repoint`: a `retract` mutation through `apply_batch`
+ `Store.write`, date and reason per c053, dry-run by default, tested), and `a548` was retracted
through it. The judgment on the gap was: build it, do not file a directive - a directive is for
work too large to do inline, and this was 150 lines against an existing pattern. Standalone
supersede was left alone; routing it through adjudication is arguably intended.

## Where things stand

The okf-fold arc is closed. The genuine deliverables, separated from the noise: the SessionStart
hook (structural surfacing), the `/end` repoint off the deleted `knowledge` path, the `cb:a547`
repoint convention, and now `mix cb.retract`. The over-flags - dangling pointers, a004 discharge,
stale paths, okf gating - were all non-issues the fold had already handled. `cb:a533` carries a
note that the CLAUDE.md write-surface line now undercounts (repoint and retract are unlisted),
to fold in on its next supersession. The desk is clean of this session's phantoms.
