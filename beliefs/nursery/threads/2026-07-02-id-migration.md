---
type: thread
title: 2026-07-02 - id migration (b-serials, merge policy, obligation hygiene)
description: Covers the session that retired the a/c id prefixes for opaque b-serials (PR #10) and the review thread that followed (PR #11) - the letter-swap migration and legacy alias, the concurrent-mint merge translation, the merge-commit-only contract, a name redaction, follow-up obligations minted to the desk, the Q7 gate made structural, and two handed-off deliberations (chronicle fold, prescription self-tracking). Use when auditing the id epoch boundary or orienting to the close-out conventions this thread practiced.
tags: [cb, nursery, schema, id-protocol, thread]
status: active
timestamp: 2026-07-02
artifact: session:2026-07-02-id-migration
---

# 2026-07-02 - id migration (b-serials, merge policy, obligation hygiene)

> **Hand-captured (2026-07-02).** No `Stop` hook runs in this remote session; written by
> hand in the established format, condensed - tool calls and reasoning stripped, exchanges
> grouped by phase. Produced: PR #10 (merged `eb8cb76`) and PR #11 (merged `4ad434b`),
> beliefs cb:b566 / cb:b573 / cb:b574-b577, the
> [cb-id-b-migration](../cb-id-b-migration.md) proto-belief document (re-homed from
> plans/), and the [prescription-self-tracking](../prescription-self-tracking.md) seed.

## Narrative

This section practices the successor close-out convention: the operator decided this
session that the chronicle register folds into the thread document (execution handed to
an agent; the chronicle prescription's supersession is pending), so no chronicles/ entry
accompanies this thread - the narrative lives here instead. (Merge-time note: the fold
executed the same day as PR #16 - cb:b578 minted, b520 superseded, chronicles/
archived - so the convention this record practiced is now law.)

Where things stood: the graph carried two id prefixes whose meanings the schema-v3
rename had orphaned - `a` for a retired type name, `c` for a grade that b056 had
demoted to a derived predicate, with code still prefix-matching in places b056 forbade.

The arc: the operator questioned the id protocol and proposed type prefixes; the
counter-analysis (identity outlives vocabulary - v3 itself the proof) landed on less
semantics instead: one opaque `b` prefix. Pre-production status made a full alpha-rename
feasible; disjoint serial ranges (a098-a565, c026-c067) made it a pure letter-swap with
a mechanical alias. Executed in four layers (spec, code-with-alias, sweep, minted
record cb:b566). Main moved mid-flight - six legacy mints and the first Belief:
trailers - and the merge translated them into b-space with exactly one renumber
(cb:a566 -> cb:b572, serial 566 contested by both sides of the fork). Review comments
arrived through the PR-watch loop and were fixed in place; a name redaction was scrubbed
to plain atomic-commits language; squash and rebase merging were prohibited in settings
and doctrine together (cb:b573) after the operator pushed back on a soft
recommendation. The close-out rounds then turned the session's own leftovers into
graph state: follow-ups minted to the desk (cb:b574-b576), the mis-shelved spec
re-homed to the nursery, the Q7 gate given a node to dep on (cb:b577), and two larger
deliberations seeded or handed off rather than left in chat.

Where things stand: the cb: graph is uniformly b-serial (238 nodes at close), the
legacy alias resolves every historical reference, merge-commit-only is settled, and the
desk holds four open obligations.

What the next session inherits: b574 (belief-collections sweep), b575 (codepath/cb-okf
renumbering), b576 (glossary regeneration), b577 (the Q7 archive-shelf decision), and
one remaining agent prompt held by the operator - prescription self-tracking,
staged in its seed (the chronicle-fold prompt executed as PR #16 the same day).

## Routing

| Topic | State | Routed to | Dangling |
|---|---|---|---|
| Id naming protocol (a/c -> opaque b-serials) | closed | [cb-id-b-migration](../cb-id-b-migration.md); minted cb:b566 | - |
| Concurrent-mint merge translation (a566-a571) | closed | [cb-id-b-migration](../cb-id-b-migration.md); postscript on [2026-07-02-authoring-pipeline](2026-07-02-authoring-pipeline.md) | - |
| Merge policy (squash/rebase prohibition) | closed | minted cb:b573; [commit-provenance-floor](../commit-provenance-floor.md) resolved block | - |
| Name redaction -> plain atomic-commits language | closed | commits `3b1aec1`/`52e6054`/`caeba87` | two sailed commit messages on main retain the name |
| Follow-up obligations to the desk | closed | minted cb:b574-b576 | discharge pending (open on the desk) |
| plans/ shelf mis-shelving | closed | re-homed as [cb-id-b-migration](../cb-id-b-migration.md) | physical archiving rides Q7 (cb:b577) |
| Q7 gate made structural | closed | minted cb:b577; annotations on the four prose sites | decision itself open on the desk |
| Chronicle fold (register into thread docs, shelf closes) | closed | executed same day as PR #16: b520 superseded, close protocol minted cb:b578, chronicles/ archived ([2026-07-02-fold-chronicle-into-threads](2026-07-02-fold-chronicle-into-threads.md)) | - |
| Prescription self-tracking (todos/desk fold) | open | [prescription-self-tracking](../prescription-self-tracking.md); agent prompt held by operator | rows unminted; the prompt's sequencing guard (chronicle fold first) is satisfied by PR #16 |

## Exchanges (condensed)

**User:** Reconsider the id naming protocol - `a`/`c` are deprecated terms; perhaps
type-based prefixes (at/ag/in/pr)?

**Claude:** Agreed the prefixes are stale, argued against type prefixes: the v3 rename
proves semantic prefixes rot, ids are the one immutable field, and the c-prefix already
stores a derived property contra b056. Recommended one opaque prefix `b`.

**User:** Agreed `b`; asked whether all existing ids could migrate, immutability being
aspirational pre-production.

**Claude:** Yes - disjoint serial ranges make the letter-swap collision-free and keep
historical references resolvable by a one-line alias; recorded, it is an alpha-rename,
not a mutation.

**User:** Authorized execution (plan doc, no context reset).

**Claude:** Executed the four layers; PR #10 opened. Merge translated main's concurrent
mints (one renumber: a566 -> b572, documented in a postscript). PR watch subscribed;
review comments answered and fixed; the pending-review identity collision surfaced (the
GitHub integration acts as the operator's account; a draft review was lost and
restored).

**User:** Asked whether PR descriptions persist; pushed back that "recommend against
squash" was too soft.

**Claude:** Conceded: squash and rebase merging sever the commit-provenance loop, so
prohibition, not preference. Operator disabled both in settings; cb:b573 minted through
the front doors recording why.

**User:** Requested the external framework name scrubbed; then that passages refer
plainly to atomic commits; review comments asked the same of a residual bullet and the
stale open-squash listing.

**Claude:** Scrubbed (current files zero mentions; two sailed commit messages remain),
rephrased, resolved the review threads. PR #10 merged on instruction (`eb8cb76`).

**User:** Asked how the parked follow-ups persist across sessions.

**Claude:** Flagged the gap honestly - prose is not obligation - and on instruction
minted cb:b574-b576 through the front doors; PR #11 opened.

**User:** Asked why cb-id-b-migration was a plan and not a proto-belief; chose to fold
the re-home into PR #11. Asked where spike item 4 persists.

**Claude:** Re-homed the document to the nursery with frontmatter and mint manifest,
repointed b574-b576's artifacts pre-landing. Answered: spike item 4 is a staged row
gated on Q7 - and the gate was prose only.

**User:** Asked about chronicles, the desk vs todos.json, and where Q7's gate is
recorded; directed: mint the Q7 decision, draft a chronicle-fold prompt, assess the
todos fold.

**Claude:** Minted cb:b577 (open-decision shape) and annotated the prose sites; agreed
chronicles reduce to a narrative section on the thread document (prompt delivered);
audited materialization (four buys, none load-bearing) and recommended the fold.

**User:** Endorsed with the pointer framing - the prescription as immutable pointer to
an obligation, the mutable implementation plan a companion proto-belief document, "a
plan in proto-belief's clothing." Directed seeding and a second prompt; merged PR #11.

**Claude:** Seeded [prescription-self-tracking](../prescription-self-tracking.md) with
the framing verbatim; delivered the second prompt with sequencing guards; merged PR #11
on instruction (`4ad434b`).

**User:** Asked whether the thread is ready to /end.

**Claude:** Almost - two gaps: the chronicle-fold decision existed nowhere in the repo,
and the session owed its own thread record. This document closes both.

## Produced

- [cb-id-b-migration](../cb-id-b-migration.md) - the migration proto-belief document
  (planted), with import/adjudication records in `cb-id-b-migration/`
- [prescription-self-tracking](../prescription-self-tracking.md) - the todos-fold seed
  (active, rows staged)
- Beliefs: cb:b566 (id protocol), cb:b573 (merge-commit only), cb:b574-b576 (follow-up
  obligations), cb:b577 (the Q7 decision, desk-tracked)
- PRs: #10 (merged `eb8cb76`), #11 (merged `4ad434b`)
