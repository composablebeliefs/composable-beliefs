# 2026-06-23 - the supersession leaves a wake

## Where things stood

The OKF/identity thread had run across several accidentally-quit sessions
(2026-06-15 through 06-17) and then sat. Its substance had since been actualized
by the neighboring sessions that did the heavy lifting: the OKF layering analysis
became `okf/meta/okf-vs-cb-layering.md` and the okf-fold; the identity work became
cb-direction's substrate-altitude definition, the one-way dependency/knowledge
invariant, and the "CB as a conformant OKF consumer, not a format owner" call; and
the concrete cleanup from that thread - dropping the connector-specific `gmail:`
scheme - had landed as `cb:c043 -> cb:c066`. This session opened on a request to
re-examine all of it after the quits and see what, if anything, was still owed.

## The arc

Re-examination found the repos clean and synced and the thread effectively closed
- with one loose thread that was not a leftover so much as a *consequence*. The
`cb:c043 -> cb:c066` supersession had dropped `gmail:` cleanly, but `cb:a526` (the
anchored-position format) still cited "the c043 grammar" and still depended on
`cb:c043`. The staleness cascade had caught it. This is the mechanism working
exactly as designed: a contract supersession leaves a wake, and the graph names
the wake instead of letting it rot silently.

Fixing it was a two-step chase, and the second step is the interesting one.
Superseding `a526 -> a550` (dep and claim repointed to `cb:c066`; the `code:`
grammar is identical between the two contracts, so the format itself did not
change) immediately re-pointed the staleness one level up: `cb:a527`, the
terms-block directive, depended on `a526` and was now depping a superseded node.
So `a527 -> a551`, dep `a526 -> a550`, and the cascade ran dry - "No stale beliefs
found." The lesson worth keeping is that superseding a node with dependents is
never a single write; you walk the dependents to the frontier. The graph tells you
how far the frontier reaches, which is the whole point of having it.

Two incidents from the wider thread finally got homes in the graph rather than
living only in the direction-repo narrative.

The first was the **wrong-clone episode** from 06-17, which had never been
recorded as a queryable agent-behavior pattern - only narrated as provenance in
the cb-direction and amieval-direction threads. The shape: the `gmail:` cleanup was
first applied to a working copy that turned out to be a months-old extraction
clone, cloned from a different upstream and never synced after its origin was
repointed (its fetch refspec still named a deleted branch, so `git fetch` had been
failing silently for weeks). The change had no valid target on canonical, but it
was reported "applied, verifier green" - and the error surfaced only on push, as a
non-fast-forward with no merge base. Three CB clones coexisting on disk made the
hazard structural, not incidental. That became `agent-behavior:a409` (the observed
error) and `agent-behavior:a410` (the rule: verify a working copy is the canonical,
remote-synced one - that `git fetch` actually succeeds, that HEAD is not diverged -
before writing to it or calling a change done; and treat the push as part of
verification, since a change that has not pushed is not confirmed).

The second was a live instance of `cb:a538`'s own subject. When this session went
to commit the `a550/a551` fix, the working tree was already clean: a concurrent
session's commit (`8c161cf`, minting `cb:a549`) had staged the same `beliefs.json`
and swept the in-flight writes into its own commit and push. Nothing was lost -
`a550/a551` were verified present in HEAD and on origin - but it is the second
recorded specimen of the exact concurrent-write sweep `a538` exists to settle, so
it landed as evidence there. The difference from the first specimen is only that
the swept HEAD happened to be gates-green this time, by timing luck rather than by
the committing session checking; the torn-HEAD risk is unmitigated.

## Where things stand

The `cb:` graph is stale-clean and verifier-green (20 passed). The
`agent-behavior` collection verifies green with the new pair. `cb:a538` carries a
second specimen. All direction content from the thread was already routed and
pushed in prior sessions; nothing strategic was produced here that needed routing.

## What the next session inherits

Nothing owed from the OKF/identity thread - it is closed. The standing obligations
are the pre-existing desk items, unchanged by this session except that `cb:a538`
(commit hygiene under concurrent writes) now has two specimens and is riper for a
decision. The three coexisting CB clones on disk - `composable-beliefs(old)`,
`composable-beliefs(also old)`, and the canonical `amieval/composable-beliefs` -
remain a live trap; `agent-behavior:a410` is the guardrail, but pruning the dead
clones would remove the hazard at the source.
