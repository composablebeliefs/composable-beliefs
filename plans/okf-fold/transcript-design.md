# okf-fold — design/decision transcript

Verbatim record: [`sessions/2026-06-22-knowledge-audit-collapse.jsonl`](sessions/2026-06-22-knowledge-audit-collapse.jsonl)
(byte-for-byte copy of the Claude Code session log, the immutable `type: source` for this
arc; `session:2026-06-22-knowledge-audit-collapse` resolves here). This file is the readable
summary; the `.jsonl` is provenance.

## Arc

The session began as an audit of `amieval/knowledge` (the OKF/Knowledge standard) and turned
into two decisions plus their execution:

1. **Elixir-only collapse (executed).** The standard had two conformant implementations — the
   Python reference tools and the Elixir `mix knowledge.*` in composable-beliefs (already a
   superset, with the `emit`/`ingest` bridge). Portability across non-CB repos was the only thing
   the Python bought, and the operator doesn't need it, so we deleted the Python + the cross-impl
   conformance scaffolding (`run.sh`, `regen.py`) and made an ExUnit test the conformance gate.
   Committed in `knowledge` (52c14ee) and `composable-beliefs` (7565850).

2. **Policy corrections (executed).** A hand-written `type: thread` doc and a hand-edited
   `knowledge/CLAUDE.md` operational directive both violated standing policy (threads persist at
   `/end` as the verbatim `.jsonl` + chronicle, `cb:a540`; operational directives live in the
   graph, `KNOWLEDGE.md §1.1`). Reverted; homed the `beliefs/`-guard as `knowledge:a003`; added
   backlog `a004`/`a005`. Fixed an unrelated stale test (`c043 → c066`). Committed (76d1145,
   e9453d4, ac3e199, d743508).

3. **Fold decision (deferred to a fresh session).** The collapse made `knowledge`'s tooling
   CB-dependent in fact, so the standalone repo no longer earns its separateness; the repo seam is
   also what kept `cb:a540` from surfacing. Decision: fold the standard into
   `composable-beliefs/okf/` as the OKF integration extension, keeping the conceptual line as a
   namespace (`okf:`, renamed from `knowledge:`) rather than a repo. Intent SSOT: `cb:a546`
   (`plan:okf-fold`). Detailed steps: [`plan.md`](plan.md).

4. **Deferred design question.** Whether to make the belief↔commit link structural via a
   `commit:`/`git:` artifact scheme — persisted with full options as `cb:a545`.

## Reasoning error caught (persisted)
The agent worked from local context and re-derived conventions instead of querying the live graph
at session start (which `MEMORY.md` explicitly points to), missing the active thread-persistence
directive — caught by the operator. Filed as Evidence on `agent-behavior:a165`.
