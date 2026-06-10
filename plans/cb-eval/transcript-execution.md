# Transcript - cb-eval execution (plans 0-3, the bench extraction, the README sweep)

**Date:** 2026-06-09/10
**Surfaces:** a single composable-beliefs TUI thread (Fable 5), receiving the plan set
inline from the user, persisting it, and executing it end to end - then carrying the
follow-on restructure (the `bench` repo extraction) and the four-repo README sweep the
same thread produced.
**Companion to:** the [`cb-eval`](README.md) plan set and [`decisions.md`](decisions.md)
(the build-time decision record). Where decisions.md records what was chosen, this
records how the build went and what it surfaced.

> User turns are verbatim (they were short, except the three answers, which are
> summarized in decisions.md). Assistant turns are condensed to their substance: what
> was read, what was decided, what was written, what went wrong, and the commits. Tool
> output is summarized, not reproduced.

---

## Summary

One session executed the entire plan set: plan-0 (the `method:` base collection, the
`sdl` re-homing, the `toy:` compliant fixture), plan-1 (collection predicates + the
method-check pass), plan-2 (the run-manifest spec, `cb.import.eval`, the Inspect
adapter, and a genuine-mockllm tier-2 round trip), and plan-3 (`cb.render.audit`,
browser-verified). The same thread then answered "what did this build," surfaced the
archive/infra identity question, extracted the execution infra into the new sibling
`bench` repo (completing the four-repo split), and rewrote all four READMEs with the
worked example's transcripts re-run against the re-homed graph.

Commits: composable-beliefs `08487b6` (plans 0-3), `68efe81` (transcript postscript),
`5d87145` (README); belief-collections `8813550` (method/sdl/toy), `0e1942b` (README);
evals `4e9e4ce` (cb-ledger, later moved), `098341a` (move to bench), `0deaa63` (README);
bench `73d519b` (initial, extracted), `1191998` (README). 261 tests green throughout;
every graph write through the flow; no `beliefs/` (cb graph) modification anywhere.

### What landed, per plan

- **Plan-0.** `method:` authored through the write flow (preflight ->
  `cb.import --write` under `CB_BELIEFS`): three enum contracts (`c1` artifact-scheme,
  `c2` kind, `c3` domain), five convention primitives (`a1` six-subject, `a2`
  staleness pivot, `a3` tag vocabulary, `a4` llm-judge naming, `a5` fixture
  provenance), six methodology contracts (`c4`-`c9`) with routing rules authored in
  from the start and `m-runs` carrying `params: {min: 3}` plus the N=3 reasoning as
  evidence. `sdl` re-homed: `depends_on: ["method"]`; `sdl:c1` superseded
  cross-namespace by `method:c1` via `CB.Belief.Mutation`; `sdl:a4`/`a5` superseded by
  `sdl:a006` (verdict) / `sdl:a007` (guidance) via preflight + `cb.adjudicate
  accept_supersede`; README names the two deliberate violations. `toy:` authored as the
  compliant, fully `fixture`-tagged acceptance fixture. All three verify green on
  schema checks; `sdl`'s old kind/domain skips disappear.
- **Plan-1.** `CB.PredicateGate` extracted as the shared resolve gate (codepath
  predicates delegate, behavior unchanged); `CB.Eval.Predicates` (arity-2, verdict
  convention `true | {false, detail-naming-ids}`); `CB.Method.Checks` (discovery by
  rule shape - active contract-grade `implies` kind routing on
  `{"verify": "collection"}` - with `:module` injection and `params` passthrough);
  wired into `cb.verify.collection` as result rows, skip row when nothing routes.
  `cb:c046` untouched: the params question resolved by reading code (below). Live:
  `toy` passes all six; `sdl` fails exactly m-runs and m-judge-validation, exit 1.
- **Plan-2.** `docs/run-manifest.md` (hash inputs spec'd exactly:
  `sha256("cb-eval-v1|eval|run|ruler[|case]")`, first 8 hex); `CB.Eval.Manifest`
  (named errors, version refusal, deterministic `to_beliefs/2`, `plan/2` partitioning
  new/no-op/identity-conflict); `Mix.Tasks.Cb.Import.Eval` (testable `process/2`,
  preflight on fresh observations, volume warning >50, `--write` hands the canonical
  spec to `cb.import`). Committed fixture manifest (4 runs x 2 rulers x 50 cases, 6
  load-bearing -> 8 aggregates + 12 case primitives). Tier 2 closed for real:
  `inspect-ai` installed, a trivial task run 3x under `mockllm`, the genuine `.eval`
  logs adapted by `inspect2manifest.py` and imported into the `fxm:` collection -
  verify green including all six method-checks, re-import a detected no-op. Tier-3
  path shortened: the `dag-vs-prose-v2` scaffold (five conditions including the
  flat-bullets control, nine `llm-judge-*` scorers via the grader model role, the
  judge-validation sampler with kappa scoring, `run.sh <model> [grader] [N] [R=3]`),
  plumbing smoke-tested end to end under mockllm.
- **Plan-3.** `CB.Render.Audit` (render-neutral tree with evidence-entry artifacts -
  the `tree`/`show` gap closed - cascade staleness at render time, supersession
  linkage, cross-namespace deps as labeled leaf links, depth truncation marks);
  `to_json/1` with pinned key order; `to_html/1` as one self-contained file with
  inline CSS and **zero JS** (native `<details>`); the mix task with
  `--collection|--beliefs/--out/--json/--depth/--date/--check`. Golden tests
  (`GOLDEN_UPDATE=1` to regenerate) gate determinism in CI; `--check` verified failing
  on a moved graph; browser-verified at realistic depth (toy:a9) and for the
  correction protocol (sdl:a4 struck, successor-linked).

### What execution surfaced that the plans had not

- **The `params` question resolved on the "document" branch.** Plan-1 said decide by
  reading `CB.Belief.Contract.Implies`, not by assumption. The catalogue's `implies`
  row declares `required_rule_fields: ["when", "requires"]` - a required list, not a
  closed set - and the interpreter reads nothing else, so the optional `params` key
  needed a moduledoc note, not a `cb:c046` supersession. Zero `beliefs/` changes in
  the whole set.
- **A discovery hazard in `Implies.applicable/2`.** Enum-registry rule entries
  (`{"field", "values"}`) decompose under the implies interpreter to
  `%{when: %{}, requires: nil}` - and an empty `when` matches *any* fields map, so
  naive role discovery over a union would route nil predicates off every enum
  contract. The method-check pass therefore filters on the catalogued kind
  (`kind == "implies"`) before asking `applicable/2`. Same hazard is latent in any
  future rule-shape-based discovery.
- **Re-homing has a vocabulary consequence the plan's letter missed.** Once `sdl`
  borrowed `method:`'s kind enum, its `kind: "policy"` verdicts became enum
  violations - the methodology contracts key on `kind: verdict`. So plan-0 step 3
  grew two adjudicated supersessions (`a4 -> a006` verdict, `a5 -> a007` guidance):
  re-kinding is a structural change, claims carried verbatim.
- **Cross-namespace supersession just works.** `sdl:c1 -> method:c1` needed no tooling
  change: `superseded_by` is a plain string the verifier checks for non-emptiness, and
  the union loader has both nodes. `CB.Belief.Mutation`'s `supersede` applied it with
  a dated evidence entry.
- **Adjudication ids are zero-padded into unpadded collections.** The generator
  produced `sdl:a006`/`sdl:a007` next to `a1`-`a5`. Cosmetic, accepted; noted in case
  id aesthetics ever matter.
- **The user's three answers reshaped acceptance more than the plans did** (full
  reasoning in decisions.md): m-runs got N=3 *and* the no-escape-hatch design (the
  kind system is the escape); the real-run gate split into three tiers, making
  "validate the adapter against a log we wrote ourselves" explicitly insufficient -
  hence the mockllm tier; and `sdl` was kept deliberately violating as the failing
  fixture, with the failure named in its README.
- **Tier-2 incidentals.** Python 3.13+ venvs ship their own `.gitignore` (the 219MB
  venv never threatened the evals commit - but stray `__pycache__` `.pyc` files did,
  caught and amended out). The browser extension's navigate tool mangles `file://`
  URLs to `https://file///...`, so the audit-tree browser check ran off a transient
  localhost `http.server`.
- **Two small Elixir teeth.** Sigil delimiters do not nest - a literal
  `(depth limit)` inside `~s(...)` terminated the sigil early (switched to `~s|...|`).
  And byte-stable JSON for the printed import spec required routing generated maps
  through `Belief.from_map |> to_map` (OrderedObject), since plain-map key order is
  not contractual.
- **Determinism vs. the render date.** A footer timestamp would break byte-identical
  re-renders, so the renderer takes an explicit `--date` and omits it otherwise; the
  importer takes all dates from the manifest's own `date` field, never the clock.
- **The repo-identity question arrived after the build.** The plans put the adapter
  "in the eval repo"; executing that revealed `evals` had two identities (archive of
  executed evals vs. shared infra). The split was decided in-thread: the lab-bench
  metaphor became the `bench` repo, `evals` stayed append-only, and the snapshot
  discipline (copy task files into the archive at run time; `config_digest` pins the
  bench state) became the seam. Post-move revalidation: adapter output byte-identical,
  re-import no-op, `verify.collection fxm` green via the rehomed registry.

### Where the ledger landed

`mix cb.verify.collection sdl` now reports 21 pass / 2 fail / 1 skip - the two
failures being the example's deliberate methodology violations, ids named.
`mix cb.import.eval` round-trips genuine Inspect logs into a verified collection and
detects both re-imports (no-op) and tampering (identity conflict).
`mix cb.render.audit` produces the publishable one-file audit tree with supersession
strike-through and stale badges. **The mission gate stays open by design**: one actual
finding shipped end to end requires the human parts - choosing the eval, judging
load-bearing cases, authoring compounds and verdict, standing behind the result. The
shortest path to closing it is `bench/dag-vs-prose-v2/run.sh` plus judgment (condition
`c` reviewed first).

---

## Thread

**User (opening):** "see this repo, and the following plans. persist these plans
locally so they are part of the record. examine, then build. ask any questions needed"
- followed by the full text of the README and plans 0-3.

**Assistant:** Persisted the five files verbatim as `plans/cb-eval/` (matching the
`plans/cb-codepath/` convention), then examined everything the plans touch: the belief
struct and contract interpreters, `Implies` (spotting that extra rule keys are
tolerated - the plan-1 params answer, settled before building), the verifier's role
discovery, the codepath predicate gate, the collection loader/registry, the write-flow
tasks, the `sdl` collection, and `cb:c046`'s actual rule rows. Asked three questions
(AskUserQuestion): the namespace name (immutable after import), the m-runs house
minimum, and whether a real Inspect run existed for plan-2/3 acceptance.

**User (via answers):** `method`; N = 3 with the full anecdote/signal-noise/floor
reasoning and the no-escape-hatch design note; no real run exists - build on fixtures
but split the gate into three tiers (committed fixtures / a genuine mockllm-produced
Inspect log / the mission gate, which is the human's), tag all synthetic collections
`fixture` in the graph itself, and shorten the human path by scaffolding the
dag-vs-prose-v2 task. (Recorded in full in decisions.md.)

**Assistant (plan-0):** Wrote decisions.md; authored the `method:` import spec (14
beliefs); preflighted against the empty collection and imported under `CB_BELIEFS`;
registered the namespace; `verify.collection method` green with every schema role
discovered from its own contracts. Re-homed `sdl`: manifest deps, `Mutation.supersede`
for the cross-namespace `c1 -> method:c1`, then the full preflight -> `cb.adjudicate
accept_supersede` flow for `a4 -> a006` and `a5 -> a007` (deps re-pointed in the same
batch, so nothing stale at rest). Wrote the sdl README naming the two deliberate
violations. Authored `toy:` as the compliant fixture (3 runs x 2 rulers,
judge-validation record, all `fixture`-tagged). All three collections green.

**Assistant (plan-1, same turn):** Extracted `CB.PredicateGate`; delegated the codepath
resolver through it unchanged; implemented the six arity-2 predicates and the
method-check pass; wired `verify.collection`; documented `params` in the `Implies`
moduledoc. One compile fix (a helper referenced before written). Live result: `toy`
6/6, `sdl` failing exactly m-runs (`sdl:a006`, 1 run) and m-judge-validation
(`sdl:a2`), exit 1 - the failing fixture working as intended.

---

**User:** "proceed"

**Assistant (plan-1 tests, plan-2):** Predicate and checks tests over in-code fixtures
(sdl as the real failing fixture via a registry-conditional integration test); full
suite green. Then plan-2: the format spec, `CB.Eval.Manifest`, `cb.import.eval` with a
testable core, the committed fixture manifest, and tests for idempotence, the
changed-content hard error, and the volume guard.

---

**User:** "proceed"

**Assistant (plan-2 tiers, plan-3):** 250 tests green. Tier 2: installed `inspect-ai`
in a venv, ran the trivial task 3x under `mockllm`, inspected the *real* log structure
before writing `inspect2manifest.py` (the point of the tier), round-tripped into the
`fxm:` collection - verify green including all six method-checks, re-import a no-op.
Scaffolded `dag-vs-prose-v2` from the v1 study materials (conditions a/b verbatim;
c/d/e mechanical renderings; nine `llm-judge-*` scorers; the validation sampler;
shellcheck-clean `run.sh`), smoke-tested under mockllm. Then plan-3: the renderer, the
task, golden tests, the `--check` failure path verified live, and the browser check
(toy:a9 at realistic depth; sdl:a4 wearing its strike-through and successor link).
Persisted the execution transcript; updated memory.

---

**User:** "ok. was this towards building out eval capability?"

**Assistant:** Yes - to one specific side: the ledger (everything after a harness
runs), deliberately not the lab bench. The two execution-leaning pieces (adapter, v2
scaffold) live outside CB, parked one command from a real run. The findings capability
still needs the human parts - the open mission gate.

**User:** "you are suggesting 'commit this across the three repos' - what three repos?"

**Assistant:** Clarified (and noted nothing had been committed, per policy):
composable-beliefs (code + plans), belief-collections (method/sdl/toy + registry),
evals (cb-ledger infra + round-trip artifact), each its own git repo.

**User:** "go ahead and commit all three"

**Assistant:** Three commits (`08487b6`, `8813550`, `4e9e4ce`), the evals one amended
to evict stray `.pyc` files and gitignore `__pycache__`/smoke artifacts.

---

**User:** "so i had imagined that the evals folder was strictly evals that had been
run, not eval infra. sounds like now it houses eval infra, or whatever you might call
it? should that be its own repo, and then the actually evals being run be a separate
repo?"

**Assistant:** Assessment (no action): `evals` was never purely an archive -
purity-test carried its own bench - but cb-ledger added *shared* infra, which is the
part that does not belong. Recommended the lifecycle split (harness repo / append-only
archive / collections unchanged), the snapshot-at-run-time discipline as the real fix,
and noted the public/private split argues for it too.

**User:** "ok, and to ge clear, is the name for the infra you're creating, or would
create in the other repo, the 'bench'? and it should live seperate from the cb repo as
well?"

**Assistant:** Yes on both: "bench" from the plan set's own "CB is the ledger, not the
lab bench" line; and emphatically separate from cb - that boundary (Elixir/
deterministic vs. Python/model-calling) is the strongest one in the set, coupled only
through the run-manifest. Laid out the four-repo end state and offered the extraction.

**User:** "yes"

**Assistant (the bench extraction):** Created `bench/`, moved the infra with rsync
(excluding caches and smoke artifacts), rehomed paths (`.venv` at the root, the smoke
fixture under `smoke/`), fresh venv, and revalidated everything from the new homes:
adapter byte-identical, re-import no-op, `verify.collection fxm` green via the rehomed
registry, v2 plumbing green, shellcheck clean. Committed bench (`73d519b`); removed
cb-ledger from evals with a "Where the infra lives" README section (`098341a`);
postscripted this transcript (`68efe81`); updated memory. Left the orphaned leftovers
and old 219MB venv for the user to authorize deleting.

**User:** "commit across repos, then run"

**Assistant:** Nothing left to commit (all heads clean); ran the authorized deletion -
`evals/cb-ledger` leftovers and `evals/.venv-inspect` gone, evals tree clean.

---

**User:** "update all of the readmes in each of these repos with comprehensive
documentation covering what has just been done. take pains to not delete any text
already there unless its incorrect or needs writing, instead focus on updating. be
comprehensive but also accessible - make sure to express concepts and not just dense
technical descriptions"

**Assistant (the README sweep):** The cb README's worked example had gone stale with
the re-homing, so every command in it was re-run and its transcripts replaced with
real output: roles discovered from `method:`, the kind/domain skips explained as
history, the two deliberate method-check FAILs narrated as the lesson, the verdict
traced as `sdl:a006`, the supersession chain shown live, and the now-wrong "eval:
scheme stays in sdl:c1" sentence corrected. Added the concept-first "The eval evidence
ledger" section (the trail behind a finding, the ledger/bench boundary, the shape of a
finding, methodology-as-contracts, the run-manifest seam, the audit tree), plus
command-surface and honest-status updates. belief-collections gained the corrected
table and "The eval family" section; bench gained the five-concepts section; evals
gained the snapshot-discipline rationale (why append-only is load-bearing). Verified
the CLAUDE.md gate untouched. Four commits: `5d87145`, `0e1942b`, `1191998`, `0deaa63`.

**User:** "persist this thread along with the plans per convention"

**Assistant:** This file - the execution thread restructured to the
`plans/cb-codepath/transcript-execution.md` convention (summary, what execution
surfaced, the thread with verbatim user turns), superseding the earlier summary-only
form of this transcript.
