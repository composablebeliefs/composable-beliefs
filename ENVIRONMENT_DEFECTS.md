# Environment defects

Defects in the remote execution environment (Claude Code on the web containers)
that affect work in this repository. Recorded so sessions stop rediscovering
them; remediations live in `.claude/hooks/session-start.sh` where one exists.

## 1. The user-global git-check Stop hook advises history rewriting

`/root/.claude/stop-hook-git-check.sh` (user-global, outside this repo) checks
local commits for `%G? == N` (no signature) or a committer email other than
`noreply@anthropic.com`, and when it matches it instructs the agent to run
`git commit --amend --no-edit --reset-author` for the tip commit or
`git rebase --exec "git commit --amend --no-edit --reset-author" <upstream>`
for earlier commits.

In this repository that advice must be disregarded, always:

- The flag is cosmetic here. Committer identity is already
  `noreply@anthropic.com`; the missing signature comes from an empty
  in-session signing key, and signing is applied at push time. Nothing is
  wrong with the commits.
- Amend and rebase rewrite commit SHAs. This graph's provenance machinery
  dereferences SHAs: `commit:` artifacts, `Belief:`/`Proto-Belief:`/`Thread:`
  trailers, and `mix cb.verify.commits`. Rewriting provenance-bearing history
  to silence a cosmetic badge severs the belief-commit loop (cb:b573 records
  the default-branch case; the graph's Git Policy extends it to every branch
  whose commits carry provenance).
- The hook re-fires EVERY TURN until commits are pushed. That is expected and
  benign; pushing is gated on explicit instruction, so the nag persists by
  design. Do not amend, rebase, or otherwise rewrite to quiet it.

No local remediation is possible (the hook is user-global, outside the repo);
the read-surface fix is the Git Policy rendered into CLAUDE.md from the graph.

## 2. Stale baked-in local `main`

The container image can bake in a clone whose local `main` ref is days behind
`origin/main`. A session that bases work on bare local `main` builds on stale
history and produces divergent branches.

Rule: never base work on bare local `main`; fetch first and branch from
`origin/main`.

Remediation: `.claude/hooks/session-start.sh` fetches origin at session start
and fast-forwards local `main` to `origin/main` when that is a pure
fast-forward.

## 3. `apt-get update` fails on the ondrej/php PPA label change

The baked-in apt sources include the `ppa:ondrej/php` repository, whose
`InRelease` metadata changed its `Label` field ("PPA for PHP" ->
"Use packages.sury.org/php instead"). Plain `apt-get update` refuses the
changed metadata and exits non-zero, which under `set -e` killed the
session-start hook before Erlang/Elixir provisioning ran (observed
2026-07-05).

Remediation: the hook runs `apt-get update` with
`--allow-releaseinfo-change` so an upstream metadata rename cannot block
toolchain provisioning.
