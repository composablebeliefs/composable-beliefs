---
type: spec
title: Concept Type Taxonomy
description: Use when deciding what `type:` a document should be, or what artifact kinds the bundle supports — the closed list of document types and which layer each belongs to.
tags: [spec, taxonomy, types]
status: active
timestamp: 2026-06-21
id: spec:types
---

# Concept Type Taxonomy

`type` is the one required field. It answers "what kind of document is this?" and places
the doc in a layer. Keep to this closed list; extend it deliberately (a new type is a
spec change, not a per-doc decision).

| `type` | Layer | What it is | Lifecycle |
|---|---|---|---|
| `source` | 1 (raw) | An immutable capture: an ingested article, statement, transcript, email, doc. Read, never rewritten. | Append-only. Never edited after capture. |
| `concept` | 2 (synthesis) | A compiled, maintained page about one entity/idea, synthesized over sources. The "wiki" page. | Rewritten in place (OKF) or superseded (CB). |
| `thread` | 1→2 | A persisted session: what was decided/done, with links to what it produced. The fix for "threads persisted ad hoc". | Captured once; its `description` is the outcome. |
| `plan` | 2 | Intended work. Replaces the `plan.md`/`USER_STORIES.md`/`DESIGN.md` sprawl. | Active → done/superseded. |
| `analysis` | 2 | A worked argument or investigation toward a conclusion. Your dated `analyses/*.md`. | Captured; may be superseded by a better analysis. |
| `position` / `decision` | 2 | A settled stance and why. The thing future-you must not silently reopen. | Active → superseded (with a reason). |
| `reference` | 2 | A stable how-to / runbook / spec / fact sheet. Low churn. | Edited as facts change. |
| `index` | — | A folder landing page for human progressive disclosure. One per directory. | Edited as the folder grows. |
| `spec` | 3 (schema) | A document defining the methodology itself (these files). | Versioned. |

## Placement rules

- **`source` is sacred.** Once captured, do not edit its body — supersede with a new
  capture if the source itself changed. This is what makes provenance trustworthy.
- **`concept` is where synthesis lives.** When a new `source` lands, the work is
  updating the relevant `concept` docs — not piling up more sources.
- **`thread` closes the centralization gap.** End a working session by writing one
  `thread` doc whose `description` lets a future agent find it without replaying the
  transcript, linking to the `plan`/`analysis`/`concept`/beliefs it produced.
- **`position` is the CB-promotion candidate.** Stances that must not be silently
  reopened are exactly where dated supersession (CB tier) earns its cost.

## Thread & session persistence

A working session persists as a **pair**, not just a summary — the raw conversation is a
Layer-1 source and must be kept, not only synthesized:

- A `source` doc holds (or points at) the **raw, verbatim transcript** — immutable. For
  agent sessions this is the host's session log **duplicated byte-for-byte** (for Claude
  Code: copy `~/.claude/projects/<project>/<session>.jsonl`) — a file copy, never a
  reconstruction. An optional readable markdown rendering may accompany it, but the copied
  log is the source of truth. Because the log is only complete at session end, duplication
  is an **end-of-session** step, not a mid-session one.
- A `thread` doc is the **summary**: its `description` is the outcome, its body links the
  raw `source` and everything the session produced.

**Traceability is bidirectional and lives in the docs, not git:**

- *Forward* (thread → docs): the `thread` doc's "What it produced" links.
- *Backward* (doc → threads): each doc carries `threads: [<origin-id>, <later-id>, …]` —
  a scalar list in frontmatter, origin first, appended on each session that edits it. For
  per-touch detail (date · thread · change), add a `## Provenance` table in the doc body
  (the body is unconstrained, so it stays readable without growing the frontmatter parser).
- The rich structured ledger (`evidence[]` with `{date, detail, artifact}`) is the **CB
  tier**'s job; the floor keeps the lightweight `threads:[]` + body table.

The *format* rule above is owned by this standard. The *operational* directive — "at
session end, render the transcript and write the pair" — lives as a directive in CB's
belief graph and is executed by `/end`, not duplicated here.

## How this maps to CB

When a domain is promoted to the CB tier, these document types become artifacts and
beliefs: a `source`/`thread` is a CB **artifact** (referenced by `artifact:` URI); a
`concept`/`position`/`analysis` conclusion becomes a typed **belief** (primitive,
compound, or implication) that `deps` on the artifacts and concepts it was built from.
OKF is the artifact substrate; CB is the epistemic overlay on top of it.
