---
type: analysis
title: How OKF, Karpathy-wiki, and CB layer
description: Use when you need the worked argument for why CB sits cleanly above OKF and what becomes redundant — not just the conclusion.
tags: [meta, analysis, okf, cb]
status: active
timestamp: 2026-06-21
threads: [meta:okf-session-2026-06-21]
---

# How OKF, Karpathy-wiki, and CB layer

## Question
Does adopting OKF for a generalized knowledge base conflict with, subsume, or sit below
the Composable Beliefs system?

## Findings

**OKF is a transport/interchange layer.** Markdown + YAML frontmatter, one required
field (`type`), untyped cross-links, optional `index.md`/`log.md`, packaged as a
git repo/tarball. Explicitly "format, not platform." It is the productization of
Karpathy's LLM-wiki (same raw/wiki/schema shape, same index/log conventions).

**CB is an epistemic-semantics layer.** Typed claims, immutability + dated supersession,
provenance with `artifact` + `evidence[]`, staleness over a real dependency DAG,
machine-checkable contracts, deterministic LLM-free read path. None of that is in OKF's
remit, by OKF's own choice.

**They layer cleanly:**

| Concern | OKF / Karpathy | CB |
|---|---|---|
| Packaging | markdown + frontmatter | JSON graph |
| Identity | file path | belief id |
| Relations | untyped links | typed `deps` edges |
| Classification | free `type` | `kind`/`domain` closed enums |
| Provenance | `resource` + `timestamp` | `artifact` + `evidence[]` |
| History | prose `log.md` | immutable supersession chain |
| Rules | none (deliberately) | contracts compiled to tests |
| Query | "any search tool" | deterministic traversal |

CB serializes *down* to OKF (every belief → a typed markdown doc; `deps` → cross-links).
OKF cannot reconstruct CB *up* without inventing exactly the discipline CB adds — the
up-conversion is lossy. That is the definition of CB sitting above OKF.

**Synthesis ownership:** synthesis-as-format is OKF's; synthesis-as-*process* (the
ingest-time wiki-maintenance loop) is Karpathy's; synthesis-as-*verifiable-epistemics*
is CB's. The default floor uses Karpathy-style prose synthesis; CB synthesis is opt-in.

## Conclusion
OKF becoming a standard is good for CB, not a threat: it validates CB's "format not
platform" thesis and hands CB a free serialization target. The move is a CB↔OKF
producer/consumer adapter; CB markets as "the typed, verifiable, supersedable dialect of
OKF." The real cost OKF imposes is that it **raises the plain-English baseline** the eval
must beat — which also makes that baseline a more credible experimental control. This
conclusion is settled in [two-tier-knowledge-architecture.md](two-tier-knowledge-architecture.md).
