# cb-eval - execution transcript

Plans 0-3 executed 2026-06-09/10 in one session. Decisions taken at build time are in
[decisions.md](decisions.md). Nothing is committed; all changes sit in the working
trees of composable-beliefs, belief-collections, and evals.

## Plan-0 - the `method:` base collection (done)

- `belief-collections/method/` authored through the write flow (preflight ->
  `cb.import --write` with `CB_BELIEFS`): 14 beliefs - three enum contracts
  (`method:c1` artifact-scheme, `c2` kind, `c3` domain), five convention primitives
  (`a1` six-subject, `a2` staleness pivot, `a3` tag vocabulary, `a4` llm-judge
  naming, `a5` fixture provenance), six methodology contracts (`c4`-`c9` =
  m-corroboration, m-provenance, m-subjects, m-runs (params min=3, evidence carries
  the N=3 reasoning), m-judge-validation, m-correction), each routed
  `{"when": {"verify": "collection"}, "requires": "<predicate>"}` at first authoring.
- `sdl` re-homed: `depends_on: ["method"]`; `sdl:c1` superseded by `method:c1`
  (cross-namespace, via `CB.Belief.Mutation` supersede); `sdl:a4`/`a5` superseded by
  `sdl:a006` (kind verdict) / `sdl:a007` (kind guidance) via preflight +
  `cb.adjudicate accept_supersede`. README documents the two deliberate
  methodology violations.
- `belief-collections/toy-eval/` (`toy:`): the compliant acceptance fixture - 3 runs
  x 2 rulers, judge-validation record, agreement compound, corroborated verdict, all
  `fixture`-tagged.
- Acceptance: `method` 17/0/1, `sdl` green on schema (kind/domain skips gone),
  `toy` green with zero local schema contracts.

## Plan-1 - collection predicates + method-check (done)

- `lib/cb/predicate_gate.ex`: the shared resolve gate (naming invariant +
  exported-at-arity), extracted from codepath predicates; `CB.Codepath.Predicates`
  delegates with behavior unchanged.
- `lib/cb/eval/predicates.ex`: the six arity-2 predicates over the union; verdict
  convention `true | {false, detail-naming-offending-ids}`; params validated as
  untrusted shape.
- `lib/cb/method/checks.ex`: discovery by rule shape (active contract-grade
  `implies` kind routing on `verify: collection`), `:module` injection, optional
  `params` passthrough.
- Wired into `mix cb.verify.collection` as result rows; no routed contracts -> one
  skip row. `cb.verify.schema` / `cb.verify.codepath` untouched.
- The `cb:c046` params question resolved by reading code: extra rule-entry keys are
  tolerated; documented in the `Implies` moduledoc, **no supersession, no `beliefs/`
  change** (see decisions.md).
- Live results: `toy` passes all six; `sdl` fails exactly m-runs
  (`sdl:a006, 1 run`) and m-judge-validation (`sdl:a2, ruler/llm-judge-vanilla`) -
  the documented teaching gaps - and exits 1.

## Plan-2 - run-manifest + cb.import.eval (done; tier-3 gate open)

- `docs/run-manifest.md`: the version-1 spec, hash-id inputs spec'd exactly
  (`sha256("cb-eval-v1|eval|run|ruler[|case]")`, first 8 hex).
- `lib/cb/eval/manifest.ex`: parse/validate (named errors, version refusal),
  deterministic `to_beliefs/2`, `plan/2` (new / no-op / identity-conflict).
- `lib/mix/tasks/cb.import.eval.ex`: testable `process/2` core; preflights fresh
  observations (contract-level conflicts block); volume warning above 50 beliefs;
  `--write` hands the canonical spec to the existing `cb.import` path.
- Fixture: `test/fixtures/run_manifest_v1.json` (4 runs x 2 rulers x 50 cases,
  6 load-bearing cases -> 8 aggregates + 12 case primitives).
- **Tier 2 closed**: `evals/cb-ledger/` - `task_smoke.py` run 3x under Inspect's
  mockllm (`inspect-ai 0.3.239`, real `.eval` logs), `inspect2manifest.py` adapter
  (forces `fixture` tag for mockllm models), imported into `evals/cb-ledger/collection`
  (`fxm:`), `mix cb.verify.collection fxm --registry evals/cb-ledger/collections.json`
  green including all six method-checks; re-import a detected no-op.
- **Tier-3 path shortened**: `evals/cb-ledger/dag-vs-prose-v2/` scaffolds the
  four-condition study (NEXT_EXPERIMENT.md) plus the flat-bullets control arm
  (condition e): conditions a/b verbatim from purity-test, c/d/e mechanical
  renderings (review c before the real run); nine `llm-judge-*` scorers via the
  grader model role; `sample_judge_validation.py` (sample -> human sheet -> kappa);
  `run.sh <model> [grader] [N] [R=3]`. Plumbing smoke-tested end to end under
  mockllm. Smoke artifacts (`logs-smoke/`, `manifest-smoke.json`,
  `sheet-smoke.json`) are disposable.
- **The mission gate stays open**: one actual finding end to end, with a human
  choosing the eval, the load-bearing cases, and authoring the verdict.

## Plan-3 - cb.render.audit (done)

- `lib/cb/render/audit.ex`: render-neutral tree (`build/3`) with evidence-entry
  artifacts (the `tree`/`show` gap closed), `--cascade` staleness at render time,
  supersession linkage, cross-namespace deps as labeled leaf links, `--depth`
  truncation marks; `to_json/1` (pinned key order) and `to_html/1` (one file,
  inline CSS, **zero JS** - collapse/expand is native `<details>`).
- `lib/mix/tasks/cb.render.audit.ex`: `--collection|--beliefs`, `--out`, `--json`,
  `--depth`, `--date` (omitted by default so re-renders are byte-identical),
  `--check` (CLAUDE.md-style; verified failing on a moved graph).
- Golden tests (`test/fixtures/audit_golden.{json,html}`, regenerate with
  `GOLDEN_UPDATE=1`) gate the committed tree in CI; determinism, escaping, and all
  node roles under test.
- Browser-verified at realistic depth (toy:a9: verdict -> agreement compound -> six
  aggregates with raw-log pointers) and for the correction protocol (sdl:a4: struck
  claim, superseded badge, successor link to sdl:a006).

## Final state

`mix test`: 261 tests, 0 failures. `cb.verify.schema` green; `method`/`toy`/`fxm`
collections verify green including method-checks; `sdl` fails its two documented
checks by design. CLAUDE.md current. tmp/ holds disposable rendered samples
(`audit-*.html`).

## Postscript (2026-06-10): the bench extraction

After committing, the execution infra moved out of `evals/cb-ledger` into its own
sibling repo, **`bench`** - completing the four-repo split (ledger framework /
graph data / execution infra / append-only run archive). Paths above that read
`evals/cb-ledger/...` now live at `bench/...` (adapter at the root, the mockllm
round-trip fixture under `smoke/`, the venv at `bench/.venv`). Revalidated
post-move: adapter output byte-identical, re-import a no-op,
`mix cb.verify.collection fxm --registry ../bench/smoke/collections.json` green.
`evals` remains the archive of executed evals; a bench study that runs for real
lands there as a snapshot.
