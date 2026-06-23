---
type: spec
title: The Two-Tier Rule — OKF Floor vs CB Ceiling
description: Use when deciding whether a domain or document needs full CB rigor or just the OKF floor — the boundary test, with the cost/benefit and worked examples.
tags: [spec, tiers, okf, cb, decision]
status: active
timestamp: 2026-06-21
id: spec:tiers
---

# The Two-Tier Rule

The whole system is cheap to adopt because **most knowledge stays on the floor**. Rigor
is opt-in, applied only where it pays. Forcing CB-grade discipline onto "when is the
furnace filter due" is the failure mode to avoid.

## The two tiers

| | **OKF tier (floor)** | **CB tier (ceiling)** |
|---|---|---|
| Discipline | frontmatter + cross-links + index + prose synthesis | + stable ids, typed `deps`, immutability, dated supersession, staleness propagation, contracts |
| Cost to author | ~0 (write markdown) | real (assert / preflight / adjudicate) |
| Contradiction handling | rewrite the page | record + date the supersession, flag dependents stale |
| Read path | manifest → concept docs | + deterministic graph traversal |
| Default for | finances, home, band ops, personal, tutorials, most docs/plans/threads | evals, policies, anything adjudicated or whose claims must stay provably true over time |

## The boundary test

Promote a domain or document to the **CB tier** only if **any** of these is true:

1. **Time-truth matters.** Someone will later ask *"when did this change, and what
   depended on it?"* — and "the page was rewritten" is not an acceptable answer.
2. **Contradictions must be caught mechanically**, not by an LLM's in-the-moment
   judgment. (A superseded dependency must *automatically* flag everything downstream
   as stale.)
3. **It will be audited or adjudicated** — the claim is evidence someone acts on, and
   the provenance chain must hold up.

If none hold, stay on the **OKF floor**. Prose synthesis maintained by the agent is
enough, and the discipline cost of CB is waste.

## Worked examples

| Knowledge | Tier | Why |
|---|---|---|
| Furnace filter size & schedule | OKF | Nobody audits it; rewrite when it changes. |
| Monthly cashflow summary | OKF | Personal; a rewrite-in-place page is fine. |
| "We decided to use a 21-day loan period" (a policy others rely on) | CB | Time-truth + adjudication: supersession must be dated and propagate. |
| An eval's verdict (dag-vs-prose) | CB | It's evidence; the provenance chain is the product. |
| A settled architectural `position` | CB-lean | Must not be silently reopened; dated supersession earns its keep. |
| A how-to for the band's merch upload | OKF | Edit as it changes; no audit trail needed. |

## Migration direction

Start everything on the **floor**. Promote a *document* (not necessarily its whole
domain) to CB the first time it trips the boundary test. Promotion is additive: add
`tier: cb`, `id`, `deps` to the existing frontmatter and register it in the CB graph —
the file stays OKF-readable throughout.

The one floor↔ceiling exception worth pulling down early: **stable `id`s**. Even
OKF-floor docs benefit from ids the moment a folder starts getting restructured, because
ids survive renames where path links don't. Adding an `id` does not make a doc CB-tier;
it just makes its identity durable.
