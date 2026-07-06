# Composable Beliefs

Composable Beliefs (CB) is a directed acyclic graph of immutable, source-grounded, composable claims that gives an agent persistent, inspectable reasoning across session boundaries. Every node carries its source or the dependency chain that reaches one, every change leaves a trace instead of overwriting, and the path that reads the graph is plain deterministic traversal with no model in the loop (`cb:b478`, `cb:b539`).

Two commitments define the design:

- **Beliefs, held revisably.** The unit of the graph records what is believed, on what evidence, and what would have to change - truth status is tracked and revisable. A belief can turn out to be wrong without breaking the model; that is what retraction is for.
- **Reasoning is authored.** Humans and agents create every belief, exercising judgment at each step; CB records the derivation and keeps it walkable.

## The mechanism

At its core CB is a schema. The graph has four structural types, one per epistemic operation: attestation (what a source said), aggregation (what its deps jointly state), inference (a conclusion licensed to exceed its deps), and prescription (what should happen). Every change to a belief is a supersession - a new node replacing the old, with the old kept and linked forward - so anything still resting on a replaced premise is mechanically detectable. There are no confidence scores: how well-grounded a belief is falls out of artifacts, evidence, and dependency structure.

The format is plain JSON. What ships in this repo is the schema plus the machinery that enforces it - an Elixir library and mix-task suite for querying, verifying, authoring, and rendering belief graphs - and the framework's own self-describing design graph in `beliefs/cb/`. One dependency (Jason), pure deterministic traversal, no LLM anywhere in the read path; CI gates every push on the test suite and the graph verifiers.

## Sixty seconds

```sh
mix deps.get && mix compile
mix bs tree cb:b047
```

```
cb:b047 [contract] Contracts carry routing tables; modules carry predicate implementations. The DSL expresses which predicates fire on which conditions; it does not express how predicates are implemented.
├── cb:b300 [attestation] A contract is the formalization of an implication - the implication states WHAT (the conclusion), the contract states HOW (rules as Given/When/Then scenarios) and ALWAYS (invariants)
├── cb:b054 [contract] A node is contract-grade iff its type is prescription and its rules or invariants array is non-empty - contract is the machine-checkable grade of a prescription, not a type. ...
│   ├── cb:b300 [attestation] ...
│   └── cb:b470 [attestation] The cb-schema-v2 design (plans/cb-schema-v2/design.md, decided 2026-06-10) replaces the three-type schema with four structural types, one per epistemic operation ...
└── cb:b046 [contract] Contract rules decompose into a closed registry of interpretable kinds, each with a Datalog fact shape, an Elixir interpreter module, and required fields per rule entry
```

A design rule of this framework (`cb:b047`) is data; the premises it rests on are themselves beliefs you can keep walking; and the traversal is pure - no model, no ranking, no retrieval, just the graph.

## Scope

Three things stay outside CB by design, left to other tools: vector memory, model calls, and task execution (`cb:b539`). CB is a reasoning and audit layer over whatever memory, retrieval, or execution systems a host already runs; building any of them into the read path would forfeit the deterministic, model-free traversal the framework exists to provide.

## Operating the graph

Read:

```sh
mix bs stats              # graph overview
mix bs show cb:b056       # one contract in full (schema discipline)
mix bs tree cb:b056       # a contract and its dependency context
mix bs history cb:b067    # a supersession chain (the artifact-scheme enum)
mix bs stale --cascade    # claims resting on withdrawn foundations
```

Write, through the sanctioned flow only - never by hand-editing graph files:

```sh
mix cb.preflight --file <f>    # check a proposed belief for conflicts
mix cb.adjudicate --file <f>   # resolve them
mix cb.import --file <f>       # write the belief
```

Three further doors complete the write surface: `mix cb.evidence` (append a dated evidence entry - the one in-place growth point on an immutable node), `mix cb.todo.close` (discharge a materialized work item), and `mix cb.supersede` (flip a belief to an existing successor). All write tasks are dry-run by default and write only with `--write`.

Verify:

```sh
mix cb.verify.schema                  # a collection against the contracts it carries
mix cb.verify.collection <namespace>  # a collection with its declared dependency collections
mix cb.generate.claude_md --check     # the compiled CLAUDE.md is current
```

The full command surface is in the [reference](docs/reference.md).

## Documentation

**[The guide](docs/guide/README.md)** is the canonical narrative reference - seven chapters (0-6) reading the framework end to end: orientation, the epistemic core, the schema, operating the graph, code anchors and positions, collections and memory, and the architecture. Every load-bearing claim in it names the belief id or source file it rests on.

Beside it:

- **[Reference](docs/reference.md)** - the full command surface and the repo layout, at a glance.
- **[Glossary](docs/glossary.md)** - every technical term, generated from `docs/glossary.data.json`.
- **[Operational learnings](docs/operations.md)** - how to run an extraction session in practice.
- **[Case studies](docs/case-studies/README.md)** - applications of the mechanism to specific domains. Currently: the eval ledger, with the run-manifest spec and a worked example.

Anchored stances live in `positions/`; session narratives open the thread documents in `beliefs/nursery/threads/`. `plans/` is a closed shelf kept in place because references point into it; archived essays and dated records live in `deprecated/`.

For the guided on-ramp, see `../belief-collections/quickstart.md` in the sibling repo - if the self-referential `cb:` graph is a lot to meet first, start with the `lib:` lending-library collection there.

## Origin

CB was extracted and decoupled from a live operational system where the graph was built against real workflows. The proprietary domain data was removed; what ships here is the generic framework plus its own self-describing design graph. The codepath capability began as a standalone plugin and collapsed into the framework when the design discussion showed the alignment was total; the record is in `plans/cb-codepath/`.

## License

Licensed under the Apache License, Version 2.0 - see [`LICENSE`](LICENSE).
