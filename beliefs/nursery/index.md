---
type: index
title: Nursery
description: Use when orienting to the belief nursery - the floor-tier workspace where proto-belief documents are deliberated in place until they plant into the graph or compost.
tags: [nursery, index]
status: active
timestamp: 2026-07-02
---

# Nursery

The nursery is the floor-tier staging ground for the belief graph: **proto-belief
documents**, deliberated in place until they **plant** into the graph or compost. It is
the cheap, mutable space *before* the expensive, immutable commit of authoring a belief -
so over-decompose freely here.

The unit doctrine (cb:a569, locked verbatim): **One proto-belief document per separable
matter.** Separable means the strands' eventual mint-manifest rows stand on independent
argument; strands whose rows need each other's reasoning share a document. Split and
merge are cheap before the gate; the boundary only turns costly at mint. The matter, not
the session, is the unit: a conversation touches several proto-beliefs and updates
whichever documents it concerns; each persists and accretes across conversations
(cb:a475's atomicity one level up).

Naming (cb:a569, [proto-belief-rename](proto-belief-rename.md)): focus, seed (for
documents), brief, and plan are retired, with no informal registers - mood is carried
only by the structural type system. Threads keep "seed" informally: they are the seed
bed ideas germinate in.

## Maturity lifecycle

Each proto-belief document carries a `maturity:` field (distinct from OKF `status:`,
which stays a valid enum value, normally `active`):

- **active** - live deliberation, not yet actualized.
- **contested** - actively in conflict with an existing belief or standard (a reopening
  or challenge), not yet resolved.
- **planted** - actualized into one or more beliefs (its mint-manifest rows carry the
  ids; frontmatter carries `minted:`). Graduates to the archive shelf; the beliefs'
  `document:` citations follow via repoint.
- **composted** - deliberated, no belief warranted (fizzled). A true fizzle that nothing
  cites may be deleted (a judgment, not a rule); a *decided-against* plants the negative
  first, then graduates.
- **grafted** - lost a contest or merged into another proto-belief: a dated "rejected: X
  because Y" block folds into the survivor, and the loser graduates carrying its
  grafted-into link - historicized, never deleted.

Verbs: **seed** (start) -> **plant** (into the graph - the wild) | **compost** (drop) |
**graft** (merge).

**Terminal documents graduate; they are never deleted** (contest resolved 2026-07-02,
[seed-lifecycle](seed-lifecycle.md)): historicize (date-stamp, record the terminal
maturity and forward links) and move to the archive shelf (location = Q7, open), with a
`cb.repoint` pass so `document:` citations follow. The document is mandatory provenance -
every belief traces back through it to the thread - so deleting it breaks the chain. A
true fizzle that accreted nothing and that nothing cites may still just be deleted: a
judgment, not a lifecycle rule. The nursery holds only live work because terminal
documents *leave*, not because they die.

## Discipline (what keeps this from becoming a shadow graph)

Validate **format**, never **relations.** The nursery is an OKF bundle - frontmatter and
manifest are checked - but it carries no dep-resolution, staleness cascade, or
conflict-preflight *between* docs. Cross-links are provisional and elevate to real graph
edges only on mint. The graph is the only authoritative structure; the nursery has no
authority, so it cannot drift against the graph - it can only feed it. Active and
contested focuses are the ones to keep visible, the way `mix bs list tag:lifecycle:discrete`
surfaces the desk.

Competing proto-beliefs resolve by **explicit contested-links** (the hard resolution);
**recency is only a soft hint** for which is the live lean - this bundle treats
`timestamp:` as last-edited, provisionally ([seed-recency](seed-recency.md)). Recency
makes staleness visible; it never silently decides.

## Proto-beliefs
- [assertions-rename](assertions-rename.md) - active - removing the dead term "assertions" from cb:a098.
- [structural-type-rename](structural-type-rename.md) - active - rename the four types to nominalized epistemic acts (attestation/aggregation/inference/prescription). Executed 2026-07-01 (PR #1 `be4ee65`, graph `c4940b9`); open residue tracked as cb:a561/cb:a562.
- [contract-predicate-demotion](contract-predicate-demotion.md) - active - drop the redundant contract boolean (derive it) and collapse the c059 carve-out it exposes. Demotion executed 2026-07-01 (`be4ee65`/`c4940b9`); the c059 carve-out decision remains open.
- [negative-case-field](negative-case-field.md) - active - whether to add a negative-case schema field.
- [atomicity-generalization](atomicity-generalization.md) - active - generalizing cb:a475 atomicity to all four types.
- [seed-absorption](seed-absorption.md) - grafted - lost the 2026-07-02 contest to seed-lifecycle; its fold mechanism survives as the graduation step. Historicized in place pending the Q7 archive shelf.
- [seed-lifecycle](seed-lifecycle.md) - active - contest resolved 2026-07-02: terminal proto-belief documents graduate (historicize + archive + repoint), never evacuate-by-deletion; the graduation prescription mints once Q7 names the archive shelf (invisibility requirement attached).
- [seed-recency](seed-recency.md) - active - dating seeds and excerpts to rank competing positions; recency soft, contested-links hard.
- [thread-repo-binding](thread-repo-binding.md) - active - persist each thread in the repo it concerns, set at thread init.
- [statement-provenance](statement-provenance.md) - active - link each thread statement to the artifact it feeds (the back-edge of seeds-carry-excerpts).
- [per-belief-files](per-belief-files.md) - planted - one JSON file per node; minted cb:a554 + the a555-a560 plan.
- [routing-ledger](routing-ledger.md) - active - per-thread dispatch table (topics, strand states, pointers, dangling questions) so a non-linear thread resumes from its ledger, not memory; a router, never a digest. Minted cb:a566; the /decompose skill build stays open.
- [mint-manifest](mint-manifest.md) - active - typed candidate-belief rows inside a maturing brief, the adopted weak form of the rejected typed-nursery-documents proposal; action items are prescription rows. Minted cb:a567.
- [commit-provenance-floor](commit-provenance-floor.md) - active - extending the graph tier's structural commit provenance (c067, Belief: trailers, verify.commits) to floor lifecycle events via Thread:/Focus: trailers. Atomic lifecycle commits adopted 2026-07-02 and minted cb:a568 (one transition per commit, split per focus); trailer vocabulary, enforcement, squash policy, and cadence open.
- [nursery-architecture](nursery-architecture.md) - contested - this model; its "Layer 1 vestigial" lean is decided-against, queued to fold into transcript-format.
- [citation-discipline](citation-discipline.md) - planted - minted as agent-behavior:a411.
- [proto-belief-rename](proto-belief-rename.md) - active - the vocabulary settlement: the artifact is the proto-belief document, focus/seed/brief/plan retired with no informal registers, the split-test unit doctrine, the Proto-Belief: trailer. Minted cb:a569; residual sweep is cb:a570.
- [transcript-format](transcript-format.md) - contested - how transcripts/seeds persist exchanges; the current live reference.

## Subdomains
- [threads/](threads/index.md) - living session transcripts: crash-safe, human-readable, and explicitly **not** provenance (the seeds above are). Captured automatically by a `Stop` hook.
