---
type: concept
title: Per-belief file storage (split beliefs.json into one file per node)
description: Covers the decision to store the graph as one JSON file per belief (a beliefs/cb/a512.json layout) instead of a single array - distinct from the per-entity grouping cb:a112 rejected - the worktree prototype that proved the read path, and the six-step implementation plan that mints from here.
tags: [cb, storage, schema, nursery]
status: active
timestamp: 2026-06-25
maturity: planted
minted: [cb:a554, cb:a555, cb:a556, cb:a557, cb:a558, cb:a559, cb:a560]
threads: [2026-06-23-a0e89dc3]
---

# Per-belief file storage

## The focus
Should the belief graph be stored as **one JSON file per node** (`beliefs/<ns>/<local>.json`,
e.g. `beliefs/cb/a512.json`) instead of the single `beliefs/beliefs.json` array?

## The decision: yes, per-belief files
Per-belief atomic files are preferred over **both** the single-file array **and** per-entity
grouping. This is a refinement of `cb:a112`, not a contradiction of it - see below.

## Why
- **cb:a112 targeted the wrong scheme.** Its "cross-entity composition is the primary value,
  splitting by entity fragments the graph" argues against grouping beliefs *under entities*.
  Per-*node* files do not fragment composition at all: every belief is addressed uniformly and
  composition stays via `deps` (id references resolved into one in-memory map at load). a112's
  objection does not reach this design.
- **Eliminates the `_keys` workaround.** `_keys` exists to make a whole-array rewrite byte-stable
  so untouched records do not churn in git. Per-file writes touch one file - no array, no churn,
  no reason for the workaround.
- **Consistent with CB's own anti-cache stance (`cb:a386`).** A single-file array is the
  cache-shaped artifact the digest antipattern warns against; per-file makes each node the unit.
- **Prepares for a database backend** (one file per node maps to one row/document; the single
  array is the thing you would have to dismantle for a DB anyway).

## The constraint (carry this into the minted belief)
Multi-node writes lose single-file write-atomicity. Today a supersession (write successor + flip
predecessor status) is one atomic tmp+rename; per-file it is N independent writes. Acceptable at
local/single-writer scale (a crash mid-batch is recoverable via re-run or `git restore`), or wrap
in an all-or-nothing write helper (per-file tmp+rename, or temp-dir + directory swap).

## Prototype evidence (worktree `proto/per-belief-files`)
- Split `beliefs.json` into 213 `beliefs/cb/<local>.json` files (canonical `to_map` per node).
- Made `CB.Belief.Store.read` directory-aware (glob + parse, sorted by id).
- The loaded graph was **byte-identical** to the single-file load (8251-line canonical
  serialization, `diff` clean); `mix bs show/stats` and `mix cb.verify.schema` (20 passed,
  0 failed) ran unchanged.
- `CB.Belief.Store` is the near-sole I/O chokepoint; only `Store.read`/`Store.write` touch the
  layout. Three readers bypass it today (`CB.Codepath.Predicates`, `CB.Belief.EditPairs`, the
  `CB.Belief.Adjudication` race-guard re-read) and should be routed through `Store.read` first.

## The plan (mints to directives, dep-chained on the decision)
1. **Centralize I/O** through `CB.Belief.Store` - route the three direct readers through `Store.read`.
2. **`Store.read` directory-aware** - glob `<ns>/<local>.json` sorted by id; single-file fallback for unsplit collections. (Prototype-proven.)
3. **`Store.write` per-file** - write changed, delete removed; choose the atomicity strategy above.
4. **Migration mix task** - split `beliefs.json` into `beliefs/<ns>/<local>.json`, remove the single file.
5. **Simplify `_keys`** - drop the churn-suppression rationale (moot per-file).
6. **Self-description** - regenerate CLAUDE.md, revise "one JSON file" docs, and **supersede `cb:a112`** with the decision belief (deferred to here, so the active graph never claims per-file before the code implements it).

## Mint shape (open - the nursery link mechanism is itself contested)
The decision mints as one belief (primitive/design-observation, refining a112); the six steps mint
as discrete directives dep-chained on it. The seed-to-belief link is undecided between
[seed-absorption](seed-absorption.md)'s `seed` prop (needs a schema change, not yet landed) and a
frozen doc as the `cb:c059` `document:` stipulation artifact. Until that resolves, mint with this
doc as the `document:` artifact and stamp `minted:` here.

## Planted (2026-06-25)
Minted as the decision `cb:a554` (primitive/design-observation) plus six discrete directives
`cb:a555`-`cb:a560` dep-chained on it, surfaced on the desk. Grounded in the `session:` artifact per
the `agent-behavior:a411` precedent (not a `document:` pointer - that mechanism in
`nursery-architecture.md` was aspirational and unimplemented). `cb:a112` is left active; its
supersession is folded into `cb:a560` and lands only when the code does.

## Related
- [seed-absorption](seed-absorption.md) - the alternative link mechanism (fold into a `seed` prop).
- [nursery-architecture](nursery-architecture.md) - the focus-as-unit model this follows.
