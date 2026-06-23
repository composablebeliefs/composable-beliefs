# Plan: Fold the `knowledge` standard into composable-beliefs as the `okf:` extension

> Persisted 2026-06-22 from the knowledge-repo audit/collapse session. SSOT for the
> *intent* is the desk directive `cb:a546`; this file is the detailed reference. Per the
> "plans encode intent, not implementation" doctrine, an executing agent must re-assess
> current state against the live tree and regenerate the sequence — do not replay these
> steps blindly.

## Context

After the Elixir-only collapse, all of `knowledge`'s executable tooling already lives in
`composable-beliefs` (`mix knowledge.*`, `lib/cb/knowledge/*`), and the `knowledge:` belief
graph is already a CB collection (`depends_on: cb`). So `knowledge` is, in fact, **CB's OKF
integration extension** — only its spec docs + conformance corpus + belief graph still sit in
a separate repo. That separateness buys conceptual cleanliness the operator no longer values
(no distribution intent) and costs a real operational seam: the CLAUDE.md / graph session-start
discipline doesn't cross the repo boundary, which is why the thread-persistence policy
(`cb:a540`) wasn't surfaced to a fresh agent.

Decision: **fold the standard into `composable-beliefs/okf/`** (mirroring the in-repo `codepath/`
collection precedent), keep the conceptual line as a **namespace** (`cb:` vs the renamed `okf:`)
rather than a repo, and decommission the `knowledge` repo. Net: one repo, one CLAUDE.md/session
discipline, no `../knowledge` cross-repo paths, and "knowledge" freed as the generic word for the
bundles built with the standard (future KBs get their own namespace, `depends_on: okf, cb`).

## Target structure

```
composable-beliefs/
  okf/                         <- the standard, beside the tooling that implements it
    beliefs.json  manifest.json    (okf: collection; namespace renamed knowledge -> okf)
    standard/ conformance/ templates/ demo/ meta/
    README.md  ADOPT.md  CONVERT.md  CLAUDE.md   (okf/ entry doc; hand-written for now)
  lib/cb/knowledge/…  lib/mix/tasks/knowledge.*   (unchanged — tool/module names stay)
  test/cb/okf_conformance_test.exs                (renamed; resolves local okf/conformance)
  plans/okf-fold/                                 (this plan + the execution transcript)
belief-collections/collections.json               ("knowledge" -> "okf"; path -> ../composable-beliefs/okf/beliefs.json)
```

Naming: namespace **`okf:`** (operator-chosen; `okfx:` is the honest alternative since it
extends OKF rather than being OKF). Mix task/module names (`mix knowledge.*`, `CB.Knowledge.*`)
stay this pass — cosmetic, large churn; optional later rename.

## Phases

### A. Move the tree
`git mv` the `knowledge` repo contents into `composable-beliefs/okf/`:
`standard/ conformance/ templates/ demo/ meta/ beliefs/ README.md ADOPT.md CONVERT.md CLAUDE.md`.
Drop `knowledge/.git` and `.gitignore`. Internal relative links survive (the tree moves together).
History: simplest is a plain move (knowledge's git history dropped; the design narrative survives
in `meta/` + `meta/sessions/*.jsonl`). Use `git subtree add` if commit history must be preserved.

### B. Namespace rename `knowledge:` -> `okf:` (write-flow, no hand-edit)
No rename task exists (only `cb.repoint`, deps not ids), so migrate by **re-import into a fresh
collection**: seed `okf/manifest.json` (`namespace: okf`, description with the `amieval/knowledge`
self-reference removed) + `okf/beliefs.json` (`[]`), then `mix cb.import` the 5 beliefs with ids
re-prefixed `knowledge:aNNN -> okf:aNNN` and the internal dep updated (`a004.deps: [knowledge:a003]
-> [okf:a003]`). Verify `mix cb.verify.collection okf`. Local parts (`a001…a005`) preserved.

### C. Rewire couplings
- `belief-collections/collections.json`: key `"knowledge"` -> `"okf"`, path -> `"../composable-beliefs/okf/beliefs.json"`.
- `test/cb/knowledge_conformance_test.exs` -> `okf_conformance_test.exs`; resolve the corpus from
  the **local** `okf/conformance` (drop the `KNOWLEDGE_REPO`/`../knowledge` sibling default).
- `lib/cb/knowledge/frontmatter.ex:7` docstring still cites the deleted `tools/build_manifest.py`
  "in the knowledge standard repo" — update to `okf/`.

### D. Doc reconciliation
- `okf/CLAUDE.md`, `ADOPT.md`, `CONVERT.md`: collapse rewrote these to "run mix from
  `composable-beliefs/` against `../knowledge/<bundle>`" -> "run mix from the repo root against
  `okf/<bundle>`".
- `okf/README.md` + `okf/CLAUDE.md`: reframe "separate standard repo / sibling composable-beliefs
  checkout" -> "the OKF integration extension within composable-beliefs."
- **Manifest bespoke-ness:** add one line to `standard/KNOWLEDGE.md` §5 — the generated
  `manifest.json` is *this standard's addition* (the agent index), **not** OKF-native (OKF's entry
  mechanism is `index.md`). Currently only implied by omission from the lineage table.
- `composable-beliefs/CLAUDE.md` "Collections" section: note the `okf:` collection if enumerated.

### E. Dangling `cb:` evidence pointers (light touch)
Active `cb:` beliefs carry `document:../knowledge/...` evidence (`beliefs.json` ~6430, 7733, 7813,
7840). These are **provenance, not deps** (`cb:a540`), and immutable beliefs aren't rewritten.
Leave as historical, OR append a corrective pointer via `mix cb.evidence <id> --detail "moved to
okf/" --artifact document:okf/standard/types.md --write`. Never hand-edit. (`document:` per `cb:c066`
is repo-relative, so `../knowledge/...` already escaped the repo; `okf/...` is more conformant.)

### F. Decommission
Remove the `knowledge` repo directory once the move is verified and committed.

## Out of scope (recommended follow-ups)
- **SessionStart hook** + an `amieval/` root `CLAUDE.md` carrying the cb session-start discipline —
  the *structural* surfacing fix (the fold only makes the right CLAUDE.md load). Relates to `cb:a543`.
- **`okf:a004`** (graph-compile `okf/CLAUDE.md`); `mix knowledge.* -> mix okf.*` rename.

## Verification (from the composable-beliefs repo root)
1. `mix compile` clean.
2. `mix test` green — incl. renamed `okf_conformance_test.exs` (13 fixtures) + `knowledge_test.exs`.
3. `mix cb.verify.collection okf` + `mix cb.verify.schema` clean; `mix bs show okf:a003` resolves.
4. `mix knowledge.validate okf/demo` -> 0; `mix knowledge.manifest okf/meta && mix knowledge.validate okf/meta` -> 0.
5. `mix knowledge.emit /tmp/okf-out && mix knowledge.validate /tmp/okf-out` -> green.
6. `grep -rn "\.\./knowledge\|amieval/knowledge\|knowledge:a" composable-beliefs belief-collections`
   returns only intentional historical evidence (or none).
7. `okf/README.md` links resolve; no `knowledge:` ids remain in the okf collection.
