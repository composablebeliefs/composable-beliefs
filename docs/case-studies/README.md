# Case studies

Composable Beliefs is a general mechanism; the documents in this directory describe applications of it to specific domains. The framing discipline throughout: the substrate is defined knowing nothing of any consumer, so the accurate sentence is always "a host uses CB to do X". The [guide](../guide/README.md) documents the mechanism itself; nothing in it depends on any material here.

Current case studies:

- **The eval ledger** ([eval-ledger.md](eval-ledger.md)) - grounding model-evaluation findings in the graph: observations as attestations, cross-ruler agreement as aggregations, verdicts as inferences, guidance as prescriptions, methodology as self-enforcing contracts. Companions: [the run-manifest spec](run-manifest.md) (the neutral JSON contract between an eval harness and the ledger, version 1) and [the worked example](worked-example-eval-verdict.md) (a verdict traced to its evidence end to end, with real command output).

The domain-specific data lives outside this repo, in sibling collections (belief-collections: `method:`, `sdl:`, `toy:`). What this repo carries is the domain-neutral machinery the case study exercises - `mix cb.import.eval`, the methodology check pass, `mix cb.render.audit` - documented here because the code exists, at the distance an application deserves.
