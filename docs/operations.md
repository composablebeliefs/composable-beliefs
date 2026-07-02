# Belief Graph - Operational Learnings

Companion to [the guide](guide/README.md). The durable *principles* now live in the graph as beliefs (`mix bs list domain:design tag:operations`); this doc keeps the **workflow** - how to run an extraction session in practice.

> The shared-prosthetic framing (`cb:a460`), composition-over-retrieval (`cb:a462`), scope-decisions-as-beliefs (`cb:a461`), and the centralized-graph rationale (`cb:a112`) are beliefs now, not prose here - read them with `mix bs show`.

## Extraction workflow

A productive extraction session processes source documents and produces concrete operational value:

1. **Archive source documents** to `sources/` as cleaned text (strip binary attachments, trim quoted text beyond two levels, keep message metadata and IDs). Name files `YYYY-MM-DD-slug.md`. The archive is a stable snapshot, not the live document - the originating system stays the source of truth.

2. **Read with decomposition intent.** Instead of reading linearly and coming away with "mostly handled," parse each section for irreducible claims and evaluate each for composition with existing beliefs.

3. **Layer beliefs.** Primitives first (grounded in source evidence), then compounds (composed beliefs), then inferences (conclusions) and directives (actions). The layering surfaces insights no single document contains - e.g. three scattered policy statements composing into one lifecycle rule that no file states on its own.

4. **User-relayed primitives.** Information relayed in conversation becomes a belief with `artifact: "user:<owner>:YYYY-MM-DD"` and `evidence` citing the session - honest provenance that says "the user told me this" rather than inventing a document.

5. **Dependency fan-in detection.** The highest-value output is often discovering that several separate threads converge on one rule. That fan-in is not visible in any single file; it emerges structurally from the graph.

## Evidence field discipline

Every primitive sourced from a document or artifact carries an `evidence` array. The `claim` is the agent's interpretation; each evidence `detail` is the specific narrative of what the source said. A future session can read the evidence and ask "does this claim actually follow from these words?" - without it, the claim is uncheckable hearsay.

**Schema note (historical):** an earlier schema used top-level `source`/`quote`; the current schema uses `artifact` + `evidence[]`. If you meet an old belief with `source`/`quote`, read `source` as `artifact` and `quote` as the first evidence entry's `detail`.

## Discharging a directive whose work shipped out-of-band

A desk directive (active, unmaterialized) usually discharges through
`/materialize` -> work -> `mix cb.todo.close`. But sometimes the work it
specifies ships *outside* that flow - a sibling session builds the tool, or it
lands as ordinary dev work - and the directive is left active while the work is
done. To reconcile the desk with reality: verify the work actually meets the
directive's spec (read the shipped code, do not trust the commit message), then
materialize the directive with a single action-item describing the completed
work (put the discharging commit in its notes), and immediately
`mix cb.todo.close` that todo with the verification result. The materialized
field then records the discharge and the directive leaves the desk; the closed
todo is the honest record of what discharged it. There is no separate
"mark discharged" verb - materialize-then-close is the path, and the action-item
text carries the out-of-band provenance (worked example: cb:a537, discharged by
`mix cb.repoint` at ac3e199).

## Observing live agent work: the lap log

A working session is observable from inside the editor: the agent appends to a
scratch markdown file (`tmp/lap-log.md`) station by station, and the operator
keeps it open in a split - Zed reloads externally-changed buffers silently, so
the pane updates live (per `cb:a497`). Entries follow the anchor discipline
(`cb:a467`): the content anchor is the truth, the line number is a write-time
snapshot, and stations that rewrite files re-emit fresh locators.

Zed link mechanics, current as of 2026-06-11: cmd-click follows markdown links
in buffers; a `:line` suffix on a relative link opens at the line; so does
`zed://file/<absolute-path>:<line>`; link targets resolve relative to the
containing file (a log in `tmp/` reaches sibling repos via `../../`). Terminal
output `path:line` is also clickable and is the fallback surface.

## Pushing CI workflow changes needs GitHub `workflow` scope

A push that touches `.github/workflows/*.yml` is rejected by GitHub when the
credential (OAuth app token, e.g. the default `gh`/Claude auth) lacks the
`workflow` scope: `refusing to allow an OAuth App to create or update workflow
... without 'workflow' scope`. The rest of the commit is fine; only the workflow
file is blocked, and the whole push fails atomically. Either push workflow edits
with a `workflow`-scoped token, or split them out and hand them off (the okf CI
gate was parked as `cb:a548` for exactly this reason, 2026-06-22).

## Session start hook + transcript capture (the host workspace)

Session **start** is surfaced by one harness hook; the **transcript** is captured
by `/end` itself (no end hook - see below). The surfacing hook is the structural
answer to the cb:a165/cb:a386 pattern - a reminder the agent must remember to act
on is procedural surfacing; a hook makes it structural. It lives in dotfiles-claude
(`~/.claude/hooks/`, registered in `~/.claude/settings.json`) as machine-level
harness config; the graph records the *why* (cb:a543 family for surfacing,
cb:a518/a540 for the transcript).

- **SessionStart -> `cb-desk.sh`.** When a session opens with cwd under
  the host workspace root, it injects the live desk
  (`mix bs list unlinked tag:lifecycle:discrete`) into context, so a fresh agent
  sees its obligations without being told to query. Silent and fail-safe outside
  the tree.

There is **no SessionEnd hook**. The verbatim transcript is captured by `/end`
itself: step 5 chooses the destination + retro-pairs, and step 7 (as the last
write before commit) does the byte-copy and commits it - the latest-possible
in-session snapshot, verifiable while you watch.

A SessionEnd finalizer was tried (a marker `/end` dropped, a hook re-copying the
complete log at true session end, SessionStart recovery for crashes) and
**removed** (cb:a518). It bought ~1-2 closing turns of no decision content at the
cost of a marker protocol, a concurrency guard, and a silent-failure surface -
and produced a real concurrency bug plus a destructive test that swept live state
(agent-behavior:a108). The accepted trade: the `/end` snapshot is the record;
turns after it (the close, or work done after `/end`) are captured only by
**running `/end` again**. If you keep working after a close sweep, re-run `/end`
before you exit.
