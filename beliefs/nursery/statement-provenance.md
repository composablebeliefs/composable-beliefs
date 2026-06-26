---
type: concept
title: Associate each thread statement with the artifact it feeds
description: Covers linking each user/agent statement in a thread to the seed or belief it is synthesized into - the back-edge of transcript-format's seeds-carry-excerpts (seed to exchange), making transcript-to-graph traceability bidirectional at statement granularity.
tags: [nursery, provenance, threads, linkage]
status: active
timestamp: 2026-06-26
maturity: active
threads: [2026-06-26-nursery-workflow]
---

# Associate each thread statement with the artifact it feeds

## The focus
Each statement (user or agent) in a thread should carry a way to reach the artifact - seed
doc or belief - it was synthesized into. Today the link runs one way: a seed quotes its
supporting exchanges (transcript-format's seeds-carry-excerpts). This is the back-edge:
exchange -> seed/belief.

## Where it stands
- **Bidirectional traceability at statement granularity.** Forward (seed -> exchange) is the
  excerpt; backward (exchange -> seed/belief) is this. Together they are the OKF
  bidirectional-traceability rule (`okf/standard/types.md`) pushed down from doc-level to
  statement-level.
- **Co-design with the excerpt rule**, not bolt-on, so the two directions stay consistent -
  one mechanism, two readings - rather than drifting into two ledgers.
- **Open:** where the back-link is stored - annotate the render/raw transcript inline, or
  keep a side index (statement id -> artifact id)? Either way it needs stable statement ids,
  which the hook would assign as it renders.

## Why it matters now
It is the safety precondition for fold-and-evacuate ([seed-absorption](seed-absorption.md)):
a losing seed folds into the winner and is deleted only because its primary reasoning stays
reachable in the raw transcript. Per-statement links are what keep that reasoning reachable -
and addressable - after the curated doc is gone.

## Related
- [transcript-format](transcript-format.md) - the forward edge (seeds carry excerpts) and
  the persist-raw decision this depends on.
- [seed-absorption](seed-absorption.md) - fold-and-evacuate is licensed by this plus
  persist-raw.

## Thread excerpts (2026-06-26)
**User:** "need to figure out how to associate each section of the thread documents to seed
docs/beliefs. in other words, each statement by agent and user should have a way of being
associated with an artifact that it is being synthesized into."
