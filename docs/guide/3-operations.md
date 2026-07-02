# 3 · Operating the graph

Reading, writing, working, and staying fresh: this chapter is the operating manual. The belief shell reads the graph deterministically; the write flow is the one sanctioned way to change it; obligation lives in the graph as queryable prescriptions; staleness is computed rather than remembered; and the nursery is the mutable floor where a proto-belief gestates before the immutable commit of authoring it.

## The belief shell

The read side is `mix bs`: a family of subcommands that walk the graph and print what is there, and nothing else. It is **pure deterministic traversal with no language model anywhere on its path** - the same graph and the same query always produce the same output. Each subcommand loads the beliefs once, walks `deps` pointers by string lookup, and renders the result. When a query surprises you, the surprise is a fact about the graph, never an artifact of the tool, so the next move is always to read the nodes it pointed at.

Two addressing conventions: `mix bs <id>` with no verb means `show`, and an id may be written bare (`b051`) or namespaced (`cb:b051`) - a bare id resolves when exactly one belief matches, and returns an ambiguity error rather than guessing when a multi-namespace union has two matches.

| Subcommand | Question it answers | Key flags |
| --- | --- | --- |
| `list [filters]` | which beliefs match? | `-v` verbose |
| `show <id>` | everything about one belief | (the default verb) |
| `tree <id>` | what does this rest on, recursively? | (box-drawing DAG view) |
| `deps <id>` | its direct upstream deps | `--deep` |
| `dependents <id>` | what rests on it? | `--deep` |
| `stale` | which active beliefs dep on a dead node? | `--cascade` |
| `recent` | what changed lately? | `--since DATE`, `--days N` |
| `path <id1> <id2>` | how are these two connected? | |
| `history <id>` | the supersession chain | |
| `subjects <ref\|type>` | which beliefs are about this? | |
| `stats` | counts across the whole graph | |

The power is concentrated in `list`, whose filters compose - each word becomes a predicate and they are ANDed. The vocabulary: a structural type (`attestation`/`aggregation`/`inference`/`prescription` - the legacy names still resolve this epoch), a status (`active`/`superseded`/`retracted`/`all`; the default is `active`, because a graph accretes dead nodes forever by design and the live working set should not be buried under its own history), `contracts` (contract-grade only), `unlinked` (prescriptions with no materialized items), `stale`, and `tag:`/`kind:`/`domain:`/`subject_type:` selectors. Intent reads straight off the line: `mix bs list prescription domain:dev tag:write-flow` is exactly "active dev-domain prescriptions tagged write-flow".

Every subcommand reads one graph - by default `beliefs/beliefs.json`. Point it elsewhere with `--beliefs PATH` (one command) or the `CB_BELIEFS` environment variable (a whole session); the flag wins over the variable, the variable over the default. `bs` reads a single file: to check a collection *together with everything it borrows*, use `mix cb.verify.collection` over the dependency closure ([chapter 5](5-collections.md)).

**A worked session** - the four moves you make constantly, live against this repo:

```sh
mix bs list unlinked tag:lifecycle:discrete   # 1. find the work (the desk)
mix bs show cb:b051                           # 2. inspect one node in full
mix bs tree cb:b489                           # 3. see what a claim rests on
mix bs stats                                  # 4. survey the whole graph
```

Move 1 is [the desk](#obligation-lives-in-the-graph), covered below. Move 2 prints a contract field by field - structural facts at the top (type, rule kind, invariants), provenance at the bottom (dated evidence, the deterministic `Support:` line). Move 3 walks the cone of support beneath a node, coloring each type and bottoming out at attestations that ground in artifacts; two guards keep it honest (`(circular ref)` for a revisited node, `(missing)` for a dep id that names nothing). Move 4 aggregates: type and status counts, stale count, unlinked prescriptions, scheme usage, dependency depth, most-depended-on nodes.

> **Pitfall.** Treating `bs` as a question-answering oracle. Every subcommand answers a structural question precisely - what matches, what depends on what, what changed - and stops there. It will not weigh two prescriptions against each other or tell you which belief is right. Use the shell to locate the nodes, then read the claims and evidence yourself. The determinism that makes the shell trustworthy is exactly the property that means it cannot do your reasoning for you.

The shell is read-only and safe to run anywhere, as often as you like. Changing the graph is a separate, deliberate surface.

## The write flow

The whole graph is one file, and nothing physically stops you from editing it. The framework forbids it anyway (`cb:b457`: never modify files under `beliefs/` without explicit user authorization; `cb:b533`: author through the write flow). The strong version of the rule is its derivation: a belief is immutable once written, so change happens by supersession - and an in-place edit erases the history the DAG exists to preserve, silently breaking both staleness detection (dependents keep pointing at a node whose meaning shifted) and the conflict record (the proof that a contested write was resolved rather than painted over).

The sanctioned pipeline runs in three stages, dry-run by default, committing only with `--write` (a property every write task in the system shares):

```
proposal.json  (a candidate belief, never typed into beliefs.json)
    |
    |  mix cb.preflight --file proposal.json        [read-only]
    v
+----------------------------------------------------------+
|  preflight: find every existing node this touches         |
|  match axes: subject ref / tag / claim-overlap >= 0.25    |
|  buckets: contract-level conflict (blocks, exit code 2)   |
|           schema conflict | supportive | neutral          |
+----------------------------------------------------------+
    |
    |  a reviewer reads the buckets and records a choice
    |  mix cb.adjudicate --file decision.json
    v
+----------------------------------------------------------+
|  adjudicate: re-read the DAG, race-guard (is the loser    |
|  still active?), apply one of three structural outcomes,  |
|  ONE atomic Store.write                                   |
+----------------------------------------------------------+
    |
    |  mix cb.import <spec.json> --write
    v
beliefs/beliefs.json   (supersession history + conflict audit intact)
```

**Preflight classifies; it never decides.** It tests three match axes - a shared subject ref, a shared tag, and claim overlap (within the same domain, at least a quarter of the shorter claim's meaningful words appear in the other) - and sorts every match into four buckets: a contract-level conflict that blocks the write, a schema conflict, a supportive match (a dependency candidate), or a neutral match. The task exits non-zero on a blocking conflict, so a script cannot sail past one.

**Semantic contact is the escalation bar.** A match escalates into a conflict bucket only when the contract-grade or schema trigger is accompanied by *semantic contact* - a shared subject ref or claim overlap (`cb:b064`). A bare tag-overlap is family resemblance, not contact: two beliefs can both wear `lifecycle:discrete` and have nothing to do with each other. This calibration was itself learned and recorded (`cb:b519`: bare tag-overlap escalated too eagerly), and it enforces at authoring time what the conflict-scope doctrine `cb:b055` states: overlap is necessary but not sufficient for contradiction.

**Adjudication applies a human decision structurally.** It re-reads the DAG and race-guards (if another session already superseded the conflicting node, it refuses to act on a stale picture), then applies exactly one of three outcomes in one atomic write:

| Outcome | What it does to the graph |
| --- | --- |
| `accept_supersede` | writes your proposal and flips the loser to `superseded` with `superseded_by` pointing forward, atomically |
| `reject_dep_tie` | writes your proposal with the overlapped belief added to its `deps`, plus a rejection evidence entry; the existing node is untouched |
| `defer` | writes a deferral attestation tagged `adjudication:deferred` that deps on the conflicting node; nothing else |

The decision becomes a permanent, queryable feature of the graph - a supersession chain, a dependency edge, or a dated deferral - rather than a note in someone's memory. That is the point of the whole arrangement, named by `cb:b387` as the consensus mechanism: conflicts surface at authoring time, resolution routes through recorded adjudication, and contradictions in the governance substrate stay *expensive to introduce* (`cb:b304`), because if contradictions are free, agent behavior drifts silently.

**The other front doors.** Preflight-adjudicate-import covers minting and superseding. Five smaller sanctioned entry points cover the mutations that do not need a full adjudication - naming them keeps "never hand-edit" from feeling like a dead end:

- `mix cb.evidence <id> --detail <text> --artifact <uri>` - appends a dated evidence entry, the one in-place growth point on an immutable node (`cb:b522`).
- `mix cb.todo.close <id> --notes <text>` - flips a materialized work item open -> done with discharge notes. Since the `cb:b563` gate, every close must either cite its implementing commit (`--commit <full-sha>`, validated and dereferenced against the repository) or explicitly record that none exists (`--no-commit`); silent omission stops being possible at the door.
- `mix cb.repoint <id> --from <dep> --to <dep>` - swings a dependency from a superseded node to its successor as an atomic drop-then-add, the move that keeps the stale report clean after a supersession (`cb:b537`).
- `mix cb.retract <id> --reason <text>` - marks a belief retracted with its date and reason. Retraction records "this should not stand"; to *replace* a belief with a better one, supersede through adjudication instead.
- `mix cb.import.eval <manifest> --collection <path>` - materializes an eval run-manifest as observation attestations ([chapter 7](7-eval-ledger.md)).

All of them route through the same mutation engine and atomic write path as the main flow, and each appends its own evidence trail - even an edit to the graph leaves a trace inside the node it touched.

**The commit provenance loop.** The `commit:` artifact scheme (`cb:b067`) plus `mix cb.verify.commits` closes the loop between the graph and version control in both directions: every `commit:` URI cited in the graph must dereference to a real commit; every `Belief:` trailer in the repo's commit history must name a live belief; and every todo close recorded with a commit key must dereference too. The belief-to-code link is CI-enforced structure, not prose convention (`cb:b545`, `cb:b563`).

**After the fact: the conflict audit.** The same overlap logic runs as a standing audit, `mix cb.audit.conflicts`, which surfaces stale overrides and scope-overlapping pairs of active prescriptions per `cb:b055`. Read its output as candidates for review, never verdicts: contradictory prescriptions are actionable; contradictory inferences are dissent, out of the audit's scope.

## Obligation lives in the graph

A team's backlog usually lives in a tracker, a plan file, or someone's head. CB puts it in the same graph as everything else (`cb:b489`): work to do lives as prescriptions - grounded, subject-scoped, conflict-audited, staleness-linked, and queryable. The sharp formulation: **a live todo is an unmaterialized discrete prescription.** The backlog is not a second system bolted onto the graph; it is a *view* of the graph, and because the task and the reasoning that justifies it are the same node, the task can never drift away from its own rationale.

**The desk** is one command:

```sh
mix bs list unlinked tag:lifecycle:discrete
```

Two filters, each load-bearing. `unlinked` selects prescriptions with no materialized work items. `tag:lifecycle:discrete` keeps only completable work, dropping standing rules: the lifecycle tag (`cb:b491`) separates *discrete* prescriptions (a definite done - "stand up the desk view") from *recurring* ones (standing rules that never finish - "always end commit messages a certain way"). An untagged prescription degrades the view, because the desk can no longer tell a forgotten task from a permanent rule; tagging lifecycle is part of authoring, not an afterthought.

**Status and materialized are orthogonal** (`cb:b380`). `status` answers "is the claim still true"; `materialized` answers "was the action executed". Four meaningful combinations, not one done-flag:

| | unmaterialized | materialized |
| --- | --- | --- |
| **active** | still-actionable work - what the desk shows | discharged at time T, still true as a principle |
| **superseded / retracted** | the obligation was replaced or withdrawn before being done | executed, and the rule has since been replaced or withdrawn |

The materialized field is deliberately modest: it records a historical fact - the action was executed on a date, via a plan - and never asserts the effects still hold (`cb:b383`). Effects decay as code and world drift, which is why `last_verified` is a separate field from `date`, and why drift audits exist as a maintenance cycle (`cb:b384`): re-check materialized beliefs, bump `last_verified` or mint a drift observation.

**Materialization** turns a prescription into concrete work items - the `/materialize` skill over `CB.Belief.Materializer`. The pipeline guards (it must be a prescription, not already materialized), produces action items, hands them to a pluggable **sink**, and links the result back onto the node. The sink is a behaviour, so where work lands is the host's decision: `Sink.JSON` appends todo records to `todos.json` (later closed through `mix cb.todo.close`); `Sink.Test` makes the sharper point that *a recorded test run counts as materialization* - each action item names a predicate, running it is the discharge, and the verdict is the ref. That is what `mix cb.verify.codepath --record` does: a prescription discharged by a passing test rather than a checked box.

**A plan is what a large prescription materializes into** (`cb:b490`). The files in `plans/` are execution records, never the source of work. Query the graph for *what is next*; follow the prescription into `plans/` for *how and history*. Plans encode intent, not implementation (`cb:b382`, `cb:b375`) - a plan stuffed with sequenced steps becomes a liability the moment the world drifts, because the steps describe a situation that no longer holds while still reading as authoritative.

**Author against the live graph, never from memory** (`cb:b504`). Multiple sessions write the graph concurrently, and a memory snapshot rots the instant another thread pushes. Before minting a backlog node: pull the repos, query the desk, follow the artifacts. The same logic governs resuming: a session resumes from the graph, never from a handoff (`cb:b508`), and session memory is an ephemeral cache, never a store (`cb:b509`). For that to work, a backlog prescription must be **self-bootstrapping** (`cb:b507`): an agent reading it cold can reach the vision, constraints, and prior work through its deps and its resolvable `document:`/`plan:` artifacts. The practice that gets you there is **retro-pairing**: a `session:` stipulation is paired with a `document:` pointer a fresh agent can actually dereference - a directive only its author's memory can interpret is not on the desk in any useful sense.

> **Pitfall.** Keeping a todo list in a plan file or in session memory. A checklist in `plans/next-steps.md` feels natural and defeats the whole arrangement: it is invisible to the desk query, not conflict-audited, not staleness-linked, and it rots exactly as the digest antipattern warns. If a task matters, it is a discrete prescription in the graph. The plan file gets the how; the graph gets the what-is-next.

## Staleness: detected, not remembered

When a node goes terminal, every active belief still depending on it is resting on a withdrawn foundation - and that condition is mechanically visible. `mix bs stale` returns the active derived beliefs whose deps include a superseded or retracted node, each paired with the offending dep ids; `--cascade` propagates transitively, so a single retraction deep in the graph surfaces everything downstream in one pass. Attestations are exempt - no deps, no withdrawn foundation to rot.

> **Key idea.** Staleness is a function of the graph, evaluated fresh each time you ask. Because immutability forces every change into a status flip, "this claim now rests on a withdrawn foundation" is always answerable by traversal - never dependent on anyone having recorded a note to that effect.

On the framework's own graph today, `mix bs stale` reports `No stale beliefs found.` The empty result is itself load-bearing: it is kept empty by the repoint front door, which swings dependents onto successors as part of every supersession ceremony. A clean report is a goal state, meaningful precisely because the same command would light up the instant a dep went terminal without a repoint.

**The digest-file antipattern.** The lesson generalizes past dep edges. The canonical case is recorded as `cb:b386`: a digest file caching the active behavioral prescriptions, regenerated by a command, freshness dependent on a skill telling agents to regenerate after writes. Agents can and do forget; the stale digest is then read as authoritative by the next session. A persisted cache of graph-derived content whose freshness is procedural *embeds the staleness risk it was meant to solve* - the cache becomes a second copy of the truth with no structural tie back to the source. The same shape recurs, and each instance closes the same way:

| The cache | The fix | Belief |
| --- | --- | --- |
| a digest of active prescriptions | load them live: `mix bs list prescription` | `cb:b477` |
| CLAUDE.md as hand-frozen facts | compile it from the graph; CI fails on drift | `cb:b466` |
| the agent's own session memory | treat work state as an ephemeral cache; promote anything load-bearing through the write flow, then prune | `cb:b509` |

The distinction underneath is **structural versus procedural freshness**. Structural: the answer is derived at the moment you read it - the read *is* the derivation, so it cannot be out of date. Procedural: the answer was derived earlier and stored, and a process is supposed to keep the copy current - which is only as good as the process, and processes that depend on remembering fail in exactly the busy cases that matter. When freshness is a property of the read path, CI can enforce it, because the oracle is always available to diff against.

> **Pitfall.** Writing a cache "for convenience" because a query feels slow or a list is handy inline. You have manufactured a second copy of graph-derived content that can only stay correct by procedure, and the procedure is the part that breaks. If a read is slow, speed up the read. If a list is handy inline, compile it from the graph with a CI gate.

**The recency view.** Staleness answers "what has rotted"; `mix bs recent` answers "what changed lately" (`cb:b501`) - new nodes, supersessions, evidence appends, materializations, retractions, over a window (`--days N`, default 7, or `--since DATE`). It reads the *epistemic* history straight from the data - creation dates, supersession links, evidence dates, materialization records - never `git log`, because the version-control history of the file and the history of the claims are different things. It exists because multiple sessions write concurrently: the view is how you observe sibling activity without trusting a memory snapshot.

**The anchor-verification gradient.** A claim anchored to a source or a code site can decay in more ways than a dep edge, and `cb:b529` lays out the three tiers: **provenance integrity** (the quoted evidence still exists where the claim said), **grounding currency** (the code referent still exists in the substrate), **behavioral validity** (the referent still behaves as claimed - predicates, contract grade). The tiers escalate from "the words are still there" to "the code is still there" to "the code still does what we said"; [chapter 4](4-code.md) picks up the lower two in full. An anchor check is a necessary condition only: a failed check flags the claim for review; a passing check is "no detected reason to doubt this yet", never re-validation - the same asymmetry as the drift audit bumping `last_verified`.

## The nursery: where beliefs gestate

Authoring a belief is an expensive, immutable commit: a wrongly-split or premature node needs a supersession to fix. The **nursery** (`beliefs/nursery/`) is the cheap, mutable floor *before* that commit: one markdown document per **focus** - a single question or proto-belief, called a **seed** - deliberated in place until it either **mints** into the graph or is dropped. Over-decompose freely here; merging two seeds is concatenate-and-delete, and the cost of a wrong split only materializes at the mint gate.

The unit is the focus, not the session. A conversation touches several focuses and updates whichever documents it concerns; the focus persists and accretes across conversations. This is the atomicity doctrine (`cb:b475`) applied one level up: a document holding several separable focuses is a mis-authored bundle, split at authoring time.

Each seed carries a `maturity:` field with a lifecycle of its own:

| Maturity | Meaning |
| --- | --- |
| `active` | live deliberation, not yet actualized |
| `contested` | in open conflict with an existing belief or a sibling seed, not yet resolved |
| `planted` | actualized into a belief; the doc records `minted: <belief-id>` and leaves the nursery |
| `composted` | deliberated, no belief warranted; the doc leaves |
| `grafted` | lost a contest or merged into another seed; it folds into the survivor as a dated "rejected: X because Y" block |

The verbs: **seed** (start) -> **plant** (into the graph) | **compost** (drop) | **graft** (merge). No tombstones: every terminal seed folds into its successor or evacuates, so the nursery only ever holds live work. A seed that reached an explicit decided-against plants the *negative* as a belief first - the graph records what was rejected and why, not just what won.

What keeps this from becoming a shadow graph is a hard discipline: the nursery validates **format, never relations**. It is an OKF document bundle ([chapter 5](5-collections.md)) - frontmatter and manifest are checked - but it carries no dep-resolution, no staleness cascade, no conflict preflight between documents. Cross-links are provisional and elevate to real graph edges only on mint. The graph is the only authoritative structure; the nursery has no authority, so it cannot drift against the graph - it can only feed it. Competing seeds resolve by explicit contested-links (the hard resolution); recency is only a soft hint for which lean is live - it makes staleness visible, it never silently decides.

The nursery earned its keep immediately: the schema-v3 structural-type rename was deliberated as a nursery focus (`beliefs/nursery/structural-type-rename.md`), executed as a recorded migration, and the focus now carries the execution record - the deliberation trail a bare commit message could never hold. Alongside the seeds, `beliefs/nursery/threads/` holds living session transcripts, captured automatically by a harness hook: crash-safe, human-readable, and explicitly *not* provenance - the seeds are.

---

Next: [chapter 4, code, anchors, positions](4-code.md) - claims anchored to lines of source, tours that run as tests, and the ceremony that captures a settled stance.

> **Grounding.**
> - In the graph: `cb:b489`/`cb:b491` (the desk), `cb:b380`/`cb:b383`/`cb:b384` (status vs materialized; drift audits), `cb:b490`/`cb:b382`/`cb:b375` (plans), `cb:b504`/`cb:b507`/`cb:b508`/`cb:b509` (live-graph authoring, self-bootstrapping, retro-pairing), `cb:b457`/`cb:b533`/`cb:b302` (the hand-edit ban), `cb:b064`/`cb:b519`/`cb:b055` (semantic contact and conflict scope), `cb:b387`/`cb:b304` (the consensus mechanism), `cb:b522`/`cb:b530`/`cb:b537` (the front doors), `cb:b067`/`cb:b545`/`cb:b563` (the commit provenance loop), `cb:b386`/`cb:b477`/`cb:b466`/`cb:b509` (the digest antipattern family), `cb:b501` (recency), `cb:b529` (the anchor gradient), `cb:b475` (atomicity, applied to nursery focuses).
> - In the code and repo: `lib/mix/tasks/bs.ex` and `lib/cb/belief/{graph,filter,formatter}.ex` (the shell), `lib/cb/belief/{conflict,adjudication,mutation,store}.ex` (the write flow), `lib/cb/belief/materializer.ex` and `lib/cb/todos.ex` (materialization and closes), `lib/cb/commit_locator.ex` and `mix cb.verify.commits` (the provenance loop), `beliefs/nursery/index.md` (the nursery's own architecture).
