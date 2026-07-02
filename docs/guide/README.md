# The Composable Beliefs guide

A framework for giving AI agents persistent, source-grounded, inspectable reasoning that survives session boundaries and composes into understanding the agent never explicitly derived. This guide reads the framework end to end: the epistemic model, the schema, the operations, the code, and the applications built on it.

It is the canonical narrative reference for this repository. Each chapter consolidates what used to be spread across several essays, is written against the live graph and source, and ends with a **Grounding** box naming the belief ids and files it rests on. A guide about source-grounded reasoning that asked you to take its word for things would fail its own first lesson - run `mix bs show <id>` on any cited belief to read it yourself.

## What you'll be able to do

- Read any belief and place it: its structural type, what grounds it, what it is about, and whether it still stands.
- Author beliefs through the sanctioned write flow instead of hand-editing a graph file, and know why that boundary exists.
- Query an entire reasoning graph deterministically with the belief shell - no model in the loop.
- Deliberate proto-beliefs in the nursery and know when one is ready to mint.
- Follow a code-anchored claim from a one-line narration to the exact line of source that proves it, and watch it run as a test.
- Trace a published eval verdict back to the raw run that produced it.
- Read the Elixir implementation with a map of every layer.

## The map

| # | Chapter | What it covers |
| --- | --- | --- |
| 0 | [Orientation](0-orientation.md) | Why a belief graph at all. The problem it targets - attention, not storage - and where the framework came from. |
| 1 | [The epistemic core](1-epistemics.md) | The four structural types - attestation, aggregation, inference, prescription - one per epistemic operation. Licensing and falsifiability, immutability and the status lifecycle, and why there are no confidence scores. |
| 2 | [The schema](2-schema.md) | The belief field by field, provenance and the closed artifact-scheme enum, contracts as schema-as-data, and how the graph describes its own schema in the graph. |
| 3 | [Operating the graph](3-operations.md) | Querying with the belief shell, the preflight-adjudicate-import write flow, obligation as queryable prescriptions, staleness detected instead of remembered, and the nursery where proto-beliefs gestate. |
| 4 | [Code, anchors, positions](4-code.md) | Codepaths - anchored tours of real source that also run as tests - plus positions and chronicles. |
| 5 | [Collections and memory](5-collections.md) | How graphs compose across namespaces, borrow contracts by role, the OKF document extension, and where CB draws the line against being a memory system. |
| 6 | [Inside the code](6-architecture.md) | The Elixir implementation: a pure, deterministic graph over one JSON file, layer by layer. |
| 7 | [The eval ledger](7-eval-ledger.md) | The first shipped application: grounding model-eval findings in an immutable, traversable graph. The run-manifest seam and the audit tree. |
| 8 | [Beyond the ledger](8-beyond-the-ledger.md) | The capstone: the ledger is one face of a general mechanism that also runs backward-looking audit and forward-looking specification. |

## Reference material

- [Glossary](../glossary.md) - every technical term across the codebase and the design graph, generated from `docs/glossary.data.json`. Chapters link a term's first load-bearing use to its entry.
- [The run-manifest spec](../run-manifest.md) - the neutral JSON contract between an eval harness and the ledger.
- [Worked example](../worked-example-eval-verdict.md) - an eval verdict traced to its evidence end to end, with real command output.
- The live graph itself: `mix bs help` for the query surface, `mix bs show <id>` for any belief this guide cites.

## How to read it

The chapters build in order, and reading straight through is the intended path - the epistemic core in chapter 1 is load-bearing for everything after it. But each chapter stands alone, with cross-links wherever it leans on another; if you arrive with one question ("what is a contract?" - chapter 2; "how does an eval become beliefs?" - chapter 7), jump in and follow links backward as needed.

Every command shown is real and runs read-only against the live graph. You do not need the Elixir source open for the conceptual chapters, but chapter 6 rewards having `lib/` beside you.

A note on ids: immutable claims preserve the vocabulary and contract ids of their day. Where an older claim says "assertion" for belief, "implication" for inference, or names a contract that has since been superseded, that is history, not error; `mix bs history <id>` walks any reference forward to the current node. This guide names current ids and the current type vocabulary throughout.

> **Relationship to cb-tut.** The sibling `cb-tut` repository renders this same material as an interactive HTML wiki (hover cards for beliefs and glossary terms, in-page search). This guide is the markdown source of truth the tutorial converges on: one chapter here corresponds to one cb-tut module, the grounding boxes carry the same ids, and the glossary data is shared (`mix cb.generate.glossary` renders both). Where the media differ, the tutorial's hover affordances become explicit `mix bs show` commands and glossary links here.
