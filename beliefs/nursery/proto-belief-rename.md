---
type: concept
title: Proto-belief - naming the nursery artifact, retiring focus/seed/brief/plan
description: Covers the vocabulary settlement naming the nursery artifact the proto-belief document - the gloss becomes the name per the rename test - retiring focus, seed (for documents; threads keep it informally), brief, and plan, with no informal genre registers surviving (mood is carried only by the structural type system, and a plan is a proto-belief whose rows are prescriptions); the split-test doctrine replacing focus-as-unit; the Proto-Belief: commit trailer; and the migration spike over live surfaces. Minted cb:a569 (doctrine) and cb:a570 (residual sweep).
tags: [nursery, vocabulary, meta, structural-types]
status: active
timestamp: 2026-07-02
maturity: active
minted: cb:a569
threads: [2026-07-02-authoring-pipeline]
---

# Proto-belief - naming the nursery artifact, retiring focus/seed/brief/plan

## The matter
The nursery's document has answered to four names - focus, seed, brief, plan - none of
them settled, each pulling a different metaphor. What is this artifact called, what
happens to the other words, and what replaces the load-bearing work "focus" was doing in
the one-document-per-focus doctrine?

## The settlement

**The artifact is the proto-belief document.** The strongest evidence was already in the
repo: the nursery index glossed its own term - "focuses (proto-beliefs)" - and the
house's rename test (structural-type-rename: when renaming lets you delete the sentence
that explains the name, the name was underpowered) says the gloss should be the name. It
is the most intuitive name to someone new to the framework, which is the test of the
most descriptive one.

**No informal genre registers survive.** The operator's argument, conceded in full:
everything the house stands behind is a belief - prescriptions included - so a plan is a
proto-belief whose manifest rows are predominantly prescriptions, no stretch anywhere.
Keeping "brief" or "plan" (or "directive") as informal registers would re-encode the
descriptive/prescriptive distinction as document vocabulary - a shadow taxonomy parallel
to the one the type enum owns, the same smell as the rejected typed-nursery-documents
proposal in softer form. Mood is carried only by the structural type system, on the
manifest rows. This sharpens structural-type-rename's decision that "directive may
survive only as an informal prose register": the register is now retired too.

**Seed returns to the thread.** The thread is where ideas actually germinate; forcing
"seed" onto the downstream document is why "a seed that survives planting" strained.
Threads are not renamed - they just *are* the seed bed, informally. "Seed" leaves the
document vocabulary; the nursery name and the lifecycle verbs (plant, compost, graft)
stay - they describe transitions of anything gestating and rename to no benefit. The
proposed `seed` prop on belief nodes dies entirely: `artifact` and `evidence[].artifact`
already carry the typed `document:` back-pointer (cb:a566-a568 the proof), so no schema
change and no field named for the retired metaphor.

**No unit noun; the doctrine is a split test.** "Focus" named the document's subject,
"question" (considered, withdrawn) privileges one register and fails the others - a
practice being formalized (citation-discipline), an execution-phase document, an
observation being captured all lack a live question. The unit is stated as a test, with
the mint manifest as the boundary oracle:

> **One proto-belief document per separable matter.** Separable means the strands'
> eventual mint-manifest rows stand on independent argument; strands whose rows need
> each other's reasoning share a document. Split and merge are cheap before the gate;
> the boundary only turns costly at mint.

(Locked verbatim by the operator; carried verbatim in cb:a569's claim.)

**The commit trailer is `Proto-Belief: <slug>`,** replacing `Focus:`. The trailer chain
now narrates the pipeline itself: `Thread:` -> `Proto-Belief:` -> `Belief:`. The four
historical `Focus:` commits stay untouched, as the type-enum migration left old
vocabulary in superseded nodes.

## Migration spike (executed items marked; the rest is cb:a570)

1. **Done this round:** this document authored under its own name; the index rewritten
   (heading, doctrine paragraph, maturity-lifecycle prose); trailer key switched
   effective immediately; mint-manifest.md's fresh "directive" miss corrected;
   plans/README.md closes the shelf to new documents.
2. **cb:a570 (residual sweep, minted so the desk tracks it):** live nursery documents
   still speaking the retired registers - transcript-format's "Seeds vs directives"
   architecture section (the concept survives as plain "prescription"), seed-lifecycle
   and seed-absorption body prose, per-belief-files, contract-predicate-demotion,
   atomicity-generalization, assertions-rename, nursery-architecture,
   thread-repo-binding, seed-recency, statement-provenance, and the three 2026-07-02
   documents' own focus/brief prose; docs/operations.md's live-register directive
   section; docs/composable-beliefs-thesis.md's "graph of assertions"; glossary old->new
   entries for focus/seed/brief/plan -> proto-belief document.
3. **Untouched forever:** the historical record (chronicles, threads, plans/ shelves,
   superseded nodes, quotes of pre-rename claims) and the sanctioned survivals (the
   belief.ex compat shim pending cb:a562; structural-type-rename itself, which is about
   the old vocabulary).
4. **Gated on Q7 (archive shelf):** triage of still-live plans into proto-belief
   documents; physical archiving of the closed plans/ shelves with a `cb.repoint` pass,
   under the operator's invisibility requirement (archived architecture must not sit in
   the working hierarchy confusing new agents). The `plan:` artifact scheme in cb:c067
   is naming residue for a future enum pass; scheme supersessions batch one change at a
   time and this one can lag.

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | The nursery artifact is the proto-belief document; focus, seed (for documents), brief, and plan are retired with no informal registers surviving - mood is carried only by the structural type system; one proto-belief document per separable matter (split test verbatim); the commit trailer is Proto-Belief:. | cb:a475 | document:beliefs/nursery/proto-belief-rename.md | cb:a569 |
| prescription (action-item) | Execute the residual vocabulary sweep (spike item 2) across live nursery documents and the missed docs surfaces; historical record untouched. | cb:a569 | document:beliefs/nursery/proto-belief-rename.md | cb:a570 |

## Thread excerpts (what grounds the settlement)

**User (the name):** "I am leaning towards defining this artifact ... proto-belief. That
is most likely to make intuitive sense to someone new to the framework, which points
towards it being the most intuitive name and the most descriptive."

**User (seed to the thread):** "seed actually is more representative of the thread. That
is truly the seed of ideas ... I don't think we should call threads seeds. I just think
they are, and that may remove seed from being an applicable term."

**User (no registers):** "To say it's stretched is to go against the title of the
framework, Composable Beliefs - everything is a belief ... a prescriptive proto belief is
in fact a belief ... we're introducing a new etymology that reflects the difference
between descriptive and prescriptive ... but we're inventing new words for it called plan
and brief. This seems to be a code smell to me."

**User (the unit):** "what happens when there is no question?"

## Related
- [structural-type-rename](structural-type-rename.md) - the precedent epoch, the rename
  test, and the informal-register sanction this sharpens away.
- [seed-lifecycle](seed-lifecycle.md) - the collapse this completes: one artifact, one
  name, mood in the type system.
- [mint-manifest](mint-manifest.md) - supplies the boundary oracle the split test runs on.
- [commit-provenance-floor](commit-provenance-floor.md) - carries the trailer vocabulary
  this settles.
