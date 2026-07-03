---
type: concept
title: Rename the "Mint manifest" section to plainer, type-accurate vocabulary
description: Covers renaming the ## Mint manifest section - the typed table of candidate beliefs a maturing proto-belief document grows before it plants (cb:b567, re-issued cb:b581) - to a plainer name such as "belief candidates". Two grounds: "mint manifest" is insider jargon (the default-read-surface hygiene vocabulary-read-surface argues for), and "mint" misleadingly evokes prescriptions/minting when the rows carry all four belief types. Records the blast radius (a wording sweep across seven living documents plus the cb:b581 convention, not a parser change, since /assert does not read the heading by name) and leaves the naming call open. Spun off from the end-skill-redesign vocabulary exchange.
tags: [nursery, vocabulary, workflow, read-surface]
status: active
timestamp: 2026-07-03
maturity: active
threads: [2026-07-02-fold-chronicle-into-threads]
---

# Rename the "Mint manifest" section to plainer, type-accurate vocabulary

## The matter

A maturing proto-belief document grows a `## Mint manifest` section: a table of the
candidate beliefs it will plant, one typed row each (type, draft claim, deps, grounding,
minted id). The convention is cb:b567, re-issued as cb:b581, and defined in
[mint-manifest](mint-manifest.md). The name "Mint manifest" is under question on two
grounds:

1. **It is insider jargon.** "Mint" and "manifest" are both house terms; a reader meeting
   the section cold does not learn from the name that it lists the beliefs the document is
   about to create. This is the default-read-surface hygiene
   [vocabulary-read-surface](vocabulary-read-surface.md) argues for - the vocabulary an
   agent ingests by default should teach, not require translation.
2. **"Mint" misleads about scope.** The word evokes minting and prescriptions, and every
   row in every mint manifest authored so far has in fact been a prescription - so the name
   quietly reinforces a wrong belief that the section is prescription-only. It is not: the
   Type column carries all four belief types (attestation, aggregation, inference,
   prescription), and a document extracting facts from a source would fill it with
   attestation and aggregation rows. The rows are *belief candidates* of any type.

The operator's proposed replacement is **"belief candidates"**, which states plainly what
the rows are and carries no type bias. The final token is the open call below.

## Where things stand

**What the section is (unchanged by any rename).** The mint manifest is the bridge from a
proto-belief document's informal prose to the typed, immutable graph nodes: late, in-place
typed decomposition, listed before the expensive mint so the document says exactly what it
will plant, and each row records its belief id once planted (cb:b581, mint-manifest.md).
The rename touches the *name* of the section, not its mechanism.

**The blast radius is a wording sweep, not a parser change.** Confirmed by inspection:

- **The `/assert` consumer does not read the heading by name.** `/assert` "consumes
  manifest rows at mint" as a documented convention (mint-manifest.md), but the skill
  itself references mint-time extraction generically and carries no parse of the literal
  string "## Mint manifest". So no code or skill breaks on a rename - the coupling is
  convention-level.
- **Seven living proto-belief documents carry the `## Mint manifest` heading:**
  mint-manifest.md, cb-id-b-migration.md, proto-belief-rename.md, commit-provenance-floor.md,
  end-skill-redesign.md, prescription-self-tracking.md, and routing-ledger.md. These are the
  cb:b570-style living-surface sweep: editable, no immutability constraint, rewritten in one
  pass - with the standard carve-outs for verbatim quotes and thread history.
- **The convention itself is cb:b581** (re-issued from cb:b567). Its claim wording, the
  `mint-manifest.md` filename and title, and the nursery index gloss all name the section.
  Changing the belief means a supersession; changing the document means a rename and a
  `cb.repoint` of any `document:` citations.

**The cost, in the terms vocabulary-read-surface already priced.** This is a wording
change, and the supersession-cost findings there apply: re-issuing a central node is
affordable but the mirrors leak (index gloss, glossary, document descriptions), and the
living-doc headings are the cheap part (a sweep). The one judgment this rename forces that a
pure-cosmetic change does not: whether the current name *actively misleads* (the "mint"→
prescription-only implication) rather than merely dating itself - which, per
vocabulary-read-surface's own carve-out, is the condition under which re-issuing for wording
is substance, not cosmetics. If it misleads, superseding cb:b581 is warranted; if it only
reads as jargon, render-time annotation or a document-only rename may suffice.

## Open

- **The name.** "belief candidates" (operator's lead) versus alternatives: "candidate
  beliefs", "plant list", "graduation manifest", "candidates". The vocabulary-read-surface
  scope lesson applies - prefer a phrase that reads plainly and never a bare common word.
- **Supersede cb:b581, or annotate, or document-rename only.** Turns on the misleads-vs-
  dates question above. If the graph-refounding path lands first, the re-mint speaks the new
  vocabulary by construction and no supersession is spent - so this may be one to hold for
  the refounding rather than pay a supersession now.
- **The convention document's own name.** Whether `mint-manifest.md` (and its cb:b581
  title) rename in lockstep, with a `cb.repoint` for citations, or the file keeps its
  historical name while the section heading changes.
- **Scope.** Is this one instance of a broader "de-jargon the nursery vocabulary" matter
  (mint, plant, compost, graft, seed) or standalone? If broader, it may want to compose with
  vocabulary-read-surface rather than stand alone.

## Mint manifest

One candidate prescription; unplanted, and the name token is the open variable above. Held
if graph-refounding lands first (the re-mint would carry the new name for free).

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | The section a maturing proto-belief document grows to enumerate the beliefs it will plant is named "belief candidates" (pending the naming call), a typed table with one row per candidate carrying all four belief types, not only prescriptions; the name states what the rows are and carries no type bias. Supersedes cb:b581's "mint manifest" naming. | cb:b569 | document:beliefs/nursery/mint-manifest-rename.md | - |

## Thread excerpts (what grounds this)

**Operator (raising it, in the end-skill-redesign review):** "Why is there a mint manifest
section ... can it be named something else? Why is there a markdown table of candidate
beliefs I don't understand the purpose? ... why isn't it called a prescription list or
something? Also, why is it limited to prescriptions? Seems like a better title would be
belief candidates."

**Clarification recorded in end-skill-redesign.md:** the manifest is not limited to
prescriptions - the Type column carries all four belief types; the `/end` redesign's rows
are all prescriptions only because a redesign mints rules. That clarification is what
surfaces the naming defect: the name reinforces the very prescription-only reading the
convention rejects.

## Related

- [mint-manifest](mint-manifest.md) - the convention this renames (cb:b567, re-issued
  cb:b581); the mechanism it defines is unchanged.
- [vocabulary-read-surface](vocabulary-read-surface.md) - the default-read-surface hygiene
  principle this applies, and the supersession-vs-annotation cost framing the naming call
  inherits.
- [graph-refounding](graph-refounding.md) - if it lands first, the re-mint carries the new
  name for free, so this rename may be one to hold rather than pay a supersession now.
- [end-skill-redesign](end-skill-redesign.md) - the deliberation this spun off from; its
  Mint manifest section is one of the seven headings a rename would sweep.
