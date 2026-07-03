---
type: concept
title: Prescriptions self-track discharge; todos, materialization, and the desk term retire
description: Covers folding the todo layer into prescriptions - discrete prescriptions carry their own open/discharged lifecycle through a generalized close door (the b563 commit-citation gate applied to the node itself), decomposition happens as child prescriptions rather than t-items, and todos.json plus the materialized field retire as a two-store sync invariant the framework rejects everywhere else. The operator's architecture: the prescription is the immutable pointer to an obligation; its mutable implementation plan, with dynamic todos, is a companion proto-belief document - a plan in proto-belief's clothing, unifying with cb:b569. The desk term retires with the indirection: the query reads literally as listing open one-off prescriptions.
tags: [nursery, cb, schema, workflow, todos]
status: active
timestamp: 2026-07-02
maturity: active
threads: []
---

# Prescriptions self-track discharge

The matter: `beliefs/todos.json` and the `materialized` field form a second store
whose state must be kept consistent with the graph. Audited, materialization buys
four things, none load-bearing:

1. **Decomposition (one prescription -> N tasks).** The graph already expresses
   one-to-many: child action-item prescriptions dep'ing on a parent.
2. **Mutable execution state kept off immutable nodes.** The boundary is already
   porous by design - evidence appends, the `materialized` stamp, and status flips
   are sanctioned in-place mutations. A discharge is `status: active -> retired`
   plus a commit-cited evidence entry, which is exactly what `mix cb.todo.close`
   does to a t-item today, one indirection away from the node carrying the
   obligation.
3. **The t-item's action text.** A restatement of the prescription's claim - a
   cached copy, the cb:b386 shape.
4. **The materialized <-> todos.json pairing.** A two-store sync invariant of
   precisely the kind the framework rejects everywhere else (derived-not-stored,
   no digests).

## The operator's architecture (2026-07-02)

The prescription is the **immutable pointer to an obligation**; the **mutable
implementation plan - with dynamic todos, checklists, partial progress - is a
companion proto-belief document** in the nursery. A plan in proto-belief's
clothing: this is not a new artifact class but cb:b569's own definition read back
(a plan is a proto-belief document whose mint-manifest rows are predominantly
prescriptions), extended to execution: the document is the cheap mutable
workspace, the prescription is the expensive immutable commitment, and discharge
happens at the node through the front door. Working state that today would be
t-item churn lives in the document; the graph records only the obligation and its
discharge.

## The fold

- **Close door generalizes:** `mix cb.todo.close` becomes a prescription-close
  door (same shape, same b563 gate: cite the implementing commit or record
  `--no-commit` with reasons), flipping the node `active -> retired` with a dated
  evidence entry. The retired status already exists and the schema verifier
  already restricts it to prescriptions.
- **Decomposition:** where a prescription genuinely fans out, mint child
  action-items dep'ing on the parent; sub-task scratch that does not deserve a
  node lives in the companion proto-belief document.
- **Stores retire:** `beliefs/todos.json` and the `materialized` field stop being
  written. Historical record: 25 t-items (and `okf/todos.json`) preserved in
  place or converted - open question below.
- **Vocabulary:** the desk term retires with the indirection that motivated it.
  The session-start query reads literally - list open one-off prescriptions
  (e.g. `mix bs open`: active, `lifecycle:discrete`, not retired) - and
  CLAUDE.md's session-start prose updates to match. The retirement sweep must
  catch every live surface that teaches the term (the vocabulary-read-surface
  lesson - agents echo what the current rulebook says): CLAUDE.md's generated
  sections and their graph sources, docs/operations.md's
  discharging-a-prescription section (the materialize-then-close pattern
  retires with the door), the glossary's Desk entry and the guide chapters
  that lean on it (1, 3, 4), the /materialize skill (retires with the sink),
  and the "desk-tracked" phrasing in live nursery documents
  (vocabulary-read-surface, graph-refounding, seed-lifecycle's Q7 line,
  commit-provenance-floor). Historical record and quoted claims stay, per the
  cb:b570 carve-outs.

## Open questions

- **Historical t-items:** preserve `todos.json` as closed record (the plans/
  shelf pattern: README, no new writes) vs convert the 25 items to evidence
  entries on their source prescriptions. Lean: preserve in place; the source
  prescriptions already carry discharge evidence, so conversion is churn.
- **Granularity discipline:** with t-items gone, mint discipline must keep
  action-items at the level of separable obligations, not checklist lines -
  the split test (cb:b569) applied to obligations. Does this need its own rule
  row or is b569 sufficient?
- **Recurring prescriptions:** `lifecycle:recurring` standing policies are
  untouched (they never materialized); confirm no surface conflates them.
- **Companion-document linkage:** the prescription's `artifact` field already
  carries `document:beliefs/nursery/<doc>.md` (b574-b576 demonstrate the shape).
  Is that sufficient, or does the companion document need a forward pointer to
  the node (mint-manifest row) only? Lean: both already exist; nothing new.

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | Discrete prescriptions self-track discharge: active -> retired through the generalized close door with commit-cited evidence (b563 gate); decomposition is child prescriptions; todos.json and the materialized field retire; mutable implementation plans live as companion proto-belief documents. | cb:b563, cb:b569 | document:beliefs/nursery/prescription-self-tracking.md | - |
| prescription (action-item) | Implement the fold: generalize cb.todo.close to the prescription-close door, retire the todos sink and materialized writes, close todos.json as historical record, rename the session-start query surface, update CLAUDE.md render sections and the guide. | cb:b563 | document:beliefs/nursery/prescription-self-tracking.md | - |

## Thread excerpts (what grounds the leans)

**Operator (the pointer framing):** "the prescription could almost be seen as a
pointer to a proto-belief which is the mutable implementation plan with dynamic
todos - a plan in proto-belief's clothing."

**Operator (the desk):** prefers sunsetting the term for the literal reading -
"search for/return a list of one off prescriptions (todos)" - and, given that,
does not see the advantage of materialization as a separate layer.
