# 2 · The schema

A belief is one struct; its meaning is a family of contracts; and the two are kept honest against each other by a test. This chapter walks the record field by field, slows down on the four provenance fields where most authoring mistakes happen, shows how a prescription hardens into a machine-checkable contract, and closes with the loop that lets the graph describe - and verify - its own schema.

## The belief, field by field

Every belief is a `%CB.Belief{}` struct defined in one file, `lib/cb/belief.ex`. That file is the schema's single source of truth in code; the contracts in the graph are its source of truth in meaning, and `mix cb.verify.schema` checks the two against each other so they cannot silently drift (`cb:a482`). Fields are emitted to JSON in one canonical order (`@ordered_keys`), so two graphs with the same content serialize byte-for-byte the same.

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Namespaced id, `namespace:local` (e.g. `cb:c051`). Globally unique; the local prefix encodes grade by convention. |
| `type` | string | One of the four structural types ([chapter 1](1-epistemics.md)). The spine of the schema. |
| `kind` | string | Semantic category, enum-validated by `cb:c039` (38 values). |
| `domain` | string | Subject area, enum-validated by `cb:c041` (five values). |
| `tags` | list | Flat cross-cutting labels. |
| `name` | string | Optional human handle (contracts often carry one, e.g. `dag-status-lifecycle`). |
| `who` | string | Optional attribution. |
| `claim` | string | The proposition the belief asserts. One line. |
| `rules` | list of maps | Contract routing rows (a tiny Datalog relation). |
| `invariants` | list | Contract invariant statements. |
| `contract` | boolean | Legacy stored marker; no longer trusted - contract-grade is derived (see below). |
| `artifact` | string | Provenance URI `scheme:rest`; scheme drawn from `cb:c067`. |
| `evidence` | list of maps | Dated `{date, detail, artifact}` entries. |
| `subjects` | list of maps | `{ref, type}` pairs: what the belief is about. |
| `deps` | list | Upstream belief ids: the DAG edges. |
| `materialized` | map | `{date, tasks}`: link to executed action items (prescriptions only). |
| `status` | string | Lifecycle state, closed enum per `cb:c053`. |
| `superseded_by` | string | Successor id; present exactly when status is `superseded`. |
| `retracted_on` / `retracted_reason` | string | Date and reason; present exactly when status is `retracted`. |
| `created` | string | ISO creation date. |

Two bookkeeping fields never reach disk as content. `_keys` remembers which JSON keys the source object actually had, so when the store rewrites the whole array it puts each record back byte-stably - a field absent on disk stays absent, and a one-belief change does not churn the thousands of untouched records around it. `_raw_type` preserves the type string as read, so a graph still carrying the pre-rename vocabulary round-trips unchanged instead of being rewritten by a read-modify-write cycle.

**Ids and the c-prefix.** An id is a namespace and a local id joined by a colon; one collection owns each namespace, so ids are globally unique, and a bare local id (`c051`) resolves to its unique namespaced match. The local prefix carries grade by convention: `c###` marks a contract, `a###` everything else, `o-<hash>` eval observations, `t####` todos. The verifier enforces that the convention is *followed* (every `c`-prefixed belief must actually be contract-grade), but the prefix is never the definition - contract identity is structural, below.

**Fields that do not exist.** Knowing what is gone is as clarifying as knowing what remains. Four things were deliberately removed, and `from_map/1` strips them on read so legacy data round-trips clean:

| Removed | Why | Carried now by |
| --- | --- | --- |
| `confidence` | a subjective scalar with no deterministic basis does no load-bearing work (`cb:a448`) | `CB.Belief.support/1`: counts of artifacts, evidence, deps |
| `source` | an untyped free-text origin field | `artifact`: a typed, scheme-validated provenance URI |
| `implication` | one field name sat on both sides of the is/ought boundary | `claim` plus `deps` |
| `patch` (kind) | an in-place edit dressed up as a record | supersession |

The stored `contract` boolean followed the same path in the schema-v3 pass: a field provably equal to `rules != [] or invariants != []` carries no independent information, so contract-grade is now **computed on read** by `CB.Belief.contract?/1`. Unmigrated data may still carry the key; it round-trips untouched but is no longer trusted, and the verifier checks that any stored value agrees with the derived definition.

> **Pitfall.** Reaching for a field the schema removed. The instinct to write `confidence: 0.7` or a free-text `source:` note is exactly the instinct the schema was redesigned to refuse, and `from_map/1` silently drops the key on the next read. When you feel the urge, the schema is pointing you at the replacement: structural support for confidence, a typed artifact for a source, supersession for an edit. The replacement is queryable; the removed field was not.

## Three closed enums, each a contract

Three fields draw from closed vocabularies, and each vocabulary is itself a contract living in the graph. Adding a value supersedes the enum contract, so the set of allowed values carries the same audit trail as any other claim (`cb:a397`).

- **`kind` - 38 values (`cb:c039`).** The semantic category: `observation`, `policy`, `convention`, `action-item`, `design-principle`, `state-machine`, `enum-registry`, `definition`, and so on. Each value has an inline definition in the contract, so the vocabulary documents itself. In the live `cb:` graph the most-used kinds are `action-item` (44), `convention` (34), and `schema` (16).
- **`domain` - 5 values (`cb:c041`).** `system`, `design`, `agent`, `ops`, `dev`. Domain is load-bearing for the conflict audit: two prescriptions in different domains are never even candidates for contradiction.
- **artifact scheme - 8 values (`cb:c067`).** `document`, `code`, `session`, `user`, `source`, `https`, `plan`, `commit`. Detailed in the next section.

The scheme enum's own history shows the discipline in action: `cb:c043` added `code:`; `cb:c066` superseded it to *drop* the connector-specific `gmail:` scheme (naming an external product inside a core enum violated the rule that the framework core names no connector, and no active belief used it); `cb:c067` superseded that to add `commit:`, making the belief-to-commit link structural rather than prose convention. Walk it with `mix bs history cb:c067`.

**Kind binds mood: the kind-type table.** `kind` and `type` are not independent. Contract `cb:c057`, a derivation-table with one row per kind, binds each kind to the structural types it may inhabit:

| Kind group | Allowed types | Example kinds |
| --- | --- | --- |
| Prescriptive (15) | `prescription` only | `policy`, `rule`, `convention`, `action-item`, `enum-registry`, `state-machine`, `output-target` |
| Descriptive (21) | `attestation` / `aggregation` / `inference` | `observation`, `fact`, `error`, `design-observation`, `outcome-claim` |
| Dual (2) | all four | `definition`, `schema` |

A `convention` can only ride a prescription, because a convention is something the house stands behind; an `observation` can never be one, because it describes rather than prescribes. The two dual kinds span the boundary, and the structural type is then decided per belief by direction of fit. Put the enums and the table together and you get the type-as-a-function property from chapter 1: mood from the kind, grounding from the provenance shape, scope from subject containment - three signals the verifier reads off the record, never off the author's intent (`cb:a472`).

## Provenance: artifact, evidence, subjects, deps

Composable Beliefs rests on a single promise: a claim with no named source does no load-bearing work. Four fields keep that promise, and three of the four are routinely confused with each other.

**`artifact` - where the belief came from.** A typed URI naming the external referent the belief was derived from (`cb:a398`, `cb:a400`), in the form `scheme:rest`, scheme drawn from `cb:c067`:

| Scheme | Names | Form |
| --- | --- | --- |
| `document:` | a whole repository file | `document:<repo-relative-path>` |
| `code:` | an anchored site *within* a file, parsed by `CB.CodeLocator` | `code:<path>#<anchor>[@N]` |
| `session:` | a working session | `session:<date-or-descriptor>` |
| `user:` | a direct user statement | `user:<name>:<date>` |
| `source:` | a cached external source document | `source:<slug>` |
| `https:` | an external URL | `https:<URL-rest>` |
| `plan:` | a plan or spec | `plan:<id-or-descriptor>` |
| `commit:` | a git commit implementing a discharge | `commit:<full-40-hex-sha>` |

Four schemes form the **stipulation subset**. A prescription that encodes an adopted convention has no upstream beliefs to ground in, so `cb:c059` lets it ground in a stipulation artifact instead: one of `plan:`, `user:`, `session:`, or `document:` - all records of a decision someone made. An external `source:` or `https:` reference never grounds a prescription, because a web page you merely read cannot adopt a convention on your behalf. A rule rests on an act of adoption, not on a citation.

The `commit:` scheme is the newest, and it closes a provenance loop in the other direction: a prescription's discharge can cite the implementing commit as a typed artifact, `mix cb.verify.commits` dereferences every cited sha, and commits carry `Belief:` trailers naming the beliefs they implement - the belief-to-code link enforced both ways in CI ([chapter 3](3-operations.md#the-write-flow) covers the gate on the todo front door).

> **Background.** The artifact *on the belief* is enum-checked; artifacts *inside evidence entries* are not. Evidence is free to cite the mechanics of how an entry was added - `adjudication:` on a write that came through the conflict flow, for example. The closed enum governs the belief's primary source.

**`evidence` - what the source actually said.** Each entry is a dated `{date, detail, artifact}` map, and the split between claim and evidence is the most important idea in this section. The claim is the generalization - the author's interpretation; each evidence `detail` is the specific narrative of what the source said (`cb:a118`). The gap between them is where misinterpretation lives *and can be audited*: a later session reads the evidence and asks the one question that keeps a graph honest - does this claim actually follow from these words? Look at `cb:a386` from chapter 1: a broad claim about caching antipatterns, one narrow dated evidence entry about a single session. A reviewer who doubts the generalization goes straight to the evidence and weighs whether one session warrants it.

Evidence is also the single exception to immutability - the append-only front door `mix cb.evidence` (`cb:a302`, `cb:a522`). Accumulating more support for a standing claim does not change what the claim says, so it needs no supersession.

**`deps` versus `subjects` - derivation versus aboutness.** A belief carries two distinct relations, and confusing them is the mistake that quietly breaks the model (`cb:a408`):

- **`deps`** is belief-to-belief *logical derivation*: the deps' claims together justify this claim. Required on aggregations and inferences, required-or-stipulated on prescriptions, absent on attestations. These are the edges of the DAG.
- **`subjects`** is belief-to-entity *topical reference*: what the belief is about. Each subject is a `{ref, type}` pair naming a file, a module, a model, an eval run, sometimes another belief.

The two are independent: a belief can be about something without depending on it, and depend on something without being about it. `cb:a386` is *about* the digest file (its one subject) yet *depends on* nothing (it is an attestation - a leaf). The confusion breaks the model because the verifier reasons over deps as logical support and over subjects as scope: smuggle a topical reference into `deps` and you assert a derivation that does not exist, corrupting the staleness walk and the grounding check; drop a real derivation into `subjects` and the belief looks ungrounded. The test that re-derives the rule: is this claim *justified by* the other thing's claim (dep), or merely *about* it (subject)?

**`claim` is a one-liner.** The provenance fields only work if the claim they support stays small: a single proposition (`cb:a114`). Multi-paragraph analyses are not a belief kind. The right home for a long analysis is a source document that cites belief ids inline, with any durable claim extracted into the graph as its own one-line belief - prose for the narrative, the graph for the atomic claims the narrative rests on.

**Provenance is created at extraction time.** A belief is authored while the agent is actively reading the source, not backfilled later from memory (`cb:a119`) - provenance written from memory is provenance you cannot trust. This rests on a prior distinction: sources are not beliefs (`cb:a113`). The source is raw material; the graph stores the distilled claims that cite it. A graph that swallowed its sources whole would be a copy of everything ever read, and would lose the claim-evidence gap that makes auditing possible.

> **Caveat.** A non-empty `deps` list is necessary, not sufficient. The verifier checks that deps resolve and (for aggregations) that subjects stay contained; it cannot check that the deps' claims *actually justify* this claim. That step is the author's responsibility - and it is the step the evidence array exists to make auditable after the fact.

## Contracts: prescriptions with teeth

A contract is a belief a machine can check. It is not a fifth type: a belief is contract-grade exactly when its type is `prescription` and its `rules` or `invariants` are non-empty (`cb:c054`), detected structurally via `CB.Belief.contract?/1` and never by id prefix. The division of labour inside such a belief is worth memorizing, from the founding definition `cb:a300`: the **claim** states WHAT (the one-line conclusion); the **rules** state HOW (routing rows saying which check fires under which condition); the **invariants** state ALWAYS (conditions that must hold over every node the contract governs).

A plain belief and a contract are two roles sharing one store (`cb:a120`): a belief says *this is true*; a contract says *this will remain true*. That single difference predicts the lifecycle - a belief can go stale and be superseded by a better-grounded successor; a contract is violated or upheld, and a violation surfaces as a failing check rather than a quiet drift.

**The rule-kind catalogue.** Contract rules are not free-form prose. They decompose into a closed catalogue (`cb:c046`): each kind pairs a Datalog-shaped declarative fact with exactly one Elixir interpreter. Datalog supplies the fact *shape* only; evaluation lives in ordinary code. The catalogue is closed by its own invariant, so adding a kind supersedes the catalogue contract itself - which is on record as having happened when `output-target` was catalogued.

| Rule kind | Fact shape | Interpreter | Governs |
| --- | --- | --- | --- |
| `state-machine` | `edge(From, To, Requires)` | `CB.Belief.Contract.StateMachine` | the status lifecycle (`cb:c053`) |
| `enum-registry` | `allowed(Field, Value)` | `CB.Belief.Contract.Enum` | the closed `kind`/`domain`/artifact-scheme enums |
| `derivation-table` | `row(Col1, ..., ColN)` | `CB.Belief.Contract.Table` | the kind-type table (`cb:c057`); the catalogue itself |
| `implies` | `implies(When, Requires)` | `CB.Belief.Contract.Implies` | predicate routing: codepath assertions, methodology checks |
| `output-target` | `field(Name, Spec)` | `CB.OutputTarget` | compiled documents and codepath render-specs |

Walk one concretely. The lifecycle contract `cb:c053` carries `kind: "state-machine"` and rows like `{"from": "active", "to": "superseded", "requires": "superseded_by"}`. The `StateMachine` interpreter reads exactly these rows and answers `edges/1`, `requires/2`, `valid_edge?/2`. It is the routing table and nothing more: it tells you the edge requires `superseded_by`; the code that actually checks the field is present lives on the other side of the line.

**The routing/implementation boundary.** That line is the keystone of the design (`cb:c047`): **contracts carry routing tables; modules carry predicate implementations.** The graph expresses which predicates fire on which conditions; it never stores executable code.

```
THE GRAPH (data)                      THE MODULES (code)
----------------                      ------------------
contract cb:c053                      CB.Belief.Contract.StateMachine
  kind: state-machine        routes   reads the rows and answers
  rules:                     ------>  "which edges exist, what each
    active -> superseded              requires"
      requires: superseded_by         (it does NOT evaluate the field -
    active -> retracted               that stays on the code side)
      requires: ...

  "which predicate fires              "how the predicate is
   on which condition"                 implemented"
              \                        /
          the line nothing crosses:
     no executable string is stored in the DAG
```

Why hold the line so strictly? An executable string in the DAG has nothing to grab onto: the compiler cannot type-check it, the editor cannot refactor it, a search for callers never finds it, and the test machinery skips it. By keeping the graph to tabular routing and pushing every predicate body into a real module, the framework lets the graph *drive* tests while the safety of those tests comes from ordinary compiled code. The shared gate, `CB.PredicateGate.resolve/3`, refuses any routed name that does not both match the predicate-name pattern and resolve to an exported function of the expected arity.

**Verification, not generation.** Given a precise contract and a module that should obey it, the tempting move is to *generate* the module from the contract. The framework refuses (`cb:a465`): spec-to-code generation is nondeterministic, unmaintainable, and inverts authority so the generated artifact becomes the thing you actually run. The sanctioned relationship is the `verify_against_contract` pattern (`cb:a417`, `cb:a425`): the module is hand-written, and a test reads the in-graph contract and asserts the module's behavior matches. Change the code but not the contract, or supersede the contract but not the code, and the next test run fails loudly at the seam.

**Neither prose nor code.** Step back and the contract occupies a level of formality neither plain English nor raw code reaches (`cb:a300`, from `cb:a133`/`cb:a134`/`cb:a135`). A prose rule cannot be mechanically checked; nothing tells you when the code has drifted from it. Raw code runs, but cannot carry its own rationale, provenance, or supersession history. A contract does both: domain-bound (it survives a code rewrite), substrate-independent (one state-machine contract can be obeyed by compiled code and by an agent reasoning in a prompt), and mechanically checkable (contracts generate tests, never the other way around). This also explains where contracts come from: a behavioral invariant first lives as a prompt-enforced prescription, and when code crystallizes around it, it hardens to contract grade (`cb:a173`). The same gradient reappears in [codepaths](4-code.md), where a narrated claim about code hardens into an assertion that runs.

## The graph describes itself

There is no separate schema file in some validation language sitting outside the data. The rules that say what a valid belief looks like are contracts *inside* the graph (`cb:a482`), queryable with the same `mix bs show` as anything else. The working set:

| Contract | Name | What it governs |
| --- | --- | --- |
| `cb:c051` | dag-structural-types | the four types, one per epistemic operation; type determines which fields are meaningful |
| `cb:c052` | dag-field-presence | field presence by type: aggregations/inferences require deps; prescriptions require deps or a stipulation artifact; contract fields are prescription-only |
| `cb:c053` | dag-status-lifecycle | the status state machine; all non-active states terminal with required linkage |
| `cb:c054` | contract-identity | contract-grade iff prescription with non-empty rules/invariants; detect structurally, never by id |
| `cb:c055` | conflict-scope-definition | two active prescriptions conflict-scope on a shared tag, subject ref, or subject type within one domain |
| `cb:c056` | schema discipline | the umbrella: provenance via `artifact`, contract-grade as derived, no `implication` field, enum-field binding, kind-type binding |
| `cb:c057` | kind-type-table | each kind maps to the structural types it may inhabit |
| `cb:c058` | subject-containment | an aggregation's subjects stay inside the union of its deps' subjects |
| `cb:c059` | prescription-grounding | deps or a stipulation artifact; external schemes never ground a prescription |
| `cb:c039` / `cb:c041` / `cb:c067` | enum registries | the closed kind, domain, and artifact-scheme vocabularies |
| `cb:c046` / `cb:c047` | rule-kind catalogue; routing boundary | how contract rules decompose and where implementations live |
| `cb:c064` | preflight escalation | when a matched belief becomes a blocking conflict in the write flow |
| `cb:c065` | claude-md-compile | CLAUDE.md compiles from the graph; every output line traces to one belief |

Notice the schema uses the framework's own machinery to describe itself: the lifecycle is a state-machine contract, the vocabularies are enum-registries, the kind-type table is a derivation-table. None of these is special-cased in code as "the schema" - they are ordinary contracts that happen to be about the shape of beliefs.

**Discovered by role, not by id.** If the verifier knew these contracts by id, the scheme would collapse the moment another collection declared its own enums under different ids. So `CB.Schema.Verifier` finds each contract by the role it plays: an enum-registry by the field it declares, the status lifecycle by its tag, the kind-type table by its columns. At no point does it match on `cb:c041`. Hand it a collection that declares its own domain enum under a different id and the same code validates against that one.

> **Key idea.** The verifier reads the schema the way a borrower would. Because it discovers contracts by role, it has no privileged knowledge of the `cb:` collection - the framework verifies its own graph with the identical code path it offers anyone who borrows the schema ([chapter 5](5-collections.md)).

The corollary that surprises people: a field with no enum contract has its check **skipped, not failed**. The verifier returns `{name, :ok | :fail | :skip, detail}` tuples precisely so that "I had nothing to check here" stays distinct from "I checked and it was wrong". On the `cb:` collection, which declares all three enums, a skip signals a missing contract; on a thin borrowing collection, skips are expected and correct.

**The dogfooding loop.** `mix cb.verify.schema` runs the verifier over both the live graph and the `CB.Belief` struct itself, against the same in-graph contracts. The closing edge is a test, `test/cb/schema_contracts_test.exs`, which asserts the struct matches the contracts in both directions - for example, that the states the `StateMachine` interpreter derives from `cb:c053` equal exactly `CB.Belief.statuses/0`. Add a status to the code without superseding the contract, or supersede the contract without touching the code, and the build goes red. This is the schema's own instance of verification-not-generation: hand-written struct, declared contracts, a test standing between them.

**Two ways the schema itself changes.** The graph's own history shows both sanctioned paths. A change of *content* is a supersession through adjudication: the three-type contract `cb:c026` fell to the four-type `cb:c051`; six contracts fell in one adjudicated sweep when the v2 schema landed. A change of *label only* is a vocabulary migration: the 2026-07-01 type rename rewrote every node's type string in one recorded pass, with the rationale carried as evidence on `cb:c051` and the code shim accepting both vocabularies for the compat epoch - identity and claims unchanged, so no supersession. Both leave a trace; neither is a hand-edit; and there is no third path (`cb:a498`).

---

Next: [chapter 3, operating the graph](3-operations.md) - the read surface, the write flow that keeps you from hand-editing, obligation, staleness, and the nursery.

> **Grounding.**
> - In the graph: `cb:a482` (the schema lives in `belief.ex` and the graph's contracts, kept in sync by verify.schema), the contract family tabled above, `cb:a397` (enum changes supersede the enum contract), `cb:a398`/`cb:a400` (artifact as typed URI), `cb:a118` (the claim-evidence gap), `cb:a408` (deps versus subjects), `cb:a114` (claim is a one-liner), `cb:a119` (extraction-time discipline), `cb:a113` (sources are not beliefs), `cb:c054`/`cb:a300` (contract identity and the WHAT/HOW/ALWAYS split), `cb:a120` (two roles, one store), `cb:c046`/`cb:c047` (the catalogue and the routing boundary), `cb:a465`/`cb:a417`/`cb:a425` (verification, not generation), `cb:a133`/`cb:a134`/`cb:a135` (neither prose nor code), `cb:a173` (inferences prototype contracts).
> - In the code: `lib/cb/belief.ex` (the struct, `@ordered_keys`, `_keys`/`_raw_type`, `from_map/1`, `to_map/1`, `contract?/1`, `support/1`), `lib/cb/schema/verifier.ex` (role discovery, the three-valued checks), the interpreters under `lib/cb/belief/contract/`, `lib/cb/output_target.ex`, `lib/cb/predicate_gate.ex`, `lib/cb/code_locator.ex`, `test/cb/schema_contracts_test.exs`.
