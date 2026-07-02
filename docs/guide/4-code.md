# 4 · Code, anchors, positions

A claim about code is only as good as a live pointer into the code. This chapter covers the anchor grammar that survives refactoring, codepaths - one artifact that reads as a narrated tour and runs as a test suite - and the document forms around the graph: positions for stances whose wording matters, chronicles and transcripts for what a session leaves behind.

## The code locator

Everything starts with how a belief names a place in source: the `code:` artifact scheme, settled in `cb:a467` and parsed by the single module `CB.CodeLocator`.

```
code:lib/cb/belief.ex#def contract?@1
     |               |             |
     |               |             occurrence selector (optional @N)
     |               one opaque literal-substring anchor
     repo-relative path (runs to the FIRST #)

* everything after the first # is ONE literal substring
  (it may itself contain more # characters)
* a literal trailing @<digits> is percent-encoded as %40<digits>
* resolved at render/run time by fixed-string match
  (grep -nF semantics) -> line numbers are NEVER stored
```

The load-bearing decision is the last line. A locator stores no line number. At render or run time, `CB.Anchor.resolve/2` reads the file and finds the lines containing the literal anchor by fixed-string match - never a regex - and the resolved line number is computed at that moment and thrown away after use. Move the anchored code in a refactor and the locator still finds it, because it was never pinned to a coordinate the refactor would invalidate.

Drift produces signals, never crashes. A **missing anchor** (the substring is no longer in the file) resolves to nothing with a warning - the maintenance cue that the anchored symbol was deleted or renamed; the stop still renders. A **loose anchor** (multiple matches, no `@N`) renders the first match plus a tighten-this-anchor warning. An explicit `@N` warns only when out of range.

## Codepaths: one artifact, one gradient

A **codepath** is a code-anchored belief collection that reads as a narrated, branching tour of real source and runs as a test suite over the same source. There is no separate format - the cb schema is the single authority. With assertions off it is a guided walk: each stop narrates its claim and resolves its anchor to a live `path:line`. With assertions on, the contract-grade stops also execute their routed predicates. That asymmetry *is* the gradient: non-contract stops narrate at every setting; only contract-grade stops assert.

Each job has exactly one home, so nothing is doubly stated and nothing can drift against itself:

| Role | Where it lives |
| --- | --- |
| location | the `code:` artifact on the stop belief |
| narration | the belief's `claim` |
| derivation | the belief's `deps` |
| assertion | the contract's `implies` rules |
| order | a separate render-spec, never the claims |

**The render-spec orders the tour.** Ordering and branching live in an output-target contract governed by `cb:c049`: an `entry` step id plus `render_steps` rows of `{id, belief, goto?, choices?}`. Navigation is render metadata that never enters `deps` and never lives in the claims - reordering a tour supersedes the render-spec and leaves every claim untouched, the same immutability move as always. The two relations are tied by a checked invariant: the render-spec's `deps` must equal the union of its steps' belief ids, enforced inside `mix cb.verify.schema`, so navigation can never quietly pull in or drop a claim.

The shipped `codepath:` collection tours CB's own data pipeline. Rendered linearly:

```sh
CB_BELIEFS=codepath/beliefs.json mix cb.render.codepath belief-pipeline
```

```
[data] `beliefs/beliefs.json:3` - Raw data - each object is one belief...
  -> How does raw JSON become a struct?: from-map
  -> How is it rendered back out?: formatter

[from-map]  `lib/cb/belief.ex:218` - The boundary: a JSON map becomes a typed %Belief{}...
[store]     `lib/cb/belief/store.ex:13` - Loads the whole graph off disk...
[formatter] `lib/cb/belief/formatter.ex:46` - Renders beliefs back out...
```

Those line numbers are nowhere in the stored render-spec; they were computed by anchor resolution at render time. The entry stop branches; in the interactive presentation (the `/present-codepath` skill) the agent stops there and waits for the reader to choose.

**Predicates are inspection-only.** A contract-grade stop carries `implies` rules naming a predicate - `{"when": {"assertions": "on"}, "requires": "from_map_roundtrips?"}`. Per the routing boundary (`cb:c047`) the graph stores only the *name*; the body lives in `CB.Codepath.Predicates`. Contract `cb:c050` adds the safety rule: predicates observe and never mutate, names must end in `?` or `_check`, and they must resolve to exported zero-arity boolean functions. The shared gate `CB.PredicateGate.resolve/3` refuses anything else, and a bad name, an unknown predicate, a raise, or a non-boolean reports as a *failure* rather than crashing the suite or executing something it should not.

The one place predicates run is the dynamic verifier:

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

The `data` stop is deliberately narration-only so the shipped example demonstrates the gradient itself. Pass `--record` and each pass/fail is written into the stop belief's `materialized` field - a recorded test run counts as materialization ([chapter 3](3-operations.md#obligation-lives-in-the-graph)). The collection's own history demonstrates the supersession discipline too: raising three stops to contract grade was a structural change, so each went through an adjudicated supersession with its claim and anchor carried verbatim, and the render-spec followed (`mix bs history codepath:c001 --beliefs codepath/beliefs.json`).

**Answer-time anchoring.** Codepaths are the formal case of a rule that applies to every claim an agent makes about code (`cb:a488`): claims about code must carry `code:` anchors that resolve at read time, and an unresolvable anchor is an ungrounded claim - fixed or withdrawn before the claim is presented. The reasoning runs back through three beliefs: code is the operational substrate, the only artifact whose meaning is enforced by execution (`cb:a484`); prose discussion above it is productive exactly when every claim terminates in an anchor into it (`cb:a485`); and the editor's role accordingly shifts from an authoring surface to an *adjudication* surface - the place claims meet the thing that actually runs (`cb:a486`).

For anchors not yet part of any collection - a draft answer, a position being captured - there is **draft mode**: `mix cb.resolve --file rows.json` validates and resolves bare `{path, anchor, nth}` rows against a root with no belief collection loaded, sharing the one tested resolver with the codepath renderer (`cb:a512`). Landing that command is what let `cb:a488` escalate to contract grade: the verification gate it names finally existed.

> **Pitfall.** Two mistakes that look like tidiness. Storing a line number - in an artifact, a note, or a "see line 169" comment - is wrong the instant the file is edited, with no warning; let the anchor resolve at read time. And pushing navigation order into `deps` or into a claim ("this is the third stop") conflates presentation with derivation, breaks the deps-equals-union invariant, and means a harmless reorder now rewrites grounded claims.

## Positions: when the wording is the artifact

A **position** captures a settled stance whose verbatim wording matters; its claims are then extracted into the graph as beliefs (`cb:a492`). Two artifacts come out of one act of judgment: the position holds the reasoning in full, and the graph holds the one-line claims lifted from it, each grounded back through a `document:` artifact. A position is exactly the source document the one-liner rule ([chapter 2](2-schema.md#provenance-artifact-evidence-subjects-deps)) calls for: the place the verbatim argument lives so the extracted claims can stay short and still trace home.

The division of labour is deliberate: the `/position` skill captures the stance, types each claim, verifies the anchors, and stops. Extraction into `beliefs/` stays with `/assert` and the write flow, so authoring a stance and minting beliefs from it remain two separately auditable steps. Framework-policy positions live in this repository's `positions/` - a distributable framework must resolve every artifact its own graph cites, so a repo-relative `document:` pointer requires the position to ship inside the repo.

> **Key idea.** Persistence ceremony is proportionate to stance (`cb:a496`). A position earns its keep when *the reasoning is the artifact*. An observation with an obvious prescription skips the document and goes straight in as a prescription, with the gap carried as a small rationale node. If every wart became a three-artifact pipeline, the pipeline would stop being read - keeping the expensive form scarce is what makes its presence a signal.

**The anchored-position format** (`cb:a550`, `cb:a551`): a `**Class:**` header naming the kind of stance, `### Claim:` sections each carrying `**Anchor:**` lines with `code:` URIs, and an optional terms block of `{term, definition, anchor?}` entries. Two constraints make the format load-bearing. Every anchor is verified resolving *with exactly one match* at authoring time through the draft-mode resolver - a loose anchor is an authoring failure. And claim order is the default walk order, which is where positions meet codepaths (`cb:a528`): **position names the epistemic artifact, codepath names the render face**. A position with anchors *has* a codepath - one authored object, two readings, no second source of truth for sequence.

## Chronicles, transcripts, and what survives a session

Every thread that does substantive work persists twice at close (`cb:a520`): a **transcript** - the condensed record co-located with its plan set - and a **chronicle** in `chronicles/` - a dated prose narrative for the operator. With the graph itself that is three persistence surfaces, each with one job: *the transcript serves the audit, the graph serves the work, the chronicle serves the steering.*

```
At session close: four surfaces, three persist
==============================================

[session memory] --prune--> gone   (ephemeral cache; no work state;
      |                             promote load-bearing items through
      |                             the write flow first, then prune)
      v
[the graph]      -> serves THE WORK
                    what is true now and what is next (the desk)

[transcript]     -> serves THE AUDIT
                    condensed receipts beside the plan set: did each
                    claim follow from what happened?

[chronicle]      -> serves THE STEERING
                    chronicles/, dated prose: the arc as story beats,
                    what the next session inherits
```

**Decision-weight sessions persist more fully** (`cb:a540`): a session that mints or supersedes stipulation-grounded beliefs, settles a stance, or adjudicates contradictory positions persists its thread verbatim at close, routed by subject. Every belief minted that session is then **retro-paired** (`cb:a507`): a `document:` pointer to the thread record joins its evidence, so a fresh agent can dereference what a bare `session:` slug cannot reach (making `session:` artifacts resolvable in their own right is open work, `cb:a518`). The prescription stays the single source of truth and must remain self-bootstrapping on its claim and deps; the verbatim thread is provenance a reader *may* consult, never a dependency a fresh agent *needs*.

The newest capture surface automates the raw end of this: a harness hook writes living session transcripts into `beliefs/nursery/threads/` as the session runs - crash-safe, human-readable, and explicitly *not* provenance (the nursery seeds and retro-paired thread records are; [chapter 3](3-operations.md#the-nursery-where-beliefs-gestate)).

**Session memory is a cache, never a store** (`cb:a509`). Project and work state is banned from it: the graph owns obligations, the repositories own records, and CLAUDE.md compiles the bootstrap. This is the digest antipattern (`cb:a386`) applied to the agent's own notebook - if you treat memory as a store and a concurrent session pushes a superseding belief, your snapshot becomes wrong with no stale-dep signal to catch it, because a private notebook is not in the graph that `mix bs stale` walks. Live work stays observable without violating the rule through the **lap log** (`cb:a497`): a scratch markdown file the operator keeps open in an editor split while the agent appends station by station - scaffolding whose load-bearing content graduates to the transcript or the graph at lap end.

> **Pitfall.** Treating session memory or a chronicle as the source of truth for work state. Memory is pruned at close; a chronicle is steering prose with ids deliberately subordinate; neither is queryable, conflict-audited, or staleness-linked. The one source of truth for what is next is the desk. The chronicle tells the operator the story; the graph tells the agent the work.

---

Next: [chapter 5, collections and memory](5-collections.md) - how graphs compose across namespaces, and the document extension that carries the nursery.

> **Grounding.**
> - In the graph: `cb:a467` (the `code:` locator), `cb:c049` (the render-spec; navigation never enters deps), `cb:c050` (inspection-only predicates), `cb:c047` (the routing boundary), `cb:a488`/`cb:a512` (answer-time anchoring and draft mode), `cb:a484`/`cb:a485`/`cb:a486` (code as operational substrate), `cb:a528` (position/codepath: artifact and render face), `cb:a492`/`cb:a496`/`cb:a550`/`cb:a551` (positions, ceremony, format), `cb:a520`/`cb:a540`/`cb:a507`/`cb:a518` (transcripts, chronicles, decision-weight sessions, retro-pairing), `cb:a509`/`cb:a497`/`cb:a386` (memory as cache; the lap log). Worked example: `codepath:c005` and its stops.
> - In the code: `lib/cb/code_locator.ex`, `lib/cb/anchor.ex`, `lib/cb/codepath.ex` and `lib/cb/codepath/{predicates,assertions}.ex`, `lib/cb/predicate_gate.ex`, `lib/cb/output_target.ex` (the deps-equals-union check), the `mix cb.render.codepath` / `mix cb.verify.codepath` / `mix cb.resolve` tasks, and `skills/position/`, `skills/present-codepath/`.
