---
type: thread
title: 2026-07-06 - atomization migration - the graph decomposed to atoms and swapped
description: The wholesale atomization migration, proposal to merge-ready PR in one session. The operator proposed decomposing conjunctive beliefs into single-sentence attestations with composites as aggregations; the assessment found the graph already held that doctrine (cb:b475/b402/b405) while violating it - 30 of 48 attestations conjunctive, zero aggregations ever. Executed as a spec-driven regenerable parallel graph (plans/atomize/, mix cb.migrate.atomize) then swapped: 31 attestations retyped to aggregation over 126 minted atoms, 24 prescriptions restated (norms in claims, enumerables in invariants, rationale in dep atoms), doctrine minted as cb:b597, b401 superseded by migration atom b811. Graph 258 -> 392 nodes, PR #29. Use when auditing the migration, resuming the 2-sentence tier or dep-grounding follow-ups, or citing the parallel-graph migration pattern.
tags: [thread, cb, schema, atomicity, migration, aggregation]
status: active
timestamp: 2026-07-07
artifact: session:2026-07-06-atomization-migration
---

# 2026-07-06 - atomization migration - the graph decomposed to atoms and swapped

> **Hook-captured, /end-finalized (2026-07-07).** Body auto-rendered by the Stop hook
> (responses only; reasoning and tool calls stripped); metadata, narrative, and routing
> synthesized at close. **Non-provenance** - the proto-belief documents and the migration
> spec are. Closed under the cb:b583 turn-separation rule: `/end` ran alone in its own
> turn, after the PR-creation exchange that ended the substantive work, so the embedded
> body is complete through PR #29's creation; the only turn omitted is this `/end` turn
> itself. The session spanned 2026-07-06 into 2026-07-07; the render slug carries the
> start date. Retro-pairing (cb:b507): cb:b597, the one belief minted through the write
> flow from this session's operator exchange, was paired to this document in this turn,
> pair-then-write. The 129 atoms and 42 reshaped nodes the migration minted are
> deliberately NOT thread-paired: their provenance is the reviewed spec
> (plans/atomize/spec.json, spec-2.json) and design record (plans/atomize/design.md),
> which every touched node already cites in its migration evidence entry - pairing them
> here would recreate the digest antipattern the graph warns about.

## Where things stand (the narrative)

**Where things stood.** The graph carried 257 nodes; the aggregation structural type had
never been instantiated; the atomicity doctrine (cb:b475) had been active since 2026-06-10
while 30 of 48 active attestations conjoined multiple assertions, and cb:b405's
decomposition sweep sat prescribed but never materialized. The operator opened with the
decomposition proposal and asked for an assessment.

**The arc.** The assessment came back: the proposal is the graph's own doctrine, violated
in practice - and the genuinely new element was putting the unused aggregation type to
work. The operator then made the call that shaped everything after: the DAG is more
aspirationally immutable than practically (one star, no users), correctness outranks
ceremony, do the wholesale migration as a parallel DAG where a decomposed belief keeps its
id and claim but becomes an aggregation over newly minted atoms. The session sharpened
that into mechanism - judgment in a reviewable spec, generation deterministic and
regenerable, identity preserved, the cb:b051 vocabulary-migration precedent extended from
labels to grounding - and minted it as doctrine (cb:b597) through preflight/import before
executing.

Execution ran in lanes. The descriptive lane covered all 57 attestations and inferences
with complete coverage required: 31 aggregations over 115 atoms, 2 inference trims, 24
keeps with recorded reasons. The generator (`mix cb.migrate.atomize`) surfaced one real
bug worth remembering: the store serializes the *raw stored* type for round-trip
stability, so the first emitted graph silently carried zero aggregations until the retype
landed on both the normalized and raw fields - caught by querying the output, now pinned
by a regression test. The prescriptive lane followed as increments (prescriptions cannot
become aggregations - the b057 mood binding): a new `restate` disposition moved norms into
claims, enumerable content into invariants, and extracted rationale into atoms the
prescription deps on. Tranche 1 took the eleven 5+-sentence claims, tranche 2 the eleven
4-sentence ones, tranche 3 (post-swap, via a `lane: prescriptive` mode) the eight
decomposable 3-sentence ones - including cb:b475 itself, which now practices what it
preaches.

On "Proceed," the swap replaced beliefs/cb wholesale and regenerated CLAUDE.md in the same
commit - its Git Policy section now renders the tightened b580/b587 norms with their
rationale living in the graph as dep atoms. Follow-through ran entirely on sanctioned
doors: cb:b401 (which still described the removed stored contract field) was superseded by
cb:b811, the migration-minted atom already stating the current rule - the deferred-
supersession door meeting a successor the migration had incidentally created; the stale
flag that raised on cb:b056 was discharged with `mix cb.repoint`; cb:b545 turned out to
need nothing, its materialized todo already closed with the implementing commit recorded.

**Where things stand now.** The live graph is 392 nodes, 346 active: 31 aggregations, 155
attestations (126 of them single-sentence migration atoms), 9 inferences, 197
prescriptions - 24 carrying invariants that used to be claim prose. Every pre-existing id
survived; every claim change carries an evidence entry with the previous text. Schema
verifies 20/20 with subject containment finally exercised, CLAUDE.md is current, 470 tests
green, stale set unchanged at its 3 pre-existing items. PR #29 carries the branch.

**What the next session inherits.** Run `mix cb.verify.collection` for the sibling
collections locally before merging PR #29 (belief-collections is not staged in the remote
environment). The 2-sentence prescription tier (~60 nodes) is mostly legitimate keeps -
opportunistic pass at best. Grounding the dep-less prescriptions in the newly minted atoms
is the remaining structural improvement and wants its own matching session. And cb:b405
(sweep-discipline) deserves an operator call: this migration effectively executed it, so
it could be materialized-and-discharged or restated to current vocabulary.

## Routing

| Topic | State | Dispatch | Dangling question |
| --- | --- | --- | --- |
| Decomposition assessment (proposal vs graph doctrine) | closed | minted cb:b597; mechanism recorded in plans/atomize/design.md | - |
| Descriptive-lane decomposition (57 nodes) | closed | plans/atomize/spec.json; swapped into beliefs/cb | - |
| Prescriptive-lane decomposition (tranches 1-3) | closed | plans/atomize/spec.json + spec-2.json; swapped | - |
| Prescriptive 2-sentence tier + dep-grounding of unlinked prescriptions | open | unrouted | which dep-less prescriptions ground in which migration atoms? |
| cb:b405 sweep-discipline disposition | open | unrouted | materialize-and-discharge, or restate to current vocabulary? |
| Sibling-collections verification | open | unrouted (noted in PR #29 body) | does mix cb.verify.collection pass against the swapped graph locally? |
| PR #29 merge | open | https://github.com/composablebeliefs/composable-beliefs/pull/29 | - |

## User

Examine the dag in this repo. Consider the proposal that beliefs should be decomposed into single sentence attestations as much as possible, with more complete statements being aggregate statements. Currently, the majority of beliefs i would argue are actually aggregate beliefs that need to be decomposed. Evaluate, analyze, and return your assessment

## Assistant

I have everything I need. Here is my assessment.

## Verdict

The proposal's diagnosis is substantially correct - and, strikingly, **it is already the graph's own active doctrine, which the graph is violating in practice**. The remedy, however, needs to be narrower than "decompose everything": sentence count is not claim count, prescriptions (73% of the graph) have a different decomposition channel than aggregation, and immutability makes a retroactive mass rewrite expensive and noisy. The right move is enforcement at the authoring gate plus opportunistic retrofit, not a big-bang sweep.

## What the graph actually looks like

Of 212 active beliefs: 155 prescriptions, 48 attestations, 9 inferences, and **zero aggregations**. Not just zero active - across all 257 nodes including superseded ones, no aggregation has ever been authored, even though it is one of the four structural types, is fully supported in `lib/cb/belief.ex:43` ("states exactly what its deps jointly state"), and is precisely the type the proposal says composite statements should be.

On the attestation side, the atomicity gap is measurable. Only 6 of 48 active attestations are single-sentence; the median is 3 sentences (~57 words), and 30 of 48 run to 3 or more. Some are unambiguous bundles: cb:b174 packs about six separable propositions (implications are behavioral directives; they work through the prompt; they're soft; they're durable; contracts are code-verified invariants; the boundary is the enforcement mechanism) into a single dep-less leaf.

The dependency structure confirms that meaning is living in prose instead of composition: mean dependency depth is 1.4, and 62 of 155 active prescriptions have no deps at all. The composition machinery the framework's own README celebrates ("an inference concludes what none of its inputs states alone") is carried by 9 inference nodes and 0 aggregations.

## The graph already agrees with you

Four active nodes state the proposal, nearly verbatim:

- **cb:b475** (prescription, "primitive atomicity doctrine"): an attestation is "one atomic statement of what a single source said, leaning verbatim. A primitive whose claim conjoins separable assertions is a mis-authored compound and is split at authoring time."
- **cb:b114** (attestation): "The schema is built around atomic, composable beliefs - the claim field is a one-liner."
- **cb:b402** ("claim-discipline"): when a claim is overcommitted, "decompose into multiple beliefs."
- **cb:b405** ("sweep-discipline"): every compound belief is reviewed and "beliefs whose type does not match their claim's actual shape are re-typed or decomposed."

So the sharpest, graph-native form of your observation is: **b405 is active but its `materialized` field is null - the decomposition sweep the graph prescribes for itself has never been executed.** And the violation is not merely legacy debt: 32 of the multi-sentence attestations predate b475 (2026-06-10), but 10 were minted on or after doctrine day, including cb:b554 (2026-06-25, 4 sentences, 6 dependents) and cb:b579 (2026-07-02). The authoring gate that b475 says enforces atomicity is not enforcing it.

## Why granularity is load-bearing in this specific system

Decomposition isn't aesthetic here; every consequential mechanism operates at node granularity, so conjunctive claims degrade all of them:

- **Supersession is all-or-nothing.** If one of b174's six propositions goes stale, superseding it forces re-asserting the other five inside a new node, muddying the traceability immutability was meant to buy.
- **Conflict detection (b055, `cb.preflight`) compares nodes.** A proposed belief can contradict one clause of a bundle and agree with the rest - adjudication then resolves a conflict that structurally doesn't exist as a node.
- **Deps are node-granular.** An inference leaning on one sub-claim of a bundle imports the rest; when an unrelated sub-claim is falsified, `mix bs stale --cascade` flags dependents that never used it. Note that two of the five most-depended-on nodes (cb:b470, cb:b554) are multi-sentence attestations.
- **Evidence appends to the node**, so with a bundled claim you cannot tell which sub-claim a dated evidence entry supports.

Atomic attestations plus aggregations fix all four at once: supersede the atom, conflict against the atom, dep on the atom, evidence the atom - and keep the readable composite as an aggregation whose meaning is exactly its deps.

## Where the proposal overreaches

Three corrections to "the majority of beliefs are aggregates needing decomposition":

**1. Sentence count overstates the backlog.** Sampling the mid-length attestations, roughly half are one proposition plus elaboration - rationale (cb:b110's counterfactual), contrast (cb:b437's "distinguished from..."), or example - not conjoined assertions. b402 already draws the correct line: a claim needing bridging prose is either underspecified (rewrite) or overcommitted (decompose). Forcing rationale sentences into standalone attestations would mint fake atoms that no source attests and nothing deps on. Realistic decomposition candidates are maybe 15-20 attestations, not 42.

**2. Prescriptions are not aggregations and can't become them.** An aggregation is descriptive - "what its deps jointly state" - while a prescription is what the house stands behind; the moods don't convert (b057 makes this a checked boundary). Multi-sentence prescriptions have their own native decomposition channel that the proposal ignores: the `rules`/`invariants` arrays. cb:b525 enumerates README sections in claim prose with `rules: []`; that content belongs in rules, not in sibling belief nodes. The prescription-side fix is (a) move enumerable content into rules/invariants and (b) ground rationale in deps - which would also chip at the 62 dep-less prescriptions.

**3. Retroactive decomposition fights immutability.** Splitting an existing node means superseding it into N atoms plus an aggregation; doing that across ~90 multi-sentence active nodes roughly triples the graph including tombstones, and every existing dependent still points at the superseded bundle unless re-authored too. That's a lot of churn carrying no new information - the kind of ceremony-without-evidence the graph's own b386 doctrine warns about in another context.

## What I'd actually recommend

1. **Enforce b475 where it says enforcement lives: the write flow.** Add a deterministic preflight signal - flag any proposed attestation whose claim exceeds one sentence (or ~25 words) as an atomicity candidate. Judgment stays human per b475, but today nothing even raises the question, and post-doctrine bundles keep landing.
2. **Start authoring aggregations.** The type's zero-instantiation after three weeks of active use is the clearest structural finding here. The natural first aggregations are exactly the composite statements you'd extract when decomposing a bundle: atoms as new attestations, the original composite restated as an aggregation over them.
3. **Retrofit opportunistically, not wholesale.** Decompose a node when it is next touched - superseded, evidenced, or newly depended-on - and prioritize the high-fanout multi-sentence nodes (cb:b470, cb:b554, cb:b174, cb:b383) where coarse granularity taxes the most dependents. This is effectively executing b405's sweep as a standing policy rather than a one-shot rewrite.
4. **Treat prescriptions separately:** claim states the norm in one or two sentences; enumerable content moves to rules/invariants; rationale moves to deps.

In short: you've re-derived the graph's own b475/b402/b405 doctrine from observation of its violations - which is itself decent evidence the doctrine is right. The genuinely new element in your proposal is putting the never-used aggregation type to work as the home for composite statements, and that's the piece I'd push on first.

Committed the session render (the ride-along artifact the Stop hook stages) and pushed to `claude/belief-decomposition-analysis-2ig4pn`. No other changes were made - the task was analysis only, and `beliefs/` was read but never modified, per the data-protection rule.

The assessment itself stands as delivered in my previous message: the decomposition proposal restates the graph's own active doctrine (cb:b475, cb:b402, cb:b405), which practice violates - 30 of 48 active attestations run 3+ sentences and the aggregation type has never been instantiated - with the recommended path being authoring-gate enforcement plus opportunistic retrofit rather than a wholesale rewrite.

## User

Ok i agree with most everything you've said, except that the dag is more aspirationally immutable than practically. The repo has one star, and that's by a friend of mine. Nobody is using this. I am more interested in correctness than strict adherence at this point. I suggest we do the wholesale migration, as a parallel belief dag. I propose that a current belief, which is depped by others, and needs to be decomposed, keeps it id and claim, but beckmes an aggregate belief, and new attestations are created to compose it. This new dag would be alongside the existing - perhaps there could be a flag to swap them. Thoughts?

## Assistant

Your keep-the-id-retype-to-aggregation move is the right core mechanism - it's the one design that makes decomposition backward-compatible, and I'd endorse the wholesale migration built around it. A few thoughts on where it needs sharpening, and one counter-proposal on the parallel-DAG mechanics.

## Why the retype move is sound

Keeping id and claim while flipping type to aggregation means every existing dependent stays valid with unchanged meaning: an aggregation "states exactly what its deps jointly state," and what it states is the same claim text the dependent originally leaned on. The node was always a de facto aggregate; the migration just makes the structure honest and pushes grounding down to new atoms.

And you have precedent that this isn't even a departure from the graph's practice. b051's Evidence 3 records the vocabulary migration: all 220 nodes rewritten in place, in one pass, explicitly framed as "identity and claims unchanged - not a supersession." An in-place retype with stable id and claim is the same class of operation - identity preserved, structure corrected. So I'd frame this migration the same way rather than as "breaking immutability": immutability protects claim identity and provenance, and both survive. Worth minting one belief that records the migration doctrine and cites that precedent, so the graph explains its own history.

## Four wrinkles to resolve in the design

**1. The aggregation contract will bite on elaboration prose.** An aggregation must state exactly what its deps jointly state. Where a bundled claim is N separable assertions, the atoms will jointly state it and the retype is clean. But roughly half the multi-sentence claims are one assertion plus rationale/contrast/example - after decomposition, no atom attests the rationale, so the verbatim claim *exceeds* its deps and the node is invalid as an aggregation by its own definition. Per node you need one of three dispositions: trim the claim (small edit, id kept), retype to **inference** instead (a conclusion licensed to exceed its deps - often the honest type for claim-plus-rationale), or attest the rationale as its own atom when a source actually said it. So the migration is a per-node typing judgment, not a mechanical split.

**2. Prescriptions need a separate lane.** 155 of 212 active nodes are prescriptions, and they can't become aggregations - b057's mood binding forbids it, and correctly: a norm isn't what its deps jointly state. Their decomposition channel is: claim keeps the norm in a sentence or two, enumerable content moves into `rules`/`invariants`, rationale moves into deps (new attestations). Same keep-the-id spirit, different mechanics. This lane is actually most of the migration by node count.

**3. Evidence has to move down.** An attestation's grounding is artifact + dated evidence; an aggregation's grounding is its deps. So when b174 retypes, its artifact and evidence entries belong on the new atoms (each atom citing the source that attests it), and the aggregation gets one fresh evidence entry recording the decomposition itself - which atoms, when, under what spec. Leaving source evidence on the aggregation would leave the atoms ungrounded and the aggregation double-grounded.

**4. Concurrent writes will race a parallel copy.** CLAUDE.md warns other sessions write these repos concurrently. A hand-built parallel directory starts going stale the moment you fork it.

## Counter-proposal on the parallel DAG

Wrinkle 4 is why I'd restructure the "parallel DAG with a swap flag" as **a decomposition spec plus a generator**, rather than a hand-maintained second graph:

- The judgment lives in a reviewable data file: per node, the disposition (aggregation / inference / claim-trim / rules-migration), the atom claims, and the evidence mapping. This is where the actual intellectual work is, and it's diffable and correctable.
- A mix task (`mix cb.migrate.atomize`, dry-run by default like the other doors) applies the spec to the *current* live graph and emits the atomic graph. Regenerable at any time, so staleness stops mattering - you re-run at swap time.
- Emit to `beliefs/cb-atomic/` for the side-by-side period. You don't need to build a swap flag: `mix bs --beliefs beliefs/cb-atomic` already exists as the selection mechanism, and because ids are stable and the change is additive-plus-retype, the atomic graph is a drop-in superset - belief-collections' `depends_on cb:` keeps resolving.
- The swap itself is then just replacing `beliefs/cb/` with the generated output in one commit (or a merge, if you stage it on a branch - honestly, git is already the parallel-DAG-with-a-flag, and a branch plus PR diff is the cheapest review surface for the swap).

Verification before swap: `mix cb.verify.schema` on the atomic graph, `mix cb.verify.collection` for the downstream collections, plus migration-specific invariants worth checking in the generator - every retyped aggregation has 2+ deps that jointly cover its claim, every atom is single-sentence and carries an artifact, no dependent's dep list changed.

Rough scope: ~30-40 attestations decompose into maybe 100-150 atoms, 9 inferences mostly pass through, ~90 multi-sentence prescriptions mostly migrate content into rules rather than minting nodes. Active graph lands somewhere around 350-450 nodes.

If that shape works for you, the natural first deliverable is the migration spec for the descriptive lane (the ~40 attestations), since that's where your retype mechanism does its work and where the aggregation type finally gets exercised. Want me to draft it?

Committed and pushed - the only change was the Stop hook's updated session transcript render, which now rides along on the branch as `afbf81c`. The design discussion stands as delivered; let me know if you want me to start drafting the decomposition spec for the descriptive lane.

## User

Yes begin, then implement what you can until context fills

## Assistant

The migration introduced no new staleness - both graphs flag the same 3 pre-existing items. The work is at a natural completion point: every 4+ sentence node in the entire graph is now handled. Here's where things stand.

## What was built this session

**The parallel atomized graph exists and verifies.** `beliefs/cb-atomic/` holds 389 nodes (live graph: 258) and passes all 20 schema checks. The live `beliefs/cb/` was never hand-touched; the only live-graph change was cb:b597, the migration-doctrine prescription, minted through the sanctioned preflight/import flow.

**The machinery** (all pushed to `claude/belief-decomposition-analysis-2ig4pn`):
- `plans/atomize/spec.json` - the reviewable judgment: 79 node entries across both lanes
- `plans/atomize/design.md` - mechanism, id policy, evidence policy, swap procedure
- `mix cb.migrate.atomize` - deterministic generator, dry-run by default, regenerable at swap time against the then-current live graph; refuses on coverage gaps, ungroundable atoms, id collisions, and cycles
- 5 tests covering the retype serialization (including a real bug caught mid-session: the store round-trips the raw stored type, so the retype had to land on both fields), inheritance, restate, and both refusal paths - full suite 470 green

**Descriptive lane (complete coverage, all 57 nodes):** 31 conjunctive attestations keep their id and claim, retype to aggregation, and ground in 115 minted single-sentence atoms (b700-b814) that inherit the parent's artifact and subjects. 2 inferences trimmed dep-restating claims. 24 keeps with recorded reasons. The aggregation type, defined but never once instantiated in the graph's history, now has 31 members.

**Prescriptive lane (incremental, both high tranches done):** all 22 prescriptions with 4+ sentence claims are dispositioned - 16 restates (claim keeps the norm, enumerable content becomes invariants, rationale extracts to atoms the prescription deps on), 2 trims, 4 keeps for discrete todos where decomposition is ceremony. This includes the CLAUDE.md-rendered policies (b580 commit-autonomy, b587 history-rewriting).

## Two things surfaced worth your attention

- **cb:b545 looks overtaken by events**: it's an open action-item asking whether to add a `commit:` scheme - but that scheme now exists in b067 and `mix cb.verify.commits` ships. Candidate for `cb.todo.close`.
- **cb:b401 contradicts b056**: it still describes the removed stored `contract` field; flagged in the spec for a follow-up supersession.

## What remains (in rough priority order)

1. **The swap** - replace `beliefs/cb/` with a fresh `--write` output in one reviewed commit, regenerating CLAUDE.md in the same commit (restated claims render into it). Everything is staged for this; it's your call when.
2. The ~48 three-sentence prescriptions - genuinely marginal territory (about half are elaboration, not conjunction), best done as incremental spec revisions.
3. Grounding the 62 dep-less prescriptions in the newly minted atoms - a dedicated matching pass.

## User

Proceed

## Assistant

The wholesale migration is complete and swapped into the live graph. Final state:

## What "Proceed" executed

**The swap is done.** `beliefs/cb/` is now the atomized graph - 392 nodes, up from 258 at session start. `beliefs/cb-atomic/` is consumed, and CLAUDE.md was regenerated in the swap commit (its Git Policy section now renders the tightened norms, with the rationale living in the graph as dep atoms instead of inline prose). Everything verifies: schema 20/20, `cb.generate.claude_md --check` current, `cb.verify.commits` clean, 470 tests green, and the stale set is back to the 3 pre-existing items.

**Follow-up work that landed after the swap:**
- **Tranche 3** via `plans/atomize/spec-2.json` and a new `lane: prescriptive` mode (the tool otherwise self-fences post-swap): 8 more restates among the 3-sentence prescriptions, including cb:b475 itself - the atomicity doctrine now practices what it preaches, with its enforcement rule as an invariant. The rest of that tier stays deliberately: enum registries are already contract-shaped, action-items carry their work descriptions, and norm-plus-elaboration claims fall on the keep side of the b402 boundary.
- **cb:b401 superseded by cb:b811** through the deferred-supersession door - the migration had already minted its successor (the atom stating contract-grade is derived, not stored), so the flip was one command. The stale flag this raised on cb:b056 was discharged by re-pointing its dep to the successor via `mix cb.repoint`.
- **cb:b545 needed nothing**: its materialized todo t0022 was already closed with the implementing commit recorded, so its active+materialized state is the correct discharged form per the b380 lifecycle.

## Final shape of the graph

346 active nodes: 31 aggregations (a type that had zero instances at session start), 155 attestations (126 of them single-sentence atoms minted by the migration), 9 inferences, 197 prescriptions - 24 of which now carry their enumerable content as invariants and their rationale as deps rather than claim prose. Every pre-existing id survived; every claim change is recorded in an appended evidence entry carrying the previous text.

## What remains, for future sessions

- The 2-sentence tier (~60 prescriptions) - mostly legitimate keeps; worth an opportunistic pass at best.
- Grounding the dep-less prescriptions in the newly minted atoms - a dedicated matching session.
- An operator call on cb:b405 (sweep-discipline): this migration effectively executed it, so it could be materialized-and-discharged or restated to the current vocabulary.

All work is committed and pushed to `claude/belief-decomposition-analysis-2ig4pn` - eleven commits from analysis through swap, each independently verified.

## User

Create pr

## Assistant

PR created: [#29 - Atomization migration: decompose conjunctive nodes into single-sentence atoms](https://github.com/composablebeliefs/composable-beliefs/pull/29)

It covers the full arc - spec, generator, parallel graph, swap, and the post-swap follow-through - with the verification story and one pre-merge caveat noted in the body: `mix cb.verify.collection` for the sibling collections couldn't run here since belief-collections isn't staged in this environment, so that's worth a local run before merging.

Want me to watch the PR? I can subscribe to its activity and respond to review comments or fix CI failures as they come in.

## Related

- [plans/atomize/design.md](../../../plans/atomize/design.md) - the migration mechanism and swap record
- [plans/atomize/spec.json](../../../plans/atomize/spec.json) / [spec-2.json](../../../plans/atomize/spec-2.json) - the decomposition judgment, all lanes
- cb:b597 - atomization-migration-doctrine, minted this session and retro-paired to this thread
- cb:b475 / cb:b402 / cb:b405 - the pre-existing doctrine this migration executed
- cb:b401 -> cb:b811 supersession; cb:b056 repoint - the post-swap follow-through
- [PR #29](https://github.com/composablebeliefs/composable-beliefs/pull/29) - the branch under review
