# okf-fold — execution transcript

Verbatim record: [`sessions/2026-06-22-okf-fold-execution.jsonl`](sessions/2026-06-22-okf-fold-execution.jsonl)
(byte-for-byte copy of the Claude Code session log, the immutable `type: source` for this
execution session). This file is the readable summary; the `.jsonl` is provenance. Continues
the arc whose design half is [`transcript-design.md`](transcript-design.md).

## Arc

A fresh agent picked up `cb:a546` from the desk and executed `plan:okf-fold` end to end,
re-assessing each step against the live tree (the plan encodes intent, not a script).

1. **Session-start discipline first.** Pulled the three touched repos, queried the desk
   (`mix bs list unlinked tag:lifecycle:discrete`), and bootstrapped from `cb:a546` + `plan.md`
   before touching anything - deliberately avoiding the `agent-behavior:a165` miss (working from
   the prompt instead of the graph).

2. **Namespace decision: `okfx:`, not `okf:`.** The one operator decision the plan left open.
   The operator chose `okfx:` over the plan's recommended `okf:` - honest-about-extending-OKF,
   since the standard's generated `manifest.json` agent-index is a bespoke addition, not
   OKF-native (OKF's entry mechanism is `index.md`). The directory stays `okf/` (mirroring the
   in-repo `codepath/` precedent); only the collection token / ids / `collections.json` key
   become `okfx`.

3. **Phases A-E executed.**
   - **A (move):** the standard tree (`standard/ conformance/ templates/ demo/ meta/` + the four
     entry docs) moved into `composable-beliefs/okf/`, **flat** - `okf/manifest.json` +
     `okf/beliefs.json` at the root, matching `codepath/`, not the old `beliefs/` subdir. The old
     `knowledge/beliefs/` was *not* moved as-is; it sourced the re-import.
   - **B (namespace rename):** no rename task exists, so migrated by re-import into a fresh
     collection. Seeded `okf/manifest.json` (`namespace: okfx`, `amieval/knowledge` self-reference
     removed) + empty `okf/beliefs.json`, then `mix cb.import --write` the 5 beliefs re-prefixed
     `knowledge:aNNN -> okfx:aNNN` with `a004.deps` updated to `[okfx:a003]`. A round-trip check
     confirmed every claim/field preserved verbatim. `a003-a005` (the audit-collapse beliefs) were
     retro-paired with a `document:` pointer to `2026-06-22-knowledge-audit-collapse.jsonl` - the
     deferred pairing that only resolved once the collection moved in-repo.
   - **C (couplings):** `belief-collections/collections.json` key+path -> `okfx ->
     ../composable-beliefs/okf/beliefs.json`; conformance test renamed
     `knowledge_conformance_test.exs -> okf_conformance_test.exs`, now resolving the in-repo
     `okf/conformance` (dropped the `KNOWLEDGE_REPO`/`../knowledge` sibling default);
     `frontmatter.ex` docstring de-staled.
   - **D (docs):** `okf/CLAUDE.md`/`README.md`/`ADOPT.md`/`CONVERT.md`/`conformance/README.md`
     reframed from "separate standard repo / sibling checkout" to "the OKF integration extension
     within composable-beliefs"; mix-command examples re-rooted (`okf/<bundle>`, run from repo
     root); `KNOWLEDGE.md §5` gained the bespoke-not-OKF clarification (and the `okfx:` rationale).
     `meta/` design narrative left historical.
   - **E (dangling pointers):** the 4 cb: beliefs carrying `document:../knowledge/...` evidence
     (`cb:a518`, `a540`, `a543`, `a544`) each got a corrective in-repo `document:okf/...` evidence
     append via `mix cb.evidence` - originals preserved (immutable, never rewritten).

4. **Phase F (decommission) deferred by the operator.** The local `knowledge/` directory was left
   in place (content safe on remote `ob6to8/knowledge@76d1145`) for manual decommission later. Its
   working tree now shows the moved files as deletions - dormant, awaiting that cleanup.

5. **Out-of-scope follow-ups not bundled** (per plan + operator): the SessionStart hook + amieval
   root CLAUDE.md (`cb:a543` family), `okfx:a004` (graph-compile `okf/CLAUDE.md`), and the
   `mix knowledge.* -> mix okf.*` rename. Tool/module names (`mix knowledge.*`, `CB.Knowledge.*`)
   stayed this pass.

## Verification (left green)
`mix test` 360/0 (incl. 13 conformance fixtures + `knowledge_test`); `mix cb.verify.collection
okfx` + `mix cb.verify.schema` clean; `mix knowledge.validate okf/demo` and `okf/meta` exit 0;
`mix knowledge.emit` + validate exit 0; `okf/README.md` links resolve; no structural `knowledge:`
ids in the okfx collection; `mix cb.generate.claude_md --check` current.

## One preserved wart (deliberate)
`okfx:a004`'s claim prose still references its sibling guard as `knowledge:a003` and the file as
`knowledge/CLAUDE.md`. The directive scoped a004's change to "internal dep updated" and said
"local parts a001-a005 preserved," so the authored claim substance was left verbatim rather than
rewritten (which would have cascaded across all five claims). The structural graph (id, deps) is
fully on `okfx:`; the prose reference is intentional historical content. Left for `okfx:a004`'s
own future execution (the graph-compile follow-up) to supersede.
