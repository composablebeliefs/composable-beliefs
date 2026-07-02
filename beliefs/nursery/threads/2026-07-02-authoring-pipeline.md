---
type: thread
title: 2026-07-02 - authoring pipeline (thread-to-graph round trip)
description: Covers the session that designed the thread-to-graph authoring pipeline - the routing ledger, the mint manifest (typed decomposition inside the brief, rejecting typed nursery documents), concurrence with seed-lifecycle's collapse, and extending commit provenance to the floor tier - executed same-session as the first full round trip from thread capture to minted beliefs. Use when orienting to the authoring pipeline or auditing the round-trip reference.
tags: [cb, nursery, pipeline, provenance, thread]
status: active
timestamp: 2026-07-02
artifact: session:2026-07-02-authoring-pipeline
---

# 2026-07-02 - authoring pipeline (thread-to-graph round trip)

> **Hand-captured (2026-07-02).** No `Stop` hook runs in this remote session (the
> [thread-repo-binding](../thread-repo-binding.md) limitation), so this thread was written
> by hand in the format the seed-lifecycle thread established. Tool calls and reasoning are
> stripped; only what was said is kept. This doc also carries the **first routing ledger**
> ([routing-ledger](../routing-ledger.md)): the session that designed the ledger is the
> first thread dispatched by one. Produced: [routing-ledger](../routing-ledger.md),
> [mint-manifest](../mint-manifest.md),
> [commit-provenance-floor](../commit-provenance-floor.md), the 2026-07-02 concurrence
> block on [seed-lifecycle](../seed-lifecycle.md), and beliefs cb:a566 / cb:a567.

## Routing

One row per topic this thread touched. Content lives in the routed-to focus doc, never
here; this table holds only dispatch state ([routing-ledger](../routing-ledger.md)).

| Topic | State | Routed to | Dangling |
|---|---|---|---|
| Typed nursery documents (one doc kind per DAG type) | closed | [mint-manifest](../mint-manifest.md) (rejected-alternative record) | - |
| Parallel thread-summary document | closed | [routing-ledger](../routing-ledger.md) | - |
| Focus/plan overlap and the seed/plan collapse | closed | [seed-lifecycle](../seed-lifecycle.md) (2026-07-02 block) | - |
| Pipeline layer count (thread / ledger / brief / graph) | closed | [routing-ledger](../routing-ledger.md), [mint-manifest](../mint-manifest.md) | - |
| Commit provenance for floor-tier lifecycle events | open | [commit-provenance-floor](../commit-provenance-floor.md) | Squash policy and trailer vocabulary await the user's reply; deliberation continues in the focus doc |
| Round-trip reference (this cycle as the exemplar) | open | - (this cycle itself) | User review of the executed round trip |
| Backfill: conform existing threads, focuses, and plans to the new standard | paused | unrouted | User intends to work backwards through the existing collection once the reference round trip is accepted |

## Where we are

- **Object of study:** the authoring pipeline from raw thread to committed belief - what
  layers exist between prose brainstorming and the immutable graph, and whether the
  nursery should grow mutable document types mirroring the four DAG types.
- **Settled this session:**
  - Four layers, not five: thread (raw + render), routing ledger (per-thread dispatch),
    focus brief (sole provenance, absorbing plans per seed-lifecycle's collapse), graph.
    Progressive formalization happens as phases of one brief, not as a chain of documents.
  - Typed nursery documents rejected on four grounds (inverts discovery order; fragments
    the focus; builds a shadow graph; attestations and aggregations need no gestation);
    the surviving weak form is the mint manifest - typed candidate-belief rows inside a
    maturing brief.
  - The thread-summary document survives as a **router, not a digest**: pointers and
    states only, so cb:a386 cannot reach it and it cannot shadow the seeds.
  - Action items in briefs are prescription rows in the mint manifest - the resolution of
    the focus/plan drift, composing with seed-lifecycle's scenario C.
  - Commit provenance already structural at the graph tier (cb:c067, `Belief:` trailers,
    `mix cb.verify.commits`, cb:a563); the open work is extending it to floor-tier
    lifecycle events, deliberated in [commit-provenance-floor](../commit-provenance-floor.md).
- **Process decision:** execute this design same-session as the first complete,
  git-auditable round trip - thread capture, ledger, briefs, mint - one commit per
  lifecycle event, so new agents and the backfill effort have a concrete reference.

## Turn-by-turn

**User (opening):** Examined the authoring and synthesis process: threads persist in
`.sessions/`, focuses gestate in the nursery, plans sit confusingly alongside as a sister
artifact with overlapping duties (focus action-item sections drift into plan territory).
Proposed: indeterminate phases of progressive decomposition from thread prose toward the
graph, realized as **typed mutable nursery documents** mirroring the four DAG types -
action items becoming mutable prescription-seed docs, arguments becoming aggregation docs
decomposable into attestations, plus inference docs. Layers: (1) threads - non-linear,
side-quest-prone, needing a parallel running summary doc (a `/decompose` skill) so the
user replies from the summary instead of memory; (2) seed docs - single focus, drawing
from many threads; (3) informal commitment to the type as a mutable typed workspace;
(4) elevation to the DAG. Asked for an assessment.

**Claude:** Concurred with the layering instinct and located half of it in the existing
system (the transcript-format pipeline; focus-as-unit). Recommended the thread-summary doc
as a **routing ledger** rather than a digest - per-topic rows of state and dispatch
pointers, immune to the cb:a386 antipattern because it holds no content. Argued against
typing *documents* by DAG type on four grounds: the type is an output of deliberation, not
an input (the aggregation/inference boundary is c058's semantic judgment); one focus mints
several beliefs of several types, so typed docs fragment the focus (the same mistake
seed-lifecycle rejected on the phase axis); typed proto-beliefs want typed proto-relations
and drift toward a shadow graph, against "validate format, never relations"; and
attestations/aggregations are mechanical at mint time - only inferences and prescriptions
need a workshop. Kept the weak form: a **mint manifest** section inside a maturing brief -
typed rows (type, draft claim, deps, artifact) committed late, at the gate, where the
argument justifying the typing lives. Noted the focus/plan unease is validated by
seed-lifecycle's collapse lean, and that action items are prescription rows in the
manifest, minted to the desk when firm - the graph is already the todo tracker. Proposed
the four-layer pipeline.

**User:** Agreed on all points; moved to implementation. Asked (1) whether to modify
seed-lifecycle or open a new focus for the rest; (2) stated the goal: a referenceable,
complete round trip from thread to graph, embodied by converting this very conversation
into the artifacts of the system just described, to serve as the reference for new agents
and for backfilling the existing collection; (3) raised the last dimension - persisting
state via git commits so every artifact transition (thread update, ledger change, brief
edit, mint) routes back to a commit, making the whole lifecycle auditable.

**Claude:** Answered: both, split by focus - seed-lifecycle gets only a dated concurrence
block (the typed-documents rejection strengthens its "status, not kind" argument), and
three new focuses open (routing-ledger, mint-manifest, commit-provenance-floor). On git
traceability: agreed, with refinements - back-pointers only (an artifact cites a
predecessor commit, never its own SHA); no cached artifact-to-commit index (git is the
deterministic index; a mapping file would be the cb:a386 antipattern); SHA durability
requires merge-without-squash. Then discovered the graph tier already implements the
loop: cb:c067 added the `commit:` scheme, cb:a545 was resolved as option 1 with
`mix cb.verify.commits` enforcing both directions, and cb:a563 gates todo closes on a
commit citation - so the open question narrowed to the floor tier, deliberated in the new
commit-provenance-floor focus. Executed the round trip: installed the toolchain, captured
this thread with its ledger, authored the three focus briefs and the seed-lifecycle
block, ran preflight, minted cb:a566 (routing ledger) and cb:a567 (mint manifest) through
`mix cb.import`, ran the verify gates, and committed one lifecycle event per commit with
`Thread:` / `Focus:` / `Belief:` trailers, pushed for review.

## Related
- [routing-ledger](../routing-ledger.md) - the ledger this thread carries the first
  instance of; minted cb:a566.
- [mint-manifest](../mint-manifest.md) - the adopted weak form of the typed-documents
  proposal; minted cb:a567.
- [commit-provenance-floor](../commit-provenance-floor.md) - the open floor-tier
  provenance deliberation.
- [seed-lifecycle](../seed-lifecycle.md) - concurrence recorded 2026-07-02; its collapse
  lean supplied the focus/plan resolution.
- [transcript-format](../transcript-format.md) - the pipeline this session extends with
  the ledger layer.
