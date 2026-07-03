---
type: concept
title: Migrate cb: ids to opaque b-serials
description: Covers retiring the a/c id prefixes for the single opaque b prefix - the letter-swap migration (serials preserved, disjointness-proven), the content-derived legacy alias, single-series minting, the merge-commit-only condition, and the last-alpha-rename closure. Executed 2026-07-02 (PR #10). Minted cb:b566 (the id protocol), cb:b573 (merge-commit only), cb:b574-b576 (the follow-up obligations).
tags: [nursery, cb, schema, id-protocol]
status: active
timestamp: 2026-07-02
maturity: planted
minted: cb:b566
threads: []
---

# cb-id-b-migration: opaque b-serial ids for the cb: graph

Status: executed (2026-07-02, PR #10 merged as eb8cb76). Authored the same day as
plans/cb-id-b-migration/design.md on the cb-schema-v3 precedent, concurrent with
cb:b569 closing the plans/ shelf; re-homed here as a proto-belief document - the
closure's own definition fits it exactly (a plan is a proto-belief document whose
mint-manifest rows are predominantly prescriptions). Import and adjudication records
live in [cb-id-b-migration/](cb-id-b-migration/).

## Motive

The id prefixes `a` and `c` predate schema v3 and are stale twice over:
`a` abbreviated *assertion*, a type name the v3 rename retired, and `c`
encodes contract-grade, which c056 demoted to a derived predicate
("the c-prefix ID convention is a naming reflection of this structural
property, not the definition of contract identity"). A prefix that
carries type or grade semantics is a second copy of a stored field
lodged in the one place that can never be corrected; the v3 rename is
the standing proof that vocabulary changes while identity must not.

The resolution is less semantics in ids, not more: a single opaque
prefix `b` (belief), serial-numbered, carrying nothing.

## Mapping rule

Pure letter-swap, serials preserved:

    cb:aNNN -> cb:bNNN        cb:cNNN -> cb:bNNN

This is collision-free for cb: because the two serial ranges are
disjoint (a098-a565, c026-c067) - verified mechanically before
execution. Serial numbers stay globally unique within the graph, so
every historical reference (`cb:a386` in a chronicle, `a563` in a
commit subject) remains resolvable by the same letter-swap.

## Scope

**Migrated now:** the cb: graph (`beliefs/beliefs.json`,
`beliefs/todos.json`), nursery seed files (living), and the living
docs: README, docs/guide/, the undated docs/ pages, glossary data,
skills/. CLAUDE.md and docs/glossary.md are regenerated, not edited.

**Left as history (the alias covers them):** chronicles/, positions/,
plans/, dated docs, nursery threads/, git history. These reference
cb ids the way commit messages do - as records of what was said at the
time.

**Deferred:** `codepath:` and `cb-okf:` collections and the
belief-collections sibling repo. codepath: and cb-okf: have colliding
a/c serials (`codepath:a001` and `codepath:c001` both exist), so their
migration needs per-collection renumbering and a coordinated sweep of
cross-namespace references - a separate pass. Until then they stay on
legacy ids, which remain fully valid.

## Legacy alias

Resolution-time fallback, derived from graph content so it can never
mis-resolve: when an id lookup fails and the local part matches
`^[ac]\d+$`, retry with the `b` letter-swap. In a migrated graph the
swap finds the renamed node; in an unmigrated graph (codepath:,
cb-okf:, belief-collections) the exact match wins first and the
fallback never fires against a real legacy node. Sites:

- `Graph.resolve_id/2` - CLI input (`mix bs show c051`), archived-doc ids
- dep resolution - cross-namespace deps from unmigrated collections
  (`lib:` nodes depending on `cb:a386`)
- `Commits.dangling_refs/2` - `Belief:` trailers (none exist in history
  yet; the normalization future-proofs the check)

## Minting

`Adjudication.next_id` collapses to a single `b` counter. The max-serial
scan reads `^[abc](\d+)$` so serial uniqueness holds across legacy ids:
minting into an unmigrated graph continues past its a/c serials rather
than restarting at b001 (which the alias would conflate with a001/c001).

## Layers, in commit order

1. **Spec** - this document.
2. **Code** - `normalize_legacy_id/1` + alias fallback at the three
   sites; single-counter minting; `[ac]` -> `[abc]` in the bs command
   regex and the glossary ref regex; delete the c-prefix identity check
   from the schema verifier (finishing what c056 started); refresh
   comments/moduledoc examples in conflict.ex and cb.import.ex; test
   updates. Green against the un-swept graph - the code must not care
   which side of the sweep it runs on.
3. **Data + living docs sweep** - letter-swap of the exact known id set
   (namespaced and bare forms), with guards: tokens preceded by `-` or
   `:` are not bare cb ids (protects artifact slugs like
   `session:2026-05-17-c039-add-definition`, which are proper names of
   historical artifacts, and other collections' ids like
   `codepath:c005`). Regenerate CLAUDE.md and glossary.md. Residual
   `[ac]\d+` occurrences reviewed by hand.
4. **Verify** - mix test, cb.verify.schema, cb.verify.commits,
   cb.generate.claude_md --check, bs smoke tests including legacy-alias
   resolution.
5. **Record** - mint the migration prescription through
   preflight/import: ids are opaque b-serials from here forward, the
   prefix carries no semantics, legacy [ac] ids resolve by letter-swap,
   and no future alpha-rename (this one worked only because b-space was
   virgin and no external consumer held references).

## Follow-ups

Minted as desk obligations 2026-07-02: the belief-collections sweep (cb:b574),
the codepath:/cb-okf: renumbering plans (cb:b575), and the true glossary
regeneration (cb:b576).

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | Ids are opaque b-serials; the prefix carries no semantics; legacy [ac] ids resolve by the letter-swap alias, exact matches first; no future alpha-rename. | cb:b056, cb:b398 | commit:a5607fb191a4beb8558f0e03e33ad99ce527c26b | cb:b566 |
| prescription | Merge-commit only: squash and rebase merging prohibited and disabled in settings; both rewrite merged SHAs, severing commit: citations and Belief: trailers on fresh clones. | cb:b563, cb:b566, cb:b568 | user:mark:2026-07-02 | cb:b573 |
| prescription (action-item) | Sweep belief-collections to b-serials: per-collection disjointness check, letter-swap where disjoint, renumber where not; verify each namespace against the migrated graph. | cb:b566 | document:beliefs/nursery/cb-id-b-migration.md | cb:b574 |
| prescription (action-item) | Renumbering plans for codepath:/cb-okf: - colliding a/c serials, no alias for renumbered ids, single-pass reference sweep. | cb:b566 | document:beliefs/nursery/cb-id-b-migration.md | cb:b575 |
| prescription (action-item) | Regenerate docs/glossary.md properly once the belief-collections registry is available, restoring the generated-not-edited invariant. | cb:b566 | document:beliefs/nursery/cb-id-b-migration.md | cb:b576 |
