# okf — the Knowledge methodology

A portable, agent- and human-readable knowledge methodology for use across all my
repos and domains (software projects **and** productivity domains — finances, home,
band ops, personal). This is **CB's OKF integration extension** — the standard folded
into composable-beliefs (`okf/`) beside the tooling that implements it, rather than a
separate repo. This directory is **both the specification and a working example of
itself**: the `meta/` directory is the design record and `demo/` is an example bundle,
both written in the format the spec defines. ("Bundle" is the generic term for any
knowledge directory in this format — so the folders are named for their role, not typed
`bundle/`.)

Point a fresh agent here and say one of:

- **"Adopt this methodology for this repo"** → the agent reads [`ADOPT.md`](ADOPT.md).
- **"Convert this existing knowledge store to this format"** → the agent reads [`CONVERT.md`](CONVERT.md).

This is a **standard, not an application**. The format is defined by the
[conformance corpus](conformance/) — valid/invalid fixtures plus their normative
results — and **implemented once**, in Elixir: the `mix knowledge.*` tasks in this
repo's [Composable Beliefs](standard/tiers.md) OKF integration layer
(`lib/cb/knowledge/*`), which also add `emit`/`ingest` to bridge the CB belief graph.
The corpus is the source of truth for what "valid" means; the implementation is held to
it by the repo's ExUnit conformance test (`test/cb/okf_conformance_test.exs`).

## What this is, in one breath

Knowledge is **plain markdown files + YAML frontmatter, organized in a directory
hierarchy, with a generated manifest as the agent's entry index.** It is
[Open Knowledge Format (OKF)](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)
as the floor, [Karpathy's LLM-wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
as the synthesis discipline, and [Composable Beliefs (CB)](standard/tiers.md) as an opt-in
ceiling for knowledge that must stay provably true over time.

## Why it exists

Across ~45 repos, persisted knowledge had drifted into five incompatible patterns
(`plan.md` vs `USER_STORIES.md` vs `DESIGN.md`; `CLAUDE.md` vs `claude.md`;
JSON-canonical vs YAML-canonical vs prose; threads persisted ad hoc). This gives all
of them one cheap shape to converge on, so a fresh agent can build context from any
repo the same way.

## Layout

```
okf/
├── README.md            ← you are here
├── ADOPT.md             ← entry point: "adopt this methodology"
├── CONVERT.md           ← entry point: "convert an existing store"
├── CLAUDE.md            ← fresh-agent entry doc for this extension
├── standard/
│   ├── KNOWLEDGE.md     ← THE spec (read this first)
│   ├── frontmatter.md   ← the frontmatter spine: field reference
│   ├── types.md         ← the concept-type taxonomy
│   └── tiers.md         ← the OKF floor vs CB ceiling boundary rule
├── meta/                ← THE DESIGN RECORD: how this methodology was conceived
│   ├── index.md
│   ├── manifest.json    ← generated
│   ├── 2026-06-21-okf-cb-design-session.md   ← thread: the session that produced this
│   ├── okf-vs-cb-layering.md                 ← analysis: OKF vs Karpathy vs CB
│   └── two-tier-knowledge-architecture.md    ← position (CB tier): the floor/ceiling decision
├── templates/           ← copy-paste starting points, one per type
├── conformance/         ← the format defined as behaviour (the spec corpus)
│   ├── fixtures/        ← valid + invalid bundles, one isolated failure each
│   └── expected/        ← the normative (severity, code, path) results
├── beliefs.json         ← the methodology's own CB operational graph (the `okfx:`
├── manifest.json           collection: backlog, conventions). A belief graph, NOT an
│                            OKF bundle — the `mix knowledge.*` OKF tooling does not apply.
└── demo/               ← a SYNTHETIC example bundle (illustrative sample data only)
    ├── index.md         ← progressive-disclosure root
    ├── manifest.json    ← GENERATED skills-style summary index (do not hand-edit)
    ├── finances/        ← productivity domain (OKF floor)
    └── home/            ← productivity domain (OKF floor)
```

`meta/` is the repo dogfooding its own format on its real history — read it to learn
*why* the spec is shaped this way. `demo/` is throwaway example data you hold up to a
newcomer; it carries no authoritative content.

This extension has two sides. The **OKF side** (`standard/`, `meta/`, `demo/`) is markdown
bundles read through a generated `manifest.json`. The **CB side** (`okf/beliefs.json`, the
`okfx:` collection) is a typed belief graph carrying the methodology's own operational
obligations and conventions — the consumer-owned counterpart to the format rules the
standard owns (see [`standard/KNOWLEDGE.md`](standard/KNOWLEDGE.md) §1.1). They relate as
substrate↔overlay: OKF docs are the artifacts; CB beliefs reference them by
`artifact:`. The OKF tooling validates the OKF side only — never point it at the
`okfx:` graph (`okf/beliefs.json`).

## The reading order

1. [`standard/KNOWLEDGE.md`](standard/KNOWLEDGE.md) — the model and its three layers.
2. [`standard/frontmatter.md`](standard/frontmatter.md) — the fields.
3. [`standard/types.md`](standard/types.md) — what kinds of documents exist.
4. [`standard/tiers.md`](standard/tiers.md) — when to stay cheap (OKF) vs when to add rigor (CB).
5. [`meta/`](meta/) — the design record, then [`demo/`](demo/) — see the format used.
