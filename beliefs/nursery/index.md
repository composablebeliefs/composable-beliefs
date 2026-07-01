---
type: index
title: Nursery
description: Use when orienting to the belief nursery - the floor-tier workspace where focuses (proto-beliefs) are deliberated in place until they mint into the graph or are dropped.
tags: [nursery, index]
status: active
timestamp: 2026-06-26
---

# Nursery

The nursery is the floor-tier staging ground for the belief graph: one document per
**focus** (a single question or proto-belief), deliberated in place until it **mints**
into a belief or is dropped. It is the cheap, mutable space *before* the expensive,
immutable commit of authoring a belief - so over-decompose freely here. The boundary to
premature decomposition is cheap to hit (merge = concatenate-and-delete) and only turns
costly at the mint gate, where a wrongly-split belief needs a supersession.

The unit is the **focus, not the session.** A conversation touches several focuses and
updates whichever docs it concerns; the focus persists and accretes across conversations.
This is the atomicity doctrine (`cb:a475`) applied one level up: a single doc holding
several separable focuses is a mis-authored bundle, split at authoring time.

## Maturity lifecycle

Each focus (a **seed**) carries a `maturity:` field (distinct from OKF `status:`, which
stays a valid enum value, normally `active`):

- **active** - live deliberation, not yet actualized.
- **contested** - actively in conflict with an existing belief or standard (a reopening
  or challenge), not yet resolved.
- **planted** - actualized into a belief. The seed's gestation folds into a `seed` prop
  on the belief and the doc evacuates the nursery; carries `minted: <belief-id>`.
- **composted** - deliberated, no belief warranted (fizzled); the doc evacuates. A seed
  that reached an explicit *decided-against* plants the negative first, then evacuates.
- **grafted** - lost a contest or merged into another seed: it folds into the survivor as
  a dated "rejected: X because Y" block and evacuates - no lingering superseded doc, no
  pointer-stub.

Verbs: **seed** (start) -> **plant** (into the graph - the wild) | **compost** (drop) |
**graft** (merge).

**No tombstones.** Every terminal seed folds into its successor (plant -> belief, contest
-> winner) or evacuates as a fizzle; the nursery only ever holds live work. The fold
mechanism and its persist-raw safety condition are [seed-absorption](seed-absorption.md).

## Discipline (what keeps this from becoming a shadow graph)

Validate **format**, never **relations.** The nursery is an OKF bundle - frontmatter and
manifest are checked - but it carries no dep-resolution, staleness cascade, or
conflict-preflight *between* docs. Cross-links are provisional and elevate to real graph
edges only on mint. The graph is the only authoritative structure; the nursery has no
authority, so it cannot drift against the graph - it can only feed it. Active and
contested focuses are the ones to keep visible, the way `mix bs list tag:lifecycle:discrete`
surfaces the desk.

Competing seeds resolve by **explicit contested-links** (the hard resolution); **recency is
only a soft hint** for which is the live lean - this bundle treats `timestamp:` as
last-edited, provisionally ([seed-recency](seed-recency.md)). Recency makes staleness
visible; it never silently decides.

## Focuses
- [assertions-rename](assertions-rename.md) - active - removing the dead term "assertions" from cb:a098.
- [structural-type-rename](structural-type-rename.md) - active - rename the four types to nominalized epistemic acts (attestation/aggregation/inference/prescription). Executed 2026-07-01 (PR #1 `be4ee65`, graph `c4940b9`); open residue tracked as cb:a561/cb:a562.
- [contract-predicate-demotion](contract-predicate-demotion.md) - active - drop the redundant contract boolean (derive it) and collapse the c059 carve-out it exposes. Demotion executed 2026-07-01 (`be4ee65`/`c4940b9`); the c059 carve-out decision remains open.
- [negative-case-field](negative-case-field.md) - active - whether to add a negative-case schema field.
- [atomicity-generalization](atomicity-generalization.md) - active - generalizing cb:a475 atomicity to all four types.
- [seed-absorption](seed-absorption.md) - active - every terminal seed folds into its successor and evacuates (plant -> belief, contest -> winner).
- [seed-recency](seed-recency.md) - active - dating seeds and excerpts to rank competing positions; recency soft, contested-links hard.
- [thread-repo-binding](thread-repo-binding.md) - active - persist each thread in the repo it concerns, set at thread init.
- [statement-provenance](statement-provenance.md) - active - link each thread statement to the artifact it feeds (the back-edge of seeds-carry-excerpts).
- [per-belief-files](per-belief-files.md) - planted - one JSON file per node; minted cb:a554 + the a555-a560 plan.
- [nursery-architecture](nursery-architecture.md) - contested - this model; its "Layer 1 vestigial" lean is decided-against, queued to fold into transcript-format.
- [citation-discipline](citation-discipline.md) - planted - minted as agent-behavior:a411.
- [transcript-format](transcript-format.md) - contested - how transcripts/seeds persist exchanges; the current live reference.

## Subdomains
- [threads/](threads/index.md) - living session transcripts: crash-safe, human-readable, and explicitly **not** provenance (the seeds above are). Captured automatically by a `Stop` hook.
