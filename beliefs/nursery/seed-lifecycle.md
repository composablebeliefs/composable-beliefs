---
type: concept
title: Seed lifecycle - graduate, don't evacuate (and the seed/plan collapse)
description: Covers whether terminal seeds persist by graduation (historicize and archive) instead of evacuating by deletion, and whether persisted seeds and plans collapse into one durable-brief concept - contesting seed-absorption's fold-and-evacuate and the no-tombstones-by-deletion reading of the nursery doctrine.
tags: [cb, nursery, lifecycle, plans, meta]
status: active
timestamp: 2026-07-02
maturity: active
threads: [2026-07-01-seed-lifecycle, 2026-07-02-authoring-pipeline]
---

# Seed lifecycle - graduate, don't evacuate (and the seed/plan collapse)

> **Contests** [seed-absorption](seed-absorption.md) (fold-and-evacuate as the terminal
> move) and [nursery-architecture](nursery-architecture.md) (the evacuation half of its
> model). Opened from a self-contained seed brief carried across sessions - itself the
> seeds-carry-excerpts pattern doing its job; the originating lean is recorded at the
> bottom, deliberated fresh here.

## The focus
When a seed goes terminal, [seed-absorption](seed-absorption.md) says it folds into its
successor and **evacuates** - the doc is deleted from the workspace. Should terminal seeds
instead **persist** as durable reasoning artifacts? And if they persist, are a persisted
seed and a plan doc still two things, or one durable-brief concept wearing two names?

## The scenarios
- **A. Status quo** - seeds evacuate; plans persist separately. Rejected below.
- **B. Seeds persist by archiving; seed and plan stay distinct.** Right lifecycle, but the
  remaining seed/plan distinction does not survive scrutiny (below).
- **C. Collapse seed and plan into one durable-brief artifact** with a workspace-to-archive
  lifecycle. **The lean.**
- **D. Eliminate the curated middle layer entirely** (graph + raw threads suffice).
  Rejected: the three layers do three jobs - the graph holds conclusions (terse,
  composable), briefs hold synthesis (the readable why, the roads not taken), threads hold
  behavior (verbatim audit). D conflates the last two; threads are too verbose and
  unstructured to be the synthesis, and beliefs too terse. Plans demonstrably earn their
  keep (`plans/done/` is a consulted record, and this bundle's own live reference is a
  seed).

## Why evacuation loses

**The scaffolding counterposition, beaten where it is false.** The strongest defense of
evacuation: "the seed was only scaffolding; the essential reasoning survives in the `seed`
prop plus the raw thread, so delete the doc." Three failures:

1. *The fold is lossy everywhere except the plant arm.* Only planting folds the full body;
   a grafted loser folds as "load-bearing sentences only" (per `agent-behavior:a411`) and a
   compost folds nothing. The curated synthesis of every losing position - the options
   weighed, the reversals, the why-not - is destroyed by design, surviving only in the raw
   thread.
2. *The raw-thread substitute is gated on machinery that does not exist.* seed-absorption
   itself names persist-raw ([transcript-format](transcript-format.md), repo-weight
   undecided) plus per-statement linkage ([statement-provenance](statement-provenance.md),
   statement ids unbuilt) as the **load-bearing safety condition** for fold-and-delete. Both
   are open. A deletion lifecycle whose safety condition is pending is not a settled
   lifecycle; it is a bet.
3. *The `seed` prop is a worse home than a doc.* A deliberation stuffed into a JSON node
   loses addressability (nothing can cite it as a `document:` artifact), loses readability
   (headers, cross-links, dated excerpts), and creates the granularity problem
   seed-absorption leaves "undecided" (one seed, several beliefs: duplicate the body into
   each, or privilege one node).

Where the counterposition is *true* - a fizzle that accreted no synthesis - the lean
concedes it: see "compost may still delete" below. The lifecycle should encode that
distinction, not apply deletion uniformly.

**Anti-drift does not reach.** `cb:a386` - the strongest pro-evacuation argument - bans
persisted caches of *current* graph-derived state whose freshness is procedural (a digest
read as authoritative). An archived seed is the opposite object: a dated record of *past*
deliberation, forward-linked (`minted:`), never read as authoritative - the graph is. The
only drift-prone part of a seed is an undated restatement of the conclusion sitting in the
live workspace, readable as maybe-current; graduation (date-stamp, forward-link, move out
of the workspace) is precisely the operation that removes that reading. `chronicles/` is
the existence proof: dated docs that restate conclusions as-of-a-date, narrating even
supersessions, and nothing reads them as live state.

**Deletion is stronger than its goal.** The actual goal is live-desk hygiene: the nursery
surfaces only active/contested work. Archiving achieves that fully - the desk is a *view*
(what the workspace holds), and graduation moves terminal docs out of it. The
forcing-function value of evacuation (fold reasoning into a durable home at plant time)
survives intact as the graduation step; it never required deleting the source.

**House precedent is uniform, and evacuation is the outlier.** `chronicles/` persists dated
reasoning that never evacuates. `plans/` graduates rather than deletes: `done/`,
`superseded/`, `deprecated/`, each README saying "Kept as the record / for lineage / for
design history." `positions/` anchors settled stances. The graph itself
supersedes-and-keeps. Fold-and-evacuate would be the only delete-based lifecycle in the
system - and it deletes exactly the layer (curated synthesis) the rest of the house works
hardest to keep. seed-absorption's tier-split defense ("different systems-of-record") only
justifies *mutability* differing across the mint gate, not *memory*: mutable-while-live at
the floor, immutable in the graph, but one memory policy everywhere - keep dated history.

## The collapse: no seed/plan distinction survives

Once seeds persist as dated, stipulation-citable briefs, every candidate distinction from
plans fails:

- **Scheme.** `plan:` vs `document:` are both `cb:c059` stipulation schemes with equal
  grounding power; per `cb:c043` they distinguish reference *form* (id-indirection vs
  repo path), not artifact ontology. Both schemes survive the collapse untouched - no
  contract change required.
- **Location.** Graph-adjacent workspace vs code-adjacent `plans/` is routing by subject -
  a shelf convention, not a kind.
- **Epistemic vs execution.** Already interpenetrates past rescue:
  [transcript-format](transcript-format.md) (a seed) carries a full numbered spike plan;
  `plans/cb-schema-v2` (a plan) is a design deliberation that grounds contract `cb:c059`
  as its stipulation. Each already does the other's whole job.
- **Live-phase gate** (the strongest candidate). Seeds terminate at the mint gate, plans at
  the ship gate - but that is a property of the *focus*, not the artifact: one focus
  routinely crosses both (transcript-format: settle the design, mint the directive, run
  the spike). Splitting one focus's brief into a seed-doc and a plan-doc by phase would
  fragment the focus - violating the nursery's own focus-as-unit doctrine (`cb:a475` one
  level up).

Steelman for keeping two names (scenario B): the house already tolerates multiple genres of
dated prose - chronicles, positions, plans - without collapsing them. But those differ in
their *live* phase (nobody deliberates in a chronicle; nobody executes a position). Seed
and plan do not differ in kind while live: both are the working brief of a focus. The
genre distinction that matters is live-brief vs archived-brief - and that is **status, not
kind**. "Plan" survives as a *role* (a brief whose current focus is execution) and
`plans/` as a *shelf*; not as a separate artifact category with its own lifecycle.

This completes, rather than reverses, transcript-format's seeds-vs-directives resolution:
the directive stays the atomic desk-tracked "do X"; the brief it cites is one concept,
whichever shelf it sits on.

## The lean (scenario C, sharpened)

1. **Terminal seeds graduate, never evacuate-by-deletion.** Graduation = historicize
   (date-stamp; record the terminal maturity and its links - `minted:` for plant,
   grafted-into for a lost contest) + move to an archive shelf outside the live workspace.
2. **The fold survives as the graduation step.** Plant still writes onto the belief; graft
   still folds a dated "rejected: X because Y" block into the winner. What changes: the
   `seed` prop shrinks from whole-body to **digest + `document:` pointer** at the archived
   brief. That dissolves seed-absorption's open granularity problem by construction - many
   beliefs, one archived brief, no duplicated body.
3. **Compost may still delete.** A true fizzle that accreted nothing worth keeping just
   goes; the raw thread suffices for it. Deletion becomes a judgment ("nothing here"),
   not a lifecycle mandate - conceding the scaffolding argument exactly where it is true.
4. **One durable-brief concept.** Persisted seed = plan = a dated chronicle-of-a-decision
   that a directive or belief cites as its stipulation; located by subject; live-desk
   expressed by status and shelf, never by deletion.
5. **The doctrine survives, stronger.** "No tombstones" still holds: a tombstone is an
   undated terminal doc squatting in the workspace, readable as maybe-current; a dated
   graduate on an archive shelf is neither. "The nursery only ever holds live work"
   becomes literally enforced by the move. And the graph stays the single source of truth:
   the archive, like the nursery, has no authority - nothing reads it as current, so it
   cannot drift against the graph; it only explains it.
6. **The safety-condition dependency inverts.** Fold-and-evacuate *needed* persist-raw and
   statement-provenance to be safe. Graduation does not: the curated synthesis survives on
   its own. Those focuses stay valuable for what raw is actually for - auditing agent
   behavior - instead of being the sole custodian of destroyed synthesis. "Archive the
   seed" and "the thread is the audit trail" reconcile as different layers with different
   jobs, not competitors.

## Open design space
- **Where is the archive shelf?** Lean: outside `nursery/` proper so the live-work
  invariant reads literally (a `beliefs/archive/` sibling, or graduating graph-subject
  briefs alongside the existing `plans/` shelves). Alternative: `nursery/archive/`
  excluded from desk views. Undecided.
- **Shelf-convention unification.** `plans/done|superseded|deprecated` and the seed
  terminal maturities (planted/composted/grafted) are near-isomorphic lifecycles; whether
  they unify into one vocabulary is cosmetic and can lag the decision.
- **Frontmatter mechanics.** The archived doc should carry its terminal maturity, terminal
  date, and forward links (`minted:`, grafted-into) as checked fields - the nursery
  validates format, and the archive should too.
- **What of the `seed` prop's schema change?** seed-absorption's "Next" (add `seed` to the
  belief schema) shrinks to digest-plus-pointer; decide whether the pointer alone
  suffices, since `evidence` can already carry a `document:` artifact.

## Origin (2026-07-01)
The originating thread's lean, recorded in the seed brief that opened this focus: scenario
C - "seeds should persist via archiving, historicized so they can't drift; persisted-seed
= plan = a dated chronicle-of-a-decision; collapse into one durable-brief concept ...
plans don't need to exist as a distinct category - they backfill the durable-brief niche
that evacuating seeds currently vacate." This session deliberated the four scenarios fresh
and **concurs**, adding the sharpenings above: the fold survives as the graduation step;
the `seed` prop shrinks to digest-plus-pointer (dissolving the granularity question);
compost may still delete; the `plan:`/`document:` schemes are untouched; and the
persist-raw/statement-provenance gate on floor deletion is dissolved rather than awaited.

## Concurrence, and a rejected alternative that strengthens the collapse (2026-07-02)

The authoring-pipeline session ([thread](threads/2026-07-02-authoring-pipeline.md))
approached from an independent direction - how briefs formalize toward the graph - and
concurred with scenario C. It also deliberated and rejected an alternative this focus had
not considered: **typed nursery documents** (one mutable doc kind per structural type,
with action items filed as prescription-seed docs). Rejected because it would multiply
artifact kinds exactly where this focus collapses them, fragment one focus's brief along
the type axis (the same mistake as the phase split above, on a new axis), and force type
commitment at minimum information - see [mint-manifest](mint-manifest.md) for the full
grounds and the adopted weak form. The typing pressure lands as structure *within* the
brief (typed manifest rows), never as document taxonomy, which sharpens this focus's
conclusion: the brief is one artifact in every phase; live-desk state is **status, not
kind** - and now, type is **rows, not documents**. The action-item drift recorded above
(briefs carrying plan sections in an undefined register) resolves compositionally:
action items are prescription rows in the brief's mint manifest, minted to the desk when
firm.

## Resolution (2026-07-02): graduation wins the contest

Operator-settled in the authoring-pipeline session. The deciding statement of the chain
argument, in the operator's words: the round trip runs thread -> routing ledger ->
proto-belief document -> DAG, "and then you can work backwards from the belief ... in
reverse through that whole series of documents. And because of that, if you remove the
[proto-belief document], you've broken that chain." The document is mandatory
provenance; no counterposition survived (the fold is lossy outside the plant arm, the
raw-thread substitute is gated on unbuilt machinery, and the node prop is a worse home).
Rejected: [seed-absorption](seed-absorption.md)'s fold-and-evacuate, grafted into this
document per its own contest arm - the fold mechanism it contributed survives as the
graduation step. Retained concession: a true fizzle that accreted nothing and that
nothing cites may still be deleted - a judgment, never a lifecycle rule.

Sharpened at resolution:
- **Graduation includes a `cb.repoint` pass.** Moving a document to the archive shelf
  breaks every `document:` citation into it (the cb:a547 hazard); the graduation
  procedure swings citations to the new path, and the document-rung verifier (cb:a571)
  makes a missed pointer a CI failure, not a silent orphan.
- **The `seed` prop is dead entirely** (with the seed vocabulary itself - cb:a569):
  `artifact` and `evidence[].artifact` already carry the typed back-pointer; no schema
  change.
- **Q7 (the archive shelf) gains the invisibility requirement:** the operator requires
  archived documents out of the working hierarchy - "redundant architecture that points
  back to a previous time and can create confusion in new agents" - which rules out
  archive-in-place and shapes the shelf options (see Open design space).
- **The graduation prescription mints after Q7** names the shelf, so the policy carries
  no hole.

## Related
- [seed-absorption](seed-absorption.md) - the fold-and-evacuate principle this contests;
  its fold mechanism survives here as the graduation step.
- [nursery-architecture](nursery-architecture.md) - the model whose evacuation half this
  contests; its focus-as-unit half supplies the collapse argument.
- [transcript-format](transcript-format.md) - the seeds-vs-directives resolution this
  completes; its persist-raw decision stops being load-bearing for floor deletion.
- [statement-provenance](statement-provenance.md) - stays valuable for raw auditability;
  no longer the safety condition for the seed lifecycle.
- `plans/done/README.md`, `chronicles/` - the house precedent: dated reasoning graduates,
  never deletes.
