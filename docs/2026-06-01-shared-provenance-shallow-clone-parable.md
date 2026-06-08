# Field Note: "Verify Against Ground Truth" Is Necessary But Not Sufficient

**Date:** 2026-06-01
**Type:** content-seed / build-in-public material
**Origin:** A live multi-agent git reconciliation during a repo split. Captured verbatim as a capstone for the operator/agent shared-substrate thesis.

## The episode

Two agents were reconciling a divergent git history before freezing a repo and extracting Composable Beliefs into its own repo. Both referenced the *same* commit by the *same* SHA (`a1b2c3d4`). Both honestly ran `git`. For three rounds they reached **opposite** commit-level conclusions:

- One agent (full clone, 1900 commits) reported the schema-discipline commits (`e5f6a7b8`, `c9d0e1f2`, `3a4b5c6d`) were ancestors of `a1b2c3d4`.
- The other agent (shallow clone, 51-commit horizon) reported they were *not* ancestors, and concluded origin/main was a "flattened history missing the schema."

Neither was lying. The shallow clone's view was **internally consistent** - `git merge-base --is-ancestor` genuinely returned "not-ancestor," because a shallow graft severs ancestry past its boundary. It felt like truth. It was a truncated view of the same reality.

The disagreement was not resolved by re-checking the tip (both agents kept doing that, and kept disagreeing). It was resolved by discovering the **asymmetry in depth of view**: same tip SHA, 47 commits vs 1900. `git rev-parse --is-shallow-repository` -> `true`.

## The lesson

"Verify against ground truth" is **necessary but not sufficient.** Two parties can share the same reference and both be honest and still diverge - if one has a truncated view of the same reality. Trust requires not just a shared *reference* but a shared, *complete* view of what that reference entails.

## The CB connection

This is the CB thesis in miniature.

Sharing the same **current state** (the tip SHA) is not enough for two parties to agree or to trust each other. You need shared **provenance** - the history of how the state was reached.

A shallow clone is precisely an operator who knows the present but cannot audit the past. It can read what *is* but not verify how it *came to be* - and so it produces confident, internally-consistent, wrong conclusions, invisibly, until the asymmetry is forced into the open.

That is exactly why a belief/contract substrate for accountable agentic work has to carry provenance and history as first-class, not just current values. Inspectability is not "can I see the present state." It is "can I see the present state *and* the depth of how it got here, on the same footing as the other party." Without shared depth, two honest agents reading the same reference will still mistrust - correctly - and neither will be able to say why.

## Tag for content

Strong opener for the build-in-public channel: a real, unscripted failure where "just check git" wasn't enough, the root cause was a difference in *provenance depth*, and the fix maps directly onto why CB privileges history over snapshots. Warts-and-all, no deck-stacking - the agent that was wrong for three rounds was the one writing this note.
