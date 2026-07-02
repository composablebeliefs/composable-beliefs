# 6 · Inside the code

The entire framework is deterministic graph code over a single JSON file. No database, no server, no model call anywhere in the read path. This chapter traces the pipeline from disk to structs and back, explains why a flat list with string-id edges is the whole graph in memory, and maps the layers that hang off it.

## A pure graph over one file

The Elixir application `:cb` has a single runtime dependency: `jason`, the JSON codec. A graph is a file on disk; reading it is a decode; writing it is an encode. That is the entire I/O story.

Two properties fall out and shape everything else. First, every public function returns `{:ok, _} | {:error, _}` - nothing raises across a module boundary, and the only deliberate `System.halt` lives in the mix tasks at the very edge. That uniform contract is why the same `lib/` modules can drive both one-shot `mix` commands and a long-lived server process without change. Second, the read path is deterministic: the same file decodes to the same structs every time, because nothing in the path reasons or samples. A test suite plus CI gates (schema verification, the anchor-rot guard, the CLAUDE.md freshness check) hold the whole thing together on every push.

## The data-flow pipeline

```
beliefs/beliefs.json          canonical store: a JSON array of beliefs
        |                       File.read + Jason.decode
        v
CB.JSON.read/1                raw decode -> {:ok, list}
        |
        v
CB.Belief.Store.read/0        Enum.map(data, &CB.Belief.from_map/1)
        |
        v
[ %CB.Belief{} ]              in-memory list of structs = THE graph
        |
        +--> CB.Belief.Graph.index/1        -> %{id => belief}
        |
        +--> query  : Filter + Graph + Formatter        (mix bs)
        +--> verify : Schema.Verifier / method checks   (cb.verify.*)
        +--> render : OutputTarget / Codepath / Audit   (cb.render.*, generate.*)
        +--> write  : Mutation / Adjudication -> Store.write/2
        |               Enum.map(_, &CB.Belief.to_map/1)
        |               Jason.encode!(pretty: true)
        v             CB.JSON.write_atomic_raw/2  (tmp + rename)
beliefs/beliefs.json
```

One read path in at the top, four uses of the loaded list in the middle, one write path back to disk at the bottom. Every stage is pure and returns a tagged tuple; these are the actual call sites, not a metaphor.

## The graph in memory is a flat list

There is no graph object. The graph in memory is a flat `[%CB.Belief{}]` list, nothing more. Edges are implicit: a belief's `deps` holds string ids naming other beliefs, and a traversal follows those strings. For fast lookup, `CB.Belief.Graph.index/1` builds a `%{id => belief}` map on demand. Forward edges are a direct read of `deps`; reverse edges are not stored anywhere - `dependents` is computed by scanning every belief's deps for the target id.

> **Key idea.** There is no graph data structure to keep consistent - only a list of structs and an index derived from it on demand. Every traversal recomputes what it needs from that one list. The simplicity is what makes the read path trivially deterministic and trivially testable.

One consequence surprises people: **the collection is a DAG by discipline, not by enforcement.** Nothing in the storage rejects a belief whose deps eventually point back to itself. The defense is local instead - every recursive walker carries its own `MapSet` visited set (the dependency walk, the eval predicates, the codepath traversal), because nothing upstream guarantees the input is acyclic. If you write a new traversal, it carries its own visited set too.

**The `_keys` shadow field** answers the question a whole-array store raises: if every write re-encodes the whole file, why doesn't it churn records nobody touched? Each struct remembers which JSON keys its source object actually had, and `to_map/1` emits a field only if it was originally present or now holds a meaningful value, in one canonical key order. Load the graph, change one belief, write it back, and the diff touches only that belief - byte-stable round-trips across hundreds of untouched records. (The planned per-belief-file layout, `cb:b554`, retires this workaround; see [chapter 5](5-collections.md#storage-one-file-today-one-file-per-node-next).)

**The store boundary.** All disk traffic goes through exactly one place: `CB.Belief.Store` - one read path (`read/0`, treating a missing file as an empty graph) and one write path (`write/2`, bottoming out in `CB.JSON.write_atomic_raw/2`, the tmp-write-then-rename move that means a crash mid-write never leaves a half-written graph). Which file the store touches comes from `CB.Config.beliefs_path/0`, with fixed precedence: the application-env value set by `--beliefs PATH` for one task run, then the `CB_BELIEFS` environment variable, then the default. Pointing the whole system at another collection is a single assignment; it reverts when the task exits. This chokepoint is also why the storage-layout migration can land without touching anything downstream.

## The layers

Around seventy modules organize into layers, each hanging off the loaded list. The map below is the tour; each module's moduledoc carries the detail, and earlier chapters cover the concepts.

| Layer | Modules | What it does |
| --- | --- | --- |
| **Infrastructure** | `CB`, `CB.Config`, `CB.JSON`, `CB.Display` | repo root and path resolution, atomic JSON I/O, terminal rendering shared by the tasks |
| **Schema core** | `CB.Belief`, `CB.Belief.Store`, `CB.Belief.Graph`, `CB.Belief.Filter`, `CB.Belief.Formatter` | the struct with byte-stable serialization, the store boundary, pure traversal (index, tree, stale, history, recent, path, stats), composable filters, ANSI rendering |
| **Contract interpreters** | `CB.Belief.Contract.{StateMachine,Enum,Table,Implies}`, `CB.OutputTarget`, `CB.PredicateGate` | one interpreter per rule kind ([chapter 2](2-schema.md#contracts-prescriptions-with-teeth)); document compilation and render-spec validation; the shared gate that resolves routed predicate names safely |
| **Verification** | `CB.Schema.Verifier`, `CB.Collection`, `CB.Method.Checks` | discovery-by-role schema checks with `:ok/:fail/:skip` outcomes; dependency-closure loading and union verification; the eval methodology pass |
| **Write flow** | `CB.Belief.Conflict`, `CB.Belief.Adjudication`, `CB.Belief.Mutation`, `CB.Belief.EditPairs` | preflight bucketing, the three adjudication outcomes with race guard, the typed mutation engine where every edit appends evidence |
| **Materialization** | `CB.Belief.Materializer`, `CB.Materializer.Sink` (+ `Sink.JSON`, `Sink.Test`), `CB.Todos` | prescription -> action items -> pluggable sink -> link back; the todo collection and its commit-gated close |
| **Anchoring and codepaths** | `CB.CodeLocator`, `CB.Anchor`, `CB.Codepath` (+ `Predicates`, `Assertions`) | the `code:` grammar, fixed-string resolution, tour rendering and the dynamic verifier ([chapter 4](4-code.md)) |
| **Commit provenance** | `CB.CommitLocator`, `CB.Commits` | the `commit:` scheme parser and the two-way belief-commit verification |
| **Eval ingestion** | `CB.Eval.Manifest`, `CB.Eval.Predicates` | run-manifest parsing and deterministic observation emission; the eval graph predicates ([chapter 7](7-eval-ledger.md)) |
| **Audit and render** | `CB.Audit.Conflicts`, `CB.Render.Audit` | the standing conflict-scope audit; the self-contained HTML evidence tree |
| **OKF interop** | `CB.Okf.{Emit,Ingest,Manifest,Validate,Frontmatter}` | the bridge between the belief layer and the cb-okf prose layer ([chapter 5](5-collections.md)) |
| **The edge** | `lib/mix/tasks/*.ex` | thin argv shells over the modules: `bs`, the `cb.*` write/verify/render tasks, the `okf.*` tasks. Write tasks apply only with `--write`. |

## Why this shape

The architecture is shaped by one requirement, worth re-deriving rather than taking on faith. CB exists to give an agent a reasoning record it can trust *without re-running a model to check it*. A read path is trustworthy exactly when nothing in it reasons: decoding JSON into structs and walking string pointers produces the same answer on every machine, every run. The moment a model call entered that path, the graph would become something you have to re-verify by sampling - the property the framework was built to remove (`cb:b539`). The same logic explains immutability: because the store only ever appends nodes or flips status fields under the write flow, the history the graph preserves can be read straight off the file.

> **Caveat.** The whole-array model has costs that scale with graph size: every write re-encodes the entire array, and reverse-edge queries scan every belief's deps. For graphs of hundreds of beliefs per collection this is well within budget, and it buys atomic writes and an index rebuilt fresh on every load with no cache to invalidate. The per-belief-file migration (`cb:b554`-`cb:b560`) is the designed next step; a graph orders of magnitude larger would also want materialized reverse edges. Present simplicity and determinism are being traded for deliberately.

For a point-in-time appraisal of how these docs track the code - method, findings, and the drift patterns to watch for - see the [docs-vs-code audit](../2026-06-23-docs-vs-code-audit.md).

---

Next: [chapter 7, the eval ledger](7-eval-ledger.md) - the first shipped application of the substrate.

> **Grounding.**
> - In the graph: `cb:b112` (the single-file rationale) and `cb:b554`-`cb:b560` (the per-belief-file refinement), `cb:b302` (immutability; change adds to the record), `cb:b539` (the deterministic, model-free read path as the protected asset).
> - In the code: `lib/cb/belief.ex` (`_keys`, `from_map/1`, `to_map/1`), `lib/cb/belief/store.ex` (the store boundary), `lib/cb/json.ex` (`write_atomic_raw/2`), `lib/cb/belief/graph.ex` (`index/1`, the dependents scan, cycle guards), `lib/cb/config.ex` (path precedence), `mix.exs` (the single dependency), and the CI workflow `.github/workflows/composable-beliefs.yml`.
