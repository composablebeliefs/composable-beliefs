---
type: concept
title: Generalize atomicity (cb:a475) to all four types
description: Covers extending the primitive-only atomicity doctrine (cb:a475) to all belief types - one belief, one falsifiable proposition - which is what licenses splitting multi-claim nodes like a098.
tags: [cb, schema, a475, nursery]
status: active
timestamp: 2026-06-25
maturity: active
threads: [2026-06-25-belief-audit]
---

# Generalize atomicity (cb:a475) to all four types

## The focus
`cb:a475` holds atomicity for primitives only:
> a primitive is one atomic statement of what a single source said... A primitive whose
> claim conjoins separable assertions is a mis-authored compound and is split at
> authoring time.

Generalize the doctrine to all four structural types.

## Where it stands
- **Reframe:** one belief = one falsifiable proposition (normally one sentence); if it
  needs more qualifying, it is a compound or a schema gap. That is a475 minus the word
  "primitive."
- Already latent - `cb:a114`: *"the claim field is a one-liner."*
- Enforcement stays judgment (a475: *"atomicity is judgment, enforced in the write flow
  rather than by a verifier check"*); a multi-sentence `claim` is a lintable *smell*, not
  a hard fail.
- This is the doctrine that licenses splitting a098 into a directive + an inference.

## Next
Draft a successor to a475 that generalizes the doctrine; run `mix cb.preflight`.

## Related
- [assertions-rename](assertions-rename.md) - the split this unblocks.
