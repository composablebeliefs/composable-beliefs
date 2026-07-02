# Docs vs. code audit - 2026-06-23

A point-in-time audit of the `docs/` essays against the actual schema
(`lib/cb/belief.ex`), the mix tasks (`lib/mix/tasks/*.ex`), and the live graph
(`mix bs`). Produced while building the `cb-tut` annotated wiki
(`composablebeliefs/cb-tut`); the full, rendered version is that repo's page 19
(`pages/19-docs-vs-code.html`) and `research/notes/docs-eval.md`. This in-repo copy
is the condensed, resolvable record the desk directive `cb:a553` grounds in.

## Verdict

The executable core is sound. Code, schema contracts, and both CI-gated compiled
`CLAUDE.md` files agree; the risk is to a human learner reading a legacy prose essay
as current, not to the running system.

## The healthy spine (accurate, current)

`eval-ledger.md`, `run-manifest.md`, `codepaths.md`, `mental-model.md`, and
`worked-example-eval-verdict.md` reproduce against the live graph. Both `CLAUDE.md`
files compile from the graph and are CI-gated (`mix cb.generate.claude_md --check`),
so the agent-facing docs cannot silently rot - the `cb:a386` discipline applied to
the docs themselves.

## The drift, in three patterns

1. **Superseded-id rot.** `reference.md` and `mental-model.md` cite `cb:c060` as the
   current CLAUDE-compile contract; it is superseded through `c065`. `belief-graph.md`
   cites `cb:c043` as the artifact-scheme enum; it is superseded by `c066` (which
   dropped `gmail:`).
2. **Legacy essays predating the 2026-06-10 four-type schema and the assertion->belief
   rename.** `actualization.md` (README-linked, undisclaimed) and the thesis body still
   teach the removed three-type "implication" model and a stray `confidence` field.
   `cb-on-the-beam.md` documents nonexistent `bs compose` / `bs relate` verbs and the
   old `assertions.json` filename.
3. **Recency lag / coverage gaps.** `cb.retract`, `cb.repoint`, `cb.resolve`, and the
   entire OKF extension (`okf/` plus the four `okf.*` tasks) have no front-door mention;
   `cb.evidence`, `cb.todo.close`, and `bs recent` are missing from `reference.md`'s
   command surface. A `/assert-session` skill is named in three docs but does not exist.

## Teaching trap

The `cb:` graph has zero compounds (`mix bs list compound` is empty), yet the README,
`mental-model.md`, and the thesis lead with compound examples that live only in the
sibling `sdl` eval collection.

## Suggested fixes

A superseded-id doc-lint; a "predates the four-type schema" banner on the legacy essays
(or a refresh); document `cb.retract` / `cb.repoint` / `cb.resolve` and the `okf.*`
tasks in `reference.md`; and either move the lead compound example to one drawn from an
eval collection or note that `cb:` carries none.

## Postscript (2026-07-02)

The docs consolidation that produced `docs/guide/` addressed the drift above:
the guide replaces `mental-model.md`, `reference.md`, `belief-graph.md`,
`codepaths.md`, `eval-ledger.md`, and `other-applications.md` (now pointer
stubs or v3-refreshed reference), is written in the schema-v3 vocabulary
(attestation/aggregation/inference/prescription), documents `cb.retract` /
`cb.repoint` / `cb.resolve` / `cb.verify.commits` / `bs recent` and the
`okf.*` tasks, drops the nonexistent `/assert-session` reference, and carries
the zero-aggregations caveat. The legacy essays (`actualization.md`,
`cb-on-the-beam.md`) now open with predates-the-schema banners.
