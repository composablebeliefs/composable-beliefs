---
type: concept
title: The upstream fix for the git-check Stop hook (non-cosmetic)
description: Describes the actual fix for the user-global git-check Stop hook's history-rewrite advice - the fix that lives upstream in the CCR environment, not in this repo. Two branches - fix the premise (provision a working in-session signing key so commits are signed at creation and the Unverified badge never appears) or fix the remedy (the hook stops recommending amend/rebase and instead states that identity is correct and signatures apply at push time). Everything the repo itself can do (cb:b585 read surface, ENVIRONMENT_DEFECTS.md) is defense, not repair.
tags: [nursery, git, provenance, environment, upstream]
status: active
timestamp: 2026-07-05
maturity: active
threads: [2026-07-05-provenance-read-surface]
---

# The upstream fix for the git-check Stop hook (non-cosmetic)

## The matter

[git-history-rewrite-surface](git-history-rewrite-surface.md) closed the
repo's side of the hazard: cb:b585 now tells every agent, on the CLAUDE.md
read surface, to disregard the git-check Stop hook's amend/rebase remedy.
That is a defense, not a repair. The hook itself -
`/root/.claude/stop-hook-git-check.sh`, user-global, injected by the CCR
environment, unreachable from any repo - still emits the rewrite instruction
every turn, in every repo, to every agent whose repo has not built an
equivalent defense. This document describes what the actual fix looks like,
so the request to whoever provisions the environment carries its full
context instead of a bug-report one-liner.

## Context: what the hook does and why both halves are wrong

The hook checks unpushed commits for `%G? == N` (no signature) or a
committer email other than `noreply@anthropic.com`, and on a match instructs
the agent verbatim: run `git commit --amend --no-edit --reset-author` for
the tip commit, or `git rebase --exec "git commit --amend --no-edit
--reset-author" <upstream>` for earlier commits, then push.

- **The premise is wrong.** In this environment the committer identity is
  already `noreply@anthropic.com`. The `N` comes from an empty in-session
  signing key (`/home/claude/.ssh/commit_signing_key.pub` observed at 0
  bytes, no private key), and signatures are applied at push time anyway -
  so the flagged state is cosmetic and self-resolving. `--reset-author`
  cannot add a signature; the advice does not even fix the badge it flags.
- **The remedy is dangerous.** Amend and rebase mint new SHAs. In any repo
  whose commits are cited by content address - here: `commit:` artifacts,
  `Belief:`/`Proto-Belief:`/`Thread:` trailers, `mix cb.verify.commits` -
  the advice, followed mechanically by an agent, severs the citation loop.
  A Stop hook is a high-authority read surface: agents treat its output as
  the environment's own voice, which is exactly why the 2026-07-04/05
  proofing sessions rated this a live hazard rather than a nit.

## The actual fix (upstream, in preference order)

1. **Fix the premise: provision a real signing key.** If the in-session
   signing key were populated, commits would be signed at creation, `%G?`
   would never read `N`, and the hook's unverified branch would go dead
   without touching its logic. This is the only fully non-cosmetic fix: it
   makes the flagged state impossible instead of changing what anyone says
   about it. (If signing is deliberately deferred to push time - the
   current design - then the badge is a known non-issue and branch 2
   applies.)
2. **Fix the remedy: the hook stops advising rewrites.** When committer
   identity already equals `noreply@anthropic.com` and only the signature
   is missing, the correct message is: "identity is correct; signatures
   apply at push time; push when instructed." No amend, no rebase. This is
   a text change in the hook and removes the hazard for every repo at once.
3. **At minimum: gate the advice on a repo marker.** If the generic advice
   must stay, the hook should detect repos where commits are provenance -
   cheap signals: squash/rebase merging disabled in repository settings,
   or the presence of `Belief:`/`Thread:` trailer conventions in history -
   and suppress the rewrite remedy there. Weakest form, still worth having:
   it turns a global hazard into a scoped one.

The un-fix to rule out explicitly: teaching each repo to defend itself (what
cb:b585 does here) does not scale and is not the fix - it is the mitigation
a repo applies because it cannot reach the hook. Every unprotected repo
remains exposed until one of the branches above lands.

## Where it must land

The hook lives in the user-global `/root/.claude` layer of the CCR container
provisioning - the same layer ENVIRONMENT_DEFECTS.md (defects 2 and 3)
identifies for the stale baked-in `main` and the apt-sources failure. The
fix belongs to whoever builds or configures that layer; nothing in a repo,
its hooks, or its settings can alter it. Open question below: the concrete
channel for filing this.

## What the repo already does (defense in depth, applied)

- cb:b585 on the CLAUDE.md read surface: disregard the hook's rewrite
  remedy, with the cosmetic-badge explanation attached.
- `ENVIRONMENT_DEFECTS.md` defect 1: the full forensic record, including
  the recommended-upstream-fix sketch this document expands.
- The hook's benign residue (the every-turn unpushed nag) is handled by
  the ride-along commit-and-push lane, not by rewriting.

## Open

- **Delivery channel.** Where does an upstream environment-defect request
  actually go - CCR feedback, an Anthropic issue tracker, or the operator
  relaying it? The action-item row stays staged until a channel is named.
- **Verification linkage.** When any branch of the fix lands, the
  effectiveness check owed on cb:b585 (see git-history-rewrite-surface,
  Status note) should be re-run: with the hazard removed at source, the
  read-surface rule becomes belt-and-suspenders and its evidence should say
  so.

## Mint manifest

Rows staged, unminted - gated on the delivery channel question above:

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription (action-item) | File the upstream git-check hook fix with the environment provisioner: preferred fix is provisioning a working in-session signing key (makes the Unverified state impossible); acceptable is removing the amend/rebase remedy in favor of "identity correct, signatures apply at push time"; minimum is gating the remedy on a provenance-repo marker. | cb:b585 | document:beliefs/nursery/git-check-hook-upstream-fix.md | - |

## Related

- [git-history-rewrite-surface](git-history-rewrite-surface.md) - the
  in-repo defense this complements; its Status note owes the verification
  check that this fix, once landed, would re-frame.
- `ENVIRONMENT_DEFECTS.md` defect 1 - the forensic record and the short
  form of the recommended fix.
- cb:b585 - the minted read-surface rule; cb:b573 - the default-branch
  provenance contract both documents build on.
