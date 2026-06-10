# The run-manifest format (version 1)

The run-manifest is the contract between the lab bench and the ledger: a neutral JSON
record of one harness execution that `mix cb.import.eval` deterministically
materializes as observation beliefs in an eval collection. A thin adapter per harness
(Inspect first; it lives in the eval repo, not here) converts native logs *to this
format*; CB never learns any harness's native log format.

## Shape

```json
{
  "manifest_version": 1,
  "eval_id": "silent-data-loss-v1",
  "date": "2026-06-09",
  "model": "model-x",
  "model_version": "model-x@2026-06",
  "harness": {
    "name": "inspect",
    "version": "0.3.61",
    "task": "silent_data_loss",
    "config_digest": "sha256:9f2c..."
  },
  "tags": [],
  "runs": [
    {
      "run_id": "run1",
      "log": "document:logs/run1.eval",
      "cases": 50,
      "scorers": [
        {
          "ruler": "deterministic-fielddiff",
          "aggregate": { "outcome_counts": { "pass": 47, "silent_loss": 3 } },
          "load_bearing_cases": [
            {
              "case_id": "case7",
              "outcome": "silent_loss",
              "detail": "record #7 absent, no warning emitted",
              "log": "document:logs/run1/case7.json"
            }
          ]
        }
      ]
    }
  ]
}
```

## Fields

| field | required | rule |
|---|---|---|
| `manifest_version` | yes | must be the integer `1`; unknown versions refuse, never best-effort parse |
| `eval_id` | yes | non-empty string; becomes the `eval/<eval_id>` subject and the first `eval:` URI segment |
| `date` | yes | `YYYY-MM-DD`; becomes `created` and the evidence date on every emitted belief - determinism requires the date to come from the manifest, never from the importer's clock |
| `model` | yes | non-empty string; the `model/<model>` subject |
| `model_version` | yes | non-empty string, conventionally `<model>@<snapshot>`; the staleness pivot (`method:a2`) |
| `harness.name` | yes | non-empty string |
| `harness.version`, `harness.task`, `harness.config_digest` | no | strings; recorded verbatim in evidence details (`config_digest` is the reproducibility hook) |
| `tags` | no | list of strings appended to every emitted belief's tags; synthetic or test manifests MUST include `"fixture"` per `method:a5` |
| `runs` | yes | non-empty list; `run_id` unique within the manifest |
| `runs[].run_id` | yes | non-empty string; the `run/<run_id>` subject |
| `runs[].log` | yes | artifact URI with scheme `document` or `https` - the raw run log pointer |
| `runs[].cases` | yes | positive integer |
| `runs[].scorers` | yes | non-empty list; `ruler` unique within the run |
| `scorers[].ruler` | yes | non-empty string; the `ruler/<ruler>` subject. LLM judges are named with the `llm-judge` prefix (`method:a4`) |
| `scorers[].aggregate.outcome_counts` | yes | map of outcome name to non-negative integer count |
| `scorers[].load_bearing_cases` | no | list; `case_id` unique within the scorer, count must not exceed `cases` |
| `load_bearing_cases[].case_id` | yes | non-empty string; the `case/<case_id>` subject |
| `load_bearing_cases[].outcome` | yes | non-empty string; becomes the `outcome:<outcome>` tag |
| `load_bearing_cases[].detail` | no | string, folded into the claim - treat as publishable prose |
| `load_bearing_cases[].log` | no | artifact URI (`document`/`https`); defaults to the run log in evidence |

## Aggregation policy (structural)

Two levels by design. Every `(run, ruler)` pair yields **one aggregate observation**,
always. A per-case observation is minted **only** for cases listed under
`load_bearing_cases`. The manifest, not the importer, decides what is load-bearing -
the judgment stays upstream, the importer stays mechanical. If an import would emit
a flood of beliefs, the load-bearing list is wrong; the importer warns above a
threshold rather than silently complying.

## What the importer emits

Per aggregate: a `kind:observation` primitive with artifact
`eval:<eval_id>/<run_id>/<ruler>`, the five aggregate subjects
(`eval`, `run`, `model`, `model_version`, `ruler` - `case` omitted, `aggregate` tag
present per `method:a1`/`method:a3`), one `outcome:<name>` tag per outcome with a
non-zero count, and an evidence entry citing the run log plus the harness identity.

Per load-bearing case: the six-subject primitive (as `sdl:a1` models) with artifact
`eval:<eval_id>/<run_id>/<case_id>/<ruler>`, the `outcome:<outcome>` tag, and an
evidence entry citing the case log (or the run log when absent).

Nothing else: **no compounds, no verdicts**. Cross-ruler agreement and verdicts are
authored by a human through the normal write flow - that division of labor is
enforced by the tool's shape.

## Identity, determinism, idempotence

Belief ids derive from the observation's identity tuple, not its content:

    aggregate: <ns>:o-<hash>  where hash = first 8 hex chars of
               sha256("cb-eval-v1|" <> eval_id <> "|" <> run_id <> "|" <> ruler)
    case:      <ns>:o-<hash>  where hash = first 8 hex chars of
               sha256("cb-eval-v1|" <> eval_id <> "|" <> run_id <> "|" <> ruler <> "|" <> case_id)

`<ns>` is the target collection's namespace, read from its `manifest.json`. The hash
inputs are the normalized identity fields joined with `|` after the fixed
`cb-eval-v1|` prefix - never raw JSON. Ids are immutable once written.

Consequences:

- The same manifest always generates a byte-identical import spec.
- Re-importing a manifest whose observations already exist is a detected **no-op**
  (same id, identical content - reported, skipped).
- A *changed* manifest under the same identity is a **hard error**: observations are
  immutable measurements. A corrected run is a new `run_id`.

## Pipeline

    mix cb.import.eval <manifest.json> --collection <path/to/beliefs.json> [--write]

validate manifest -> generate spec -> preflight each fresh observation against the
collection (a conflict is a signal, not an obstacle to bypass) -> hand the fresh
beliefs to the existing import path. Dry run prints the spec; `--write` commits.
