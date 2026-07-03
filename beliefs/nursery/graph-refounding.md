---
type: concept
title: Graph re-founding at a dev milestone
description: Covers re-initializing the belief graph when CB reaches a development milestone - the dev-era churn (id migrations, vocabulary renames, schema epochs) should not be the permanent record a shipped framework presents. Straight deletion fails three hard tethers; the workable form is re-founding into a fresh collection with the dev graph frozen as a closed, resolvable, out-of-default-view collection. Raised by the operator in the fold-chronicle session; composes with vocabulary-read-surface and the Q7 invisibility requirement.
tags: [nursery, lifecycle, collections, provenance, milestone]
status: active
timestamp: 2026-07-03
maturity: active
threads: [2026-07-02-fold-chronicle-into-threads]
---

# Graph re-founding at a dev milestone

## The matter

The graph on record is mostly CB building itself: an id migration, two vocabulary
renames, schema epochs, shelf closures - scaffolding churn, not the design. Should the
belief graph be re-initialized when CB reaches a development milestone, so that the
permanent record a shipped framework presents is the design and not the ugly dev work
that produced it? Raised by the operator (2026-07-03) while weighing the cost of burning
supersessions on vocabulary fixes; the graph's own precedent invites the question:
cb:b566 says the id letter-swap "was sound only because b-space was virgin and no
external consumer held references, conditions the migration itself ended." There is a
class of move that is legitimate exactly once, before external consumers exist - a
re-founding is that move at graph scale, and pre-milestone is the only time it will ever
be cheap.

## Where things stand

**Straight deletion fails three hard tethers.** Wiping beliefs.json is off the table:

1. **Commit trailers.** Every `Belief:` trailer in git history must name a live node -
   `mix cb.verify.commits` fails permanently on a wiped graph, and history is immutable
   (cb:b573 exists precisely to keep those SHAs dereferenceable).
2. **Document citations.** The chronicles shelf, plans/, positions/, the guide's
   grounding boxes, and the glossary all cite node ids; every one would dangle.
3. **The test corpus.** The 407-test suite, the codepath collection, and the worked
   examples run against this graph's real shape.

**The workable form: re-found into a fresh collection.** At the milestone, freeze the
dev-era graph as a closed collection (working name `cb-v0:`) - complete, resolvable,
never extended - and initialize the milestone graph as a new collection that re-mints
only the rules that survived, in current vocabulary, each citing its `cb-v0:` ancestor as
provenance. The framework already ships every mechanism this needs: namespaces,
collections.json, cross-namespace `depends_on`, cross-collection resolution in the shell
and verifiers. Old trailers and citations keep resolving into the frozen collection; new
agents boot from a clean rulebook that never mentions focuses or directives; the dev
history is there when wanted and invisible by default - the operator's invisibility
requirement (Q7, cb:b577), satisfied without deleting a node. The constitutional
reading: the dev graph becomes the founding archive, not the operating law.

**Relations.**

- [vocabulary-read-surface](vocabulary-read-surface.md) - a re-founding launders retired
  vocabulary wholesale, so it moots the render-time annotation machinery; hold that
  build while this matter is open. The b567/b572 supersession test stays compatible
  either way (two more supersessions cost the frozen collection nothing).
- [seed-lifecycle](seed-lifecycle.md) Q7 / cb:b577 - the archive-shelf decision and its
  invisibility requirement are this same instinct at document scale; a re-founding
  extends it to the graph tier and should land as one coherent policy, not two.
- The deprecated-directory proposal rejected in vocabulary-read-surface is this idea's
  weak form; re-founding is the strong form done with the grain - nothing hidden by
  instruction, everything relocated by collection boundary, which the tooling respects
  structurally.

## Open

- **What is the milestone?** A version cut, a schema freeze, the first external
  consumer, or an operator declaration. The b566 logic says the gate closes when
  external references exist - so the milestone must come before adoption, not after.
- **Namespace assignment.** Does the new collection take `cb:` (and the frozen one
  re-register as `cb-v0:`), so living docs keep reading naturally - which then needs a
  resolution story for historical `cb:` references (trailers, archived docs) into the
  frozen collection, on the b566 exact-match-beats-alias precedent? Or does the frozen
  graph keep `cb:` and the new one take a fresh namespace, leaving history untouched but
  making the new graph the odd name out?
- **The survival criterion.** What re-mints: every active prescription? Active
  attestations/aggregations/inferences too, or only what the surviving prescriptions
  dep on (the dependency closure of the operating rules)?
- **Ancestor provenance shape.** A `cb-v0:` id in `deps` (cross-namespace, machinery
  exists), an evidence entry citing the ancestor, or a dedicated field; and whether
  re-minted nodes carry fresh serials or preserve them for legibility.
- **Verifier epoch-awareness.** `mix cb.verify.commits` must resolve pre-milestone
  `Belief:` trailers into the frozen collection; whether that is a collections.json
  lookup or an explicit epoch table.
- **Cadence.** Once or recurring? "Re-initialized when cb reaches a dev milestone"
  (operator) reads as potentially recurring; the b566 logic says each re-founding is
  only sound while the *new* space has no external consumers, so recurrence gets harder
  every time and the machinery should not assume it.

## Thread excerpts (2026-07-03)

**User (the proposal):** "another approach is this - the belief graph is re-initialized
when cb reaches a dev milestone. I say this being this stage has been a lot of ugly dev
work that potential should not live on the permanent record."

**User (the context, same exchange):** "Ok I lean towards 2 as a test, and this raises
interesting issues that we have no choice to consider." - option 2 being the b567/b572
supersession test in vocabulary-read-surface.

**Claude (the reframe):** deletion breaks trailers, citations, and the test corpus;
"freeze the dev-era graph as a closed collection ... and initialize the milestone graph
as a new collection that re-mints only the rules that survived, in current vocabulary,
each citing its cb-v0: ancestor as provenance ... The dev graph becomes the founding
archive, not the operating law."

## Related

- [vocabulary-read-surface](vocabulary-read-surface.md) - the pollution problem a
  re-founding solves wholesale; its annotation build is gated on this matter.
- [seed-lifecycle](seed-lifecycle.md) - Q7, the archive shelf, and the invisibility
  requirement (cb:b577).
- cb:b566 - the last-alpha-rename closure; the once-only-while-virgin logic this
  generalizes.
- cb:b573 - merge-commit only; the SHA-durability constraint any re-founding must not
  break.
