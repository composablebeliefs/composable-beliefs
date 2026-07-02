Finalize and persist the session's thread: synthesize metadata onto the live render, conform it to the thread shape, register it in the nursery, and commit it with the session's work.

The Stop hook (`.claude/hooks/transcript_hook.py`, registered in the committed `.claude/settings.json`) rewrites a responses-only render plus a raw jsonl copy into `beliefs/nursery/threads/.sessions/` every turn, in local and remote sessions alike. That working area is gitignored - in a remote session it dies with the container - so persistence happens here: `/end` turns the live render into a committed thread doc.

**Threads are not provenance.** The nursery seeds are; a belief grounds in a seed, never in a transcript (`beliefs/nursery/threads/index.md`). A thread exists for crash safety and human reading.

## Steps

1. **Locate the live render** in `beliefs/nursery/threads/.sessions/` (`<date>-<session>.md`, with `<date>-<session>.jsonl` beside it). If the hook was not running (no render exists), fall back to hand-capturing from context in the same format - disclose that in the doc's blockquote, as the existing hand-captured threads do.

2. **Synthesize the metadata the hook cannot know.** Frontmatter: `type: thread`, `title` (`<date> - <short arc name>`), `description` (what the session covered and when to read it), `tags` (include `thread`), `status: active`, `timestamp` (today), `artifact: session:<date>-<slug>`. These are only knowable at session end; the hook owns the live body, `/end` owns the metadata (transcript-format's pipeline).

3. **Conform the body** to the thread shape (`2026-06-25-belief-audit.md` is the prototype): the frontmatter above, a capture-provenance blockquote (hook-rendered or hand-captured), a `## Where we are` digest of what settled, the turn-by-turn body, and a `## Related` section linking the focuses and beliefs the session fed.

4. **Write and register.** Write to `beliefs/nursery/threads/<date>-<slug>.md`. Add it to the threads index (`threads/index.md` Contents) and the nursery `manifest.json` (bump `count`, add the entry with the `session:` artifact). Back-link it from any focus docs the session fed (their `threads:` frontmatter).

5. **Leave the raw jsonl in `.sessions/`, uncommitted.** Committing raw is gated on transcript-format's repo-weight decision (the LFS lean); until that lands, the render is the committed lane and the raw copy is working-area only. Do not delete it.

6. **Commit and push** the thread doc, index, and manifest together with the session's work - per the repo's git policy, only when the user has instructed the commit (invoking `/end` for a session whose work is being pushed is that instruction for the thread that records it).
