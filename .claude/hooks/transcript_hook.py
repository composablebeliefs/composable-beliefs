#!/usr/bin/env python3
"""Stop hook: regenerate a non-provenance prose transcript of the session into
the nursery threads/.sessions/ subdir, alongside a raw jsonl copy.

Reads the Stop-hook JSON on stdin, walks the session jsonl, and writes a clean
Human/Assistant transcript. For each turn it keeps ONLY the response the agent
actually shared - the text after the turn's last tool call - dropping the
interstitial "let me check X" narration that precedes each tool batch, along
with all reasoning, tool calls, tool results, and system noise. Turns with no
tool calls (plain conversation) keep all their text. Idempotent: regenerates
the whole doc each turn (no append markers, naturally crash-safe). The raw
jsonl is copied in beside the render each turn (the persist-raw lane; its
commit is gated on transcript-format's repo-weight/LFS decision).

The output dir is derived from $CLAUDE_PROJECT_DIR (set by the harness for
hooks), falling back to this script's own location (<repo>/.claude/hooks/), so
the same hook runs in local and remote sessions. Registered in the committed
.claude/settings.json. On the first capture of a session it emits a
systemMessage pointing at the live render and the /end step that persists it.

This artifact is NOT provenance - the nursery seeds are. It exists for crash
safety and human reading. Never let the graph depend on it.
"""
import json
import os
import shutil
import sys


def project_dir():
    d = os.environ.get("CLAUDE_PROJECT_DIR")
    if d and os.path.isdir(d):
        return d
    # <repo>/.claude/hooks/transcript_hook.py -> <repo>
    return os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    )


THREADS_DIR = os.path.join(
    project_dir(), "beliefs", "nursery", "threads", ".sessions"
)

# A text block shorter than this that precedes a tool call is treated as "let me
# check X" narration and dropped. Longer pre-tool blocks are substantive answers
# and are kept (e.g. an analysis given before the commits that act on it).
NARRATION_MAX_CHARS = 300


def main():
    try:
        hook = json.load(sys.stdin)
    except Exception:
        return 0

    tpath = hook.get("transcript_path")
    sid = hook.get("session_id")
    if tpath and not sid:
        sid = os.path.basename(tpath).removesuffix(".jsonl")
    sid = sid or "unknown"
    if not tpath or not os.path.exists(tpath):
        return 0

    # Flatten the jsonl into ordered events: ("user", text) | ("text", text) | ("tool", None)
    events = []
    first_ts = None
    try:
        fh = open(tpath, encoding="utf-8")
    except Exception:
        return 0
    with fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            typ = o.get("type")
            if typ not in ("user", "assistant") or o.get("isSidechain") or o.get("isMeta"):
                continue
            first_ts = first_ts or o.get("timestamp")
            content = (o.get("message") or {}).get("content")
            if typ == "user":
                if not isinstance(content, str):
                    continue  # tool_result turns are lists - drop them
                text = content.strip()
                if not text or text.startswith("<"):
                    continue  # system reminders, slash-command wrappers, caveats
                events.append(("user", text))
            elif isinstance(content, list):
                for b in content:
                    if not isinstance(b, dict):
                        continue
                    if b.get("type") == "text" and (b.get("text") or "").strip():
                        events.append(("text", b["text"]))
                    elif b.get("type") == "tool_use":
                        events.append(("tool", None))
                    # thinking blocks are dropped

    # Segment into turns. Drop only SHORT text that precedes a tool call - the
    # "let me check X" narration. Keep substantive blocks (long) wherever they fall,
    # and any block not followed by a tool (the turn's closing response).
    sections = []

    def flush(user_text, seg):
        if user_text is not None:
            sections.append(("User", user_text))
        tool_idxs = [i for i, (kind, _) in enumerate(seg) if kind == "tool"]
        kept = []
        for i, (kind, t) in enumerate(seg):
            if kind != "text":
                continue
            followed_by_tool = any(ti > i for ti in tool_idxs)
            if followed_by_tool and len((t or "").strip()) < NARRATION_MAX_CHARS:
                continue  # short pre-tool narration
            kept.append(t)
        text = "\n\n".join(x.strip() for x in kept if x and x.strip()).strip()
        if text:
            sections.append(("Assistant", text))

    cur_user, seg = None, []
    for kind, t in events:
        if kind == "user":
            if cur_user is not None or seg:
                flush(cur_user, seg)
            cur_user, seg = t, []
        else:
            seg.append((kind, t))
    if cur_user is not None or seg:
        flush(cur_user, seg)

    date = (first_ts or "")[:10]
    out = [
        f"# Session transcript - {sid}",
        "",
        "> Auto-captured by the Stop hook. **Non-provenance** (see [index](index.md)) -"
        " the nursery seeds are the provenance. Substantive responses are kept; short"
        " pre-tool narration, reasoning, and tool calls are stripped.  ",
        f"> Session `{sid}`" + (f" | {date}" if date else ""),
        "",
    ]
    for speaker, text in sections:
        out += [f"## {speaker}", "", text, ""]

    stem = f"{date}-{sid[:8]}" if date else sid[:8]
    render_path = os.path.join(THREADS_DIR, f"{stem}.md")
    first_capture = not os.path.exists(render_path)
    try:
        os.makedirs(THREADS_DIR, exist_ok=True)
        with open(render_path, "w", encoding="utf-8") as f:
            f.write("\n".join(out))
        shutil.copyfile(tpath, os.path.join(THREADS_DIR, f"{stem}.jsonl"))
    except Exception:
        return 0

    if first_capture:
        rel = os.path.relpath(render_path, project_dir())
        print(json.dumps({
            "systemMessage": (
                f"Transcript capture live: {rel} (+ raw jsonl beside it, both"
                " uncommitted). Run /end before finishing to persist the thread."
            )
        }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
