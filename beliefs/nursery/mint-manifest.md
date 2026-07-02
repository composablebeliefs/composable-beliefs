---
type: concept
title: The mint manifest - typed decomposition inside the brief, not typed documents
description: Covers the mint manifest - a late-stage section in a maturing focus brief enumerating the candidate beliefs it will plant as typed rows (structural type, draft claim, deps, grounding artifact, minted id) - adopted as the surviving weak form of the rejected typed-nursery-documents proposal; action items in briefs are prescription rows, resolving the focus/plan drift in composition with seed-lifecycle's collapse. Minted cb:a567.
tags: [nursery, cb, schema, workflow, structural-types]
status: active
timestamp: 2026-07-02
maturity: active
minted: cb:a567
threads: [2026-07-02-authoring-pipeline]
---

# The mint manifest - typed decomposition inside the brief, not typed documents

## The focus
How does a focus brief's informal prose become the typed, immutable nodes the graph
demands? The originating proposal: type the *nursery documents themselves* by eventual
DAG type - mutable attestation-seed, aggregation-seed, inference-seed, and
prescription-seed docs as a staging layer between briefs and the graph, so ideas move
from the informal to the formal through explicitly typed workspaces. This focus records
why that loses, and what survives it.

## Rejected: typed nursery documents

Four grounds, each drawn from doctrine already in force:

1. **It inverts the discovery order.** The structural type is an *output* of
   deliberation, not an input. The aggregation/inference boundary in particular is
   cb:c058's semantic judgment - whether the claim's scope escapes its deps - which
   [structural-type-rename](structural-type-rename.md) calls the whole point of the
   framework. Filing a mutable doc under a type forces classification at the moment of
   least information; the nursery's value is deferring expensive commitments to the gate.
2. **It fragments the focus.** One focus routinely mints several beliefs of several types
   (structural-type-rename minted contract rewrites plus prescriptions cb:a561/a562; the
   a098 audit minted a prescription plus an inference). Typed docs shatter one argument
   across three or four files - the same mistake [seed-lifecycle](seed-lifecycle.md)
   rejected on the phase axis, transposed to the type axis, against focus-as-unit.
3. **It builds the shadow graph.** The nursery validates format, never relations. Typed
   proto-beliefs want typed proto-relations (a proto-inference wants proto-deps, a
   proto-aggregation wants proto-attestations) - a second, mutable DAG that can drift
   against the real one.
4. **Half the types need no gestation.** An attestation is mechanical extraction from an
   artifact (`/assert` does it at mint time); an aggregation is bounded by its inputs.
   Only inferences and prescriptions genuinely need a workshop, so the typed layer would
   be ceremony for two of four types.

## Adopted: the manifest section

What survives is **progressive formalization as phases of one document**: when a focus
approaches the mint gate, its brief grows a `## Mint manifest` section - a table of the
candidate beliefs the focus will plant, one row each:

| Column | Meaning |
|---|---|
| Type | attestation / aggregation / inference / prescription |
| Draft claim | the proposition as currently worded |
| Deps | known dependency ids |
| Grounding | the artifact URI (for prescriptions, typically `document:` this brief per cb:c059) |
| Minted | `-` while a candidate; the belief id once planted |

The type commitment happens **late** (at the gate, when the deliberation that justifies
it is done) and **in place** (inside the brief, next to the argument). `/assert` consumes
manifest rows at mint; a row flips its Minted cell when it plants. The practice existed
informally before it had a name - structural-type-rename's "Decisions" plus its ordered
spike functioned as a manifest and drove same-day execution - so this focus names and
standardizes it rather than inventing it.

**Partial planting.** A focus may mint some rows and stay live: maturity stays `active`,
minted rows carry their ids, open strands keep deliberating. This sidesteps the contested
graduation-timing question ([seed-lifecycle](seed-lifecycle.md) vs
[seed-absorption](seed-absorption.md)) - nothing about the manifest presumes either
terminal lifecycle.

**Action items are prescription rows.** The observed drift of briefs growing loose
"action item" sections that do plan-work in an undefined register resolves here: an
action item is a prescription row in the manifest - loose while the focus is live, minted
as a real prescription (and `/materialize`d) when firm. The graph remains the only todo
tracker (the desk is `mix bs list unlinked tag:lifecycle:discrete`); no mutable
prescription-feed document competes with it. This composes with seed-lifecycle's
collapse: the brief is one artifact whatever phase its focus is in, and type appears
late, on rows, never on documents.

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | A focus brief approaching the mint gate carries a mint manifest of typed candidate-belief rows; type commitment happens late, on rows inside the brief, never early as typed nursery documents; action items are prescription rows. | cb:a475 | document:beliefs/nursery/mint-manifest.md | cb:a567 |

## Thread excerpts (what grounds the decision)

**User (the proposal):** "what if you were to aspirationally move into types of mutable
documents within the nursery that reflect eventual solid types within the dag ... anything
that is an action item ... would become a mutable prescription feed document. Anything
that is an argument ... moving towards some sort of a conclusion would be an aggregation.
That aggregation, once settled as a mutable document, could be decomposed into
attestations ... we would be moving from the informal to the formal."

**Claude (the counter and the keep):** "Typing documents by DAG type is the wrong grain:
the type should be committed late, inside the focus doc, as a mint-manifest section - not
early, as four new document categories ... That is exactly the typed decomposition you
want, committed at the right time (late) in the right place (inside the focus, where the
argument that justifies the typing lives)."

**User (concurrence, next turn):** "Excellent! Agree on all points."

## Related
- [seed-lifecycle](seed-lifecycle.md) - the collapse this composes with; its 2026-07-02
  block records how the typed-documents rejection strengthens "status, not kind".
- [structural-type-rename](structural-type-rename.md) - supplies the type vocabulary the
  manifest rows carry, and the informal precedent for the section.
- [routing-ledger](routing-ledger.md) - the same session's other adopted practice; the
  ledger dispatches threads into briefs, the manifest dispatches briefs into the graph.
- [atomicity-generalization](atomicity-generalization.md) - one row, one falsifiable
  proposition; the manifest is where mis-bundled claims get split before they cost a
  supersession.
