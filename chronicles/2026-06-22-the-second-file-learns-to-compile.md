# 2026-06-22 — The second file learns to compile

**Span:** 2026-06-22 — one focused thread, discharging `okfx:a004`
(continues [the extension comes home](2026-06-22-the-extension-comes-home.md)).
**Register:** chronicle (cb:a520) — narrative for the operator; the audit trail lives in
`okfx:c001`'s evidence, the `okfx:a004` materialization (`okf/todos.json` t0001), and this
session's verbatim log at `plans/okf-fold/sessions/2026-06-22-okf-claude-md-compile.jsonl`.

## Where things stood

The fold left `okf/` home in composable-beliefs but its `CLAUDE.md` was still hand-written. That is
the exact shape the house warns against: the previous chronicle noted that `okf/CLAUDE.md` carried
the `beliefs/`-guard as hand-stated prose, and that the framework `CLAUDE.md` does not work that way
— it *compiles* from the `cb:` graph, read-only, gated by `--check`. `okfx:a004` was the open
obligation to make the second file behave like the first. The prior session named it explicitly as
inherited work.

## The arc

The session-start discipline paid off immediately, the same way it did for the fold. The task prompt
cited the output-target contract as `cb:c061`, then `cb:c062`; the live graph said both were
superseded, the active node being `cb:c065` (the chain c060 → c061 → c062 → c063 → c065, each a
render-list maintenance bump as skills came and went). Trusting the graph over the prompt is the
whole doctrine, and here it was a concrete fork: author against c065's actual shape, not the
prompt's stale memory of it.

The real design question was not "how do I write a second contract" but "why does the generator
refuse a second contract." `mix cb.generate.claude_md` hard-enforces a *single* active
`output:claude-md` target and halts on `:multiple_targets`. The resolution was to notice the
enforcement is **per store, not per graph-of-graphs**: the generator reads one belief file at a
time. So the move was the same `--beliefs PATH` override that `mix bs`, `cb.import`, and
`cb.preflight` already carry — point the store at `okf/beliefs.json`, find the one okfx target
there, compile it. The no-arg invocation keeps compiling `cb:` from `beliefs/beliefs.json`; each
store still carries exactly one target. Eleven lines of generator change, consistent with every
other collection-override door in the codebase, rather than a new multi-target mode.

Authoring the contract was mechanical once the shape was clear: `okfx:c001`, an `output-target`
contract mirroring `cb:c065` — `output_path`, a `header_comment` carrying the title and intro, and
`render_sections` whose belief union equals the contract's deps. The hand-written file decomposed
into five sections; four became new claude-md convention beliefs (`okfx:a006-a009`, the same
`kind: convention` / `tags: [claude-md]` shape the `cb:` render beliefs use), and the fifth —
the `beliefs/` guard — was `okfx:a003` itself, rendered directly. That was the point of the whole
task: the guard stops being hand-copied prose and becomes a compiled view of the graph node that
owns it. The amieval root `CLAUDE.md`, freshly rewritten this same day, had already recorded the
principle out loud — "the framework and `okf/` CLAUDE.mds compile because they embed directives" —
so rendering the directive verbatim is the sanctioned design, not a workaround.

One honest wart got rendered into the output and left there deliberately. `okfx:a003`'s claim still
says `knowledge/beliefs/`, the old standalone-repo layout, where the live store is `okf/beliefs.json`.
Because a003 is now a render_section, that stale path compiles verbatim into `okf/CLAUDE.md` — a
title that says "okfx graph" over a body that says "knowledge/beliefs/". The fix is a supersession,
not an edit, and it belongs to the same `knowledge → okf` path migration that the fold deliberately
kept separate from the tooling rename. So rather than smuggle a five-word belief rewrite into a
machinery task, the staleness became its own desk item, `okfx:a010`, grounded on a003 and c001 and
tagged for that migration. The same boundary the fold drew around `mix knowledge.*` now holds for
the path prose.

The gate was the last piece. The recon said to "mirror how the cb: file is checked" — but the
surprise was that the `cb:` file *wasn't* checked by anything: no test, no CI step ran
`--check`. So the new `test/cb/generated_claude_md_test.exs` gates **both** files at once, reading
each store explicitly and comparing the compiled bytes to disk — the library-level equivalent of
`--check`, side-effect-free so it stays `async: true` rather than mutating global config mid-suite.
The okfx file got its drift gate and the framework file got the gate it had been missing.

## Where things stand

Done and green. `okf/CLAUDE.md` compiles from `okfx:c001` via
`mix cb.generate.claude_md --beliefs okf/beliefs.json`, read-only by the same header-comment-plus-`--check`
doctrine as the framework file. `mix test` 362/0 including the new dual gate and the 13 conformance
fixtures; `cb.verify.collection okfx` and both schema passes clean; both `--check` paths report up to
date. `okfx:a004` is discharged — materialized to `okf/todos.json` t0001 and closed — so the desk
(`mix bs --beliefs okf/beliefs.json list unlinked tag:lifecycle:discrete`) now shows only the three
genuine backlog items.

## What the next session inherits

The okfx desk: `okfx:a001` (pilot the CONVERT runbook on a real store), `okfx:a002` (the `threads:[]`
provenance convention), `okfx:a005` (port the conformance regen to a mix task), and now `okfx:a010`
(supersede a003's stale `knowledge/beliefs/` path and regenerate `okf/CLAUDE.md`). The broader
`knowledge → okf` migration the fold opened is still live: the cosmetic `mix knowledge.* → mix okf.*`
rename, and a010 rides alongside it. From the fold's own inheritance list, the `cb:a543` family — the
SessionStart hook that would make surfacing structural instead of procedural — remains the real fix
for the a165 shape; this session, like the fold, only sets the stage. And the `knowledge` repo is
still local, decommission-pending by operator choice.
