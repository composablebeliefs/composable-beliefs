# cb-id-b-migration: opaque b-serial ids for the cb: graph

Status: executing (2026-07-02)

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

- belief-collections sweep (same rule; verify per-collection serial
  disjointness first).
- codepath:/cb-okf: renumbering plan.
