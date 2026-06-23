---
type: thread
title: 2026-06-21 — Knowledge methodology designed, built, and integrated with CB
description: Use when you need what happened in the session that created this standard and CB's OKF integration layer, without replaying it. Outcome: a conformance-tested OKF standard + a working CB↔OKF bridge.
tags: [meta, thread, design]
status: active
timestamp: 2026-06-21
id: meta:okf-session-2026-06-21
artifact: session:2026-06-21-okf-knowledge-design
---

# 2026-06-21 — Knowledge methodology designed, built, and integrated with CB

> **Provenance.** This is the *summary* (Layer 2). The raw verbatim transcript (Layer 1,
> immutable) is the byte-for-byte session log, now persisted as the paired `source` doc:
> [`2026-06-21-okf-cb-session-source.md`](2026-06-21-okf-cb-session-source.md) →
> [`meta/sessions/2026-06-21-okf-cb-design.jsonl`](sessions/2026-06-21-okf-cb-design.jsonl).
> Docs this session authored carry `threads: [meta:okf-session-2026-06-21]`; subsequent
> sessions append their ids.

## What this session was
Evaluate whether to build a generalized, cross-repo knowledge base on the Open Knowledge
Format (OKF), how it relates to Karpathy's LLM-wiki and the existing Composable Beliefs
(CB) system, and how to centralize the currently-haphazard threads/plans/analyses. It
grew into building the standard, CB's integration layer, and the CB↔OKF bridge.

## What was decided
- **OKF is the floor, CB is the opt-in ceiling** (two-tier). OKF is mostly a renaming of
  a pattern already reinvented in `SECOND-BRAIN/second-brain`. CB is a conceptual
  superset with a separate serialization — build an adapter, not a migration; CB's
  `beliefs.json` stays canonical.
- **The synthesis layer IS the wiki** — one body of OKF markdown both agent and human
  read; a rendered site is a throwaway view. Agent reads synthesis first, drills to sources.
- **`description` is a relevance hook + a generated `manifest.json`** give the
  skills-style "understand a doc without loading it" capability.
- **Identity: path-canonical, `id` additive.** Floor docs use path identity; CB-tier docs
  carry a stable `namespace:local` `id` (decoupled from path, survives renames).
- **`knowledge` is a standard, not an app** — defined by a conformance suite so multiple
  implementations can be checked for equivalence. It is a sister repo under `amieval/`.
- **CB is a conformant OKF consumer/dialect, not a format owner** (positioning recorded
  in `cb-direction`).
- **Threads persist as `source` (raw) + `thread` (summary)** with `threads:[]` provenance;
  the operational `/end` directive lives in CB's graph, the format rule in this standard.

## What it produced
- **The standard** (`amieval/knowledge`, `ob6to8/knowledge`): [spec](../standard/KNOWLEDGE.md),
  [types](../standard/types.md), [frontmatter](../standard/frontmatter.md), [tiers](../standard/tiers.md),
  [ADOPT](../ADOPT.md), [CONVERT](../CONVERT.md), templates, `tools/build_manifest.py`,
  `tools/validate.py` (self-verifying, `--json`), and a [conformance suite](../conformance/README.md).
- **CB's OKF integration layer** (`composable-beliefs`): `mix knowledge.manifest` /
  `knowledge.validate` (byte-equal Elixir ports, pass all 13 fixtures) plus the bridge
  `mix knowledge.emit` (the 202-belief graph validates 0/0) and `mix knowledge.ingest`.
- The [layering analysis](okf-vs-cb-layering.md), the [two-tier position](two-tier-knowledge-architecture.md),
  and the cb-direction note `2026-06-21-cb-as-conformant-okf-consumer.md`.
- The **soft id-format check** (`id_format_invalid`, warns) added to both implementations.

## Open / next
- Use the OKF/Karpathy wiki as the prose baseline arm in the dag-vs-prose eval.
- Pilot CONVERT on a real store (e.g. `SECOND-BRAIN/second-brain`, including `[[wikilink]]`
  → path-link + `deps` transforms).
- Done: renamed `spec/` → `standard/` (folders denote role, not type).
- Next: assert the `/end` thread-persistence directive into CB's graph; wire the verbatim
  transcript-file duplication into `/end` (it copies the `.jsonl`, it does not reconstruct).
