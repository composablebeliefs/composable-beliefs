# 5 · Collections and memory

A belief graph is rarely one graph. The framework, the argument that motivates it, and every worked example each live in their own collection, in their own namespace, and borrow the framework's contracts by declaring a dependency. This chapter covers the composition model, the storage layout and where it is headed, the cb-okf extension that gives prose knowledge a home, and the boundary that keeps CB from becoming a memory system.

## A collection is a graph plus a manifest

A **collection** is a `beliefs.json` graph in a declared namespace, paired with a sibling `manifest.json` carrying three things: the `namespace` the collection owns, a human `description`, and a cross-namespace `depends_on` list naming the namespaces it borrows from (`cb:a463`). That is the whole declaration - no registration step inside the graph, no schema header. Because every collection is the same shape, you query any of them with the same shell, pointed at a different file (`--beliefs PATH` or `CB_BELIEFS`).

**Namespacing keeps ids globally unique.** `cb:c051` is local id `c051` in the `cb` namespace. The rules are deliberately strict:

- Exactly one owning collection per namespace, so an id is globally unique across the ecosystem.
- Dependencies may cross namespaces, as long as the other namespace is declared in `depends_on`.
- **`cb:` depends only within `cb:`.** Every other collection may depend on the framework graph; it depends on none of them.
- Bare ids resolve when unambiguous; a bare id matching two namespaces is an error, not a guess.

The one-way rule is the load-bearing one. If `cb:` could depend on `agent-behavior:`, shipping the framework would mean shipping the failure-mode catalogue that motivated it, and the framework graph could go stale whenever that catalogue did. The same reasoning gives the content split (`cb:a464`): **`cb:` holds only the framework's what and how** - schema, mechanism, positioning. The motivating *why* lives outside: the agent failure modes in `agent-behavior:`, the paradigm argument in `paradigm:`. A reader who wants the design loads `cb:` alone and finds a complete, internally consistent graph; a reader who wants the motivation loads the collections that depend on it and cite its ids, never the reverse.

## Borrowing by role, and the closure

When a collection declares `depends_on: ["cb"]`, it borrows the framework's contracts - **by the role they play, never by literal id**. This is the discovery-by-role machinery from [chapter 2](2-schema.md#the-graph-describes-itself) doing the work that makes composition possible: the verifier finds an enum contract by the field it declares, the status lifecycle by its tag, the kind-type table by its columns. A borrowing collection that re-declares a vocabulary under its own ids is checked against its own declaration, and a collection that declares no contract for some field has that check **skipped, not failed** - "nothing declares this vocabulary" is a visible outcome distinct from "checked and wrong".

Verification of a borrowing collection runs over the whole closure:

```
mix cb.verify.collection <ns>
  1. closure(ns)  = ns + transitive depends_on   (cycle-safe)
  2. load_union   = one flat [%CB.Belief{}] over the closure
  3. verify + method checks run over that union
```

The namespace-to-path lookup is a small registry, `belief-collections/collections.json`, mapping each namespace to its graph file. The framework's own graph is verified by the exact code path it offers every borrower - composition is not a special mode, just the ordinary case with more than one file loaded.

**The live collection map.** The framework repo ships three collections of its own; the rest live in the sibling `belief-collections` repo:

| Namespace | What it holds | Lives in |
| --- | --- | --- |
| `cb` | the framework's self-describing design graph: schema, mechanism, positioning | this repo, `beliefs/` |
| `codepath` | the code-anchored tour of CB's own pipeline ([chapter 4](4-code.md)) | this repo, `codepath/` |
| `cb-okf` | the operational graph of the cb-okf knowledge extension | this repo, `okf/` |
| `lib` | the lending library, the gentle on-ramp collection (`cb:a459`) | belief-collections |
| `agent-behavior` | the why: the catalogue of agent failure modes CB answers | belief-collections |
| `paradigm` | the broader argument for the paradigm shift | belief-collections |
| `method` | the shared eval methodology contracts ([chapter 7](7-eval-ledger.md)) | belief-collections |
| `sdl`, `toy` | eval provenance: worked-example observations, agreements, verdicts | belief-collections |

Two clusters are worth naming. The eval cluster (`method` + `sdl` + `toy`) is the worked example of all four structural types outside `cb:` - it is where aggregations earn their keep, and where chapter 7 lands. The knowledge cluster (`cb-okf`) is the rest of this chapter. Both borrow `cb:` by role and add their own vocabulary on top - the eval collections declare an `eval:` artifact scheme that `cb:` itself never carries.

> **Pitfall.** Depending on another collection's beliefs without declaring the namespace in your manifest. This *passes* `mix cb.verify.schema`, because the single-collection check counts and defers cross-namespace deps rather than resolving them. The gap surfaces only at `mix cb.verify.collection`, where the closure is built from `depends_on`: an undeclared namespace is never loaded, the dep resolves to nothing, and the check fails. A dep that crosses a namespace boundary is a promise your manifest has to keep.

## Storage: one file today, one file per node next

Each collection is a single `beliefs.json` array. The original rationale (`cb:a112`) was that supersession chains, staleness, and conflict scope all require seeing the whole set at once, and per-*entity* files would scatter that structure. The store reads the whole array once and rewrites it atomically, with the `_keys` mechanism keeping untouched records byte-stable.

That decision has since been refined rather than reversed. `cb:a554` records the current position: per-*belief* files (one JSON file per node, `beliefs/<ns>/<local>.json`) are preferred over both the single array and per-entity grouping - the cross-entity-composition concern does not apply when every node is addressed uniformly, per-node files eliminate the `_keys` churn-suppression workaround, and they prepare the store for a database backend. A worktree prototype proved the loaded graph byte-identical either way. The migration is planted as a plan (`cb:a555`-`cb:a560`) that lands behind the `CB.Belief.Store` chokepoint - the near-sole I/O seam - so the query surface, the verifiers, and this chapter's composition model are unchanged by it. Until that code ships, the single file remains the layout, and `cb:a112`'s supersession is deliberately deferred so the graph never claims a storage shape the code does not implement.

## The cb-okf knowledge extension

CB deliberately holds only verifiable claims, so prose knowledge needs a home of its own. That home is **cb-okf**, folded into this repo at `okf/` (`cb:a546`): CB's dialect of the Open Knowledge Format - plain markdown plus YAML frontmatter, organized in a directory hierarchy, with a generated manifest as the agent's entry index. The directory is both the specification and a working example of itself: `standard/` defines the format, `meta/` is the design record written in it, `demo/` is an example bundle, and a conformance corpus of valid/invalid fixtures is the source of truth for what "valid" means, with the Elixir implementation held to it by test.

The layers map onto one stack:

```
ceiling   Composable Beliefs        knowledge that must stay provably
(opt-in)  the verifiable layer      true; marked tier: cb
-------   --------------------      --------------------------------
middle    synthesis-discipline      cross-linked, history-bearing
          wiki                      prose with a maintenance habit
-------   --------------------      --------------------------------
floor     Open Knowledge Format     portable markdown + YAML
                                    frontmatter + generated manifest
```

The extension's own operational graph is the `cb-okf:` collection (`okf/beliefs.json`, `depends_on: ["cb"]`) - the name marks it as CB's dialect: the OKF floor plus CB's additions (the agent-index manifest and the two-tier model), rather than OKF-native. The [nursery](3-operations.md#the-nursery-where-beliefs-gestate) is a live example of the floor tier in action: an OKF bundle whose format is validated and whose relations deliberately are not.

**The bridge is implemented once**, under `lib/cb/okf/`, driven by four mix tasks: `mix okf.emit` projects the CB graph down to an OKF bundle; `mix okf.ingest` reads a bundle back up; `mix okf.manifest` generates or checks the bundle index; `mix okf.validate` runs the conformance validator. A document projected from a belief is stamped with `tier: cb` frontmatter carrying its `id` and `cb_type`, which is what makes the round trip possible. Emit maps each structural type to a document type - attestation to `reference`, aggregation to `concept`, inference to `analysis`, prescription to `position`.

The projection is lossy by design, and the shape of the loss is the boundary restated in code: **ingest turns every document into exactly one attestation** grounded in `artifact: document:<path>` - no aggregations, no inferences, no deps are inferred from prose. Rebuilding the typed composition is the job of `/assert` and human judgment, never an extraction pass. Prose can be lifted into attestations mechanically; the derivations on top are the work the graph exists to make someone do on purpose.

## The memory boundary

The most important thing CB refuses to become is a memory system (`cb:a539`). Vector memory, model calls, recall and retrieval, and eval execution all stay outside its scope; CB ingests their outputs as observations and audits them. The reason is the property the framework exists to provide: every read - shell, verifier, document compilation - is plain data traversal. Build retrieval into CB and a read becomes a model call: nondeterministic, unauditable, different on each run.

Underneath the refusal is a claim about where the value comes from: **composition, not retrieval** (`cb:a462`). A RAG-style system uses a graph to *find* relevant context - surfacing answers that already exist in the corpus. This graph's value is *concluding* what follows from combining facts. Retrieval can hand you back two observations that a record was dropped on case 7 of two runs; only composition produces the corroboration and the generalization on top. Retrieval finds; composition derives - a similarity index bolted onto the graph would find the leaves and miss the structure.

The same structure serves two readers at once (`cb:a460`): the DAG is a **shared prosthetic** compensating for two different limitations with one queryable object - a human expert's attention-bounded, implicit grasp of the interconnections, and an agent's context loss at every session boundary.

One research question rides on this boundary staying honest: the DAG-versus-prose eval (`cb:a544`) runs the structured CB arm against a prose baseline, and the open direction is to make that baseline a strong, agent-maintained OKF wiki rather than an ad-hoc prose control. Whether structure decisively beats strong plain English is deliberately framed as unsettled - stating "the DAG wins" would be exactly the strawman the belief exists to retire. `mix okf.emit` can generate the structured arm's bundle from the same source graph, so both arms derive from one source.

> **Pitfall.** Trying to make CB do retrieval, or be your memory store. The two tempting moves - bolting a vector index onto `beliefs.json`, or dumping session state into the graph as a recall cache - both forfeit the property the substrate exists for. Work state belongs in prescriptions that are conflict-audited and staleness-linked; prose knowledge belongs in cb-okf; CB stays the layer above, auditing what the other systems store and claim.

---

Next: [chapter 6, inside the code](6-architecture.md) - the Elixir implementation, layer by layer.

> **Grounding.**
> - In the graph: `cb:a463` (namespacing and the one-way dependency rule), `cb:a464` (`cb:` holds only the what and how), `cb:a459` (the lending-library on-ramp), `cb:a112` (the single-file rationale) and `cb:a554`-`cb:a560` (per-belief files: the refinement and its plan), `cb:a546` (fold the knowledge standard in as the extension at `okf/`), `cb:a539` (not a memory system), `cb:a462` (composition over retrieval), `cb:a460` (the shared prosthetic), `cb:a544` (the DAG-versus-prose eval).
> - In the code and repo: `lib/cb/collection.ex` (closure and union), `lib/cb/schema/verifier.ex` (discovery by role; deferred cross-namespace deps), `lib/cb/config.ex` (`--beliefs`/`CB_BELIEFS` precedence), `lib/cb/okf/` and the `mix okf.*` tasks, `okf/` (the standard, its conformance corpus, and the `cb-okf:` manifest), `belief-collections/collections.json` (the registry).
