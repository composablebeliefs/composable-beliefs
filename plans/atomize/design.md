# Atomization migration - descriptive lane

Wholesale decomposition of conjunctive descriptive nodes (attestations and
inferences) into single-sentence atoms, per the primitive atomicity doctrine
(cb:b475) and claim discipline (cb:b402). Operator-authorized departure from
per-node supersession ceremony: this is a structural refactor in the spirit of
the vocabulary migration recorded on cb:b051 (identity and claims preserved,
structure corrected in place), executed as a regenerable parallel graph rather
than an edit to the live store.

## Mechanism

- The judgment lives in `spec.json`: one entry per active descriptive node,
  with a disposition and, for decompositions, the atom claims.
- `mix cb.migrate.atomize` applies the spec to the live graph and emits the
  full migrated graph to `beliefs/cb-atomic/` (dry-run by default; `--write`
  to emit). The live `beliefs/cb/` is never touched. Regenerate at any time;
  the swap is replacing `beliefs/cb/` with the output in one reviewed commit.

## Dispositions

- `aggregate` - the node was a de facto bundle. It keeps its id and claim,
  retypes to `aggregation`, and gains deps on newly minted atoms. Atoms are
  attestations carrying the parent's artifact, kind, domain, tags, and
  subjects (subject containment then holds by construction), one migration
  evidence entry, and `created` = migration date. The parent's original
  evidence entries stay in place as the historical record of the attestation
  event; the parent gains one migration evidence entry naming its atoms.
- `trim` - an inference whose claim restated its deps; the claim is rewritten
  to the conclusion, everything else unchanged.
- `keep` - single assertion, or elaboration rather than conjunction; passes
  through unchanged. Notes record why, and flag follow-ups (b376's missing
  artifact, b401's pending supersession) that are out of this lane's scope.

## Atom ids

Assigned deterministically by the generator: spec nodes sorted ascending, atom
ids allocated sequentially from `id_base` (b700), leaving headroom below for
concurrent live minting. The generator refuses to run if any allocated id
already exists in the live graph.

## Validation (generator-enforced)

- Every active attestation/inference in the live graph has a spec entry.
- Every `aggregate` node has 2+ atoms and an artifact for them to inherit.
- No dependent's deps change; all pre-existing ids survive with claims intact
  (aggregate and keep verbatim, trim excepted).
- Output loads, is a DAG, and passes `mix cb.verify.schema`.

## Prescriptive lane (incremental)

Prescriptions decompose differently and cannot become aggregations (the
b057 mood binding): the claim keeps the norm, enumerable normative content
moves into `invariants` (free-form prose, unlike the interpretable-kind
`rules` DSL, which this migration deliberately does not touch), and
descriptive rationale extracts to atoms appended to the prescription's
deps (`restate` disposition; atoms take `atom_kind`/`atom_artifact` since
prescriptive kinds cannot land on attestations). Unlike the descriptive
lane, coverage is incremental - prescriptions without a spec entry pass
through unchanged - so the tranche can grow spec revision by spec
revision. First tranche: the eleven 5+-sentence claims (7 restates, 1
trim, 3 keeps for discrete work items where decomposition is ceremony;
b545 additionally flagged as likely overtaken by events).

Note for swap time: restates change prescription claims, and some (b587's
Git Policy paragraph) render into CLAUDE.md - regenerate it
(`mix cb.generate.claude_md`) as part of the swap commit.
