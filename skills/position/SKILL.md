---
name: position
description: Capture a settled stance as an anchored position document in the host repo's positions/ - verbatim passages, typed claims, resolver-verified anchors. Applies the ceremony gate first (cb:b496); extraction into the graph stays with /assert. Never writes beliefs/.
---

Capture a position at the moment a thread settles something concrete: stage the
epistemic artifact - the stance in its verbatim wording, decomposed into claims
with intended types and verified anchors - as a markdown file under the host
repo's `positions/`. This skill writes the position document only; turning its
claims into beliefs is `/assert`'s job, and this skill **never writes
`beliefs/`**. The worked instance is
`positions/2026-06-10-code-as-operational-substrate.md`.

## The ceremony gate (cb:b496)

Before staging anything, decide whether a position is earned. Persistence
ceremony is proportionate to stance:

- **Position document** only when the verbatim reasoning is the artifact - a
  stance whose exact wording matters and whose claims will then be extracted.
- **Observation with an obvious prescription** skips the document: route to
  `/assert` as a prescription, the gap carried as rationale prose or a small
  design-gap node underneath.
- **Spec is not stance.** Format and schema decisions land as schema/contract
  beliefs via `/assert`, not as positions (cb:b511 is the precedent - the
  ceremony rule redirected the position-format spec to direct schema capture).

If the gate says no document, say so, hand the material to `/assert`, and stop.

## Input

`$ARGUMENTS` names the stance - a quoted passage, a pointer into the thread, or
a short description of what just settled. If omitted, identify the settlement
point yourself: the passage the user confirmed or adopted. When in doubt about
which passage is the stance, ask; the wording is the artifact.

## Homing (cb:b492)

Stage the file in the repo where the claims will home: claims about
CB-the-system land in this repo's `positions/`; claims about the world or a
mission land in the owning collection's repo. Filename:
`positions/YYYY-MM-DD-<slug>.md`. Anchors resolve against that repo's root.

## Steps

1. **Quote the stance verbatim** as a blockquote. Verbatim means verbatim; the
   only permitted edit is transliterating emdashes to hyphens per repo
   formatting policy, noted in the Origin line when done.
2. **Write the header:** `# Position: <title>`, then `**Type:** position`,
   `**Class:** <e.g. design-policy>` (cb:b511), `**Status:** active`,
   `**Authored:** <date>`, `**Origin:** <thread description,
   session:<date>-<slug>>`. A `session:` slug is a dead end for a fresh reader
   (cb:b507, cb:b518) - the document itself must carry everything needed to
   understand the stance; cite the slug for provenance, never for meaning.
3. **Decompose into claims.** Each `### Claim: <one-sentence claim>` section
   carries `**DAG status:** pending` and `**Intended:** <type, kind>` - decide
   the mood by direction of fit as `/assert` does (falsified by the world:
   inference; violated or withdrawn: prescription). Order the claims as the
   argument runs: claim order is the default codepath walk order (cb:b511).
4. **Anchor claims about code.** Each such claim carries one or more
   `**Anchor:** code:<path>#<anchor>` lines in the b043 grammar. An anchored
   claim terminates in the substrate (cb:b485); a claim about code with no
   resolvable anchor is ungrounded (cb:b488).
5. **Verify every anchor through the draft-mode gate (cb:b512).** Write the
   anchors to a scratch JSON array (`code:` URI strings pass through verbatim)
   and run `mix cb.resolve --file <rows.json> --root <host repo root>`. Never
   hand-run grep against the resolver's semantics - one resolver, two faces.
   Any unresolved anchor: fix it or drop the claim's anchor before presenting
   (cb:b488). Treat a loose-anchor warning as a failure at authoring time:
   tighten the anchor or add `nth` until each resolves with exactly one match.
6. **Write the file and present it** - header, verbatim stance, claims with
   anchors, plus the resolver output showing every anchor green.
7. **Hand off extraction to `/assert`** when the user wants the claims in the
   graph. Preflight, adjudication, and import all live there.
8. **After import, flip the records:** for each extracted claim, change
   `**DAG status:** pending` to `extracted` and add a `**Belief:**` line
   rendered per the cb:b503 convention - an italic gloss (enough meaning to
   keep reading), a link to the rendered card, and a link to the JSON
   definition at its write-time-resolved line, e.g.
   `(*the gloss* - [cb:aNNN card](<card path>) | [json:<line>](<beliefs.json path>:<line>))`.
   The line number is a write-time snapshot; the id is the durable reference.
   While b503 is still settling through use, gloss + id is the floor; add the
   links when card and JSON paths resolve from the position's directory.

## Rules

- **Never write `beliefs/`.** Extraction, preflight, and import belong to
  `/assert`; this skill stages documents only.
- **Capture at settle time.** The worked trace's failure mode: rationale
  captured a day late was reachable only through an unresolvable `session:`
  slug and was nearly lost (cb:b518). Appending later is recovery, not the
  pattern - run this skill when the thread settles, not at wrap-up.
- **Don't lower the gate.** If every wart became a three-artifact pipeline,
  the pipeline would stop being read (cb:b496).
- **Anchors are verified, not asserted.** No anchor enters the file without a
  green `mix cb.resolve` run at authoring time, one match each.
- **No emdashes** anywhere in the document, including inside quotes
  (transliterate, and say so in Origin).
- **Naming:** position is the epistemic artifact - the stance and its claims;
  codepath is the render face resolved from its anchors. A position with
  anchors has a codepath for free.
