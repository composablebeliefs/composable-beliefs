# Case study: the eval ledger

An application of the substrate: grounding model-evaluation findings in an immutable, traversable graph. A published eval finding - "model X silently drops records from bulk writes" - rests on a trail: how many runs, which scorers, where the raw logs live, whether the LLM judge was validated, whether a correction was visible or a quiet rewrite. The ledger makes that entire trail graph structure: every measurement a belief, every methodological rule a contract, every correction a supersession a reader can see.

Everything here is the general mechanism of the [guide](../guide/README.md) applied to one domain. The application lives mostly in the sibling belief-collections repo (the `method:`, `sdl:`, and `toy:` collections); what lives in this repo is the domain-neutral machinery the application exercises: the importer, the methodology pass, and the audit renderer.

One boundary is held on purpose: **CB is the ledger; the lab bench stays external.** Running evals - orchestration, sampling, retries, model calls - happens in an external harness. CB ingests the harness's *output record* through one neutral format and never grows toward execution.

## Why this domain needs a ledger

The measured failure modes of eval pipelines are structural, which is what makes a structural ledger the right tool:

- **Judges fail systematically.** Swap the order of two answers and most LLM judges flip their verdict in a large fraction of comparisons; pad an answer with information-free repetition and most judges reward it ([Zheng et al. 2023](https://arxiv.org/abs/2306.05685)). Judges measurably favor their own outputs ([Panickssery et al. 2024](https://arxiv.org/abs/2404.13076)), and more than a dozen distinct judge biases are catalogued with effect sizes ([Ye et al. 2024](https://arxiv.org/abs/2410.02736)).
- **Awareness alone does no measurable work.** LLMs exhibit a self-correction blind spot: competent at correcting errors in others' output, failing on identical errors in their own ([Liu et al. 2025](https://arxiv.org/abs/2507.02778)).
- **The mitigations that work are procedures**: swap-and-require-agreement, binary grading against concrete criteria, judge panels, calibration against human labels. Human-subjects research reached the same verdict decades earlier (Meehl's clinical-versus-statistical prediction; Kahneman and Tversky's heuristics-and-biases program): systematic error yields to procedure and structure. The mapping from human biases to LLM failure modes is functional; what transfers is the debiasing logic, and that is the part the ledger encodes as machine-checkable contracts.

## The shape of a finding

A published finding is an evidence chain that exercises all four structural types, with a strict division of labour between machine and human. One term of art: a **ruler** is the ledger's word for a scorer or judge - deterministic differs and LLM judges alike.

- **Observations** (attestations) - what a ruler measured: one aggregate per (run, ruler) pair, plus per-case attestations for the handful of cases that carry the finding. Imported mechanically. Observations are *immutable measurements*: a new model snapshot never supersedes them, because the old snapshot really did behave that way on that day.
- **Cross-ruler agreement** (aggregations) - two independent rulers reached the same outcome; the aggregation asserts the corroboration, which neither observation states alone. Authored by a human. This is where the aggregation type earns its keep ([guide chapter 1](../guide/1-epistemics.md#aggregation-exactly-what-the-deps-say)): six-subject observations pile up, and subject containment has something to bite on.
- **Verdicts** (inferences) - the falsifiable finding, scoped to a `model_version` subject. Authored by a human, and inference-only *by contract*: a verdict must be derived, never merely attested or prescribed. When new snapshot evidence arrives, the verdict is what gets superseded - the staleness pivot - and `--cascade` flags everything downstream for review.
- **Guidance** (prescriptions) - the rule resting on the finding ("do not use unguarded bulk writes..."). Violated or withdrawn, never falsified. The finding and the prescription are separate nodes by design, so a newer snapshot falsifies the verdict without ambiguity about what happens to the rule that rested on it.

The four types as eval roles is the same is/ought machinery from [guide chapter 1](../guide/1-epistemics.md), applied: the clean run kills the generalization while the case-7 observations stay true forever, and the guidance node either follows its verdict into supersession or survives on other grounds - visibly, either way.

## Methodology as contracts that enforce themselves

House methodology usually lives in prose - a METHODOLOGY.md nobody can mechanically check. Here it is six contract-grade beliefs in the shared `method:` collection (in the sibling belief-collections repo), each routing to a named predicate that runs over any eval collection during `mix cb.verify.collection`:

| Contract | What it enforces |
| --- | --- |
| m-corroboration | every verdict reaches a cross-ruler-agreement aggregation, or visibly carries the `single-ruler` escape tag |
| m-provenance | every observation carries an `eval:` identity URI *and* a raw-log pointer in its evidence |
| m-subjects | every observation carries the six conventional subjects (eval, run, case, model, model_version, ruler) |
| m-runs | every verdict cites at least 3 distinct runs - **no escape hatch**: a result that falls short is authored as an observation or guidance instead |
| m-judge-validation | every LLM-judge observation is joined by that judge's human-agreement validation record |
| m-correction | corrections are supersessions with dated evidence; bare retraction is reserved for full withdrawal |

Because these are graph-shape checks, they are pure traversal - deterministic - so they run as a static pass beside the schema checks. A failed check names the offending belief ids: the failure message is the work order. And "methodology v2" is a batch of adjudicated supersessions of these contracts, dated and diffable via `mix bs history`.

## The run-manifest: how harness output becomes ledger input

The seam between bench and ledger is one neutral JSON format, the **run-manifest** ([full spec](run-manifest.md)). A thin adapter per harness converts native logs to it; CB never learns any harness's log format. `mix cb.import.eval <manifest.json> --collection <path> [--write]` validates, generates a spec, preflights each fresh observation, and hands the result to the ordinary import path. Three properties keep the importer mechanical:

- **The aggregation policy is structural.** Every (run, ruler) pair yields one aggregate observation, always; per-case observations are minted only for cases the manifest lists as *load-bearing*. The judgment of what is load-bearing stays upstream with a human; the importer stays mechanical - and warns if a manifest would flood the graph, because the graph must stay human-readable.
- **Identity is hashed, so change is detectable.** Belief ids derive from the observation's identity tuple (eval, run, ruler[, case]). The same manifest re-imported is a detected no-op; a *changed* manifest under the same run id is a hard error - a corrected run gets a new `run_id`.
- **It emits observations only.** The moment an importer authors judgments, the judgment layer has been automated away; the tool's shape enforces the division of labour. One provenance rule rides along: anything derived from synthetic or mock data carries the `fixture` tag, so test scaffolding can never be mistaken for a finding.

## The audit tree: the published artifact

```sh
mix cb.render.audit <verdict-id> --collection <ns> --out audit.html
```

renders a belief's full evidence tree as **one self-contained HTML file**: verdict at the root, deps walked down to leaf observations, every subject, tag, artifact, and evidence entry's raw-log pointer. Superseded nodes render struck-through with a link to their successor; nodes resting on superseded deps carry a `stale` badge; a footer records the union's namespaces and content digest. Zero JavaScript (collapse/expand is native `<details>`), no external assets, no network: a reader needs only a browser. A `--json` twin exposes the same tree as data, and `--check` lets CI gate a committed tree against the graph exactly as CLAUDE.md is gated.

The result: a reader of a published finding can answer "what evidence does this verdict rest on, and where are the raw logs?" by traversal, and a corrected finding *visibly wears* its correction.

## Walk it yourself

The worked example lives in the sibling belief-collections repo as the `sdl:` collection (the silent-data-loss finding) with the small `toy:` collection for self-contained demonstrations, and [the worked-example doc](worked-example-eval-verdict.md) traces a verdict end to end with real command output: from the published finding down to the raw logs, the methodology checks that judge it, and the supersession machinery run for real - including a check *built to fail on purpose*, so you can see what a violation looks like. The short version:

```sh
mix cb.verify.collection toy                                   # schema checks + all six method checks
mix cb.render.audit toy:a10 --collection toy --out audit.html  # a verdict's evidence tree as one file
```

The entire eval ledger - observations, agreements, verdicts, guidance, methodology - required *no new schema*. The eval collections declare one extra artifact scheme (`eval:`) and a handful of kinds, and everything else is the same four types, the same lifecycle, the same verifier discovered by role.

## Current state

The pipeline has been exercised end to end on genuine Inspect logs: harness run -> adapter -> run-manifest -> import -> verified collection -> rendered audit tree, with idempotent re-import, identity-conflict detection, and golden-file determinism tests on the renderer. That round trip used the zero-cost mockllm provider, so by the fixture-provenance rule everything in it carries the `fixture` tag: it demonstrates the machine and is deliberately distinguishable from a finding. No real finding is published yet; the first one is human work the machinery is waiting on - choosing the eval, judging load-bearing cases, authoring the aggregations and verdict.

> **Grounding.**
> - In the graph and collections: the `method:` contracts (m-corroboration through m-correction) in belief-collections; the `sdl:` and `toy:` worked collections; `cb:b539` (the scope boundary: CB ingests and audits records; execution stays in the harness).
> - In the code: `lib/cb/eval/manifest.ex` (parsing and deterministic emission), `lib/cb/eval/predicates.ex` and `lib/cb/method/checks.ex` (the methodology pass), `lib/cb/render/audit.ex` (the audit tree), the `mix cb.import.eval` and `mix cb.render.audit` tasks.
> - In the docs: [the run-manifest spec](run-manifest.md), [the worked example](worked-example-eval-verdict.md).
