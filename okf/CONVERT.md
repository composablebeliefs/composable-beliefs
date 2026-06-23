# CONVERT — migrating an existing knowledge store to this format

You are an agent told: *"convert this existing knowledge store to this format."* The
store may be ad-hoc markdown, a `plan.md`/`DESIGN.md` sprawl, a notes folder, a JSON
belief file, or some mix. Convert **without losing provenance** and **without inventing
rigor that wasn't there.**

**Each mutating step ends in a gate you run — do not proceed past a failing gate.**
Self-verification commands (no tooling is copied into the target repo — run the
`mix okf.*` tasks from the `composable-beliefs` repo root against the bundle path):

```
mix okf.manifest <root>   # (re)generate <root>/manifest.json
mix okf.validate <root>   # exit 0 = pass; FAIL: lines stop you
```

## 0. Read the spec
[`standard/KNOWLEDGE.md`](standard/KNOWLEDGE.md), then [`standard/types.md`](standard/types.md) and
[`standard/tiers.md`](standard/tiers.md).

**Gate (self-check):** you must be able to name which artifact kinds map to which `type`,
and the rule for what stays on the OKF floor. If not, re-read `types.md`/`tiers.md`.

## 1. Snapshot, then inventory (transform comes later)
First ensure the original is recoverable: confirm the store is committed in git (or copy
it aside). Then walk it and record, for each artifact: current path, what it actually is,
and target `type`. Write the inventory as a `type: analysis` doc in `<root>/meta/` so the
conversion itself is provenanced.

Common mappings:
| You find | Maps to |
|---|---|
| `README.md`, runbooks, how-tos | `reference` |
| `plan.md`, `USER_STORIES.md`, roadmap | `plan` |
| dated `analyses/*.md`, investigations | `analysis` |
| ingested articles, transcripts, statements | `source` (immutable) |
| pages about an entity/topic, synthesized notes | `concept` |
| settled decisions, ADRs | `position` |
| session logs, chat exports | `thread` |
| a JSON belief/assertion file | keep as CB store; **emit** `concept`/`source` docs from it (see §4) |

**Gate:** `git status` shows the original tracked/clean (recoverable), and the inventory
doc exists. Do not edit any source file until both are true.

## 2. Add the frontmatter spine, don't rewrite bodies
For each file: prepend the spine (`type`, `title`, `description`, `tags`, `status`,
`timestamp`). **Write a real relevance hook for `description`** (≥20 chars, "Use when…")
— the highest-value part of the conversion. Preserve original dates in `timestamp`. Leave
body content intact unless a file mixes types — then split it.

**Gate (incremental):** after converting each batch,
`mix okf.manifest <root> && mix okf.validate <root>` and clear every `FAIL:`. The validator
catches the conversion's typical misses: missing `type`, vague/short `description`,
leftover `<placeholder>`, bad `timestamp`, broken cross-link.

## 3. Preserve provenance
- A file that was an immutable capture → `type: source`; **stop editing its body**.
- Deep history stays in git: the conversion is a commit, so `git log` preserves the past.
- Convert ad-hoc cross-references into markdown links to the new paths. (The validator
  fails on any link whose target file doesn't exist — use it to find the ones you missed.)

**Gate:** `mix okf.validate <root>` reports **zero** `broken link` failures.

## 4. Decide the tier per document (default: floor)
Everything lands on the **OKF floor** unless [`standard/tiers.md`](standard/tiers.md)'s boundary
test trips; only then add `tier: cb`, `id`, `deps`. If the source was already a CB/belief
graph (e.g. `assertions.json`), **keep it as the canonical store and emit an OKF
projection** (each belief → a typed `concept` doc; `deps` → cross-links + `deps`
frontmatter). Don't flatten a belief graph into prose and lose the edges.

**Gate:** for every `tier: cb` doc, `mix okf.validate` confirms it has an `id` and ids are
unique (it FAILs otherwise). Cross-bundle `deps` may show as `WARN` — that's expected.

## 5. Final manifest + acceptance test
```
mix okf.manifest <root> && mix okf.validate <root>
```
Must exit 0. Then pick **three** task-shaped questions a future agent might ask, and
confirm each is answerable from `manifest.json` + at most two docs. If not, the
`description`s are too vague — fix them, not the bodies, and re-run.

## 6. Report
Summarize: counts by `type`, what stayed floor vs went CB, anything you could not place
(flag for the human), the new entry `index.md`, and confirmation that `mix okf.validate` exits
0. Note that the original remains in git history for any unconverted detail.
