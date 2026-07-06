# The derived index

A standalone companion to [chapter 4](4-code.md). It documents `CB.Derived` - the structural index of symbol spans and compiler-verified call edges that sits *under* the belief graph, and the doctrine that keeps it there. It is un-numbered because it describes infrastructure beside the epistemic spine, not a step in it: nothing in chapters 0-8 depends on it, but the anchor and codepath machinery of chapter 4 is what it exists to harden.

## Two kinds of knowledge about code

Everything in this repository rests on a distinction the index makes physical. **Asserted** knowledge is what the graph holds: claims someone chose to make, immutable, evidence-grounded, superseded rather than edited. **Derived** knowledge is what a parser or compiler can extract mechanically: which functions exist, who calls whom. Derived facts change with every commit and nobody should have to stand behind them - re-derive and you have the new truth.

That is why code structure must never enter the graph. Representing call edges as beliefs would mean thousands of ceremonial supersessions per commit to track what a re-index gives for free, and would bury the property that makes the graph valuable - every node is something someone stands behind - under mechanical noise. So the derived layer lives in its own artifact with the opposite lifecycle:

| | the graph (`beliefs/`) | the index (`.cb-derived/index.json`) |
| --- | --- | --- |
| a node is | a claim someone made | a fact a tool extracted |
| on change | superseded, with reasons | regenerated, wholesale |
| in git | tracked - it *is* the record | gitignored - it is a cache |
| wrong how | falsifiable, interestingly | stale, boringly |

The index is disposable by construction: delete it, run `mix cb.index`, and you have lost nothing.

## Why the graph wants this layer at all

The anchor machinery of chapter 4 deliberately stores no line numbers: a `code:` locator is a literal substring resolved at render time. That buys refactor-survival and costs structural blindness, in two specific ways:

- a **moved** anchor silently resolves to its new line - nothing says whether it still sits inside the function it was minted against;
- a codepath's narrated stop sequence is reconstructed by hand - nothing checks that the chain of calls it walks actually exists.

Both blind spots need structural facts, and both consumers are contractually **in-process**. Routed codepath predicates must be zero-arity, inspection-only functions resolved by the predicate gate (`cb:b050`, `cb:b047`) - a predicate cannot shell out to an external indexer without making the verify suite depend on that tool's installation and freshness. And `CB.Anchor.resolve/2` runs on every render and verify; its consultations cannot round-trip through a subprocess. An external code-graph tool (a GitNexus, a language server) stays a fine *evidence oracle* for attestations - cited at arm's length like any external source - but for these two consumers the facts must be loadable in the same BEAM. That is the entire reason `CB.Derived` exists, and the reason it is so small.

## What Elixir gives away for free

A polyglot indexer needs tree-sitter grammars and heuristic import/receiver resolution, and honestly scores each guessed edge with a confidence. Elixir code can be analyzed from the inside with none of that:

- `Code.string_to_quoted/2` with token metadata yields the real AST plus `end` positions - symbol spans without heuristics;
- a **compiler tracer** observes every call *as the compiler resolves it* - call edges that are simply true.

So the index carries no confidence scores anywhere. That is not an omission; it is `cb:b448` ("subjective scores synthesized without a deterministic basis do no load-bearing work") satisfied at the root: every row is deterministic, the *derived* form whose door `cb:b390` explicitly left open. The honest limitation is shape, not certainty - dynamic dispatch and `apply/3` never reach the tracer, so their edges are absent rather than guessed.

## Building it

```
mix cb.index                 # symbols + call edges (forces a traced recompile)
mix cb.index --no-calls      # symbols only, no recompile
mix cb.index --paths lib     # comma-separated roots (default lib)
mix cb.index --status        # freshness report; exit 1 when stale or absent
mix cb.index --json          # machine-readable summary
```

On this repository:

```
$ mix cb.index
Compiling 76 files (.ex)
indexed 76 file(s), 993 symbol(s), 12632 call edge(s) -> .cb-derived/index.json
```

Three modules do the work, split so that everything interesting is testable without a compiler in the loop:

- **`CB.Derived.Symbols`** parses each `.ex` file and extracts module and `def`/`defp`/`defmacro`/`defmacrop` rows with line spans. Nested modules concatenate the way the compiler concatenates them; clauses stay separate rows (each has its own span); dynamic heads (`def unquote(name)(...)`) are skipped; a file that does not parse is indexed hash-only with the error recorded, so staleness tracking still covers it.
- **`CB.Derived.Tracer`** collects call events - remote, local, imported, and their macro variants - into a named ETS table. One non-obvious mechanism: the tracer module handed to the compiler is *generated at runtime* (`install/0`), because a forced recompile purges the project's own modules, and a tracer living in `lib/` would vanish mid-compile under the compiler calling it. The generated module is self-contained and purge-proof; the project module shapes its raw rows into edges afterwards.
- **`CB.Derived.Index`** assembles, persists, and queries. `build/2` is pure - it takes the edge list as input rather than running the compiler - and the artifact is byte-stable: same tree, same bytes (key order pinned with `Jason.OrderedObject`, rows sorted at build), so a rebuild diffs clean.

## Querying it

```elixir
{:ok, idx} = CB.Derived.Index.load(File.cwd!())

# The anchor-drift primitive: which symbol does this line sit in?
CB.Derived.Index.enclosing_symbol(idx, "lib/cb/anchor.ex", 40)
#=> %{kind: "def", module: "CB.Anchor", name: "resolve", arity: 2, line: 31, end_line: 46}

# The impact primitive: who calls this?
CB.Derived.Index.calls_to(idx, {CB.Anchor, :resolve, 2})
#=> CB.Codepath.resolve_stop/3 (lib/cb/codepath.ex:126)
#=> Mix.Tasks.Cb.Resolve.resolve_row/2 (lib/mix/tasks/cb.resolve.ex:111)

# The codepath-spine primitive: is this narrated chain real?
CB.Derived.Index.call_chain?(idx, [{CB.Codepath.Predicates, :resolve, 2},
                                   {CB.PredicateGate, :resolve, 3}])
#=> true
CB.Derived.Index.chain_gaps(idx, [{CB.Anchor, :resolve, 2},
                                  {CB.PredicateGate, :resolve, 3}])
#=> [{{CB.Anchor, :resolve, 2}, {CB.PredicateGate, :resolve, 3}}]  # no such edge
```

That `calls_to` answer is worth pausing on: the index names exactly the two consumers that `CB.Anchor`'s own moduledoc names in prose. The derived layer and the asserted layer agree - and only one of them had to be written by hand.

The full surface: `symbols_in/2`, `enclosing_symbol/3`, `defines?/4`, `calls_from/2`, `calls_to/2`, `call_edge?/3`, `call_chain?/2`, `chain_gaps/2`, `stale_files/2`. Modules and functions are stored as strings (`inspect/1` form); queries accept atoms or strings, and nothing on the read path creates an atom from index data - the same discipline the predicate gate applies to names in the DAG.

## Freshness, or: a cache that knows it is one

The digest antipattern (`cb:b386`) says a cached summary becomes silently wrong the moment the world moves. The index is exactly such a cache, so it carries its own staleness signal: a sha256 per indexed file, compared against the working tree by `stale_files/2` and `mix cb.index --status`:

```
$ mix cb.index --status
index fresh
$ echo "# drift" >> lib/cb/anchor.ex && mix cb.index --status
changed: lib/cb/anchor.ex
1 file(s) drifted - run `mix cb.index`
$ echo $?
1
```

A consumer - a structural predicate, an anchor check, a CI step - refuses a stale index instead of answering from it. The rule is the same one the graph applies to itself with `mix bs stale`: detect staleness, never remember to check.

## What it deliberately is not

No embeddings, no hybrid search, no community clustering, no multi-language parsing, no MCP surface. Those belong to LLM-retrieval infrastructure - the GitNexus-shaped layer a polyglot host repo might run beside cb and cite as evidence. This index serves belief *verification*, and holds to the two consumers that justify it. If a use ever demands more, the doctrine still routes it: derived facts to a disposable substrate, and only claims worth standing behind into the graph.

## Open ends

The library is the substrate; its consumers are follow-up work. `CB.Anchor.resolve/2` does not yet consult the index (symbol-aware drift detection: "the anchor left `resolve/2`"), no shipped codepath predicate yet calls `call_chain?/2`, and a `mix bs stale`-sibling that walks `code:` artifacts against the index is unbuilt. The query surface above was shaped so each of those is a small change in its consumer, not a change here.

---

> **Grounding.**
> - In the graph: `cb:b448` (no confidence scores; specific evidence over synthesized certainty), `cb:b390` (confidence reinstatable in derived form - the door this index walks through), `cb:b050` (inspection-only, in-process predicates), `cb:b047` (contracts route, modules implement), `cb:b467` (the `code:` locator design whose blind spots this closes), `cb:b386` (the digest antipattern, applied here to the index's own freshness).
> - In the code: `lib/cb/derived/symbols.ex`, `lib/cb/derived/tracer.ex`, `lib/cb/derived/index.ex`, `lib/mix/tasks/cb.index.ex`; tests under `test/cb/derived/`. Consumers-to-be: `lib/cb/anchor.ex`, `lib/cb/predicate_gate.ex`, `lib/cb/codepath/predicates.ex`.
