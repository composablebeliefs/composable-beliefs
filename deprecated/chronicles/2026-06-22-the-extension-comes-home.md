# 2026-06-22 — The extension comes home

**Span:** 2026-06-22 — one focused thread, the execution half of the okf-fold arc
(continues [the standard was an extension all along](2026-06-22-the-standard-was-an-extension.md)).
**Register:** chronicle (cb:a520) — narrative for the operator; the audit trail lives in
`cb:a546`'s evidence, `plan:okf-fold`, and this session's verbatim log.

## Where things stood

The previous session decided the fold and stopped: `cb:a546` carried the intent, `plan:okf-fold`
the steps, deliberately left for a fresh agent so it ran against the live tree rather than that
conversation's drift. The one open choice in the plan was the namespace token — `okf:` or `okfx:`.

## The arc

A cold agent picked `cb:a546` off the desk and, this time, did the session-start discipline first
— pulled the repos, queried the desk, bootstrapped from the directive and the plan — rather than
running on the prompt. That mattered: the prior session's whole incident (a165) was an agent
working from local context instead of the graph, and the fold's deeper purpose is to make the right
CLAUDE.md load so that miss gets harder.

The namespace question went to the operator and the answer was the *honest* one: **`okfx:`**, not
`okf:`. The reasoning is small but real — this standard isn't vanilla OKF. OKF's entry mechanism is
`index.md`; the generated `manifest.json` agent-index is a bespoke addition layered on top. `okfx:`
says "extends OKF" out loud. That decision then wrote itself into the manifest description and into
`KNOWLEDGE.md §5`, where the bespoke-not-OKF point had only ever been *implied* by its absence from
the lineage table. The naming choice surfaced a latent documentation gap and closed it.

The move itself was unremarkable in the good way. The tree went into `composable-beliefs/okf/`,
**flat** — `manifest.json` + `beliefs.json` at the root, matching the `codepath/` precedent, not
the old `beliefs/` subdir. The plan had listed `beliefs/` among the things to move; re-assessing
against the live `codepath/` layout said otherwise, and the fresh re-import made the old subdir
moot anyway. The five `knowledge:` beliefs became `okfx:` by re-import into an empty collection (no
rename task exists, so re-import is the migration), claims preserved verbatim, `a004`'s dep
re-pointed, and `a003-a005` finally retro-paired to their session transcript — a pairing that
*couldn't* resolve until the collection lived in the same repo as the plan that holds the `.jsonl`.
That was the seam the whole fold was about, closing in miniature.

The couplings came next: `collections.json`, the conformance test (renamed, now reading the in-repo
corpus instead of a `../knowledge` sibling), a stale docstring, and the four cb: beliefs whose
evidence still pointed at `../knowledge/...`. Those four got corrective in-repo pointers appended
through `mix cb.evidence` — never rewritten, because they're immutable and the originals are
honest history. Appending rather than editing also future-proofed them against the decommission
that would otherwise strand the old paths.

Two things were *left alone* on purpose. `okfx:a004`'s claim prose still names its sibling guard as
`knowledge:a003`; the directive scoped a004's change to its dep and said "preserve a001-a005," so
the authored substance stayed verbatim rather than triggering a five-claim rewrite. And Phase F —
the actual `rm` of the `knowledge` directory — the operator deferred. The content is safe on the
remote; the local dir sits dormant, its working tree showing the moved files as deletions, waiting
for a manual decommission the operator wants to do deliberately (archive the remote too).

## Where things stand

The fold is done and green: `mix test` 360/0 including the 13 conformance fixtures now reading
`okf/conformance`, `cb.verify.collection okfx` and the schema clean, the OKF bundle tooling
(`validate`, `emit`) exit-0 against the relocated bundles, README links resolving, no structural
`knowledge:` ids left in the collection. `cb:a546` carries a completion-evidence entry recording
all of it, including the two deliberate non-actions. One repo, one CLAUDE.md discipline, no
`../knowledge` paths in code or config — which is what the fold was for.

## What the next session inherits

The `knowledge` repo still exists locally, decommission-pending — the one piece of `cb:a546` not
discharged, by operator choice. The plan's out-of-scope follow-ups are still live and unstarted:
the SessionStart hook + an `amieval/` root CLAUDE.md (the `cb:a543` family) that would make
session-start surfacing *structural* instead of procedural — the real fix for the a165 shape, which
the fold only sets the stage for; `okfx:a004` (compile `okf/CLAUDE.md` from the graph, which would
also retire the preserved `knowledge:a003` prose wart); and the cosmetic `mix knowledge.* → mix
okf.*` rename. The desk (`mix bs list unlinked tag:lifecycle:discrete`) still shows `cb:a546` until
the operator decommissions and discharges it.
