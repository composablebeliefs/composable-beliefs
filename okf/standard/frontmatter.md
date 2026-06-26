---
type: spec
title: Frontmatter Field Reference
description: Use when authoring or validating a doc's YAML frontmatter — every field, whether it's required, and its allowed values.
tags: [spec, frontmatter, schema]
status: active
timestamp: 2026-06-21
id: spec:frontmatter
---

# Frontmatter Field Reference

YAML frontmatter is a fenced `---` block at the very top of the file. Keep it to the
documented subset below — the manifest generator parses this subset deterministically
(it is not a full YAML parser, by design: a constrained spine is easier to validate).

## Tier-1 fields (OKF floor)

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | **yes** | scalar | The only OKF-required field. One of the taxonomy types — see [`types.md`](types.md). |
| `title` | recommended | scalar | Human label. Defaults to filename if absent. |
| `description` | recommended | scalar / `>` block | The **relevance hook**. "Use when… / Covers…". ≤2 lines. The single most important field — see KNOWLEDGE.md §4. |
| `tags` | recommended | inline list `[a, b]` | Lowercase, hyphenated. Semantic, for filtering. |
| `status` | recommended | scalar | `active` \| `superseded` \| `retracted` \| `draft`. Default `active`. |
| `timestamp` | recommended | ISO date | Last meaningful update, `YYYY-MM-DD`. |
| `resource` | optional | URI | OKF field: link to the external system this doc mirrors (a dashboard, sheet, console). |

## Tier-2 fields (CB ceiling — additive, optional)

Adding these does not break OKF compatibility (only `type` is required; extra fields
are legal). They light up only for CB-aware tooling.

| Field | Type | Notes |
|---|---|---|
| `id` | scalar `namespace:local` | Stable identity, decoupled from path (survives renames). Required if other docs depend on this one. Shape: `^[a-z][a-z0-9-]*:[a-z0-9-]+$` (e.g. `cb:a131`, `fin:cashflow`, `cb-okf:a004`) — a CB-dialect addition, **not** OKF-native, soft-checked (`id_format_invalid` warns, never fails). The namespace may contain hyphens, matching the artifact-scheme rule. The namespace is a grouping convention, not a registry and not the `type`. See KNOWLEDGE.md §6. |
| `deps` | inline list of ids | Typed dependencies — the load-bearing edges. A `concept` lists the sources/concepts it is synthesized from. |
| `tier` | scalar | `okf` (default) \| `cb`. Marks a doc as governed by CB discipline (immutability, supersession). |
| `kind` | scalar | CB sub-classification (e.g. `directive`, `observation`, `verdict`). Closed enum per the host CB graph. |
| `supersedes` / `superseded_by` | id | Dated supersession chain. Set `status: superseded` alongside `superseded_by`. |
| `artifact` | URI | CB provenance carrier for `source`/`thread` docs: `gmail:…`, `document:…`, `session:…`, `https:…`. |

## Conventions

- **Dates are absolute.** `2026-06-21`, never "today" / "last week".
- **One concept per file.** If `description` needs an "and", split the file.
- **Filenames** are lowercase-hyphenated; date-prefix time-bound docs (`2026-06-21-slug.md`).
- **Status changes are edits to frontmatter**, not deletions. Retire by setting
  `status: retracted` (OKF floor) or via supersession (CB tier).
