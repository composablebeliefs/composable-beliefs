---
type: position
title: Knowledge is OKF on the floor, CB at the ceiling
description: Use when tempted to make everything CB-rigorous, or to drop CB for plain OKF — the settled two-tier decision and what would change it.
tags: [meta, position, decision, okf, cb]
status: active
timestamp: 2026-06-21
tier: cb
id: meta:two-tier
deps: [spec:tiers, spec:knowledge]
threads: [meta:okf-session-2026-06-21]
---

# Knowledge is OKF on the floor, CB at the ceiling

## Decision
The cross-repo knowledge base uses **OKF as the universal floor** and **CB as an opt-in
ceiling**. Every domain and document defaults to the floor (frontmatter + cross-links +
prose synthesis). A document is promoted to the CB tier only when it trips the boundary
test: time-truth matters, contradictions must be caught mechanically, or it will be
audited/adjudicated.

This doc is itself CB-tier (note `tier: cb`, `id`, `deps`) to demonstrate the ceiling on
a doc that genuinely qualifies — it is a governing decision that must not be silently
reopened.

## Why
- The floor is near-zero cost, so it actually gets adopted across all repos; forcing CB
  rigor onto personal/productivity knowledge is waste (the furnace-filter case).
- CB rigor (immutability, dated supersession, staleness, contracts) earns its cost only
  where someone later asks "when did this change and what depended on it."
- OKF compatibility is preserved at the ceiling: CB fields are additive frontmatter on
  OKF-readable files, so a generic consumer still works.

See the full argument in [okf-vs-cb-layering.md](okf-vs-cb-layering.md) and the boundary
test in [../standard/tiers.md](../standard/tiers.md).

## What would change this
- If maintaining two tiers proves more confusing than one, collapse to OKF-only and run
  CB entirely as a side graph (no `tier` field on docs).
- If the dag-vs-prose eval shows structured substrate does **not** beat a strong OKF
  prose baseline on tasks that matter, demote CB from "ceiling" to "side experiment" and
  supersede this position.
