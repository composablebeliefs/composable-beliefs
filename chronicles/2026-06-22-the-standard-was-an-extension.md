# 2026-06-22 — The standard was an extension all along

## Where things stood

`amieval/knowledge` was a separate repo: a portable OKF/Knowledge standard with its own Python
reference tools, a conformance suite, and a small `knowledge:` belief graph. The story it told
about itself was "a standard, not an app" — implementation-independent, adoptable anywhere, with a
second (Elixir) implementation in composable-beliefs kept honest by a conformance corpus.

## The arc

It started as an audit. The format and both implementations were sound; what turned up was edge
drift — a sitemap missing the `beliefs/` dir, two dead anchors, a `beliefs/` directory that the OKF
tools would silently clobber if pointed at it. Fixing those was easy. The interesting part was what
the operator did with the two-implementations fact.

If the conformance corpus defines the format as behaviour, then the two implementations exist *to be
collapsible* — and the Elixir one was already a superset (it carried the `emit`/`ingest` bridge the
Python never had). The only thing the Python bought was zero-install portability across non-CB
repos, and the operator doesn't distribute this. So we deleted ~490 lines of Python plus the bash
conformance runner and its fixture-authoring script, and turned an ExUnit test into the single
conformance gate. Nothing of capability was lost; what evaporated was the scaffolding whose only job
was keeping two implementations in sync.

Then the operator pulled the thread further. With the tooling now CB-coupled, "knowledge is an
independent standard" was no longer true — you can read a bundle without CB, but you can't generate
or validate one. The `knowledge:` graph was already a CB collection; the tooling already lived in
composable-beliefs as the "OKF integration layer." Two of the three parts were already CB
extensions. The separate repo was just the spec docs lagging behind, kept apart for a conceptual
cleanliness the operator decided was contrived. The honest framing: this is *his bespoke OKF
application built on CB*, and the clean line is a namespace, not a repo.

Two incidents made the session sharper than a refactor. First, the agent hand-wrote a `type: thread`
summary mid-session — exactly the artifact `/end` is supposed to produce from the verbatim log — and
hand-edited `CLAUDE.md` with an operational directive that `§1.1` says belongs in the graph. The
operator caught both. The root cause was the same one a165 names: the agent ran on local context
instead of querying the live graph at session start, even though `MEMORY.md` points right at it. The
fix wasn't just reverting; it was recognizing that a *memory pointer to query the graph* is
procedural surfacing — the a386 antipattern aimed at the agent's own onboarding — and that the real
fix is structural (a SessionStart hook), which the repo fold also helps by collapsing two CLAUDE.mds
into one.

## Where things stand

The collapse and corrections are committed across `knowledge` and `composable-beliefs`. The fold is
*decided but not executed* — `cb:a546` carries the intent, `plan:okf-fold` the steps, deliberately
left for a fresh session so it runs against the live tree rather than this conversation's drift. A
deferred design question (`commit:` artifact scheme) sits in `cb:a545` with its options intact.

## What the next session inherits

`mix bs list unlinked tag:lifecycle:discrete` surfaces `cb:a546`: fold `knowledge` into
`composable-beliefs/okf/`, rename `knowledge: → okf:`, rewire the couplings, decommission the repo.
The plan flags the real follow-through beyond the move: a SessionStart hook + an `amieval/` root
CLAUDE.md so the next agent doesn't repeat the surfacing miss this session diagnosed. The namespace
question (`okf:` vs `okfx:`) is the one open choice in the plan.
