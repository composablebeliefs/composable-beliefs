---
type: spec
title: The Knowledge Methodology
description: The canonical spec — three layers, the frontmatter spine, the manifest index, and the OKF/CB two-tier rule. Read this first when adopting or converting.
tags: [spec, okf, cb, methodology]
status: active
timestamp: 2026-06-21
id: spec:knowledge
---

# The Knowledge Methodology

## 1. Lineage (what this is built from)

| Layer | Source | What we take |
|---|---|---|
| Format | **OKF** (Open Knowledge Format) | markdown + YAML frontmatter, directory hierarchy, `index.md` progressive disclosure, cross-links, "format not platform" |
| Synthesis discipline | **Karpathy LLM-wiki** | three layers (raw → wiki → schema), ingest-time synthesis, `index.md`/`log.md`, compounding artifact |
| Epistemic rigor (opt-in) | **Composable Beliefs (CB)** | typed claims, stable ids, typed `deps`, dated supersession, staleness propagation, contracts |

The floor is OKF-compliant: every file is plain markdown any editor renders and any
search tool indexes. The ceiling (CB) is **additive frontmatter** on the same files —
it never breaks OKF compatibility (see §6).

### Methodology vs standard

This repo is the **methodology** (the umbrella: format, practices, the two-tier
philosophy, thread persistence, the ADOPT/CONVERT workflow). The conformance-tested
**format standard** is the subset defined in `standard/` and checked by `conformance/`.
Methodology ⊇ standard: not everything here is machine-enforced (the two-tier rule and
thread persistence are practice, not conformance checks).

### What the standard owns vs what consumers own

A governing boundary, so rules don't get duplicated or misplaced:

- **Format rules** (how a doc is shaped: types, frontmatter, manifest, links, ids, and
  how threads persist) are **owned here**, in the standard. One source of truth.
- **Operational directives** (when/how an agent *does* something — e.g. "at session end,
  duplicate the transcript and write the source+thread pair") are **owned by the
  consumer**. In the CB world that means a directive *belief in the graph* (CB renders
  directives live from the DAG rather than caching them to a file), which `deps`/`artifact`
  grounds back to the relevant doc here. Consumers reference the standard; they do not
  re-state its rules.

## 2. The three layers

This is the Karpathy shape, made concrete.

```
┌─ Layer 3: SCHEMA ──────────────────────────────────────────────┐
│  This spec + CLAUDE.md conventions. How the bundle is built.    │
├─ Layer 2: SYNTHESIS (the "wiki") ──────────────────────────────┤
│  Compiled concept docs. Maintained at ingest time. OKF markdown.│
│  ← Both agent AND human read THIS first. ─────────────────────  │
├─ Layer 1: SOURCES ─────────────────────────────────────────────┤
│  Immutable captures (type: source). Drilled into only when the  │
│  synthesis is insufficient or provenance is in question.        │
└─────────────────────────────────────────────────────────────────┘
```

**There is no separate "human wiki."** The synthesis docs *are* the wiki, and they are
OKF markdown that both the agent and a human read. A rendered website (e.g. the OKF
HTML visualizer) is just `render(bundle)` — a throwaway view, never authored, never a
source of truth.

**Default read path:** agent loads `manifest.json` → matches by `description` → loads
the synthesis docs it needs → drills to Layer-1 sources only for provenance or detail.

## 3. The frontmatter spine

Every document carries the same frontmatter spine. Only `type` is strictly required
(OKF rule); the rest are strongly recommended. Full field reference:
[`frontmatter.md`](frontmatter.md).

```yaml
---
type: concept            # REQUIRED. one of the taxonomy types (see types.md)
title: Household cashflow # human label
description: >           # RELEVANCE HOOK — see §4. the most important field.
  Use when reasoning about monthly money in/out, recurring obligations, or runway.
tags: [finances, recurring, runway]
status: active           # active | superseded | retracted | draft
timestamp: 2026-06-21    # last meaningful update (ISO date)
# --- tier-2 (CB) fields, optional, additive ---
id: fin:cashflow         # stable identity (see §6)
deps: [fin:income-sources, fin:fixed-costs]   # typed dependencies
---
```

## 4. `description` is a relevance hook, not a summary

This is the mechanism that lets an agent understand what a doc holds **without loading
it** — the same trick as a Claude skill's `description` or a `MEMORY.md` one-liner.

- Write it as **"Use when…" / "Covers…"** — what question this doc answers.
- ≤ 2 lines. If you need more, the doc is doing too much; split it.
- It must be true and discriminating: an agent decides *load or skip* from this line
  alone, so a vague description silently costs context on every traversal.

Bad: `description: Notes about money.`
Good: `description: Use when reasoning about monthly money in/out, recurring obligations, or runway.`

## 5. The manifest (the summary index)

`bundle/manifest.json` is a **generated** harvest of every doc's frontmatter into one
small file the agent loads first. It is the skills-style summary layer. Contract:

> **This is this standard's addition, not OKF-native.** OKF's entry mechanism is
> `index.md` (human progressive disclosure); the generated `manifest.json` agent-index is
> a bespoke extension this methodology layers on top — which is why the lineage table (§1)
> credits OKF with `index.md` but not the manifest. It is the concrete reason the
> collection's namespace is `okfx:` (extends OKF) rather than `okf:`.

- Produced by `mix okf.manifest <root>` (in the `composable-beliefs` repo); **never hand-edited**.
- One entry per `.md` doc: `path`, `type`, `title`, `description`, `tags`, `status`,
  `timestamp`, and (if present) `id`, `deps`, `tier`.
- Small by construction — bodies are excluded. An agent reads the whole manifest
  cheaply, then loads only the bodies whose `description` matches its task.
- Regenerated on every write to the bundle (CI or a pre-commit hook; for now, run the
  tool by hand — see ADOPT.md).

`index.md` files complement the manifest for **human** progressive disclosure (browse
a folder, read its index, descend). The manifest is for the agent; `index.md` is for
the human walking the tree. Both are derived from the same docs.

## 6. Identity: path-canonical, id-additive

OKF identity is the **file path**, and cross-links are plain markdown links to paths —
so a generic OKF consumer navigates with zero integration. Keep that as canonical.

`id` is an **additive** tier-2 field (legal OKF — only `type` is required). Your tooling
uses it for two things generic tools can't do:

1. **Typed `deps`** that survive prose (the CB edge), and
2. **Rebinding path links after a rename** — the id is the stable anchor.

Rule: **never drop the path links.** A doc that links *only* by id is no longer OKF.
So: path links canonical (OKF stays intact), id additive (CB tier rides on top). `id`
is the first CB feature worth pulling down into the floor, because these repos
restructure constantly and renames otherwise break cross-links.

## 7. Synthesis: how Layer 2 is maintained

**Default (OKF/Karpathy floor):** when a new source lands, the agent updates the
relevant concept docs in place — integrating the new fact, resolving contradictions by
rewriting, refreshing cross-links and the folder `index.md`. Prose, model-maintained.
This is enough for almost everything.

**Ceiling (CB):** for knowledge that will be *audited or adjudicated*, synthesis is not
a rewrite — it is a typed compound belief with recorded `deps`, dated supersession, and
propagating staleness. The contradiction is not erased; it is dated and superseded, and
dependents are flagged stale. Use this only where someone will later ask "when did this
change and what depended on it." The boundary rule is in [`tiers.md`](tiers.md).

## 8. What a bundle looks like

```
bundle/
├── index.md          # root: what's here, links to domain indexes
├── manifest.json     # generated
├── <domain>/
│   ├── index.md       # domain landing: progressive disclosure
│   ├── <concept>.md   # type: concept   (Layer 2 synthesis)
│   ├── <source>.md    # type: source    (Layer 1 immutable capture)
│   └── ...
└── meta/             # knowledge about the knowledge system itself
```

A bundle is portable: a git repo, a tarball, or a mounted directory. No SDK, no runtime
required to read it. Tooling (the manifest generator, optionally a CB graph) is
additive at the edges, never a prerequisite for reading.
