# Reference

The command surface and the repo layout, at a glance. The narrative treatment of everything here is [the guide](guide/README.md); the schema tables (contract family, artifact schemes, kind-type table) live in [its schema chapter](guide/2-schema.md).

## The command surface

**Read** - the belief shell (`mix bs`, run `mix bs help` for the full set): deterministic, read-only, pure traversal. Every command takes `--beliefs PATH` (or the `CB_BELIEFS` env var) to target another collection; ids may be bare (`b051`) or namespaced (`cb:b051`).

```sh
mix bs list [filters]     # list beliefs (type, status, contracts, unlinked, stale,
                          #   tag:, kind:, domain:, subject_type:, subject queries)
mix bs show <id>          # one belief in full (also the default verb: mix bs <id>)
mix bs tree <id>          # a belief and its dependency context (the audit tree)
mix bs deps <id>          # direct deps (--deep for the full chain)
mix bs dependents <id>    # reverse lookup (--deep for transitive)
mix bs history <id>       # the supersession chain
mix bs stale              # beliefs with superseded/retracted deps (--cascade transitive)
mix bs recent             # graph changes in a window (--days N | --since DATE)
mix bs path <id1> <id2>   # connection between two beliefs
mix bs subjects <ref>     # beliefs by subject
mix bs stats              # graph-level statistics
```

**Author** - the write flow ([guide chapter 3](guide/3-operations.md#the-write-flow); never hand-edit a graph file). All write tasks are dry-run by default and apply only with `--write`.

```sh
mix cb.preflight --file <proposed.json>       # conflict detection (read-only)
mix cb.adjudicate --file <adjudication.json>  # apply a captured human adjudication
mix cb.import <spec.json> [--write]           # batch-import new beliefs
mix cb.import.eval <manifest.json> --collection <path> [--write]
                                              # materialize a run-manifest as observations
```

**The smaller front doors** - sanctioned mutations that need no adjudication:

```sh
mix cb.evidence <id> --detail <text> --artifact <uri>   # append a dated evidence entry
mix cb.todo.close <id> --notes <text> --commit <sha>    # flip a todo open -> done
                                                        #   (--no-commit to record none exists)
mix cb.repoint <id> --from <dep> --to <dep>             # swing a dep to its successor
mix cb.retract <id> --reason <text>                     # retract with date and reason
```

**Verify.** Static (deterministic, no predicate execution): `mix cb.verify.schema` checks one collection against the contracts it carries; `mix cb.verify.collection <namespace>` checks it in the context of its declared dependency collections, including the eval method-check pass; `mix cb.verify.commits` checks the belief-commit provenance loop in both directions. Dynamic (the one place predicates run): `mix cb.verify.codepath [--record]`.

**Resolve** - `mix cb.resolve --file <rows.json>`: draft-mode anchor resolution, validating bare `{path, anchor, nth}` rows with no belief collection loaded (the verification gate for answer-time anchoring and the `/position` skill).

**Render and generate**: `mix cb.generate.claude_md [--check]`, `mix cb.generate.rules`, `mix cb.generate.glossary [--check]`, `mix cb.render.codepath [--json]`, `mix cb.render.audit <id> [--check]`.

**Audit**: `mix cb.audit.conflicts` (the `cb:b055` conflict-scope audit).

**OKF interop** ([guide chapter 5](guide/5-collections.md#the-cb-okf-knowledge-extension)): `mix okf.emit`, `mix okf.ingest`, `mix okf.manifest [--check]`, `mix okf.validate`.

## What is in this repo

- `lib/cb/` - the framework, in layers ([guide chapter 6](guide/6-architecture.md) is the map): the graph layer (struct, store, traversal, filters, conflict preflight, adjudication, mutation), the contract layer (rule-kind interpreters, schema verifier, collection loader, output-target compiler), the codepath layer (locator, anchor resolver, renderer, predicates), the eval layer (run-manifest parser/importer, method checks, audit-tree renderer), the commit-provenance layer, and the OKF bridge. Sole dependency: Jason.
- `beliefs/` - the framework's own self-referential graph (`beliefs.json`, run `mix bs stats` for the live shape), plus the nursery (`beliefs/nursery/`, [guide chapter 3](guide/3-operations.md#the-nursery-where-beliefs-gestate)) and the todo collection.
- `codepath/` - the `codepath:` collection: the belief-pipeline tour that also runs as a test suite.
- `okf/` - the cb-okf knowledge methodology: the standard, its conformance corpus, a demo bundle, and the `cb-okf:` operational graph.
- `skills/` - agent skills for a Claude-Code-style harness: `/assert`, `/assertions`, `/materialize`, `/position`, `/present-codepath`. Symlinked into `.claude/skills/`.
- `docs/` - [the guide](guide/README.md), this reference, the [glossary](glossary.md), the [run-manifest spec](run-manifest.md), the [worked example](worked-example-eval-verdict.md), and the essays and dated analyses.
- `plans/` - design records and executed plans with their transcripts. `chronicles/` - session narratives. `positions/` - anchored stances.
- CI (`.github/workflows/composable-beliefs.yml`) - on every push: the test suite (including an anchor-rot guard against the real source), `cb.verify.schema`, and the CLAUDE.md freshness gate.

## A quick tour

```sh
mix deps.get
mix bs stats              # graph overview
mix bs show cb:b056       # one contract in full (schema discipline)
mix bs tree cb:b056       # a contract and its dependency context
mix bs history cb:b067    # a supersession chain (the artifact-scheme enum)
mix cb.verify.schema      # check the struct against the in-graph schema contracts
mix cb.verify.collection codepath          # a collection + its declared deps
CB_BELIEFS=codepath/beliefs.json mix cb.render.codepath belief-pipeline   # tour the pipeline
CB_BELIEFS=codepath/beliefs.json mix cb.verify.codepath belief-pipeline   # test the pipeline
```

For the guided version, see `../belief-collections/quickstart.md`.
