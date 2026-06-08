# Composable Beliefs

Composable Beliefs (CB) is a framework for giving AI agents **persistent, inspectable, composable reasoning**: a directed acyclic graph of structured claims ("beliefs") an agent can query, compose, supersede, and act on - with provenance, a self-describing schema, and contracts that carry their own rules and invariants.

The dependency footprint is one library (Jason). The graph layer is deterministic - pure traversal, no LLM required. The test suite and `mix cb.verify.schema` are green.

## Why

Agents lose their reasoning at every session boundary. The durable artifacts they leave behind - guidance files, system prompts, memory notes - are flat instructions: an agent can satisfy them superficially without internalizing the reasoning, and there is no structural record of *why* a rule exists or whether it is still true.

CB treats beliefs as data:

- **Composable** - small primitives combine into compounds; the whole carries more than the parts.
- **Inspectable** - every primitive cites a source; you can query the graph, trace a conclusion to its evidence, and see what depends on what.
- **Supersedable** - beliefs are immutable; change happens by superseding, retracting, or retiring, so history is traceable and staleness is detectable.
- **Self-describing** - the schema of the graph is itself expressed as contracts *in* the graph.

## Core concepts

**Three structural types**
- `primitive` - an atomic claim grounded in a single source (a fact, observation, rule, or policy).
- `compound` - a claim composed from other beliefs (its `deps`); it means more than its parts.
- `implication` - something that should happen, or a contract that enforces an invariant.

**Provenance.** Every primitive cites an `artifact` (a typed URI such as `document:`, `source:`, `session:`, `user:`, `https:`) and may carry `evidence[]` entries. Conclusions trace back to the records that produced them.

**Status lifecycle (immutability).** Beliefs are never edited in place. A belief is `active`, then may become `superseded` (replaced by a named successor), `retracted` (withdrawn, with a reason), or `retired` (a contract no longer in force). Because change is structural, a belief whose dependency was superseded is *detectably stale*.

**Contracts.** A contract is an implication with `contract: true` and non-empty `rules` / `invariants`. Interpreters give contracts a small queryable API - for example a `state-machine` (`{from, to, requires}` edges) or an `enum` (`{field, values}` closed enumeration).

**Self-referential schema.** The graph's own schema - the closed enums for `kind`, `domain`, and artifact scheme; the status lifecycle; the contract discipline - is expressed as contracts (`cb:c029`, `cb:c038`-`cb:c041`) *inside the graph*. `mix cb.verify.schema` checks the `CB.Belief` struct against those contracts, so code and declared schema cannot silently drift.

## What is in this repo

- `lib/cb/` - the framework: the `CB.Belief` struct + serialization, the deterministic graph layer (traversal, filter, conflict-preflight, supersession, staleness), the contract interpreters, a pluggable materializer, and the `mix bs` belief shell + `mix cb.*` operations. Sole dependency: Jason.
- `beliefs/beliefs.json` - the belief graph (see below).
- `docs/` - the design reference (`belief-graph.md`) and operational learnings (`operations.md`). The guided `quickstart.md` lives with the teaching material in `belief-collections`.
- `skills/` - agent skills (`/assert`, `/assertions`, `/assert-session`, `/materialize`) for working the graph in a Claude-Code-style harness.
- CI (`.github/workflows/composable-beliefs.yml`) - on every push, runs the tests, `cb.verify.schema`, and a docs-freshness gate that fails if the committed CLAUDE.md drifts from the graph (`cb.generate.claude_md --check`).

## The belief graph

`beliefs/beliefs.json` is **self-referential**: it is CB's own design expressed as beliefs - the framework describing itself in its own format (run `mix bs stats` for the live shape). It holds:

- the **schema contracts** that define the graph's own discipline - the status lifecycle (`cb:c029`), schema discipline (`cb:c038`), conflict scope (`cb:c032`), and the closed enums for `kind`, artifact-scheme, and `domain` (`cb:c039`-`cb:c041`), among others;
- the **mechanism** primitives and compounds - provenance and evidence discipline, immutability, the contract layer, the consensus/preflight workflow, materialization, cross-session and cross-subagent persistence;
- the **positioning** beliefs - what belongs in the graph versus in code, and why contracts sit between literal code and plain English.

`mix cb.verify.schema` checks the `CB.Belief` struct against the schema contracts in this graph - the graph is both the example and the specification.

> Note: because beliefs are immutable historical records, many claims predate this repo's vocabulary and still read "assertion" where the framework now says "belief." That wording is preserved deliberately - editing a belief's claim in place would violate the immutability the model is built on.

## Quick start

```sh
mix deps.get
mix bs stats              # graph overview
mix bs list               # list beliefs
mix bs show cb:c038       # one contract in full (schema discipline)
mix bs tree cb:c038       # a contract and its dependency context
mix cb.verify.schema      # check the struct against the in-graph schema contracts
```

Belief ids are namespaced (`cb:`), so the shell takes the full id. See the guided tour in `belief-collections` (`../belief-collections/quickstart.md`).

## Walkthrough: tracing an eval verdict to its evidence

This walkthrough teaches one thing end to end: in CB, an eval verdict is not a free-floating score - it is a belief whose every dependency you can walk back to the exact model runs and raw logs that produced it, deterministically, with no LLM in the loop. The vehicle is the `sdl` collection (`eval-provenance`): a published eval, `silent-data-loss-v1`, rendered in miniature. Six beliefs capture two scorer observations of a single failing case, the cross-ruler verdict they compose into, the routing guidance that follows, and the collection's own artifact-scheme contract.

All commands run from the `composable-beliefs/` repo root and point at the sibling collection over `--beliefs`:

```sh
mix deps.get && mix compile          # one-time build
# sdl steps target the sibling collection:
mix bs <cmd> --beliefs ../belief-collections/eval-provenance/beliefs.json
```

You can set `CB_BELIEFS=../belief-collections/eval-provenance/beliefs.json` once instead of repeating the flag. One caveat: the final two steps query CB's own graph (`beliefs/beliefs.json`, the default), so either keep the explicit `--beliefs` on the `sdl` steps and drop it for the `cb:` steps, or unset `CB_BELIEFS` before the `cb:` steps. This walkthrough uses the explicit flag throughout.

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
  PASS  no implication field - no belief carries the deleted implication field
  PASS  action-item shape - all action-items are non-contract implications with empty rules/invariants
  PASS  compound/implication deps - all active compounds and non-contract implications have non-empty deps
  PASS  status enum - all nodes have status in ["active", "superseded", "retracted", "retired"] (framework canon)
  PASS  superseded linkage - all superseded nodes link to successor
  PASS  retracted linkage - all retracted nodes have date and reason
  PASS  c-prefix is contract-grade - all c-prefix IDs carry contract: true
  
14 passed, 0 failed, 2 skipped (16 checks)
```

The interesting line is `schema roles discovered`. The verifier does not match contracts by hardcoded id. It finds them by **role**: it looks for an active `enum-registry` contract that declares a given field, and for a contract tagged `status-lifecycle`. Here it discovers `artifact-scheme=sdl:c1` (the collection's own enum) and falls back to framework canon for the status lifecycle. This is why a brand-new collection passes rules it never restated: framework-universal checks (the `type` enum, the contract biconditional, the `scheme:id` artifact format, the c-prefix rule) are applied by role, not copied into the collection.

The two `SKIP`s are expected. `sdl` declares an artifact-scheme enum but no enum-registry contract for `kind` or `domain`, so those checks have nothing to enforce and skip rather than fail. In real use a collection borrows `kind` and `domain` from `cb:` and the skips disappear.

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

```sh
mix bs show cb:c040
```

```
ID:          cb:c040
Type:        implication (contract)
Kind:        enum-registry
Domain:      system
Name:        -
Claim:       Canonical enum of artifact URI schemes. Each scheme declared inline with its URI form. The enum is closed: no artifact value with a scheme outside this set is permitted on active beliefs.
Status:      active
Tags:        dag-schema, enum, artifact-scheme
Subjects:    a mix task (module)
Deps:        cb:a397, cb:a398, cb:a407
Rules:       1 rule(s)
Invariants:
             - Exactly one rule entry, with field 'artifact-scheme'.
             - Each value matches /^[a-z][a-z0-9-]*$/.
             - Values are unique within the entry.
             - Every value has a corresponding entry in the definitions map.
             - For all active beliefs b where b.artifact is not null: scheme(b.artifact) is in values.
Evidence:    reshaped rules from 'artifact-scheme:<value> - <definition>' strings to a single {field,values,definitions} enum-registry entry; switched kind schema->enum-registry and added the new 'plan' scheme (handoff section 2.5); representational, content-preserving (definitions retained verbatim).
             artifact: session:2026-06-07-cb-restructure-stage2
             date: 2026-06-07
Materialized: -
Support:     artifacts=2 evidence=1 deps=3
Created:     2026-05-15
```

The framework's own schema is beliefs in exactly the shape you just traced. `cb:c038` is a `[contract]` whose deps are primitives (`cb:a397`-`a405`, `cb:a408`) - the same composition you saw in `sdl:a3`, applied to the schema itself. Three of those primitives are the rules the `sdl` example obeys:

- **`cb:a398`** defines the artifact field as a typed URI of form `scheme:id`. This is the rule that makes `eval:silent-data-loss-v1/run3/case7/...` a well-formed artifact at all.
- **`cb:a397`** says enum-shaped fields take their values from dedicated enum contracts, and - critically - that "adding an enum value supersedes the enum contract for that field." That is precisely how `eval:` would be added to `cb:c040` for real.
- **`cb:a408`** is the deps-vs-subjects distinction the `sdl` beliefs follow throughout: `deps` is belief-to-belief derivation, `subjects` is belief-to-entity topical reference.

`cb:c040` is the closed artifact-scheme enum, itself a contract-grade implication (`Type: implication (contract)`). The `c` prefix marks contract-grade beliefs: the verifier enforces the rule that every `c`-prefixed id carries `contract: true`. (The reverse - that every contract uses a `c` prefix - is a naming convention, not a checked invariant.)

### What you just traced

Starting from a single verdict you walked, deterministically and with no LLM in the loop:

- **the verdict** - `sdl:a4`, "do not use it unguarded for bulk record operations";
- **why we believe it** - `sdl:a3`, cross-ruler agreement that neither scorer states alone;
- **the exact model runs** - `sdl:a1` and `sdl:a2`, the deterministic and LLM-judge scorers of `run3/case7`, each grounded in an `eval:` identity URI;
- **the raw logs** - `document:logs/run3/case7.json`, the evidence artifact reachable from the `show` view.

And you saw that the framework describing all of this is itself the same kind of graph: `cb:c038`/`cb:c040` are beliefs you query with the same `bs` commands.

The one production prerequisite to run this for real in the `cb:` graph is to add the `eval` scheme to `cb:c040` - an additive supersession of the enum contract per `cb:a397`, gated on authorization to modify the canonical graph. Nothing else in `cb` changes: the schema, the verifier's role-based discovery, the query surface, and the staleness model all already accommodate it.

## Honest status - where this actually stands

To calibrate expectations:

- **Real and tested.** The deterministic graph layer (the belief shell, traversal, supersession, staleness, conflict-preflight, the contract interpreters, schema verification) is the solid core, with a green test suite and `cb.verify.schema`.
- **Demonstrated, not yet load-bearing at runtime.** Beliefs are currently *authored* and *compiled into context at session start*; no hook yet queries the graph *contextually at decision time*. Until that exists, the graph is high-value developer-facing structure, not yet an operational runtime substrate. A development state, not a refutation.
- **Stubbed.** The materializer (implication to action items) ships a generic JSON sink; wiring it to a real task system is the host's job (`CB.Materializer.Sink`).
- **Out of scope here.** A graph-visualization / dashboard UI; the skills assume a Claude-Code-style agent harness.

## Origin

CB was extracted and decoupled from a live operational system where the graph was built and battle-tested against real workflows. The proprietary domain data was removed; what ships here is the generic framework plus its own self-describing design graph.

## License

Licensed under the Apache License, Version 2.0 - see [`LICENSE`](LICENSE).
