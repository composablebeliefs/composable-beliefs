---
type: thread
title: 2026-06-25 - belief-by-belief audit (starting cb:a098)
description: Covers the node-by-node belief audit opened on cb:a098 - its split into a directive plus inference, and the schema questions raised: generalizing atomicity past primitives, a negative-case field, mood living in kind. Use when revisiting a098 or those decisions.
tags: [cb, schema, belief-audit, thread]
status: active
timestamp: 2026-06-25
artifact: session:2026-06-25-belief-audit
model: claude-opus-4-8[1m]
effort: max
---

# 2026-06-25 - belief-by-belief audit (starting cb:a098)

> **Broken out into the nursery (2026-06-25).** Live work moved to per-focus docs under
> `nursery/`; this thread is kept as the originating record. Produced:
> [assertions-rename](../nursery/assertions-rename.md),
> [negative-case-field](../nursery/negative-case-field.md),
> [atomicity-generalization](../nursery/atomicity-generalization.md),
> [nursery-architecture](../nursery/nursery-architecture.md), and
> [citation-discipline](../nursery/citation-discipline.md) (minted `agent-behavior:a411`).

## Where we are

- **Object of study:** cb:a098 (directive, kind `convention`, active, no deps, no
  supersession links).
- **Settled this far:**
  - a098 is schema-*legal* (kind -> directive per c057; grounded via the `user:`
    stipulation per c059) but mis-authored: it staples two claims, which the verifiers
    never catch (a475: atomicity is write-flow judgment, not a verifier check).
  - The is/ought boundary is already mechanized in `kind` (c057), so "directives must
    say should" is rejected - it resurrects the deleted `implication` prose marker.
  - The single-sentence norm already exists, but only for primitives (a475, a114); the
    open move is to generalize it to all four structural types.
- **Proposed re-authoring of a098** (supersede with an edit-pair):
  - **D** (directive, `convention`): "Author a belief as the extractable behavioral
    pattern; record each evidencing incident as an evidence entry, not as its own claim."
  - **I** (inference, `deps: [D]`): "Because incidents are recorded as evidence rather
    than claims, repeated incidents strengthen a single belief instead of spawning new
    ones." This is the real inference - it was hiding in a098's evidence prose.
- **Open threads:**
  1. Supersede a098, or accept-with-disclaimer as a pre-discipline legacy node?
  2. `negative-case` as a new field - leaning *no*: the negative channel already exists
     as `invariants` (contract-scoped); a free-prose field fails the c047 test ("a field
     exists so a predicate fires on it"). Decide whether invariants-style negatives
     should extend to non-contract beliefs, and if so what reads them.
  3. Generalize a475 (atomicity) from `primitive` to all belief types - this is what
     licenses the a098 split.

## Thread

### 2026-06-25 - Mark (opening: cb:a098)

I would like to dig into the beliefs themselves. I think there are issues that can only
really be surfaced and explored when taking them one by one.

Let's look at cb:a098:

> "Assertions express extractable behavioral patterns as beliefs, not individual
> occurrences. Incidents that evidence the pattern belong in the evidence array, not as
> the claim itself."

"assertions" was the original term for beliefs, now deprecated. To me, this could be
improved to "beliefs express extractable behavioral patterns." Do you see an issue with
removing "assertions" here?

The "not individual occurrences" becomes implicit - OR we consider a new prop which
represents "negative-case" - which in this case, would be "not individual occurrences".

"Incidents that evidence the pattern belong in the evidence array, not as the claim
itself." - this should arguably be its own claim, and "not as the claim itself" as a
negative-case prop (if we adopt that).

Not as to type - currently this is a directive of kind "convention" (i think its kind at
least). I would argue that the is/ought boundary is also is/should, which hews closer to
the wording used. You could almost make a rule that directives MUST include should in a
claim. I would also argue that ALL beliefs should be expressable as a single sentence -
if more qualifying is needed, you are likely dealing with a compound, or the schema is
undeveloped (ie. the need for "negative-case.")

So, "beliefs express extractable behavioral patterns" could really be seen as two
potential belief types:

1. "beliefs express extractable behavioral patterns." - an inference, with evidence
2. "beliefs SHOULD express extractable behavioral patterns." - a directive

Let's break down the evidence:

> "2026-03-22 The user reframed the initial belief: state the behavior that can be
> extrapolated from an incident, so the recounted experience becomes evidence in an array
> rather than the claim itself. The claim captures the pattern; the evidence captures
> each incident. Multiple incidents strengthen the same belief rather than creating new
> ones. (user:2026-03-22)"

First, this seems less "evidence" and more a history of why some original belief, which
isn't even attributed to an id, was superseded. Also, what is this "evidence" exactly?
Some verbatim quote of the user, or...? Where is the thread? Not sure this deserves to be
evidence.

"state the behavior that can be extrapolated from an incident, so the recounted
experience becomes evidence in an array rather than the claim itself." - this is a
"should" for sure, and i believe as a result should exist as a directive.

"The claim captures the pattern; the evidence captures each incident. Multiple incidents
strengthen the same belief rather than creating new ones." - this seems to me to more be
a claim of type "inference", potentially holding all of the potential/discussed nodes
here as deps.

Thoughts?

### 2026-06-25 - Claude

Two facts from the live schema move the board before going point by point:

**The is/ought boundary is already mechanized - in `kind`, not in claim wording.** c057
(kind-binds-mood) maps `convention` to `allowed_types: [directive]`, full stop. So a098
is *structurally* a prescription already; nothing in the claim text carries that load.
This kills the "directives MUST include should" idea on its own terms.

**The single-sentence norm already exists - but only for primitives.** a475 ("Primitive
atomicity doctrine: a primitive is one atomic statement... A primitive whose claim
conjoins separable assertions is a mis-authored compound and is split at authoring time.
Atomicity is judgment, enforced in the write flow rather than by a verifier check") and
a114 ("the claim field is a one-liner"). Your instinct is house doctrine - it just hasn't
been generalized off `primitive`. And a475's last clause is the punchline for a098:
atomicity is *not* verifier-checked, so a directive that staples two claims sails
through. a098 is schema-legal (kind -> directive per c057, grounded via the `user:`
stipulation per c059) and still mis-authored. The verifiers were never going to catch it.

**1. Removing "assertions" - yes, but it's a supersession, and don't stop at the noun.**
Mechanically you don't edit a098; you mint a successor and link `superseded_by`. But
"beliefs express extractable behavioral patterns" swaps the dead term and leaves the mood
ambiguous - "express" reads as either *is* or *ought*. If it's a directive, author it in
prescriptive voice ("Author beliefs as..."). Side note while we're killing the term: it
survives twice in this node - the claim *and* `subjects[0].type: "assertions"`.

**2. `negative-case` as a field - I'd push back, and I think you've half-reinvented
something you already have.** The framework's test for a field is c047: a field exists so
a *predicate* fires on it. `negative-case` as free prose with no check is decoration that
pretends to be structure - and it cuts directly against the v2 purge of
confidence/source/implication. More to the point: CB deliberately *externalizes* contrast
into edges (conflict scope c055, supersession) rather than internalizing it into a node.
And where a "must NOT" is genuinely load-bearing and checkable, the slot already exists -
it's called `invariants`, and it's the negative-case channel for contract-grade
directives (c026's "primitives and compounds cannot carry contracts" is exactly a
negative case as an invariant). So the real question isn't "add negative-case" - it's "do
you want invariants-style negatives on *non-contract* beliefs, and what reads them?" For
a098 specifically you need neither: "not individual occurrences" dissolves the moment you
state the *positive* home (the evidence array). State where incidents go and the negative
is implied.

**3. Splitting the second sentence - agree it's overloaded, but the clean form is one
directive, not two.** The two sentences are the same coin: "not as the claim" (negative)
and "in the evidence array" (positive). Authored well that's a single prescription:
*"Author a belief as the extractable pattern; record each incident as an evidence entry,
not as a new claim."* One claim, one direction of fit. The genuine *second* node is hiding
elsewhere - see 5.

**4. "Directives MUST contain should" - no; the single-sentence norm - yes, generalize
a475.**

- The "should" rule re-introduces exactly the antipattern v2 deleted: marking mood with a
  prose token (`implication`) instead of with structure (`type` + `kind`). c057 already
  enforces mood off `kind` deterministically; a claim restating it in words is redundant
  and unenforceable without NLP. It also breaks on imperative directives ("Author X as
  Y"), which are prescriptions containing no "should." Keep mood in `kind`; treat
  prescriptive *reading* as a style guideline, not a checkable rule.
- The single-sentence norm is the good half. Reframe it as "one belief = one falsifiable
  proposition (normally one sentence); if it needs more qualifying, it's a compound or a
  schema gap." That's already a475 minus the word "primitive." The move is to mint a
  successor to a475 that generalizes atomicity to all four types - which is precisely what
  licenses splitting a098. Multi-sentence claims are a *lint* you could actually flag
  (count sentences in `claim`), even though the judgment call stays human per a475.

**5. inference + directive - the directive is right; the "inference" arm is not an
inference.** "Beliefs express extractable behavioral patterns" isn't "a descriptive
conclusion licensed to exceed its deps" (c051) - it has no deps under it and asserts
nothing beyond the directive. It's either a `definition` (dual-mood per c057) or just the
directive in indicative voice, i.e. a restatement, i.e. noise. Don't mint it. **The real
inference is the sentence buried in your evidence**: *"Multiple incidents strengthen the
same belief rather than creating new ones."* That one *does* exceed its dep - it's a
falsifiable structural consequence of the authoring rule (author patterns-with-evidence
=> N incidents reinforce one node instead of spawning N). So the honest decomposition is
two nodes, but not your two:

- **D** (directive, kind `convention`): "Author a belief as the extractable behavioral
  pattern; record each evidencing incident as an evidence entry, not as its own claim."
  Grounds: `user:2026-03-22`.
- **I** (inference): "Because incidents are recorded as evidence rather than claims,
  repeated incidents strengthen a single belief instead of spawning new ones."
  `deps: [D]`.

**6. The evidence - your critique is right and sharper than you put it.** That entry is
three things welded together: (a) a *reframing narrative* ("The user reframed the initial
belief...") - which is a supersession rationale, except a098 supersedes nothing and is
superseded by nothing, so the prose is standing in for an edit-pair the graph never
recorded; (b) the *should*, which is D's content; (c) the *inference*, which is I. And the
provenance is sub-standard by the house's current bar: `user:2026-03-22` is a bare
datestamp - no thread, no verbatim, a paraphrase. Compare a494/a553, which carry
`session:` slugs and retro-paired verbatim transcripts per the a507 protocol. a098 simply
predates that discipline.

Which is the meta-finding worth naming: **a098 is a pre-everything node.** Created
2026-03-22 - before the four-type schema (c051, 2026-06-10), before atomicity doctrine
(a475), before provenance retro-pairing (a507). It's first in the file, and going
front-to-back you'll keep hitting this stratum. The exercise is less "is a098 wrong" (it's
legal) and more "a098 is a core sample of the era before the disciplines that would now
reject it."

## Open / next

- Decide open thread 1 (supersede a098 vs accept-with-disclaimer).
- Decide open thread 2 (negative-case field vs extend invariants vs neither).
- Decide open thread 3 (generalize a475 atomicity to all types).
- If superseding: draft D and I as import files and run `mix cb.preflight` to see whether
  preflight's supportive-match flags them against the rest of the graph.
