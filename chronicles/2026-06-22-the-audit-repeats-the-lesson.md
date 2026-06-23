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

## What the next session inherits

`cb:a548` on the desk: add `mix cb.generate.claude_md --check --beliefs okf/beliefs.json` to
`.github/workflows/composable-beliefs.yml` (needs a `workflow`-scoped push). Otherwise the
okf-fold arc is closed. The SessionStart hook should now surface this and the rest of the desk
automatically — the next session is the first test of whether the structural fix holds.
