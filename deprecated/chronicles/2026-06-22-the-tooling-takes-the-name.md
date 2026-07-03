# 2026-06-22 — The tooling takes the name

**Span:** 2026-06-22 — the closing beat of the okf-fold arc: decommission, the
surfacing file, and the `knowledge.* -> okf.*` rename. Continues
[the extension comes home](2026-06-22-the-extension-comes-home.md) and the okfx:a004
agent's [the second file learns to compile](2026-06-22-the-second-file-learns-to-compile.md).
**Register:** chronicle (cb:a520) — narrative for the operator; the receipts live in
`cb:a546`/`okfx:a010` discharge notes, the supersession chain, and commits 304da5e / 0720a29.

## Where things stood

The fold had landed but three things trailed it: the `knowledge` repo still sat on disk
(decommission deferred), the surfacing fix that started the whole thread (a cold agent
working from the prompt instead of the graph, agent-behavior:a165) was unbuilt, and the
tooling still wore the old name — `mix knowledge.*`, `CB.Knowledge.*` — even though it now
served the `okf/` directory.

## The arc

**The repo went quietly.** The operator decommissioned `knowledge` by hand; the proof it
was clean was that `mix test` stayed 362/0 with the sibling gone, no `../knowledge` left in
any code path. `cb:a546` was materialized and closed — the directive finally off the desk.

**The surfacing file, and a lesson.** The structural fix for a165 turned out smaller than
billed. A SessionStart hook would touch the operator's *global* `~/.claude` config and fire
in every unrelated project, so the right scope was a single `amieval/CLAUDE.md` that Claude
Code auto-loads up the tree — a router that points any cold agent at the graph and the desk.
Writing it, the agent reached for a forward-looking note ("hand-written until cb:a543 lands,
then it compiles") and grounded it in cb:a543 from memory — without reading that cb:a543 is
the *global* graph (unrelated) or checking whether a belief already governed the question.
The operator's "is this something we can resolve now?" pulled the thread. Preflight surfaced
cb:a466, which already settles it: generated prose compiles where there's an oracle;
hand-written prose is reserved for a distinct audience and *must not freeze drifting lists*.
The amieval file is a router, so it's correctly hand-written — but its repos list was exactly
the frozen list a466 forbids (the `knowledge` entry had just gone stale). Fixed: the list now
points at `collections.json` and `ls`; the note cites a466, not a543. The miss itself is the
same shape as a165 (memory substituting for a graph query), filed as a fifth specimen on it.

**The tooling took the name.** A clean rename: `mix okf.*`, `CB.Okf.*`, `lib/cb/okf/`,
`okf_test.exs`. The hand-written docs followed. The interesting part was the tail: three
render-section beliefs (a003, a007, a008) named the old commands and *compile verbatim* into
`okf/CLAUDE.md`, so a code-only rename would have left the generated doc serving dead
commands. They went through the write flow — superseded to a011/a012/a013, the output-target
contract c001 -> c002 repointed, the file regenerated. Superseding a003 also corrected its
stale `knowledge/beliefs/` path, which is what `okfx:a010` was holding; that discharged too.
Two beliefs were left alone on purpose: `okfx:a004` (a discharged directive, its old path now
historical) and `okfx:a005` (an illustrative "e.g." command name) — superseding non-compiled
historical or illustrative prose would be churn against immutability.

## Where things stand

One repo, one CLAUDE.md discipline per tree, tooling named for what it serves. Everything
green and pushed (0720a29): `mix test` 362/0, both `cb.generate.claude_md --check` paths,
`cb.verify.collection okfx`, schema, `mix okf.validate`. `amieval/CLAUDE.md` is the live
surfacing fix (local file; amieval isn't a git repo).

## What the next session inherits

The okfx desk holds three: `okfx:a001` (pilot the CONVERT runbook on SECOND-BRAIN),
`okfx:a002` (backfill the threads:[] provenance convention), `okfx:a005` (port the deleted
conformance regen.py to a `mix okf.conformance.regen` task — name it freshly when built).
Still unbuilt from the broader family: the SessionStart hook is deliberately *not* done — the
amieval file is the lighter, correct surfacing fix, and the global directive graph (cb:a543)
remains its own piece of work. The cross-collection desk gap (cb:a500) still bites: cb: and
okfx query separately, so the desk is two `mix bs` calls until it's built.
