# Belief Graph - Operational Learnings

Companion to `belief-graph.md`. The durable *principles* now live in the graph as beliefs (`mix bs list domain:design tag:operations`); this doc keeps the **workflow** - how to run an extraction session in practice.

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

## Session lifecycle hooks (the amieval tree)

A session in the amieval tree is bracketed by two harness hooks. Both are the
structural answer to the cb:a165/cb:a386 pattern - a reminder the agent must
remember to act on is procedural surfacing; a hook makes it structural. The
scripts live in dotfiles-claude (`~/.claude/hooks/`) because they are machine-level
harness config, registered in `~/.claude/settings.json`; the graph records the
*why* (cb:a543 family for surfacing, cb:a518/a540 for the transcript).

- **SessionStart -> `cb-desk.sh`.** When a session opens with cwd under
  `/Users/mark/dev/repos/mine/amieval`, it injects the live desk
  (`mix bs list unlinked tag:lifecycle:discrete`) into context, so a fresh agent
  sees its obligations without being told to query. Silent and fail-safe outside
  the tree.

- **SessionEnd + SessionStart -> `cb-finalize-transcript.sh`.** Fixes the
  transcript tail-gap: `/end`'s in-close copy runs before the session actually
  ends, so it structurally under-captures the closing turns. The fix rides a
  per-session marker `/end` step 7 drops:
  `~/.claude/transcript-pending/<session_id>.json` = `{"dest": <abs .jsonl>, "repo": <abs repo>}`.
  The same script runs at both events:
  - **SessionEnd:** finalize THIS session - re-copy the **complete** `.jsonl`
    over the in-`/end` snapshot, commit + push in `repo`, remove the marker.
    No-op on `resume`.
  - **SessionStart:** RECOVERY - finalize **orphaned** markers from prior
    sessions, skipping the current session's own. Catches a SessionEnd that never
    fired (silent failure OR crash - SessionEnd does not fire on crash). Guarded
    for concurrency: only a marker whose log has been **idle > 6h** is recovered.
    A concurrent live session writes its log every turn (recent mtime), so it is
    never finalized from another session - without that guard, a new session
    would prematurely commit a running session's incomplete log and delete its
    marker. (SessionEnd finalizes its own session unguarded.)

  This makes it **self-verifying**: a marker's *presence* means "not yet
  finalized", its *absence* is proof the log landed. A thread is never lost - at
  worst finalized one session late, by the next SessionStart. (A marker whose log
  is missing is left for a later retry, so truly-dead markers linger until swept
  manually - `ls ~/.claude/transcript-pending/`.)

Trigger boundary: SessionEnd is the *user/harness* ending the session (`/clear`,
logout, CLI exit) - not `/end` completing. `/end` only leaves the marker; the
session may continue (or `/end` again) before it actually ends, and the finalizer
captures everything up to that point. The reliable backbone is still the
*in-session* `/end` snapshot (verifiable, committed while you watch); the hook is
the best-effort extension that closes the tail, with SessionStart recovery as its
backstop.
