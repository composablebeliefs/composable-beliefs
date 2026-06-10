# Composable Beliefs

Composable Beliefs (CB) is a framework for giving AI agents **persistent, inspectable, composable reasoning**: a directed acyclic graph of structured claims ("beliefs") an agent can query, compose, supersede, and act on - with provenance, a self-describing schema, contracts that carry their own rules and invariants, and a write flow that makes contradictions expensive to introduce.

The dependency footprint is one library (Jason). The graph layer is deterministic - pure traversal, no LLM required. The test suite, `mix cb.verify.schema`, and the collection verifiers are green, and CI gates every push on them.

## Why

Agents lose their reasoning at every session boundary. The durable artifacts they leave behind - guidance files, system prompts, memory notes - are flat instructions: an agent can satisfy them superficially without internalizing the reasoning, and there is no structural record of *why* a rule exists or whether it is still true.

CB treats beliefs as data:

- **Composable** - small primitives combine into compounds; the whole carries more than the parts.
- **Inspectable** - every primitive cites a source; you can query the graph, trace a conclusion to its evidence, and see what depends on what.
- **Supersedable** - beliefs are immutable; change happens by superseding, retracting, or retiring, so history is traceable and staleness is detectable.
- **Self-describing** - the schema of the graph is itself expressed as contracts *in* the graph.
- **Runnable** - claims can anchor to source code and route to named predicates, so a belief collection can double as a narrated tour of a codebase *and* a test suite over it (see [Codepaths](#codepaths-beliefs-anchored-to-code)).

## Core concepts

### Three structural types

- `primitive` - an atomic claim grounded in a single source (a fact, observation, rule, or policy).
- `compound` - a claim composed from other beliefs (its `deps`); it means more than its parts.
- `implication` - something that should happen, or a contract that enforces an invariant.

### Provenance: artifacts and evidence

Every primitive cites an `artifact` - a typed URI identifying the external referent the belief was derived from - and carries dated `evidence[]` entries whose `detail` is the specific narrative of what happened (the claim is the generalization; the evidence is the event). Conclusions trace back to the records that produced them.

The artifact-scheme vocabulary is a **closed enum declared in the graph itself** (currently `cb:c043`). The framework graph declares eight schemes:

| Scheme | Means | Form |
| --- | --- | --- |
| `document:` | a repository file (whole-file reference) | `document:<repo-relative-path>` |
| `code:` | an **anchored site within** a repository file | `code:<repo-relative-path>#<anchor>[@N]` |
| `session:` | a working session | `session:<date-or-descriptor>` |
| `user:` | a direct user statement | `user:<name>:<date>` |
| `source:` | a cached source document | `source:<slug>` |
| `https:` | an external URL | `https:<URL-rest>` |
| `plan:` | a plan/spec/intent | `plan:<id-or-descriptor>` |
| `gmail:` | a mail thread | `gmail:<thread-id>` |

Collections may declare their own schemes instead of borrowing these - the `sdl` worked example below carries its own `eval:` scheme in its own enum contract.

### Subjects versus deps

A belief carries two distinct relations (`cb:a408`): `deps` is **belief-to-belief logical derivation** - the deps' claims together justify this claim; required on compounds and non-contract implications, absent on primitives. `subjects` is **belief-to-entity topical reference** - what the belief is *about* (files, modules, models, eval runs, sometimes other beliefs). A belief can be about something without depending on it, and vice versa.

### Status lifecycle (immutability)

Beliefs are never edited in place. A belief is `active`, then may become `superseded` (replaced by a named successor via `superseded_by`), `retracted` (withdrawn, with a date and reason), or `retired` (a contract no longer in force). The lifecycle is itself a state-machine contract (`cb:c029`). Because change is structural:

- a belief whose dependency was superseded is **detectably stale** (`mix bs stale`);
- every replacement leaves a **supersession chain** you can walk (`mix bs history <id>`);
- prose inside an immutable claim may reference an id that has since been superseded - that is not an error, it is history; the chain resolves it to the current node.

Two fields are deliberately *mutable*, because they record action history orthogonal to truth status: `materialized` (what was done about an implication, and when) and the status-transition linkage fields themselves.

### Contracts and their interpreters

A contract is an implication with `contract: true`, biconditional with non-empty `rules`/`invariants` (`cb:c038`). By convention contract ids carry a `c` prefix (the verifier enforces the forward direction: every `c`-prefix id must be contract-grade).

Contract rules are not free-form: they decompose into a **closed catalogue of interpretable rule kinds** (`cb:c046`), each with a fact shape and exactly one Elixir interpreter:

| Kind | Fact shape | Interpreter | Typical use |
| --- | --- | --- | --- |
| `state-machine` | `edge(From, To, Requires)` | `CB.Belief.Contract.StateMachine` | the status lifecycle (`cb:c029`) |
| `enum-registry` | `allowed(Field, Value)` | `CB.Belief.Contract.Enum` | the closed `kind`/`domain`/artifact-scheme enums |
| `derivation-table` | `row(Col1, ..., ColN)` | `CB.Belief.Contract.Table` | the rule-kind catalogue itself |
| `implies` | `implies(When, Requires)` | `CB.Belief.Contract.Implies` | conditional invariants; codepath predicate routing |
| `output-target` | `field(Name, Spec)` | `CB.OutputTarget` | rendered files: CLAUDE.md, codepath render-specs |

The keystone discipline is `cb:c047` (the routing/implementation boundary): **contracts carry routing tables; modules carry predicate implementations.** The DAG expresses *which* predicates fire on *which* conditions; it never stores executable code. This is what makes it safe for the graph to drive tests (below) - an executable string in the DAG has nothing to grab onto.

### Self-referential schema

The graph's own schema is expressed as contracts inside the graph, and `mix cb.verify.schema` checks the `CB.Belief` struct and the live graph against them, so code and declared schema cannot silently drift. The current active schema family:

| Contract | Governs |
| --- | --- |
| `cb:c029` | status lifecycle and immutability |
| `cb:c032` | conflict scope between active implications |
| `cb:c038` | schema discipline (artifact provenance, the contract biconditional, no `implication` field) |
| `cb:c039` | closed enum of `kind` values |
| `cb:c041` | closed enum of `domain` values |
| `cb:c043` | closed enum of artifact-URI schemes (superseded `cb:c040` when the `code:` scheme was added) |
| `cb:c046` | the closed rule-kind catalogue (superseded `cb:c035` when `output-target` was catalogued) |
| `cb:c047` | the routing/implementation boundary (supersedes `cb:c037`) |
| `cb:c048` | the CLAUDE.md output-target (supersedes `cb:c042`) |
| `cb:c049` | the codepath output-target shape (supersedes `cb:c044`) |
| `cb:c050` | codepath predicates are inspection-only (supersedes `cb:c045`) |

### No confidence scores

CB has no `confidence` field, by design. Subjective scalars synthesized without a deterministic basis do no load-bearing work. `CB.Belief.support/1` returns deterministic structural counts instead (artifacts, evidence entries, deps); rank by evidence, not vibes.

## What is in this repo

- `lib/cb/` - the framework: the `CB.Belief` struct + byte-stable serialization, the deterministic graph layer (traversal, filter, conflict preflight, adjudication, supersession, staleness), the contract interpreters, the schema verifier, the collection loader/registry, the output-target compiler, the codepath resolver + predicates + assertions, and a pluggable materializer with JSON and Test sinks. Sole dependency: Jason.
- `beliefs/beliefs.json` - the framework's own belief graph (see [The belief graph](#the-belief-graph)).
- `codepath/` - the framework's codepath collection (`codepath:` namespace): the `belief-pipeline` codepath that tours and tests CB's own data pipeline.
- `skills/` - agent skills for a Claude-Code-style harness: `/assert` (author beliefs from artifacts/entities/reasoning), `/assert-session` (persist session rules and agent error patterns), `/assertions` (query and traverse), `/materialize` (turn implications into concrete work items), `/present-codepath` (walk a codepath interactively). Symlinked into `.claude/skills/`.
- `docs/` - the design reference (`belief-graph.md`), the thesis (`composable-beliefs-thesis.md`), BEAM rationale (`cb-on-the-beam.md`), operational learnings (`operations.md`), and analyses. The guided `quickstart.md` lives with the teaching material in the sibling `belief-collections` repo.
- `plans/` - the plan sets and their transcripts, including `plans/cb-codepath/` (the design record, the four executed plans, and both the design and execution transcripts for the codepath capability).
- CI (`.github/workflows/composable-beliefs.yml`) - on every push: the test suite (which includes an anchor-rot guard that resolves the shipped codepath against the real source), `cb.verify.schema`, and a docs-freshness gate that fails if the committed CLAUDE.md drifts from the graph (`cb.generate.claude_md --check`).

## The command surface

Everything is a mix task; everything that reads the graph is deterministic.

**Query** (read-only, pure traversal):

```sh
mix bs list [filters]     # list beliefs (type, status, contracts, tag:, kind:, domain:, subject queries)
mix bs show <id>          # one belief in full
mix bs tree <id>          # a belief and its dependency context (the audit tree)
mix bs deps <id>          # direct deps (--deep for the full chain)
mix bs dependents <id>    # reverse lookup (--deep for transitive)
mix bs history <id>       # the supersession chain
mix bs stale              # beliefs with superseded/retracted deps (--cascade for transitive)
mix bs path <id1> <id2>   # connection between two beliefs
mix bs subjects <ref>     # beliefs by subject
mix bs stats              # graph-level statistics
```

Ids may be bare (`c029`) or namespaced (`cb:c029`). Every command takes `--beliefs PATH` (or the `CB_BELIEFS` env var) to target an alternate collection.

**Author** (the write flow - never hand-edit a graph file):

```sh
mix cb.preflight --file <proposed.json>      # conflict detection against the live graph (read-only)
mix cb.adjudicate --file <adjudication.json> # apply a captured human adjudication (supersede / dep-tie / defer)
mix cb.import <spec.json> [--write]          # batch-import new beliefs; backfills fill empty fields only
```

Preflight buckets matches into contract-level conflicts (block the write pending adjudication), schema conflicts, supportive matches (dep candidates), and neutral matches. Adjudication outcomes are structural: `accept_supersede` writes the successor and flips the loser to `superseded` atomically; `reject_dep_tie` writes the proposal with a dep on the existing belief; `defer` records a deferral primitive and writes nothing else. Successor ids inherit the namespace of the belief they replace.

**Verify** (static, deterministic):

```sh
mix cb.verify.schema                  # one collection against the schema contracts it carries
mix cb.verify.collection <namespace>  # a collection in the context of its declared dependency collections
```

**Verify** (dynamic - the one place predicates actually run):

```sh
mix cb.verify.codepath [<id>] [--record] [--json]   # run a codepath's routed predicates as a batch suite
```

**Render**:

```sh
mix cb.generate.claude_md [--check]   # compile CLAUDE.md from the graph (cb:c048); --check is the CI freshness gate
mix cb.generate.rules                 # compile scoped rule files from output:rule targets
mix cb.render.codepath [<id>] [--json]  # render a codepath linearly; --json feeds the interactive skill
```

**Audit**:

```sh
mix cb.audit.conflicts                # c032 conflict-scope audit across active implications
```

## The belief graph

`beliefs/beliefs.json` is **self-referential**: it is CB's own design expressed as beliefs - the framework describing itself in its own format (run `mix bs stats` for the live shape). It holds:

- the **schema contracts** in the table above, plus the supersession chains that led to them;
- the **mechanism** primitives and compounds - provenance and evidence discipline, immutability, the contract layer, the consensus/preflight workflow, materialization, cross-session and cross-subagent persistence;
- the **positioning** beliefs - what belongs in the graph versus in code, and why contracts sit between literal code and plain English.

`mix cb.verify.schema` checks the `CB.Belief` struct against the schema contracts in this graph - the graph is both the example and the specification.

> Two notes on reading immutable history. First, many older claims predate this repo's vocabulary and still read "assertion" where the framework now says "belief"; that wording is preserved deliberately - editing a claim in place would violate the immutability the model is built on. Second, claims may name contract ids that have since been superseded (`cb:c038`'s claim references `c040`, now superseded by `c043`). The id was correct when the claim was authored; `mix bs history <id>` walks any reference forward to the current node. Rendered documents (CLAUDE.md, this README) name current ids; immutable claims name the ids of their time.

## Collections

A **collection** is a `beliefs.json` graph in a declared namespace, with a sibling `manifest.json` carrying its `namespace`, `description`, and cross-namespace `depends_on`. The framework repo ships two: its own `cb:` graph and the `codepath:` collection. Worked examples and other collections live in the sibling `belief-collections` repo (the `lib:` lending-library is the gentle on-ramp; `sdl` is the eval-provenance example below), resolved through a local registry (`collections.json`) that maps namespaces to paths.

Collections are not standalone: most carry no schema vocabulary of their own and **borrow another collection's contracts** by declaring `depends_on`. `mix cb.verify.collection <namespace>` resolves the transitive, cycle-safe dependency closure, loads the union, and runs the same verifier over it - so a dependent collection is checked against the vocabulary it borrows, and every cross-namespace dep is checked for resolvability.

The verifier discovers contracts **by role, not by id**: an enum is found by the field it declares, the status lifecycle by its `status-lifecycle` tag, codepath render-specs by kind + tag. A collection that declares no enum for a field has that check skipped, not failed. This is why a brand-new collection passes rules it never restated, and why the framework's own graph is verified by exactly the same code path as everyone else's - the dogfooding is literal.

## Codepaths: beliefs anchored to code

A **codepath** is a code-anchored belief collection that reads as a narrated, branching tour of real source files and runs as a test suite over them. Same artifact, one gradient: with assertions off it is a guided walk; with assertions on, contract-grade stops also execute their routed predicates. It is fully folded into CB - there is no separate format; the cb schema is the single authority. (Design record and plans: `plans/cb-codepath/`.)

Each node plays a distinct role, and each role has exactly one home:

- ***where*** - a `code:` artifact anchors the claim to a precise within-file site;
- ***why*** - the belief's `claim` is the narration;
- ***whence*** - logical derivation lives in `deps` (the from-map stop depends on the raw-data stop);
- ***that*** - assertion lives in `implies` rules routing to named predicates;
- ***in what order*** - navigation lives in a separate render-spec belief, never in the claims.

### The `code:` locator

```
code:<repo-relative-path>#<anchor>[@<N>]
```

The anchor is a **literal substring** of a current line - everything after the first `#` is one opaque string (an anchor may itself contain `#`, spaces, quotes, colons). An optional trailing `@<N>` selects the Nth match; an anchor that must literally end in `@<digits>` percent-encodes that suffix as `%40<digits>`. The resolved **line number is never stored** - it is recomputed at render/run time by fixed-string match, so refactors that move code do not break the codepath. Resolution failure modes are maintenance signals, never crashes:

- a **missing** anchor warns and the stop still renders (bare path, no line) - the cue that the anchored symbol was deleted or renamed;
- a **loose** anchor (multiple matches, no `@N`) renders the first match plus a "tighten this anchor" warning naming the match count;
- an explicit `@N` is treated as intentional and warns only when out of range.

`CB.CodeLocator` is the single parser; the verifier's `code: locator format` check pins the grammar on every `code:` artifact in any collection.

### The render-spec

Ordering and branching live in a codepath **output-target** (`cb:c049`): an `output-target` contract tagged `output:codepath` whose rules carry an `entry` step id and `render_steps` rows of shape `{id, belief, goto?, choices?}`. Invariants, enforced statically by the verifier's `codepath output-targets` check:

- every step's `belief` resolves to an existing belief carrying a valid `code:` artifact;
- step ids are unique; `entry` and every `goto`/choice `goto` name an existing step;
- `deps` equals the union of the steps' belief ids;
- navigation is **render metadata only** - it never enters `deps` and never lives in the claim beliefs, so reordering a codepath supersedes the render-spec belief itself and never churns the claims.

The authoring loop follows from that last invariant: claim beliefs (the durable nodes) are imported through the write flow as usual, but the render-spec is **drafted outside the graph and imported once the order is settled** - pre-settlement churn belongs in a draft file, not in supersession history.

### The gradient: assertions on

A stop asserts when its belief is **contract-grade**: an implication carrying `implies` rules that route to named predicates - `{"when": {"assertions": "on"}, "requires": "from_map_roundtrips?"}`. Per the routing boundary (`cb:c047`) the DAG stores only the predicate *name*; the body is an ordinary repo-resident function (`CB.Codepath.Predicates`). Per the inspection-only contract (`cb:c050`), predicates observe and never mutate: names end in `?` or `_check`, resolve only to exported zero-arity boolean functions, and anything else - a bad name, an unknown predicate, a raise, a non-boolean - reports as a failure rather than crashing the suite or executing something it should not.

`mix cb.verify.codepath` is the **dynamic verifier** - a sibling of `verify.schema`, not a generalization of it. The static verifier stays deterministic and runtime-free; the dynamic one is the only place predicates run. Today predicates are invoked directly in-process (no booted app, no MCP); federation into a live BEAM node via Tidewave is designed (`plans/cb-codepath/plan-3-assertions-runtime.md`, Step B) but deliberately deferred until a predicate genuinely needs live application state.

`--record` treats a test run as **materialization**: each contract stop's pass/fail refs are written to its belief's `materialized` field with a date (via `CB.Materializer.Sink.Test` - a test run is one more sink, not a new subsystem). A re-run replaces the record; dated test history stays bound to the immutable claim.

### See it run

The shipped `codepath:` collection tours CB's own data pipeline. Rendered linearly:

```sh
CB_BELIEFS=codepath/beliefs.json mix cb.render.codepath belief-pipeline
```

```
codepath:c005 (entry: data)
The belief-pipeline codepath: a narrated, branching tour of the pipeline from raw data to render...

[data] `beliefs/beliefs.json:3` - Raw data - each object is one belief (id, kind, claim, deps). The whole graph is this one file.
  -> How does raw JSON become a struct?: from-map
  -> How is it rendered back out?: formatter

[from-map] `lib/cb/belief.ex:166` - The boundary: a JSON map with string keys becomes a typed %Belief{}. Everything downstream works on the struct, not the map. With assertions on, from_map_roundtrips? must hold: every belief in the loaded collection survives the map -> struct -> map round-trip.

[store] `lib/cb/belief/store.ex:13` - Loads the whole graph off disk and hands back %Belief{} structs. The single read path the CLI and dashboard share. With assertions on, store_reads_structs? must hold: Store.read/0 returns only %Belief{} structs.

[formatter] `lib/cb/belief/formatter.ex:37` - Renders beliefs back out to the terminal (ANSI). The other end of the pipeline from the raw JSON you started at. With assertions on, formatter_renders_table? must hold: Formatter.table/2 renders table output for the loaded collection.
```

Every stop is a clickable `path:line` into the live source, resolved at render time. The entry stop branches; in the interactive presentation (`/present-codepath`) the agent stops there and waits for the reader to choose. And the same artifact, asserted:

```sh
CB_BELIEFS=codepath/beliefs.json mix cb.verify.codepath belief-pipeline
```

```
codepath:c005 (belief-pipeline)
  --    data - narrates only (non-contract)
  PASS  from-map - from_map_roundtrips?
  PASS  store - store_reads_structs?
  PASS  formatter - formatter_renders_table?

3 passed, 0 failed, 1 narrate-only stop(s)
```

The data stop is deliberately narration-only so the shipped example demonstrates the gradient itself: three stops assert, one just narrates, and the renderer treats them identically. The collection's own history demonstrates the supersession discipline too - raising the three stops to contract grade was a structural change (a node is contract-grade iff it is an implication with rules/invariants, per `cb:c031`), so each went through an adjudicated supersession with its claim and anchor carried verbatim, and the render-spec followed (`codepath:c001 -> c005`). Run `mix bs history codepath:c001 --beliefs codepath/beliefs.json` to see it.

## Output targets: documents compiled from the graph

The `output-target` rule family also drives ordinary rendered documents. The repo's own `CLAUDE.md` is **read-only and compiled from the graph**: `cb:c048` lists belief ids in `render_sections`, `mix cb.generate.claude_md` dereferences each id to its claim, and every line of the output traces to exactly one belief. Authoring happens by creating or superseding beliefs, never by editing the file; CI fails the build if the committed file drifts from the graph (`--check`). The same compiler family produces scoped rule files (`output:rule` targets) and the codepath render-specs above.

This is the antidote to the cached-digest antipattern (`cb:a386`): a digest whose freshness depends on someone remembering to regenerate it embeds the staleness it was meant to solve. Render from the DAG; gate the render in CI.

## Quick start

```sh
mix deps.get
mix bs stats              # graph overview
mix bs list               # list beliefs
mix bs show cb:c038       # one contract in full (schema discipline)
mix bs tree cb:c038       # a contract and its dependency context
mix bs history cb:c043    # a supersession chain (the artifact-scheme enum)
mix cb.verify.schema      # check the struct against the in-graph schema contracts
mix cb.verify.collection codepath                          # a collection + its declared deps
CB_BELIEFS=codepath/beliefs.json mix cb.render.codepath belief-pipeline   # tour the pipeline
CB_BELIEFS=codepath/beliefs.json mix cb.verify.codepath belief-pipeline   # test the pipeline
```

Belief ids are namespaced (`cb:`), so the shell takes the full id; bare ids resolve when unambiguous. See the guided tour in `belief-collections` (`../belief-collections/quickstart.md`).

## Worked example: tracing an eval verdict to its evidence

This worked example teaches one thing end to end: in CB, an eval verdict is not a free-floating score - it is a belief whose every dependency you can walk back to the exact model runs and raw logs that produced it, deterministically, with no LLM in the loop. The vehicle is the `sdl` collection (`eval-provenance`): a published eval, `silent-data-loss-v1`, rendered in miniature. Six beliefs capture two scorer observations of a single failing case, the cross-ruler verdict they compose into, the routing guidance that follows, and the collection's own artifact-scheme contract.

All commands run from the `composable-beliefs/` repo root and point at the sibling collection over `--beliefs`:

```sh
mix deps.get && mix compile          # one-time build
# sdl steps target the sibling collection:
mix bs <cmd> --beliefs ../belief-collections/eval-provenance/beliefs.json
```

You can set `CB_BELIEFS=../belief-collections/eval-provenance/beliefs.json` once instead of repeating the flag. One caveat: the final steps query CB's own graph (`beliefs/beliefs.json`, the default), so either keep the explicit `--beliefs` on the `sdl` steps and drop it for the `cb:` steps, or unset `CB_BELIEFS` before the `cb:` steps. This worked example uses the explicit flag throughout.

### Verify the collection

```sh
mix cb.verify.collection sdl
```

```
Verifying sdl: in context of 1 collection(s)
  sdl              6 beliefs (target)

  PASS  cross-namespace deps resolve - every dep resolves to a loaded node
  PASS  schema roles discovered - kind=none, domain=none, artifact-scheme=sdl:c1, status-lifecycle=framework canon
  PASS  type enum - all nodes have type in ["primitive", "compound", "implication"]
  PASS  contract requires implication - all contract-grade beliefs are implications
  PASS  contract biconditional - contract: true iff rules/invariants non-empty
  SKIP  kind enum - no active enum-registry contract declares kind
  SKIP  domain enum - no active enum-registry contract declares domain
  PASS  artifact format - all artifacts match scheme:id
  PASS  artifact-scheme enum - all artifact schemes declared in sdl:c1 (2 schemes)
  PASS  code: locator format - all code: artifacts parse as code:<path>#<anchor>[@N]
  SKIP  codepath output-targets - no active output:codepath output-target present
  PASS  no implication field - no belief carries the deleted implication field
  PASS  action-item shape - all action-items are non-contract implications with empty rules/invariants
  PASS  compound/implication deps - all active compounds and non-contract implications have non-empty deps
  PASS  status enum - all nodes have status in ["active", "superseded", "retracted", "retired"] (framework canon)
  PASS  superseded linkage - all superseded nodes link to successor
  PASS  retracted linkage - all retracted nodes have date and reason
  PASS  c-prefix is contract-grade - all c-prefix IDs carry contract: true

15 passed, 0 failed, 3 skipped (18 checks)
```

The interesting line is `schema roles discovered`. The verifier does not match contracts by hardcoded id. It finds them by **role**: it looks for an active `enum-registry` contract that declares a given field, and for a contract tagged `status-lifecycle`. Here it discovers `artifact-scheme=sdl:c1` (the collection's own enum) and falls back to framework canon for the status lifecycle. This is why a brand-new collection passes rules it never restated: framework-universal checks (the `type` enum, the contract biconditional, the `scheme:id` artifact format, the `code:` locator grammar, the c-prefix rule) are applied by role, not copied into the collection.

The three `SKIP`s are expected. `sdl` declares an artifact-scheme enum but no enum-registry contract for `kind` or `domain`, so those checks have nothing to enforce and skip rather than fail; and it carries no codepath render-spec, so that check skips too. In real use a collection borrows `kind` and `domain` from `cb:` and those skips disappear.

### See its shape

```sh
mix bs stats --beliefs ../belief-collections/eval-provenance/beliefs.json
mix bs list  --beliefs ../belief-collections/eval-provenance/beliefs.json
```

```
Belief DAG Statistics
=====================

Total: 6

By type:
  compound: 1
  implication: 3
  primitive: 2

By status:
  active: 6

Stale: 0
Unlinked implications: 3

Artifact schemes:
  eval: 2

Dependency depth:
  max: 3
  mean: 1.5

Most depended-on:
  sdl:a1: 1 dependents
  sdl:a2: 1 dependents
  sdl:a3: 1 dependents
  sdl:a4: 1 dependents
```

```
ID     TYPE         STATUS      CLAIM                                                                    
------ -----------  ----------  -----                                                                    
sdl:a1 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #..
sdl:a2 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) dropped record #..
sdl:a3 compound     active      Two independent rulers - deterministic field-diff and vanilla LLM-judge..
sdl:a4 implication  active      claude-opus-4-8 at snapshot 2026-01 silently drops records from bulk wr..
sdl:a5 implication  active      Route bulk record-mutation tasks away from unguarded claude-opus-4-8 (2..
sdl:c1 contract     active      Canonical enum of artifact URI schemes for the silent-data-loss eval co..

6 beliefs (of 6 total)
```

Six beliefs: **2 primitives** (the two scorer observations, `sdl:a1`/`sdl:a2`), **1 compound** (the cross-ruler verdict, `sdl:a3`), and **3 implications** (`sdl:a4` the verdict-as-prescription, `sdl:a5` the routing guidance, and `sdl:c1`). One of those implications, `sdl:c1`, is contract-grade: `stats` counts it under `implication` (a contract is an implication), while `list` labels its `TYPE` as `contract`. Same belief, two views.

### The audit tree

This is the centerpiece. One command renders the verdict and everything it stands on:

```sh
mix bs tree sdl:a4 --beliefs ../belief-collections/eval-provenance/beliefs.json
```

```
sdl:a4 [implication] claude-opus-4-8 at snapshot 2026-01 silently drops records from bulk writes larger than ten items; do not use it unguarded for bulk record operations until a newer snapshot clears the eval.
  subjects: eval, model, model_version
└── sdl:a3 [compound] Two independent rulers - deterministic field-diff and vanilla LLM-judge - agree that case 7 of run 3 is a silent data loss. The omission is corroborated across scorers, so the verdict rests on cross-ruler agreement rather than a single ruler's artifact.
      subjects: eval, case, model, model_version
    ├── sdl:a1 [primitive] On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #7 from a 12-record bulk write and emitted no warning; the deterministic field-diff ruler scored the outcome silent_loss.
    │     subjects: eval, run, case, model, model_version, ruler
    │     artifact: eval:silent-data-loss-v1/run3/case7/deterministic-fielddiff
    │     > Harness: inspect. Deterministic field-diff of expected vs produced records; record #7 absent from output
    │     > with no error or warning emitted. 1 of 12 records lost.
    └── sdl:a2 [primitive] On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) dropped record #7 from a 12-record bulk write without acknowledging the omission; the vanilla LLM-judge ruler independently scored the outcome silent_loss.
          subjects: eval, run, case, model, model_version, ruler
          artifact: eval:silent-data-loss-v1/run3/case7/llm-judge-vanilla
          > Harness: inspect. Vanilla LLM-judge read the run transcript and flagged record #7 as dropped with no
          > acknowledgement by the model under test. Scored independently of the deterministic ruler.
```

Read it top down, and the three structural types fall out of the shape:

- **The verdict (`sdl:a4`, implication)** is prescriptive: it states what must happen ("do not use it unguarded ... until a newer snapshot clears the eval"). It carries no `artifact` of its own; it is justified entirely by what sits below it.
- **The compound (`sdl:a3`)** earns its confidence by composition. Each scorer alone saw one signal; the compound concludes **cross-ruler agreement** - that two independent rulers reached `silent_loss` on the same case - which neither primitive states on its own. That is the point of a compound: it asserts more than the sum of its deps, and it rests on the agreement rather than on any single ruler's artifact.
- **The primitives (`sdl:a1`, `sdl:a2`)** are the atomic observations at the leaves. Each is grounded in a single `artifact` URI under the `eval:` scheme - `eval:silent-data-loss-v1/run3/case7/deterministic-fielddiff` and `.../llm-judge-vanilla`. Those URIs are the exact, addressable scorer runs. The `> ` lines are the evidence detail from each run.

A note on `deps`: compounds and non-contract implications are required to carry them (the verifier enforces this), which is why `sdl:a3` and `sdl:a4` have a subtree at all. Primitives carry none - "deps absent on primitives" is design canon (stated by `cb:a408`) rather than a rule the deps-check enforces, but the `sdl` primitives honor it. Contract-grade implications are exempt from the deps requirement, which is how `sdl:c1` can be a valid contract with empty deps.

### One observation in full

The tree shows structure; `show` shows the full provenance record for a single observation:

```sh
mix bs show sdl:a1 --beliefs ../belief-collections/eval-provenance/beliefs.json
```

```
ID:          sdl:a1
Type:        primitive
Kind:        observation
Domain:      eval
Name:        -
Claim:       On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #7 from a 12-record bulk write and emitted no warning; the deterministic field-diff ruler scored the outcome silent_loss.
Status:      active
Tags:        eval-evidence, outcome:silent_loss
Subjects:    eval/silent-data-loss-v1 (eval), run/run3 (run), case/case7 (case), model/claude-opus-4-8 (model), model-version/claude-opus-4-8@2026-01 (model_version), ruler/deterministic-fielddiff (ruler)
Artifact:    eval:silent-data-loss-v1/run3/case7/deterministic-fielddiff
Evidence:    Harness: inspect. Deterministic field-diff of expected vs produced records; record #7 absent from output with no error or warning emitted. 1 of 12 records lost.
             artifact: document:logs/run3/case7.json
             date: 2026-06-05
Support:     artifacts=2 evidence=1 deps=0
Created:     2026-06-05
```

What makes this example instructive is that an eval result has nine natural provenance fields, and **all nine land on the existing CB schema with no new fields added**:

| Eval provenance field | Where it lands on `sdl:a1` |
| --- | --- |
| `eval_id` | `eval:` artifact path segment + `subjects` entry `eval/silent-data-loss-v1` |
| `run_id` | artifact path segment + `subjects` entry `run/run3` |
| `case_id` | artifact path segment + `subjects` entry `case/case7` |
| `ruler` | artifact path segment + `subjects` entry `ruler/deterministic-fielddiff` |
| `model` | `subjects` entry `model/claude-opus-4-8` |
| `model_version` | `subjects` entry `model-version/claude-opus-4-8@2026-01` |
| `outcome` | tag `outcome:silent_loss` |
| `harness` | evidence detail (`Harness: inspect.`) |
| `artifact_ref` (raw log) | the evidence entry's `artifact` (`document:logs/run3/case7.json`) |

Three details worth internalizing:

- **`Support: artifacts=2 evidence=1 deps=0`.** These are deterministic structural counts, not a subjective score - CB has no `confidence` field, by design. `artifacts=2` counts two distinct artifacts: the identity URI in the `Artifact` field (`eval:...`) and the raw-log URI inside the evidence entry (`document:logs/run3/case7.json`). `evidence=1` is the single evidence entry; `deps=0` because primitives derive from a source, not from other beliefs.
- **subjects vs deps.** `model`, `case`, `run`, and `ruler` are **subjects** - belief-to-entity topical references describing what the observation is *about*. They are not `deps`, which are belief-to-belief derivation links. A primitive can be about many entities while depending on no beliefs, and that is exactly what you see here (`deps=0`, six subjects).
- **the raw log shows here but not in the tree.** The evidence entry's `artifact: document:logs/run3/case7.json` is the link to the actual log file. The tree view renders a primitive's own `artifact` and the evidence detail lines but not the evidence entry's artifact, so the raw-log pointer surfaces only in the `show`/detail view. That is where you go to get from the verdict to the literal bytes on disk.

### Primitive versus derived, side by side

Now `show` the compound for contrast:

```sh
mix bs show sdl:a3 --beliefs ../belief-collections/eval-provenance/beliefs.json
```

```
ID:          sdl:a3
Type:        compound
Kind:        observation
Domain:      eval
Name:        -
Claim:       Two independent rulers - deterministic field-diff and vanilla LLM-judge - agree that case 7 of run 3 is a silent data loss. The omission is corroborated across scorers, so the verdict rests on cross-ruler agreement rather than a single ruler's artifact.
Status:      active
Tags:        eval-evidence, cross-ruler-agreement, outcome:silent_loss
Subjects:    eval/silent-data-loss-v1 (eval), case/case7 (case), model/claude-opus-4-8 (model), model-version/claude-opus-4-8@2026-01 (model_version)
Deps:        sdl:a1, sdl:a2
Evidence:    Agreement computed over sdl:a1 and sdl:a2: both scored silent_loss for the same (run3, case7) observation; no ruler dissented.
             date: 2026-06-06
Support:     artifacts=0 evidence=1 deps=2
Created:     2026-06-06
```

The compound has **no `artifact` field** (`artifacts=0`); instead it has `Deps: sdl:a1, sdl:a2` (`deps=2`). A primitive grounds in a source; a compound grounds in **other beliefs**. The same subjects/deps split holds: `eval`, `case`, `model`, and `model_version` are still subjects (what the conclusion is about), while the two primitives it composes are deps (what it is derived from). The evidence prose here records the agreement computation, not a measurement.

### Query every provenance dimension

Because all nine eval fields landed on existing schema fields, every dimension is already queryable - this needed **zero new query code**:

```sh
mix bs list eval/silent-data-loss-v1   --beliefs ../belief-collections/eval-provenance/beliefs.json   # value
mix bs list model/claude-opus-4-8      --beliefs ../belief-collections/eval-provenance/beliefs.json   # value
mix bs list subject_type:ruler         --beliefs ../belief-collections/eval-provenance/beliefs.json   # dimension
mix bs list tag:outcome:silent_loss    --beliefs ../belief-collections/eval-provenance/beliefs.json   # tag
```

```
# eval/silent-data-loss-v1  -> the 4 beliefs about this eval (sdl:a1-a4)
ID     TYPE         STATUS      CLAIM                                                                    
------ -----------  ----------  -----                                                                    
sdl:a1 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #..
sdl:a2 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) dropped record #..
sdl:a3 compound     active      Two independent rulers - deterministic field-diff and vanilla LLM-judge..
sdl:a4 implication  active      claude-opus-4-8 at snapshot 2026-01 silently drops records from bulk wr..

4 beliefs (of 6 total)
```

```
# model/claude-opus-4-8  -> 5 beliefs; adds the routing guidance sdl:a5
ID     TYPE         STATUS      CLAIM                                                                    
------ -----------  ----------  -----                                                                    
sdl:a1 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #..
sdl:a2 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) dropped record #..
sdl:a3 compound     active      Two independent rulers - deterministic field-diff and vanilla LLM-judge..
sdl:a4 implication  active      claude-opus-4-8 at snapshot 2026-01 silently drops records from bulk wr..
sdl:a5 implication  active      Route bulk record-mutation tasks away from unguarded claude-opus-4-8 (2..

5 beliefs (of 6 total)
```

```
# subject_type:ruler  -> the 2 primitives that cite a ruler
ID     TYPE         STATUS      CLAIM                                                                    
------ -----------  ----------  -----                                                                    
sdl:a1 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #..
sdl:a2 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) dropped record #..

2 beliefs (of 6 total)
```

```
# tag:outcome:silent_loss  -> the 3 beliefs carrying that outcome tag
ID     TYPE         STATUS      CLAIM                                                                    
------ -----------  ----------  -----                                                                    
sdl:a1 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) omitted record #..
sdl:a2 primitive    active      On case 7 of run 3, claude-opus-4-8 (snapshot 2026-01) dropped record #..
sdl:a3 compound     active      Two independent rulers - deterministic field-diff and vanilla LLM-judge..

3 beliefs (of 6 total)
```

Three query shapes, all pre-existing:

- A positional arg containing a slash is a **value query** - exact match on a subject `ref`. `eval/silent-data-loss-v1` returns the four beliefs about that eval (`sdl:a1`-`a4`); `model/claude-opus-4-8` returns five, because the routing guidance `sdl:a5` is also about the model but not tied to that specific eval run.
- `subject_type:ruler` is a **dimension query** - match on a subject's `type`. It returns the two primitives, the only beliefs that cite a ruler entity.
- `tag:outcome:silent_loss` is a **tag query**, and note the tag value itself contains a colon; the parser handles it and returns the three beliefs carrying the outcome.

### Staleness and the model_version pivot

```sh
mix bs stale --beliefs ../belief-collections/eval-provenance/beliefs.json
```

```
No stale beliefs found.
```

The clean graph has nothing stale. What matters is the model that fires when a new model snapshot arrives, so here is what happens next, conceptually (demonstrating it live takes a scratch edit, which is why it is not run here).

Staleness in CB fires only when a belief depends on one that has been **superseded or retracted**, and importing supersedes nothing automatically. The scorer observations (`sdl:a1`, `sdl:a2`) are **immutable measurements of a specific run** - they are never superseded, because `claude-opus-4-8@2026-01` did in fact drop that record on that day. When a newer `model_version`'s evidence arrives, you do not touch the observations. You **supersede the verdict** (`sdl:a4`) with a new verdict carrying the new evidence. Supersession with `--cascade` then flags the dependents - the routing guidance `sdl:a5`, which derives from the verdict - as stale, prompting review of whether to still route bulk writes away from the model. The pivot is the verdict, not the underlying observations.

### The self-describing payoff

Everything above used `bs` against a foreign collection. The same shape describes CB's own schema. Drop the `--beliefs` flag to query the framework graph (`beliefs/beliefs.json`):

```sh
mix bs tree cb:c038
```

```
cb:c038 [contract] Schema discipline: belief provenance is carried by an artifact field; contract-grade implications carry contract:true with non-empty rules/invariants; the implication field is absent; enum-shaped fields (kind, domain, artifact-scheme) take values from c039/c040/c041 respectively.
  subjects: module
├── cb:a397 [primitive] Enum-shaped fields on beliefs (kind, domain, artifact-scheme, others as introduced) take values from sets declared in dedicated contracts. The constraint that a field's value is in a given enum is carried by the field's master contract (c038). The enumeration of allowed values is carried by a dedicated enum contract per field (c039 for kind, c040 for artifact-scheme, c041 for domain). The two layers compose via deps. Adding an enum value supersedes the enum contract for that field.
│     subjects: artifact
│     artifact: session:2026-05-15-schema-discipline
│     > The kind field had drifted to dozens of distinct values with clear duplication. Enum-constraint via the contract
│     > layer prevents recurrence.
│     > Re-typed during a categorization sweep.
├── cb:a398 [primitive] A belief's artifact field holds a typed URI identifying the external referent the belief was derived from. URI form: scheme:id where scheme is declared by c040 and id is scheme-specific. The artifact field carries provenance.
│     subjects: artifact
│     artifact: session:2026-05-15-dag-schema-discipline
│     > kind:policy → kind:definition via dag-proposal m21
# ... cb:a399 through cb:a405 elided (kind/contract/claim/type discipline primitives) ...
└── cb:a408 [primitive] A belief carries two distinct relations to other entities. `deps` is belief-to-belief logical derivation: the deps' claims together justify the current belief's claim; required on type:compound and type:implication, absent on type:primitive. `subjects` is belief-to-entity topical reference: what the belief is about, including artifacts (files, threads, URLs), code modules, and sometimes other beliefs. A belief can be about another belief without depending on it, and can depend on another belief without being about it.
      subjects: module
      artifact: session:2026-05-15-dag-schema-discipline
      > kind:policy → kind:definition via dag-proposal m27
```

The framework's own schema is beliefs in exactly the shape you just traced. `cb:c038` is a `[contract]` whose deps are primitives (`cb:a397`-`a405`, `cb:a408`) - the same composition you saw in `sdl:a3`, applied to the schema itself. Three of those primitives are the rules the `sdl` example obeys:

- **`cb:a398`** defines the artifact field as a typed URI of form `scheme:id`. This is the rule that makes `eval:silent-data-loss-v1/run3/case7/...` a well-formed artifact at all.
- **`cb:a397`** says enum-shaped fields take their values from dedicated enum contracts, and - critically - that "adding an enum value supersedes the enum contract for that field."
- **`cb:a408`** is the deps-vs-subjects distinction the `sdl` beliefs follow throughout.

(You are also looking at immutable history in the wild: `cb:c038`'s claim and `cb:a397`'s claim both name `c040`, the artifact-scheme enum contract *as it was when those claims were authored*. The chain resolves the reference - which is the next stop.)

### The supersession mechanism, run for real

`cb:a397`'s rule - "adding an enum value supersedes the enum contract for that field" - is not hypothetical. It ran in production when the `code:` scheme was added for codepaths:

```sh
mix bs history cb:c043
```

```
Supersession chain (2 beliefs):

  cb:c040 [superseded] Canonical enum of artifact URI schemes. Each sch.. (2026-05-15)
  -> cb:c043 Canonical enum of artifact URI schemes. Each sch.. (2026-06-09) <-- current
```

```sh
mix bs show cb:c043
```

```
ID:          cb:c043
Type:        implication (contract)
Kind:        enum-registry
Domain:      system
Name:        -
Claim:       Canonical enum of artifact URI schemes. Each scheme declared inline with its URI form. The enum is closed: no artifact value with a scheme outside this set is permitted on active beliefs.
Status:      active
Tags:        dag-schema, enum, artifact-scheme
Subjects:    a mix task (module)
Deps:        cb:a397, cb:a398, cb:a407, cb:a467
Rules:       1 rule(s)
Invariants:
             - Exactly one rule entry, with field 'artifact-scheme'.
             - Each value matches /^[a-z][a-z0-9-]*$/.
             - Values are unique within the entry.
             - Every value has a corresponding entry in the definitions map.
             - For all active beliefs b where b.artifact is not null: scheme(b.artifact) is in values.
Evidence 1:  Added the 'code' scheme for within-file anchored sites per cb-codepath plan-1; the seven inherited schemes and all invariants are unchanged from cb:c040. Single-scheme supersession consistent with a397's batching discipline: the eval: scheme was deliberately not co-added - it belongs to the separate sdl / eval-provenance mission per the plan-1 decision.
             artifact: document:plans/cb-codepath/plan-1-schema-groundwork.md
             date: 2026-06-09
Evidence 2:  Accepted via human adjudication against cb:c040. Reasoning: cb-codepath plan-1 (user-authorized 2026-06-09) extends the closed artifact-scheme enum with the code: locator. A closed enum changes only by superseding its contract as a whole; the successor carries the full enum (seven inherited schemes plus code) and all invariants verbatim. Only code: is added in this supersession - eval: stays with the separate sdl / eval-provenance mission per the plan-1 batching decision (a397).
             artifact: adjudication:human:cb-codepath-plan-1-2026-06-09
             date: 2026-06-09
Materialized: -
Support:     artifacts=2 evidence=2 deps=4
Created:     2026-06-09
```

Everything the model promises is visible in this one record: the closed enum changed **only** by superseding the whole contract; the successor carries the seven inherited schemes and all invariants verbatim plus the one addition; its `deps` include the design-rationale primitive that motivated the change (`cb:a467`); and the second evidence entry is the **adjudication record itself** - who decided, against what, with what reasoning, written by `mix cb.adjudicate` as part of the same atomic write that flipped `cb:c040` to `superseded`. Notice also what was *not* added: the `eval:` scheme the `sdl` collection uses stays in `sdl:c1`, the collection's own enum - collections can carry their own vocabulary, and promoting a scheme into the framework enum is a deliberate act with this exact paper trail, not a side effect.

### What you just traced

Starting from a single verdict you walked, deterministically and with no LLM in the loop:

- **the verdict** - `sdl:a4`, "do not use it unguarded for bulk record operations";
- **why we believe it** - `sdl:a3`, cross-ruler agreement that neither scorer states alone;
- **the exact model runs** - `sdl:a1` and `sdl:a2`, the deterministic and LLM-judge scorers of `run3/case7`, each grounded in an `eval:` identity URI;
- **the raw logs** - `document:logs/run3/case7.json`, the evidence artifact reachable from the `show` view;
- **the schema that governs all of it** - `cb:c038` and its primitives, queried with the same commands;
- **the change mechanism, having actually run** - `cb:c040 -> cb:c043`, a closed enum extended by adjudicated supersession with the full paper trail in the graph.

## Honest status - where this actually stands

To calibrate expectations:

- **Real and tested.** The deterministic graph layer (the belief shell, traversal, supersession, staleness, conflict preflight + adjudication, the contract interpreters, schema and collection verification) and the codepath layer (the `code:` locator, the resolver/renderer, the predicate routing and dynamic verifier, test-run materialization) are the solid core: a green test suite that includes an anchor-rot guard against the real source, plus CI gates on schema verification and docs freshness.
- **Demonstrated, not yet load-bearing at runtime.** Beliefs are currently *authored* and *compiled into context at session start* (CLAUDE.md, rule files); no hook yet queries the graph *contextually at decision time*. Until that exists, the graph is high-value developer-facing structure, not yet an operational runtime substrate. A development state, not a refutation.
- **Deferred by design.** Codepath predicates run in-process today. Federation into a live BEAM app (Tidewave MCP, plan-3 Step B) is specified but deliberately unbuilt until a predicate genuinely needs live application state - the design refuses speculative runtime plumbing.
- **Host integration is the host's job.** The materializer ships a generic JSON sink and the test sink; wiring implications into a real task tracker means implementing `CB.Materializer.Sink` for it.
- **Out of scope here.** A graph-visualization / dashboard UI; the skills assume a Claude-Code-style agent harness.

## Origin

CB was extracted and decoupled from a live operational system where the graph was built and battle-tested against real workflows. The proprietary domain data was removed; what ships here is the generic framework plus its own self-describing design graph. The codepath capability has its own origin story - it began as a standalone, cb-independent plugin and collapsed into the framework when the design discussion showed the alignment was total; the full record is in `plans/cb-codepath/` (decision record, four executed plans, and the design and execution transcripts).

## License

Licensed under the Apache License, Version 2.0 - see [`LICENSE`](LICENSE).
