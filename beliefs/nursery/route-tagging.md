---
type: concept
title: Route-tagging - per-paragraph topic tags that aggregate thread excerpts per focus
description: Covers marking each thread paragraph with the artifact it feeds via per-paragraph, multi-ref route tags placed on the frozen body at finalization, so a focus's cross-thread discussion aggregates into an append-only, date-stamped excerpt log in its proto-belief document. Formalizes the scattershot hand-picked "Thread excerpts" sections into a located, auditable, cross-thread audit trail. The concrete form of statement-provenance's back-edge, keyed on the routing-ledger's routed-to vocabulary; a third motion of /decompose. Unminted; rows staged.
tags: [nursery, threads, provenance, linkage, workflow]
status: active
timestamp: 2026-07-04
maturity: active
threads: [2026-07-04-route-tagging]
---

# Route-tagging - per-paragraph topic tags that aggregate thread excerpts per focus

## The matter

Every proto-belief document ends with a hand-curated `## Thread excerpts` section: a
few verbatim quotes the author picked to ground the design. The selection is invisible -
you cannot see what was left out without re-reading the whole thread - so it is arbitrary
and omission-prone, and it carries no systematic pointer back to *where* in the thread it
came from. There is also no cross-thread view: when the same matter is discussed again in
a later thread, its excerpts are not gathered with the first thread's. The routing ledger
(cb:b572/b582) tracks *dispatch* - which strand routed where - but not the located text
that grounds each strand.

What is missing is the back-edge at sub-thread granularity: from each region of a thread
to the artifact it feeds, in a form that both locates the selection (so omission becomes
auditable) and aggregates across threads (so a matter's whole conversational history is
readable in one place). This is statement-provenance's open question - "annotate inline,
or keep a side index?" - answered.

## The design: per-paragraph route tags on the frozen body

Mark each thread paragraph with the artifact its content feeds, using an inline tag keyed
on the **routed-to artifact id**, not a free topic phrase:

```
<p routes="route-tagging statement-provenance">
... one paragraph feeding both matters ...
</p>
```

Four properties, each settled against a rejected alternative:

- **Keyed on the routed-to artifact id, not a topic name.** The tag vocabulary is the
  routing ledger's `routed to` column - a controlled set already maintained, that cannot
  drift. Two threads discussing the same matter *necessarily* emit the same string
  (a filename), so the cross-thread join is exact. A free-text topic name would drift
  (`turn-separation` vs `end-turn-sep`) and the join would silently fail.

- **Per-paragraph, multi-ref.** A turn covers several matters, so turn granularity is too
  coarse; the paragraph is the atom. A paragraph that serves two matters carries both refs
  on one element (set-membership), never two overlapping elements - so there is never a
  nested range, and validity is trivial. Aggregation for a matter = every paragraph whose
  ref-set contains it.

- **Lifted whole, no within-region trimming.** The selection act is the tag boundary, and
  the boundary lives *in the thread* where it is auditable - anyone can open the thread and
  see exactly what is inside vs outside the tags. Omission does not vanish (a boundary is a
  choice) but it becomes located and reviewable instead of a hidden editorial cherry-pick.
  This is the cure for the current section's arbitrariness.

- **Placed on the frozen body, at finalization.** The Stop hook rewrites the live thread
  body every turn, so hand-placed tags in a live thread are clobbered next turn - the same
  frontmatter-preservation problem the ledger has. Tagging is therefore a finalization-time
  operation over the frozen body (cb:b583: the embedded body freezes when `/end` runs). It
  is a third motion of the `/decompose` pass that already runs there (route content, update
  ledger, and now tag + append excerpt - one motion, per routing-ledger's maintenance rule).

## The doc-side view: an append-only excerpt log

Each referenced proto-belief document carries the aggregated excerpts **materialized into
the .md** (not rendered live on the command line): the operator reads in GitHub and code
editors, where a CLI-derived view is invisible, and readability is the point. A copy from a
frozen thread is not the cb:b386 staleness trap - that trap is a digest of a *live* source
that must be regenerated; a quote of a frozen transcript never goes stale.

The one place cb:b386 could still bite is growth: when a *new* thread later feeds the same
matter, a from-scratch-regenerated section would silently omit it. The dodge is
**append-at-route-time, additive-only**: the same `/decompose` pass that finalizes thread N
appends thread N's tagged paragraphs into each referenced document, stamped with N's date.
Each thread is frozen when finalized, so each appended block is write-once and never
revisited; the section grows by one dated block per thread, chronologically, and nothing is
ever regenerated. There is no cache to refresh - only an append log. So the section is an
append-only, per-thread, date-stamped log of whole tagged paragraphs, and it is exactly the
cross-thread audit view the hand-picked section cannot produce.

## Freeze: the trigger is the strand's state, not archival

A document **accepts excerpt appends while its matter is unresolved**, and freezes
acceptance the moment its matter resolves (mints its belief[s], or is dropped). Each
appended block was already frozen on arrival; what resolution freezes is the *acceptance of
new appends*. "Archived" is the name for the document after that point, not a separate gate -
archival does not confer the freeze, matter-resolution does, and they fire together.

This rides on cb:b569's unit doctrine, not a looser "one focus" rule. A document is one
*separable matter*: strands whose mint-manifest rows stand on independent argument belong in
separate documents; strands that share reasoning cohabit. So the routing ledger stays
legitimately multi-row (a thread touches many topics; several may route to the same matter),
while the matter is the aggregation and freeze unit. A document that wants half-freezing -
one strand minted, an *independent* strand still open - is a cb:b569 split signal, resolved
by splitting, so the per-document key never has to freeze half a file.

## Open

- **Detection and placement mechanics.** Does `/decompose` propose the paragraph boundaries
  and refs for operator review, or place them autonomously? The tag is a selection, so a
  review step is the conservative default; the automation is unbuilt (shared with the
  routing-ledger `/decompose` open work).
- **Tag syntax in Markdown.** Raw `<p routes="...">` is HTML-in-Markdown (renders, but wraps
  the paragraph in a block element); a comment-delimited form (`<!-- routes: ... -->` fences)
  keeps the prose untouched but is not a single element. Pick one that survives the hook's
  render and stays greppable.
- **What is a valid ref target.** Proto-belief documents are excerpt sinks; code files and
  immutable beliefs are not (a belief cannot accrete, and `beliefs/` is protected). A strand
  routed only to code or to `unrouted` has no sink - does it carry a tag with no append, or
  no tag until it routes to a document?
- **Migration.** Do the existing hand-picked `## Thread excerpts` sections get backfilled
  from tags, or does the log start forward-only and the old sections stay as-is?
- **Bloat.** Whole-paragraph, no-trim, across many threads grows the section without bound;
  accepted as the cost of never trimming, but a per-matter size at which a split is
  warranted may want naming.

## Mint manifest

Candidates (unplanted) while the `/decompose` mechanics firm up. Deps are existing beliefs;
statement-provenance and transcript-format are unminted and cited as document grounding.

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | A finalized thread body is route-tagged at finalization: each paragraph carries zero-or-more `routes` refs keyed on the routed-to artifact id (never a free topic name); refs are multi-valued on one element (no overlapping tags); tagging runs on the frozen body as a motion of the same pass that routes content and updates the ledger. | cb:b572, cb:b583, cb:b569 | document:beliefs/nursery/route-tagging.md | - |
| prescription | Each referenced proto-belief document carries its route-tagged excerpts as an append-only, per-thread, date-stamped log of whole tagged paragraphs, materialized into the document and never regenerated; a document accepts appends while its matter is unresolved and freezes acceptance when the matter resolves. | cb:b386, cb:b569, cb:b572 | document:beliefs/nursery/route-tagging.md | - |
| prescription | `/decompose` gains route-tagging and excerpt-append as motions alongside routing and ledger-update, run once over the frozen body at finalization. | cb:b572, cb:b583 | document:beliefs/nursery/route-tagging.md | - |

## Thread excerpts (2026-07-04)

**Operator (the proposal):** "use the routing table and work backwards into the thread and
create XML tags that mark where in the thread there are sections that pertain to different
topics defined in the routing table ... that would then be lifted and reprinted within the
proto belief document for readability, which would allow you to audit essentially the
conversations that have occurred that relate to a specific topic."

**Operator (the cross-thread payoff):** "other threads can relate to single protobelief
documents ... that would get the same XML tag, which would then connect to the routing table
and then connect to the protobelief document ... you'd be able to see all the conversations
that have happened across all threads that relate to this topic," marked "with date, time
stamps."

**Operator (rejecting editorial trimming):** "Have found the agent's selections to be
arbitrary, with sins of omission. One man's bloated is another's sufficient." - which moved
the selection from a hidden cherry-pick to the auditable tag boundary, lifted whole.

**Operator (per-row freeze):** "less about whether the document is archived and more about
the state of the routing ledger row" - the freeze trigger is matter-resolution, not archival.

**Operator (the granularity correction):** turn granularity fails because "turns often cover
many topics that should be separately marked. More realistic is per-paragraph."

## Related

- [statement-provenance](statement-provenance.md) - the back-edge this makes concrete
  (exchange -> artifact); its open "annotate inline vs side index" question is answered here
  by inline per-paragraph tags. Co-designed, not bolted on: one mechanism, two readings.
- [routing-ledger](routing-ledger.md) - supplies the routed-to vocabulary the tags key on,
  and the `/decompose` pass this inserts a third motion into. Per-thread dispatch (coarse);
  route-tags are sub-thread location (fine); the two compose.
- [transcript-format](transcript-format.md) - the forward excerpts rule and the frozen-body
  persistence (cb:b583) this depends on; its frontmatter-preservation is the model for
  keeping tags across hook rewrites.
- [mint-manifest](mint-manifest.md) - the candidate-row convention this document's Mint
  manifest follows (cb:b567/b581).
- [seed-lifecycle](seed-lifecycle.md) - graduation and the terminal-document freeze this
  reads matter-resolution against (cb:b569 unit doctrine one level up).
