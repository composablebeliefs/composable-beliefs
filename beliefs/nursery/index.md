---
type: index
title: Nursery
description: Use when orienting to the belief nursery - the floor-tier workspace where focuses (proto-beliefs) are deliberated in place until they mint into the graph or are dropped.
tags: [nursery, index]
status: active
timestamp: 2026-06-25
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
  on the belief and the doc evacuates the nursery (mechanism under decision in
  [seed-absorption](seed-absorption.md)); carries `minted: <belief-id>`.
- **composted** - deliberated, no belief warranted (fizzled); terminal. A seed that
  reached an explicit *decided-against* plants the negative instead.
- **grafted** - merged into another seed; carries a forward pointer to it.

Verbs: **seed** (start) -> **plant** (into the graph - the wild) | **compost** (drop) |
**graft** (merge).

## Discipline (what keeps this from becoming a shadow graph)

Validate **format**, never **relations.** The nursery is an OKF bundle - frontmatter and
manifest are checked - but it carries no dep-resolution, staleness cascade, or
conflict-preflight *between* docs. Cross-links are provisional and elevate to real graph
edges only on mint. The graph is the only authoritative structure; the nursery has no
authority, so it cannot drift against the graph - it can only feed it. Active and
contested focuses are the ones to keep visible, the way `mix bs list tag:lifecycle:discrete`
surfaces the desk.

## Focuses
- [assertions-rename](assertions-rename.md) - active - removing the dead term "assertions" from cb:a098.
- [negative-case-field](negative-case-field.md) - active - whether to add a negative-case schema field.
- [atomicity-generalization](atomicity-generalization.md) - active - generalizing cb:a475 atomicity to all four types.
- [seed-absorption](seed-absorption.md) - active - planted seeds fold into a `seed` prop on the belief.
- [nursery-architecture](nursery-architecture.md) - contested - this model; conflicts with the OKF transcript-pair rule (path 1 chosen).
- [citation-discipline](citation-discipline.md) - planted - minted as agent-behavior:a411.
- [transcript-format](transcript-format.md) - contested - how transcripts/seeds persist exchanges; reverses the .sessions gitignore call.

## Subdomains
- [threads/](threads/index.md) - living session transcripts: crash-safe, human-readable, and explicitly **not** provenance (the seeds above are). Captured automatically by a `Stop` hook.
