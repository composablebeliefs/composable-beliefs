# Plan 2 - The run-manifest and `cb.import.eval`: harness output becomes ledger input

Define the neutral **run-manifest** JSON a harness emits, and the importer that
deterministically materializes it as observation beliefs in an eval collection. The
manifest is the contract between the lab bench and the ledger: Inspect (or any future
harness) adapts *to it*; CB never learns any harness's native log format.

**Status:** Proposed 2026-06-09. Nothing built.
**Date:** 2026-06-09
**Depends on:** plan-0 (vocabulary + subjects conventions to emit against).
**Touches:** `lib/cb/eval/manifest.ex` (new: parse + validate); `lib/mix/tasks/cb.import.eval.ex` (new: manifest -> import spec -> existing import path); docs (`docs/run-manifest.md`, the format spec); the Inspect adapter lives in the **eval repo**, not here - this plan only fixes its target format; tests + one committed fixture manifest.

## Context

`mix cb.import` already takes a batch spec and is the Elixir-native alternative to
disposable scripts; the write flow (preflight/adjudicate/import) already exists. What
is missing is the translation from "a harness ran 4 runs x 50 cases x 2 scorers" to
beliefs that honor the plan-0 conventions and the aggregation policy - mechanical,
volume-heavy, and exactly the kind of thing that must be deterministic so a re-import
is detectable as a no-op rather than a duplicate flood.

## Design

### The run-manifest (format spec, versioned)

```json
{
  "manifest_version": 1,
  "eval_id": "silent-data-loss-v1",
  "model": "model-x", "model_version": "model-x@2026-06",
  "harness": {"name": "inspect", "version": "...", "task": "...", "config_digest": "..."},
  "runs": [
    {"run_id": "run1", "log": "document:logs/run1.eval", "cases": 50,
     "scorers": [
       {"ruler": "deterministic-fielddiff",
        "aggregate": {"outcome_counts": {"pass": 47, "silent_loss": 3}},
        "load_bearing_cases": [
          {"case_id": "case7", "outcome": "silent_loss",
           "detail": "record #7 absent, no warning emitted",
           "log": "document:logs/run1/case7.json"}
        ]}
     ]}
  ]
}
```

Two levels by design (the aggregation policy, made structural): every
`(run, ruler)` pair yields **one aggregate observation** always; a per-case
observation is minted **only** for cases the harness/author listed under
`load_bearing_cases`. The manifest, not the importer, decides what is load-bearing -
the judgment stays upstream, the importer stays mechanical.

### What the importer emits

Per aggregate: a `kind:observation` primitive, artifact
`eval:<eval_id>/<run>/<ruler>`, subjects per plan-0 (minus `case`), tags from
`outcome_counts`, evidence entry citing the run log and the harness identity
(`config_digest` included - the reproducibility hook). Per load-bearing case: the
six-subject primitive exactly as `sdl:a1` models. Nothing else: **no compounds, no
verdicts**. Cross-ruler agreement and verdicts are authored by the human through the
normal write flow - that is the division of labor, enforced by the tool's shape.

### Determinism and idempotence

Belief ids derive from manifest content (`<ns>:o-<short-hash(eval,run,ruler[,case])>`),
`created` from a manifest date, ordering canonical. Same manifest -> byte-identical
import spec. Importing a manifest whose observations already exist is a detected
no-op (id collision with identical content), and a *changed* manifest under the same
identity is a hard error - observations are immutable measurements; a corrected run
is a new `run_id`.

### Pipeline shape

`mix cb.import.eval <manifest.json> --collection <path> [--write]` = validate
manifest -> generate import spec -> hand to the existing import path (preflight
applies; fresh observation primitives should preflight clean - a conflict is a
signal, not an obstacle to bypass). Dry-run prints the spec; `--write` commits.

## Steps

1. Write `docs/run-manifest.md` (the spec above, precisely) + a fixture manifest.
2. `CB.Eval.Manifest`: parse, validate (versions, URI well-formedness against the
   `method:` scheme enum, load-bearing case ids within range), with named errors.
3. `Mix.Tasks.Cb.Import.Eval`: spec generation with hash ids; wire through the
   existing import path; idempotence + changed-content error paths under test.
4. In the eval repo (separate work, contract fixed here): `inspect2manifest.py`
   converting an Inspect `.eval` log to a manifest; acceptance below uses its output.

## Acceptance criteria

- A real Inspect run (the DAG-vs-prose study or any current experiment) round-trips:
  log -> adapter -> manifest -> `cb.import.eval --write` -> `mix cb.verify.collection`
  green, including plan-1's method-check pass if landed.
- Re-running the import is a no-op; mutating one outcome in the manifest under the
  same run id errors loudly.
- A 4-run x 2-ruler x 50-case manifest with ~6 load-bearing cases imports in seconds
  and yields ~8 aggregates + ~12 case primitives - the graph stays human-readable
  (this is the volume guard: if an import yields hundreds of beliefs, the manifest's
  load-bearing list is wrong, and the importer warns above a threshold).

## Risks and non-goals

- **The importer becoming the author.** The moment it emits compounds or verdicts,
  the judgment layer has been automated away and the ledger's meaning degrades.
  Hard line: primitives only.
- **Id scheme regret.** Hash ids are forever (immutability). Spec the hash inputs
  exactly (normalized fields, not raw JSON) before first `--write` against a real
  collection.
- **Manifest version drift.** `manifest_version` is checked, and unknown versions
  refuse rather than best-effort parse.
- **Non-goal:** the adapter itself (eval-repo work); reading native Inspect logs in
  Elixir; importing task instances or prompts (instance data never enters the
  graph - artifacts point at logs, the logs live wherever the public/private split
  puts them).
