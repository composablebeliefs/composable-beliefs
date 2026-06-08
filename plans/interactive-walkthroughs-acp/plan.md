# Interactive Code Walkthroughs over ACP

A persistent, refactor-tracking format for **agent-guided walkthroughs of the
codebase**: an author working with the agent to build the app records ordered,
branching "walk this code" paths to a data file; a later session loads that file
and *presents* it — emitting clickable `path:line` references that drive the
editor's viewport, narrating each stop, and offering branch points the reader
chooses. The static layer ships first; a deferred runtime layer (Tidewave) pairs
each stop with live values from the running app.

> Why ACP, not the TUI: the clickable `path:line` → jump-to-editor behavior needs
> an **editor host** that linkifies the reference and drives its viewport. Zed-over-ACP
> provides exactly that. The capability is host-bound, not format-bound — a browser
> rendering Markdown is sandboxed from the editor and cannot navigate it. This is the
> intended **usage split**: *author/dev the walkthrough in the TUI* (subscription
> pricing, high-token edit/compile/run work); *present it in ACP* (metered, but
> low-token — mostly read-file + emit-refs).

**Status:** Proposed 2026-06-08. Nothing built. Phase 1 is pure data + one skill, no new infra.
**Date:** 2026-06-08
**Depends on:** nothing for Phase 1. Phase 3 (runtime) depends on Tidewave + a booted `cb-dashboard`.
**Touches:** new `walkthroughs/` data dir (location TBD — see Open Questions); a new `present-walkthrough` skill; for Phase 3, `cb-dashboard/mix.exs` + `cb-dashboard/lib/cb_dashboard/endpoint.ex:63`.

## Context

The repo already ships a **prose** "guided tour" — `belief-collections/quickstart.md`
walks a newcomer through the belief graph with CLI commands. This plan does *not*
replace that; it adds a different artifact: an **interactive, editor-anchored**
walkthrough that leads the reader through the *actual source files* rather than code
blocks copied into a doc. Two properties make this worth a format of its own:

- **Refs can't silently fork.** A copied snippet in a wiki is stale the moment it's
  pasted. A `path:line` always opens current truth. (The line *number* drifts on
  refactor — addressed below by anchoring on symbols, not lines.)
- **The reader stays in the real file** — surrounding code, blame, jump-to-definition,
  the running app — instead of an amputated excerpt.

The "presentation is human-driven, not auto-advancing" property is a **feature, not a
limitation** for this use case: it is an audit/comprehension workflow for a person
co-authoring the app. The reader drives; the agent narrates and offers choices. That is
precisely what enables **branching** — a passive renderer could not offer a fork and
wait for a pick.

## Capability boundary (what ACP does and does not give)

| Capability | Available? | Mechanism |
|---|---|---|
| Clickable `path:line` that opens + scrolls the editor | **Yes** | Zed/ACP linkifies the pattern; *reader* clicks, *editor* navigates (pull, not push) |
| Agent narration + ordered steps + branch prompts | **Yes** | The agent emits text from the walkthrough file |
| Agent auto-advances / highlights a sub-range / tracks reader position | **No** | No control channel back to the editor; reframed here as the human-driven feature |
| Live runtime values paired with each step | **Deferred (Phase 3)** | Tidewave MCP eval into the running BEAM — a side channel, *not* driving the terminal pane |

The agent never drives the bottom terminal pane. In Phase 3 the pane simply runs
`mix phx.server`; the agent reaches the runtime through Tidewave's MCP eval tool.

## Design: the walkthrough file

A JSON file (per repo convention: JSON over YAML) holding one or more walkthroughs.
The critical decision: **anchors are symbols/snippets, not line numbers.** Line numbers
are a cached hint resolved at present-time; the durable key is a string the presenter
greps for. Refactors that move code don't break the walkthrough; only deleting/renaming
the anchored symbol does — and *that* surfaces as a clear "step N anchor not found"
signal that the walkthrough needs maintenance, rather than silent rot.

A walkthrough is a **DAG**, not a list (which mirrors this repo's own belief-graph
domain): steps carry optional `choices` that jump to other step ids.

```json
{
  "walkthroughs": [
    {
      "id": "belief-pipeline",
      "title": "The pipeline, data → render",
      "entry": "data",
      "steps": [
        { "id": "data",      "file": "composable-beliefs/beliefs/beliefs.json", "anchor": "^  {",                "note": "Raw data — each object is one belief (id, kind, claim, deps).",
          "choices": [ { "label": "How does raw JSON become a struct?", "goto": "from-map" },
                       { "label": "How is it rendered back out?",       "goto": "formatter" } ] },
        { "id": "from-map",  "file": "composable-beliefs/lib/cb/belief.ex",        "anchor": "def from_map",   "note": "Boundary: JSON map (string keys) → %Belief{}.", "goto": "store" },
        { "id": "store",     "file": "composable-beliefs/lib/cb/belief/store.ex",  "anchor": "def read",       "note": "Loads the whole graph off disk." },
        { "id": "formatter", "file": "composable-beliefs/lib/cb/belief/formatter.ex","anchor": "def table",     "note": "Renders beliefs to the terminal (ANSI)." }
      ]
    }
  ]
}
```

- `anchor` — a literal or regex the presenter resolves to a current line. First match wins; a step may add `occurrence: 2` if needed.
- `note` — the narration for the stop.
- `choices` — optional branch prompts (`label` shown to reader, `goto` is a step id). A step with neither `choices` nor `goto` ends that path.
- `entry` — the starting step id.

## Design: the `present-walkthrough` skill

A skill (`/present-walkthrough <id>`) so any later session presents without re-explaining.
The skill is thin; the data file is the source of truth. Behavior:

1. Read the walkthrough file; select the walkthrough by `<id>` (list available ids if omitted).
2. Starting at `entry`, for each step: grep `file` for `anchor` → current line; emit `file:line — note`.
3. Follow `goto` automatically; at a step with `choices`, emit the choices and **stop**, waiting for the reader to pick. The reader's pick names the next step.
4. If an anchor doesn't resolve, emit `⚠ step <id>: anchor "<anchor>" not found in <file>` and continue — a maintenance signal, not a crash.

The skill keeps **all** anchor-resolution logic; the JSON stays pure data, hand-editable
in the TUI.

## Runtime layer (Phase 3, deferred — do not half-wire)

The architecture is already favorable: `cb-dashboard` is Phoenix 1.7 + LiveView on
Bandit and depends on `{:cb, path: "../composable-beliefs"}` (`cb-dashboard/mix.exs:35`),
so `CB.Belief.Store`, the structs, and the materializer are **loaded inside the running
dashboard's BEAM**. Wiring:

1. Add `{:tidewave, "~> 0.4", only: :dev}` (pin at implementation time).
2. Mount it in the dev-only block at `cb-dashboard/lib/cb_dashboard/endpoint.ex:63` (`if code_reloading? do`).
3. Register the Tidewave MCP server (Claude only connects MCP at startup — restart after).
4. Run `mix phx.server` in the bottom pane.

Then a step can carry an optional `eval` (an inspection expression). At present-time the
skill calls Tidewave's eval and pairs the static ref with the live value:

> Step `store` — `CB.Belief.Store.read/0` at `store.ex:13`.
> Live: `CB.Belief.Store.read() |> length()` → **103 beliefs**; first is `%CB.Belief{kind: …}`.

This is REPL-augmented guided reading, **not** a breakpoint debugger (no execution halt).
That is the better primitive here — inspect any expression at the narrated moment, with
none of the breakpoint-coordination cost. **Constraint:** `eval` expressions are
**inspection only** (reads), never mutation; enforce by review convention and document it
in the skill's contract. A fourth visualization surface comes free: the dashboard itself
renders the belief graph, so a wired session triangulates editor (code) + agent
(narration/branching) + Tidewave (live values) + dashboard (rendered state).

## Phasing

- **Phase 1 (data + skill, usable alone):** author the walkthrough JSON seeded with `belief-pipeline`; write `present-walkthrough` with branching. Anchors may start as line numbers but should move to symbols immediately.
- **Phase 2 (refactor-resilience):** anchor resolution by symbol/regex; the "anchor not found" maintenance signal; a second walkthrough (e.g. the dashboard LiveView flow) to prove the format generalizes.
- **Phase 3 (runtime, stretch):** Tidewave wiring; optional `eval` per step; inspection-only guard. Ship as a documented `## next` in the skill until deliberately built — do not half-wire.

## Acceptance criteria

- `/present-walkthrough belief-pipeline` in an ACP session emits ordered `path:line — note` stops; clicking a ref navigates Zed's viewport.
- A branch step stops and waits; the reader's pick resumes at the chosen step.
- Renaming a non-anchored symbol and moving the anchored code does **not** break the walkthrough (line re-resolves); deleting the anchor yields a clear maintenance warning, not a silent wrong line.
- The JSON is authored/edited in the TUI and presented unchanged in ACP — the dev/present split holds end to end.
- (Phase 3) A step with `eval` shows a live value from the running dashboard alongside its static ref.

## Risks and non-goals

- **Line drift** → mitigated by symbol anchors (Phase 2); the whole reason not to ship raw line numbers as truth.
- **Terminology collision** with the existing prose "guided tour" (`quickstart.md`) → call these **walkthroughs**, not tours; this artifact *operationalizes* the prose tour into an interactive, editor-anchored, refactor-tracking form, it does not replace it.
- **Tidewave evaluates arbitrary code in the running app** → restrict `eval` to inspection; never mutation.
- **Non-goal:** a real breakpoint debugger. Explicitly out — REPL-style inspection is the chosen primitive.
- **Non-goal:** agent-driven auto-advance or sub-line highlighting. The human-driven model is the design, not a gap to close.

## Open questions for the author

1. **Home for the walkthrough data.** Options: (a) `belief-collections/` next to `quickstart.md` (teaching material lives there per principle #7); (b) a top-level `walkthroughs/`; (c) per-subsystem files. Where does the canonical walkthrough JSON live, and is it one file or one-per-subsystem?
2. **Anchor syntax.** Literal-substring only, or allow regex + `occurrence:`? Regex is more precise but harder to hand-author in the TUI.
3. **Skill home.** Project-level `.claude/skills/` in which repo (`composable-beliefs`? a top-level `amieval` skill?), given the walkthrough spans `composable-beliefs` *and* `cb-dashboard`?
4. **Phase 3 appetite.** Ship Phases 1–2 and stop (static, branching, refactor-tracking), or commit to the Tidewave runtime layer up front?
5. **Branch model.** Linear-with-optional-detours, or full DAG with re-convergence (multiple steps `goto` the same node)? The schema supports both; which do walkthroughs actually use?
