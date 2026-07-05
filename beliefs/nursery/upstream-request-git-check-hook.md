---
type: concept
title: Upstream request - CCR git-check Stop hook (paste-ready)
description: The paste-ready upstream request for the CCR git-check Stop hook defect - a false Unverified detection (%G? misreads SSH-signed commits when no allowedSignersFile is configured) coupled to a history-rewrite remedy. Prescriptive proto-belief, companion to git-check-hook-upstream-fix; carries the 2026-07-05 revised forensics (commits are signed at creation by the environment helper and verify on GitHub).
tags: [nursery, git, provenance, environment, upstream]
status: active
timestamp: 2026-07-05
maturity: active
---

# Upstream request: CCR git-check Stop hook - false "Unverified" detection and history-rewrite remedy

A prescriptive proto-belief: the request itself, drafted to be filed verbatim
in whatever tracker the delivery channel turns out to be. Target: whoever
provisions the Claude Code on the web (CCR) container environment - the
user-global `/root/.claude` layer and the `/opt/env-runner/environment-manager`
signing helper. The deliberation about the fix lives in
[git-check-hook-upstream-fix](git-check-hook-upstream-fix.md); the condensed
forensic record lives at `ENVIRONMENT_DEFECTS.md` (defect 1). Everything below
the rule is the paste payload.

---

## Summary

The user-global Stop hook `/root/.claude/stop-hook-git-check.sh` flags
in-session commits as "Unverified" and instructs the agent to fix them with
`git commit --amend --no-edit --reset-author` / `git rebase --exec ...`.
Both halves are wrong:

1. **The detection is a false positive.** Commits in this environment are
   already SSH-signed at creation and GitHub verifies them
   (`verification.verified: true, reason: valid`). The hook reads
   `%G? == N` as "no signature", but with `gpg.format=ssh` and no
   `gpg.ssh.allowedSignersFile` configured, git reports `N` for signed and
   unsigned commits alike - so the hook fires on every unpushed in-session
   commit, flagging commits that will show as Verified.
2. **The remedy rewrites history.** Amend and rebase mint new SHAs. Agents
   treat Stop-hook output as the environment's own voice and follow it
   mechanically. In any repository whose commits are cited by content
   address - `commit:` artifacts, commit-trailer conventions, SHA-dereferencing
   verification tooling - the advice severs the citation loop. This repository
   (composablebeliefs/composable-beliefs) is such a repo and had to ship a
   standing "disregard this hook's remedy" instruction on its agent read
   surface (cb:b585) as a defense.

The advice is not merely risky, it is useless on its own terms: the flagged
state does not exist (the commit is signed and verifies), and even where a
signature were genuinely missing, `--reset-author` addresses identity, which
is already correct (`noreply@anthropic.com`).

## Environment forensics (re-verified 2026-07-05, ~23:20 UTC)

Container: CCR session on branch `claude/git-check-hook-upstream-xa2q1r`,
repo composablebeliefs/composable-beliefs, git 2.43.0.

- `/root/.claude/stop-hook-git-check.sh` present, sha256
  `1e1c49718621d862047df01ded139d0d0efc5142c2f6db08a01ad853768ea690`.
  The remedy text (line 58), verbatim:

  > Please run 'git config user.email noreply@anthropic.com && git config
  > user.name Claude', then 'git commit --amend --no-edit --reset-author'
  > for the tip commit, or 'git rebase --exec "git commit --amend --no-edit
  > --reset-author" $upstream' for earlier commits, then push.

- Signing configuration (git global): `commit.gpgsign=true`,
  `gpg.format=ssh`, `gpg.ssh.program=/tmp/code-sign` (symlink to
  `/opt/env-runner/environment-manager`),
  `user.signingkey=/home/claude/.ssh/commit_signing_key.pub`.
- `/home/claude/.ssh/commit_signing_key.pub` is 0 bytes and no private key
  file exists - yet signing works: the environment-manager binary produces a
  valid ssh-ed25519 signature regardless. The empty pubkey file is a red
  herring that misled earlier forensics (which concluded "unsigned, signing
  applies at push time" - superseded by the observations below).
- Local commit objects carry `gpgsig -----BEGIN SSH SIGNATURE-----` headers
  at creation (verified via `git cat-file commit`), before any push.
- GitHub verifies them: commit `ed88031` (pushed 2026-07-05) returns
  `verification: {verified: true, reason: "valid", verified_at:
  "2026-07-05T23:09:30Z"}` from the REST API.
- Controlled test (git 2.43.0, fresh repo, no `gpg.ssh.allowedSignersFile`):
  an unsigned commit and a commit signed via `/tmp/code-sign` **both** report
  `%G? == N`, alongside `error: gpg.ssh.allowedSignersFile needs to be
  configured and exist for ssh signature verification`. The hook's own
  comment - "%G? is N for unsigned commits; signed-but-locally-unverifiable
  commits report B/U/E, so this is a reliable presence check" - is false for
  SSH signatures: without an allowedSignersFile git does not distinguish
  signed from unsigned in `%G?`.

Net: the hook fires its "Unverified" branch, with the rewrite remedy, on
every turn in which a signed, correctly-attributed, will-verify-on-GitHub
commit is merely unpushed.

## Why this matters beyond one repo

- A Stop hook is a high-authority read surface: agents follow its
  instructions mechanically, every turn, in every repo in the environment.
- Repos that bind commits to provenance by SHA (citation artifacts, commit
  trailers, verification tooling that dereferences commit hashes) lose their
  citation loop the moment an agent obeys the amend/rebase instruction.
  Recovery is manual and the damage is silent until verification runs.
- The only defense available from inside a repo is a standing
  counter-instruction on its agent-facing read surface, which does not scale
  and does not protect any repo that has not built it.

## Requested fix, in preference order

1. **Fix the detection so the false positive disappears.** Signing already
   works at commit creation; the hook just cannot see it. Either provision
   `gpg.ssh.allowedSignersFile` (mapping `noreply@anthropic.com` to the
   environment signing key) so `%G?` reports good signatures correctly, or
   replace the `%G?` test with an actual signature-presence check (e.g.
   `git cat-file commit <sha> | grep -q '^gpgsig '`). With detection fixed,
   the hook's Unverified branch goes dead in normal operation and its text
   never reaches an agent.
2. **Drop the amend/rebase remedy.** When the committer identity already
   equals `noreply@anthropic.com`, the correct message is: "identity is
   correct; commits are signed at creation by the environment key; push when
   ready." No amend, no rebase, no `--reset-author`. A pure text change that
   removes the hazard for every repo at once, independent of branch 1.
3. **At minimum, gate the remedy on a provenance-repo marker.** If generic
   rewrite advice must stay, suppress it where commits are provenance -
   cheap signals: squash/rebase merging disabled in repository settings, or
   commit-trailer conventions (`Belief:`, `Thread:`, and similar) present in
   history. Weakest form; turns a global hazard into a scoped one.

**Smallest acceptable change:** delete the amend/rebase sentence at line 58
of `/root/.claude/stop-hook-git-check.sh` and replace it with non-rewriting
guidance ("identity is correct; commits are signed at creation; push when
ready"). Everything else above is better, but that one sentence is the
hazard.

## Repro, condensed

```sh
# in any CCR session with commit.gpgsign=true (the default here):
git commit --allow-empty -m probe          # signed at creation via /tmp/code-sign
git cat-file commit HEAD | grep gpgsig     # signature present
git log --format='%h %G?' -1               # reports N anyway (no allowedSignersFile)
# -> Stop hook flags the commit as Unverified and prescribes amend/rebase,
#    although pushing it as-is yields verified: true on GitHub.
```
