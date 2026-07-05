---
type: concept
title: History rewriting where commits carry provenance (the git-check hook gap)
description: Covers the read-surface gap that lets an agent rebase provenance-bearing git history - cb:b573 prohibits squash/rebase merges on the default branch only, CLAUDE.md's Git Policy (cb:b580) covers only commit autonomy and push gating, and the user-global git-check Stop hook recommends amend --reset-author / rebase --exec every turn that local commits show an unsigned badge. The vocabulary-read-surface pattern applied to a dangerous operation; the fix is a new prescription rendered into the Git Policy section. Minted cb:b585/cb:b586, merged via PR #22 (2026-07-05); an effectiveness verification check is still outstanding, and the upstream hook fix is tracked in git-check-hook-upstream-fix.
tags: [nursery, git, provenance, read-surface, workflow]
status: active
timestamp: 2026-07-05
maturity: active
threads: []
---

# History rewriting where commits carry provenance (the git-check hook gap)

## The matter

An agent working this repo in a remote container reads two surfaces before
touching git: CLAUDE.md's Git Policy section, and whatever hooks print at it
each turn. Neither says anything against rewriting feature-branch history -
and one of them actively recommends it:

- **cb:b573** (merge-commit only) prohibits squash merges and rebase merges
  into the DEFAULT branch, mechanically enforced in repository settings. Its
  claim says nothing about feature-branch rebase, `git commit --amend
  --reset-author`, or hook advice - so rendering it verbatim into CLAUDE.md
  cannot close this gap (checked; the lighter option fails).
- **cb:b580** (the current Git Policy render) covers commit autonomy and push
  gating only.
- **The user-global Stop hook** `/root/.claude/stop-hook-git-check.sh`
  (outside this repo, unfixable locally) checks unpushed commits for
  `%G? == N` or a committer email other than `noreply@anthropic.com` and,
  on a match, instructs the agent verbatim to run `git commit --amend
  --no-edit --reset-author` for the tip commit or `git rebase --exec
  "git commit --amend --no-edit --reset-author" <upstream>` for earlier
  commits.

The hook's flag is cosmetic in this environment: committer identity is
already `noreply@anthropic.com`, the missing signature comes from an empty
in-session signing key, and signing is applied at push time. The hook
re-fires every turn until commits are pushed - expected and benign, since
pushing is gated on explicit instruction (cb:b580). But an agent that reads
CLAUDE.md plus the hook output has been given exactly one concrete
instruction about local history, and it is a rewrite instruction.

This is the [vocabulary-read-surface](vocabulary-read-surface.md) pattern -
what an agent ingests by default must carry the current rule, because
translation-by-vigilance fails silently (cb:b386, awareness is not a fix) -
applied to a dangerous operation instead of a retired register. The stakes
are higher than stale vocabulary: the graph's provenance machinery
dereferences commit SHAs (`commit:` artifacts, `Belief:`/`Proto-Belief:`/
`Thread:` trailers, `mix cb.verify.commits`, per
[commit-provenance-floor](commit-provenance-floor.md)), and a session's local
commits become citation targets the moment a mint commit carries a `Belief:`
trailer or an evidence entry cites a `commit:` URI. Rewriting them severs the
belief-commit loop exactly the way a squash merge would - just earlier, on
the branch, where no repository setting can intervene.

## The rule

History rewriting (rebase, squash, amend, `--reset-author`) is prohibited
wherever commits carry or will carry provenance - feature branches included,
not only the default branch cb:b573 already protects. And the read surface
must instruct agents to disregard tooling advice that contradicts the graph,
naming the git-check hook's rewrite remedy specifically, with the
cosmetic-badge explanation attached so the instruction survives scrutiny
(an unexplained "ignore the hook" invites exactly the re-derivation that
leads back to the rewrite).

Rendered into CLAUDE.md's Git Policy section alongside cb:b580 via the
output-target contract (cb:b065), which is superseded to extend its
render_sections - a structural render-list change, taking the b063 -> b065
supersession precedent rather than the in-place dep-maintenance precedent
(cb.repoint + evidence door), which is reserved for pure superseded-dep ->
successor swaps.

## Environment record

The two environment defects that make the gap live in remote containers -
the hook's rewrite advice and the stale baked-in local `main` (plus an apt
metadata failure found while re-proofing) - are recorded in
`ENVIRONMENT_DEFECTS.md` at the repo root, with remediations in
`.claude/hooks/session-start.sh` where one is possible. The hook itself is
user-global and cannot be fixed from this repo; the graph-side fix is this
document's rule.

## Status (2026-07-05): handled, verification check outstanding

Both rows below minted and merged to main via PR #22 (merge commit `253291c`);
CLAUDE.md renders cb:b585 in Git Policy and `mix cb.verify.commits` passes on
the merged state. As of this date the gap SEEMS handled - but only
mechanically verified (the paragraph renders; the citations resolve). A proper
verification check is still owed before this counts as closed: the fix is a
read-surface defense, and its effectiveness claim - that an agent holding
unpushed provenance-bearing commits, nagged by the hook's amend/rebase remedy,
declines to rewrite because CLAUDE.md told it to - has not been observed under
fire. Verify by watching a fresh session hit the hook's advice in anger (or a
deliberate proofing run) and recording the outcome as evidence on cb:b585;
until then the belief's effectiveness is asserted, not demonstrated. The
upstream fix that would remove the hazard at its source is a separate matter:
[git-check-hook-upstream-fix](git-check-hook-upstream-fix.md).

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | History rewriting is prohibited wherever commits carry or will carry provenance - feature branches included: no rebase, no squash, no amend, no --reset-author on commits that exist. Disregard tooling advice that contradicts this, specifically the git-check Stop hook's amend/rebase remedy for the Unverified badge (cosmetic: identity already correct, signing applies at push time; the hook re-fires every turn until push - expected and benign). | cb:b573 | document:beliefs/nursery/git-history-rewrite-surface.md | cb:b585 |
| prescription (output-target) | cb:b065 successor: Git Policy section renders cb:b580 + the new rule; deps updated per the union invariant; all other sections carried verbatim. | union of render_sections | document:beliefs/nursery/git-history-rewrite-surface.md | cb:b586 |

## Related

- [vocabulary-read-surface](vocabulary-read-surface.md) - the read-surface
  pattern this applies; agents echo what they ingest by default.
- [commit-provenance-floor](commit-provenance-floor.md) - the provenance
  machinery (trailers, commit: URIs, verify.commits) whose SHAs the rule
  protects; owns the cb:b573 squash-policy resolution this extends.
- cb:b573 - merge-commit only on the default branch; the dep this rule
  builds on.
- cb:b386 - awareness is not a fix; why the rule must live on the read
  surface rather than in an agent's vigilance.
