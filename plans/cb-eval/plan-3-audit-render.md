# Plan 3 - `cb.render.audit`: the published audit tree

Render a verdict's full evidence tree as a **self-contained static HTML file** (and a
JSON twin) suitable for publishing beside a finding. This is the house signature
artifact: verdict at the root, deps walked to the leaf observations, every artifact
and evidence pointer visible - including the raw-log artifacts inside evidence
entries that `bs tree` currently elides - plus supersession and staleness state, so a
corrected finding *visibly wears* its correction.

**Status:** Proposed 2026-06-09. Nothing built.
**Date:** 2026-06-09
**Depends on:** plan-0 (vocabulary; renders any belief but is designed for verdicts); a real collection from plan-2 makes the acceptance fixture honest.
**Touches:** `lib/cb/render/audit.ex` (new: tree -> HTML/JSON); `lib/mix/tasks/cb.render.audit.ex` (new); reuse of the existing traversal (`bs tree`'s walker) and `CB.Display` where sensible; one embedded HTML template (no external CSS/JS assets, no CDN); tests with golden-file output.

## Context

`mix bs tree` is the audit walk, but it is terminal-bound, omits evidence-entry
artifacts (the raw-log pointer surfaces only in `show`), and requires Elixir. The
published artifact must be clickable by a reader with a browser and nothing else, and
must be regenerable byte-identically in CI so a post's tree can be gated against the
graph the same way CLAUDE.md is.

## Design

### Output

`mix cb.render.audit <belief-id> [--beliefs PATH|--collection NS] [--out FILE]
[--json] [--depth N]`

- **HTML (default):** one file, inline CSS, minimal inline JS (collapse/expand
  only; renders fully without JS). Root = the requested belief (typically a
  `kind:verdict` implication). Each node shows: id, type/kind badge, full claim,
  subjects, tags, artifact (as text; `https:` artifacts also link), and **every
  evidence entry with its detail, date, and artifact** - closing the `tree`/`show`
  gap. Status is loud: `superseded` nodes render struck with a link-line to the
  successor; nodes with superseded/retracted deps carry a `stale` badge
  (`--cascade` semantics applied at render time). A footer records: source
  collection + namespaces in the union, render date, the renderer version, and the
  graph file's content digest - the reader's reproducibility anchor.
- **JSON (`--json`):** the same tree as data (the HTML is a pure function of it),
  for anyone who wants to build their own viewer - the format is the offer.

### Determinism

Byte-stable output for a given graph + id + options (stable ordering, no
timestamps beyond the dated fields already in beliefs plus the explicit render-date
field, digest computed from canonical serialization). Golden-file tests pin it; a
`--check` mode (CLAUDE.md-style) lets CI gate a committed tree against the graph.

### What it is not

Not a site generator, not a dashboard, not interactive beyond collapse/expand. One
verdict, one file. Indexing trees into a published site is the eval repo's static
tooling, downstream of this artifact.

## Steps

1. Extract/reuse the tree traversal into a render-neutral structure (nodes +
   edges + status/staleness annotations), including evidence-entry artifacts.
2. JSON encoder over that structure; golden test.
3. HTML template + encoder; golden test; manual check in a browser at realistic
   depth (a verdict over 2 rulers x 4 runs with ~10 case primitives).
4. `--check` mode; CI example wiring (gate one committed fixture tree).

## Acceptance criteria

- `mix cb.render.audit sdl:a4 --collection sdl --out audit.html` produces one file
  that opens in a browser with no network access and walks verdict -> compound ->
  primitives -> evidence raw-log pointers, all visible.
- Superseding the fixture verdict and re-rendering shows the strike-through +
  successor link on the old node and the stale badge on its dependents - the
  correction protocol, visible to a reader.
- Re-render is byte-identical; `--check` fails when the graph moves under a
  committed tree.
- A non-Elixir reader test: someone unfamiliar with CB can answer "what evidence
  does this verdict rest on, and where are the raw logs?" from the HTML alone.

## Risks and non-goals

- **Scope inflation toward a viewer product.** Collapse/expand is the entire JS
  budget. Search, filtering, graph visualization: out, permanently or until a plan
  argues otherwise on mission grounds.
- **Depth blowups.** Verdicts in mature collections may transitively reach the
  methodology contracts and half the union. `--depth` defaults sane (the evidence
  chain, not the vocabulary closure); cross-namespace deps render as labeled leaf
  links by default rather than being walked.
- **Claim text is published verbatim.** The render is public; authors must already
  treat claims/evidence as publishable prose. Worth one line in the authoring
  skill notes, not a renderer feature.
- **Non-goal:** PDF/PNG export; theming; serving anything; rendering codepaths
  (covered by `cb.render.codepath`).
