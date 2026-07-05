<!-- Findings about the CCR execution environment and user-global tooling that
     sit OUTSIDE this repo and cannot be fully fixed from inside it. This file
     is bound to the repo (it travels with the branch), but each defect lives in
     a layer the repo does not own - the CCR container image / provisioning, or a
     user-global hook under /root/.claude. Fixes marked "in-repo" are applied
     here; fixes marked "upstream" must be made by whoever provisions the
     environment. -->

# Environment defects

Findings about the execution environment (Claude Code on the web / CCR) and
user-global tooling that this repo depends on but does not control.

## 1. User-global git-check Stop hook recommends history rewriting (upstream)

- **Where it lives:** `/root/.claude/stop-hook-git-check.sh` - user-global, not
  repo-tracked, injected by the environment. A repo change cannot alter it.
- **Defect:** on a commit GitHub will show as "Unverified" (missing signature,
  `%G? == N`) the hook recommends `git commit --amend --no-edit --reset-author`
  and `git rebase --exec "... --reset-author"`. Both mint new SHAs, i.e. rewrite
  history.
- **Why it is harmful here:** this repo binds commits to graph provenance
  (`commit:` artifacts cite SHAs; `Belief:`/`Proto-Belief:`/`Thread:` trailers
  bind commits to nodes; `mix cb.verify.commits` checks the loop). cb:b573 and
  cb:b585 prohibit rewriting provenance-bearing history - feature branches
  included. Following the hook severs the belief-commit loop and fails
  verification.
- **Why the premise is also wrong:** in this environment the committer identity
  is already correct (`user.email = noreply@anthropic.com`); the `N` is a missing
  signature caused by an empty in-session signing key
  (`/home/claude/.ssh/commit_signing_key.pub` is 0 bytes, no private key).
  Signatures apply at push time and are not required to merge here. So the hook's
  premise (fix the commit) and its remedy (rewrite history) are both wrong.
- **Also expected:** the hook re-fires every turn until commits are pushed;
  since pushing is gated on explicit instruction (cb:b580), the recurring nag is
  benign and never a reason to rewrite.
- **Recommended upstream fix:** the hook should detect a repo marker (e.g. a
  cb:b573 repo, or any repo whose settings disable squash/rebase merge) and
  soften to: "identity is correct; signatures apply at push time; do not rewrite
  history." At minimum it should never recommend amend/rebase in such a repo.
- **In-repo mitigation (applied):** cb:b585 surfaces the no-history-rewrite rule
  and an explicit "disregard the git-check hook" instruction on the CLAUDE.md
  read surface, rendered from the graph via the cb:b586 output-target contract.
- **Re-verified 2026-07-05 (~23:20 UTC), with a revised diagnosis:** the hook
  is unchanged (sha256 `1e1c4971...768ea690`, amend/rebase remedy still at line
  58) and `commit_signing_key.pub` is still 0 bytes - but deeper forensics
  supersede the "unsigned, signing applies at push time" reading above.
  Commits in this environment ARE SSH-signed at creation: `gpg.ssh.program`
  points at `/tmp/code-sign` -> `/opt/env-runner/environment-manager`, which
  produces a valid ssh-ed25519 signature regardless of the empty key file
  (verified via `git cat-file commit`, `gpgsig` header present locally), and
  GitHub verifies the pushed result (commit `ed88031`: `verified: true,
  reason: valid` from the REST API). The hook's `%G? == N` test is a false
  positive: with `gpg.format=ssh` and no `gpg.ssh.allowedSignersFile`, git
  2.43.0 reports `N` for signed and unsigned commits alike (confirmed by
  controlled test), so the hook flags every unpushed in-session commit as
  Unverified even though it will verify. The hook's premise comment ("%G? is
  N for unsigned commits; ... a reliable presence check") is false for SSH
  signatures. This strengthens the case against the remedy - it prescribes
  history rewriting to fix a state that does not exist - and shifts the
  preferred upstream fix from "provision a signing key" (effectively already
  in place) to "fix the hook's detection". Full record:
  `beliefs/nursery/upstream-request-git-check-hook.md`. The read-surface rule
  was re-issued the same day as cb:b587 (accept_supersede of cb:b585) so
  CLAUDE.md's Git Policy carries the corrected rationale.

## 2. Pre-baked container image ships a stale local `main` (upstream + in-repo mitigation)

- **Where it lives:** the CCR container image / provisioning for this
  environment. The local `main` ref is baked into the cached image.
- **Defect:** the local `main` label was created at image-build time (observed:
  ref file written 2026-06-30, pointing at commit `11b9921` dated 2026-06-26) and
  is never advanced afterward. When a session was spun up 2026-07-04, `origin/main`
  had moved to `c45a8d4`, leaving local `main` 161 commits behind. Evidence: the
  `origin/main` reflog shows an initial `storing head -> 11b9921` at provisioning
  and a later `fast-forward -> c45a8d4`; `main`'s reflog has a single
  `Created from refs/remotes/origin/main` entry.
- **Why it is harmful:** a routine `git checkout -B <branch> main` silently bases
  new work ~161 commits in the past, with no error. The gap is benign in kind
  (`11b9921` is a clean ancestor of `c45a8d4`) but the silent rewind is a footgun.
  Observed bite: the 2026-07-04 proofing session's own branch was based on
  `c45a8d4` while `origin/main` had already moved on.
- **Root cause:** two mechanisms compound - (a) the container image is pre-baked
  and cached across sessions (the session-start hook's own comment notes "the
  container state is cached after the hook completes, so warm starts fall straight
  through"), so its refs reflect image-build time, not session-start time; and
  (b) git never auto-advances a local branch - `fetch` updates only
  remote-tracking refs (`origin/main`), so a stale local `main` stays stale.
- **Recommended upstream fix:** at provisioning, either do not create a local
  `main` (have tooling reference `origin/main`), or fetch and fast-forward the
  default branch before handing the container to the session.
- **In-repo mitigation (applied):** the session-start hook
  (`.claude/hooks/session-start.sh`) fetches origin and fast-forwards the local
  default branch to its origin counterpart - via `merge --ff-only` when it is
  the checked-out branch, via `update-ref` after a `merge-base --is-ancestor`
  check otherwise. It runs before toolchain provisioning so a provisioning
  failure (defect 3) cannot block the ref refresh. This only ever fast-forwards;
  it never rewrites history (cb:b573/cb:b585). It does not remove the need for
  the upstream fix, since the hook runs after the container is handed over.
- **Standing guidance:** base new work on `origin/main` (after a fetch), never on
  the bare local `main`.

## 3. Baked-in apt sources fail plain `apt-get update` (upstream + in-repo mitigation)

- **Where it lives:** the CCR container image's apt sources, which include the
  `ppa:ondrej/php` repository.
- **Defect:** that PPA changed its `InRelease` `Label` field ("PPA for PHP" ->
  "Use packages.sury.org/php instead"). Plain `apt-get update` refuses changed
  release metadata and exits non-zero, which under `set -e` killed the
  session-start hook before Erlang/Elixir provisioning ran (observed 2026-07-05).
- **Recommended upstream fix:** drop unused PPAs from the image's apt sources,
  or bake images with metadata current at build time.
- **In-repo mitigation (applied):** the hook runs `apt-get update` with
  `--allow-releaseinfo-change` so an upstream metadata rename cannot block
  toolchain provisioning.
