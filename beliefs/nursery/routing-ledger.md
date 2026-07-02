---
type: concept
title: The routing ledger - per-thread dispatch for non-linear conversations
description: Covers the routing ledger - a per-thread table of topics, strand states, dispatch pointers, and dangling questions that lets a multi-topic thread be resumed from its ledger instead of from memory - designed as a router, never a digest (content lands in focus docs; the ledger holds only pointers and states, keeping it outside cb:a386's reach); location lean in-thread, maintained by the hook or a /decompose skill. Minted cb:a566; open on hook mechanics and the skill build.
tags: [nursery, threads, provenance, workflow]
status: active
timestamp: 2026-07-02
maturity: active
minted: cb:a566
threads: [2026-07-02-authoring-pipeline]
---

# The routing ledger - per-thread dispatch for non-linear conversations

## The focus
Threads are demonstrably non-linear: a session touches several focuses, spawns side
quests, pauses strands mid-air (the 2026-06-25/26 thread seeded at least five focuses
with reversals mid-stream). Under focus-as-unit the synthesized *content* is already
homed - it lands in whichever focus docs the conversation concerns - but nothing tracks
the *dispatch*: which strands this thread opened, which are paused on a question, which
were routed where, and which dangle unrouted. The user is left holding that state in
memory. Should each thread carry a parallel summary document, and if so, what shape keeps
it from becoming a stale digest?

## The design: a router, never a digest

The originating proposal was a running thread-summary document - synthesized statements
grouped by topic heading, updated by a `/decompose` skill, so the user replies from the
summary instead of re-reading the thread. The trap is cb:a386: a persisted summary whose
freshness depends on remembering to regenerate it embeds the staleness it was meant to
solve - and a summary that *restates* thread content also silently duplicates the focus
docs, where that content is supposed to live.

The version that survives both objections is a **routing ledger**: one row per topic the
thread touches, holding only

- **topic** - what the strand is about, one line;
- **state** - `open` (live), `paused` (waiting on a dangling question), `closed`
  (resolved; nothing further expected in this thread);
- **routed to** - the focus doc that absorbed the strand's content, or `unrouted`;
- **dangling** - the open question, when paused or open.

State describes the conversation strand; routed-to describes dispatch. They are
orthogonal: a strand can be routed and still open (deliberation continues in the focus),
or closed and unrouted (nothing worth keeping). Content never lives in the ledger - only
pointers and states - so it cannot drift into a shadow copy of the seeds. It answers
exactly one question: *what would I need to know to reply to this thread without
re-reading it?*

## Location (lean: in-thread)

The ledger is per-thread, non-authoritative (like the render - a convenience, not
provenance), and rewritten as the thread advances. Lean: a `## Routing` section at the
top of the thread doc itself - one file per thread, and the hook that rewrites the body
every turn can preserve it the way transcript-format already preserves frontmatter.
Alternative: a sibling file per thread; adopt only if hook mechanics demand it.
First instance: [threads/2026-07-02-authoring-pipeline](threads/2026-07-02-authoring-pipeline.md).

## Maintenance

For hook-captured threads, a `/decompose` skill (or an extension of the transcript hook's
`/end` half) maintains the rows at the same moment content is routed into focus docs -
routing and ledger update are one motion, not a regeneration step that can be forgotten.
For hand-captured threads the ledger is hand-kept, as here. The skill build is open work;
the practice does not wait for it (cb:a566 prescribes the ledger, not the automation).

## Mint manifest

| Type | Draft claim | Deps | Grounding | Minted |
|---|---|---|---|---|
| prescription | Every persisted thread carries a routing ledger: one row per topic, holding strand state, dispatch pointer, and dangling question; content lands in focus docs, never in the ledger. | cb:a386 | document:beliefs/nursery/routing-ledger.md | cb:a566 |

Open rows (not yet candidates): the `/decompose` skill build and the hook-preservation
mechanics may mint an action-item prescription once the design firms up.

## Thread excerpts (what grounds the design)

**User (the need):** "a thread which may cover a whole bunch of different topics, and it
can be quite hard to keep track of all the different threads and not lose ... elements of
the discussion within the thread ... the user wouldn't need to keep in mind all the
dangling conversations and threads that have been paused within the thread itself, but
instead could read the thread summary document and refer strictly to that when replying."

**Claude (the reframe):** "A parallel document that restates what the thread discussed is
a digest of the thread, and it will also silently duplicate the focus docs ... The
version that avoids both problems: a routing ledger per thread ... it holds pointers and
states, not claims."

## Related
- [transcript-format](transcript-format.md) - the pipeline this inserts into, between the
  render and the seeds; its frontmatter-preservation mechanism is the model for keeping
  the ledger across hook rewrites.
- [statement-provenance](statement-provenance.md) - finer-grained (per-statement) linkage;
  the ledger is per-topic dispatch, not provenance - the two compose.
- [mint-manifest](mint-manifest.md) - the same session's other adopted practice; together
  they complete the thread-to-graph pipeline.
- [thread-repo-binding](thread-repo-binding.md) - where the ledger lives follows where the
  thread lives.
