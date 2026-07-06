---
type: concept
title: Route-tagging - per-paragraph topic tags that aggregate thread excerpts per focus
description: Covers marking each thread paragraph with the artifact it feeds via per-paragraph, multi-ref route tags placed on the frozen body at finalization, so a focus's cross-thread discussion aggregates into an append-only, date-stamped excerpt log in its proto-belief document. Formalizes the scattershot hand-picked "Thread excerpts" sections into a located, auditable, cross-thread audit trail. The concrete form of statement-provenance's back-edge, keyed on the routing-ledger's routed-to vocabulary; a third motion of /route (renamed from /decompose), folded into /end once built. Revised 2026-07-04 against a fresh-context audit. Unminted; rows staged.
tags: [nursery, threads, provenance, linkage, workflow]
status: active
timestamp: 2026-07-04
maturity: active
threads: [2026-07-04-route-tagging, 2026-07-04-council-design]
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
<routes ref="route-tagging statement-provenance">
... one paragraph feeding both matters ...
</routes>
```

Four properties, each settled against a rejected alternative:

- **Keyed on a canonical artifact id; the routed-to sink is the aggregating ref.** The ref is
  a canonical artifact id (a proto-belief document name, or a belief/code id), never a
  free-text topic phrase, so two threads about the same matter *necessarily* emit the same
  string and the cross-thread join is exact; a free-text name would drift (`turn-separation`
  vs `end-turn-sep`) and the join would silently fail. The anti-drift property comes from
  using canonical ids, **not** from the routing-ledger column specifically (the audit found
  the first retrofit tagging ids outside that column - `cb:b518`, `transcript-format` - all
  still canonical, so the join survived). The residual gap the audit exposed is
  *artifact-choice*: a paragraph can feed a sink document and an incidental belief at once, so
  the rule is - **the routed-to sink document is the aggregating ref** (it accretes an excerpt
  log); incidental belief/code ids are optional **back-links** that do not aggregate and need
  no sink. That keeps two taggers from fragmenting the join by picking different artifacts,
  and it answers the valid-ref-target question below.

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
  is a third motion of the `/route` pass (renamed from `/decompose`) that already runs there
  (route content, update ledger, and now tag + append excerpt - one motion, per
  routing-ledger's maintenance rule). Once built, `/route` runs as a step *inside* `/end`,
  tagging the body `/end` just embedded.

## The doc-side view: an append-only excerpt log

Each referenced proto-belief document carries the aggregated excerpts **materialized into
the .md** (not rendered live on the command line): the operator reads in GitHub and code
editors, where a CLI-derived view is invisible, and readability is the point. This is a
**readability-versus-freshness tradeoff, not a cb:b386-clean design** (the earlier draft
overstated it). An individual excerpt block is safe - it quotes a *frozen* thread, so it
never goes stale the way a digest of a live source does. What is not automatically safe is
the log's *completeness*.

Two residual cb:b386 exposures remain, both procedural: (1) a **forgotten append** - if
thread N feeds the matter but its `/route` pass is skipped, the log silently omits N and
reads as complete; and (2) an **un-propagated correction** - tags are a mutable overlay on a
frozen body, so a later tag fix does not reach the write-once log, and log != current-tags.
The **append-at-route-time, additive-only** discipline (the `/route` pass that finalizes
thread N appends N's tagged paragraphs, stamped with N's date, write-once) narrows the
failure from *wrong content* to *missing content*, but it does not remove the procedural
dependency.

The structural backstop is a verifier, **`cb.verify.route_tags`**, that re-derives each
sink's log from the current tags and fails on divergence - converting the guarantee from
procedural to structural (the framework's own "verify structurally, don't rely on
remembering" move). It closes both exposures for tags that exist. It does *not* close **tag
coverage** - whether every paragraph that feeds a matter was tagged is editorial and has no
mechanical oracle, so a forgotten *tag* reproduces the incomplete-log harm a forgotten
*append* did. A ledger cross-check (every thread whose routing ledger routes to sink M
contributes a dated block or declares none) lifts coverage-checking to row granularity;
paragraph-level omission stays a judgment. So the section is an append-only, per-thread,
date-stamped cross-thread view - backed by a verifier for what can be mechanized, and honest
about the omission axis that cannot.

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

**Backfilling a frozen document is a bounded migration, not a standing exception.** A
graduated/frozen matter accepts no new appends - but a one-time, operator-authorized
*migration* of a pre-spec artifact (bringing a founding example up to the spec, as the
end-skill-redesign backfill did) is a normal migration, and is distinct from a recurring
"any frozen doc may be backfilled once" carve-out, which is rejected. The migration is
labelled as such on the document; absent that label, a frozen matter's log never changes.

## Audit dispositions (2026-07-04)

A fresh-context audit reviewed this spec and its first retrofit (the route-tagging round-trip,
graph unchanged). The round was dev-dev and is cited by commit, not threaded (per
council-mechanism's tiering rule); its findings are dispositioned into this document above:

- **Rejected: "keyed on the routed-to column, cannot drift."** The retrofit used refs outside
  that column (`cb:b518`, `transcript-format`, `cb:b573`), so the claim was false as written.
  Reworded to *canonical artifact id* + the sink-is-aggregating-ref / incidental-ids-are-
  back-links rule (F1), which also resolves the valid-ref-target open item.
- **Rejected: "no cache to refresh - a cb:b386-clean design."** Reframed as a
  readability-versus-freshness tradeoff with two residual procedural exposures (forgotten
  append, un-propagated correction), backed by the new `cb.verify.route_tags` verifier; tag
  coverage stays editorial (F2).
- **Rejected: `<p routes="...">` syntax.** The spec documented a form the retrofit abandoned;
  `<p>` is HTML-allowlisted (renders visibly) and cannot wrap multi-block regions. Corrected
  to `<routes ref="...">` throughout (F4).
- **Accepted: bounded-migration framing for the freeze-backfill** (F6), and the **bloat
  bound** (F7). The **cb:b583 overstatement** (F3) is spun off to the `/end` lineage.

## Open

- **Detection and placement mechanics.** Does `/route` propose the paragraph boundaries
  and refs for operator review, or place them autonomously? The tag is a selection, so a
  review step is the conservative default; the automation is unbuilt (shared with the
  routing-ledger `/route` open work).
- **Tag syntax in Markdown - resolved to `<routes ref="...">`.** The unknown element is
  stripped in GitHub's rendered view (clean prose) and stays greppable in source. `<p
  routes="...">` was **rejected**: `<p>` is HTML-allowlisted so it is *not* stripped (it
  renders as a visible paragraph wrapper) and it cannot legally wrap the multi-block regions
  the tags span. A comment-delimited form (`<!-- routes: ... -->` fences) stays open as an
  alternative that keeps the prose untouched but is not a single element.
- **Valid ref target - resolved (F1).** The routed-to sink document is the aggregating ref
  and accretes the log; immutable beliefs and code files are optional back-links that do not
  aggregate (a belief cannot accrete, and `beliefs/` is protected). A strand routed only to
  code or to `unrouted` carries a back-link with no append, or no tag until it routes to a
  document.
- **Migration.** Do the existing hand-picked `## Thread excerpts` sections get backfilled
  from tags, or does the log start forward-only and the old sections stay as-is?
- **Bloat - bound wanted (F7).** Whole-paragraph, no-trim, across many threads grows the
  section without bound; the audit made it concrete (the retrofit added ~150 lines to a
  233-line doc). Name a per-matter size threshold at which the log collapses to the CLI
  live-rendered view (the option declined for readability - so the threshold is exactly where
  in-place readability stops being viable), treated as a signal rather than a silent cap.
- **`/end` fold and the `cb:b583` spin-off (F3).** The audit surfaced that `cb:b583`'s own
  claim prescribes "only the `/end` turn is omitted," which overstates whenever a session
  continues past `/end` - a latent defect in the shipped `/end` protocol, not route-tagging's.
  It is spun off to the `/end` lineage as a supersession, noted here because the audit raised
  it.

## Mint manifest

Candidates (unplanted) while the `/route` mechanics firm up. Deps are existing beliefs;
statement-provenance and transcript-format are unminted and cited as document grounding.

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | A finalized thread body is route-tagged at finalization: each paragraph carries zero-or-more `<routes ref="...">` refs, each a canonical artifact id (never a free topic name); refs are multi-valued on one element (no overlapping tags); the routed-to sink document is the aggregating ref and incidental belief/code ids are non-aggregating back-links; tagging runs on the frozen body as a motion of the same pass that routes content and updates the ledger. | cb:b572, cb:b583, cb:b569 | document:beliefs/nursery/route-tagging.md | cb:b588 |
| prescription | Each referenced proto-belief document carries its route-tagged excerpts as an append-only, per-thread, date-stamped log of whole tagged paragraphs, materialized into the document and never regenerated; a document accepts appends while its matter is unresolved and freezes acceptance when the matter resolves. This is a readability-versus-freshness tradeoff, not cb:b386-clean; its completeness is backed structurally by `cb.verify.route_tags`, not by procedural discipline. | cb:b386, cb:b569, cb:b572 | document:beliefs/nursery/route-tagging.md | cb:b589 |
| prescription | `cb.verify.route_tags` re-derives each sink's excerpt log from the current route tags and fails on divergence, converting the log's freshness guarantee from procedural to structural; it also enforces that every ref resolves to a real artifact and every tagged sink carries its log. Tag *coverage* (that every feeding paragraph was tagged) stays editorial and is lifted only to row granularity by a routing-ledger cross-check. | cb:b386 | document:beliefs/nursery/route-tagging.md | cb:b590 |
| prescription | `/route` (renamed from `/decompose`) gains route-tagging and excerpt-append as motions alongside routing and ledger-update, run once over the frozen body at finalization, and folded into `/end` as a finalization step once built. | cb:b572, cb:b583 | document:beliefs/nursery/route-tagging.md | - |

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
  and the `/route` pass (renamed from `/decompose`) this inserts a third motion into.
  Per-thread dispatch (coarse); route-tags are sub-thread location (fine); the two compose.
- [council-mechanism](council-mechanism.md) - the review mechanism whose founding worked
  example was the audit of this spec; the source of the tiering rule under which that audit
  round is cited by commit rather than threaded.
- [transcript-format](transcript-format.md) - the forward excerpts rule and the frozen-body
  persistence (cb:b583) this depends on; its frontmatter-preservation is the model for
  keeping tags across hook rewrites.
- [mint-manifest](mint-manifest.md) - the candidate-row convention this document's Mint
  manifest follows (cb:b567/b581).
- [seed-lifecycle](seed-lifecycle.md) - graduation and the terminal-document freeze this
  reads matter-resolution against (cb:b569 unit doctrine one level up).
