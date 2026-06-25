#!/usr/bin/env python3
"""Stop hook: regenerate a non-provenance prose transcript of the session into
the nursery threads/ subdomain.

Reads the Stop-hook JSON on stdin, walks the session jsonl named by
`transcript_path`, and writes a clean Human/Assistant transcript with tool
calls, tool results, reasoning, and system noise stripped. Idempotent: it
regenerates the whole doc each turn (no append markers, naturally crash-safe).

This artifact is NOT provenance - the nursery seeds are. It exists for crash
safety and human reading. Never let the graph depend on it.
"""
import json
import os
import sys

# Auto-transcripts live in a dot-dir so the OKF manifest (Path.wildcard, match_dot
# false) skips them and they can be gitignored - regenerated every turn, never
# committed, never part of the validated bundle. On disk for crash safety + reading.
THREADS_DIR = (
    "/Users/mark/dev/repos/mine/amieval/composable-beliefs"
    "/beliefs/nursery/threads/.sessions"
)


def assistant_text(content):
    if not isinstance(content, list):
        return ""
    parts = [
        b.get("text", "")
        for b in content
        if isinstance(b, dict) and b.get("type") == "text"
    ]
    return "\n".join(p for p in parts if p).strip()


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

    sections = []
    cur, buf = None, []
    first_ts = None

    def flush():
        text = "\n\n".join(buf).strip()
        if cur and text:
            sections.append((cur, text))

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
            if typ not in ("user", "assistant"):
                continue
            if o.get("isSidechain") or o.get("isMeta"):
                continue
            first_ts = first_ts or o.get("timestamp")
            content = (o.get("message") or {}).get("content")

            if typ == "user":
                if not isinstance(content, str):
                    continue  # tool_result turns are lists - drop them
                text = content.strip()
                # drop system reminders, slash-command wrappers, caveats (all <-tagged)
                if not text or text.startswith("<"):
                    continue
                speaker = "Human"
            else:
                text = assistant_text(content)
                if not text:
                    continue  # tool-only / thinking-only turn
                speaker = "Assistant"

            if speaker != cur:
                flush()
                cur, buf = speaker, []
            buf.append(text)
    flush()

    date = (first_ts or "")[:10]
    out = [
        f"# Session transcript - {sid}",
        "",
        "> Auto-captured by the Stop hook. **Non-provenance** (see [index](index.md)) -"
        " the nursery seeds are the provenance. Tool calls and reasoning stripped.  ",
        f"> Session `{sid}`" + (f" | {date}" if date else ""),
        "",
    ]
    for speaker, text in sections:
        out += [f"## {speaker}", "", text, ""]

    fname = f"{date}-{sid[:8]}.md" if date else f"{sid[:8]}.md"
    try:
        os.makedirs(THREADS_DIR, exist_ok=True)
        with open(os.path.join(THREADS_DIR, fname), "w", encoding="utf-8") as f:
            f.write("\n".join(out))
    except Exception:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
