# Format notes carried from the archived code-walkthrough repo

> Carried forward verbatim (2026-06-09) from `amieval/code-walkthrough` SPEC.md as
> input to plan-1 of this set. **Not a format authority** - the cb schema is the
> single authority; plan-2 reauthors codepaths as cb collections. Terminology is
> pre-rename ("walkthrough" = what this set calls a codepath).

# Walkthrough format spec

A walkthrough file is JSON (per the repo-family convention: JSON over YAML). It is
**pure data** - all interpretation logic lives in the `present-walkthrough` skill, so
the file stays hand-editable in a plain editor. This is the single source of truth for
the format; instances conform to it and define nothing themselves.

## Top level

```json
{ "walkthroughs": [ <walkthrough>, ... ] }
```

A file holds one or more walkthroughs. The presenter selects one by `id`.

## Walkthrough

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Stable identifier, named on the command line to select this walkthrough. |
| `title` | yes | Human-readable name shown when the walkthrough starts or when ids are listed. |
| `entry` | yes | The `id` of the step to start at. |
| `steps` | yes | The array of steps. Order in the array does not drive presentation - `entry` + `goto` + `choices` do. |

## Step

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Stable identifier, unique within the walkthrough; the target of `goto`/`choices`. |
| `file` | yes | Path to the source file, **relative to the base directory** the walkthrough's paths are authored against (see the `present-walkthrough` skill's path-resolution rules). |
| `anchor` | yes | A **literal substring** the presenter greps for to resolve the current line. |
| `occurrence` | no | 1-based index selecting the Nth match of `anchor`. Defaults to `1` (first match). |
| `note` | yes | The narration emitted for this stop. |
| `goto` | no | The `id` of the next step, followed automatically. |
| `choices` | no | Branch prompts; presented, then the presenter stops and waits for the reader to pick. |

A step with neither `goto` nor `choices` ends that path.

### `choices`

```json
"choices": [
  { "label": "How does raw JSON become a struct?", "goto": "from-map" },
  { "label": "How is it rendered back out?",        "goto": "formatter" }
]
```

Each choice has a `label` (shown to the reader) and a `goto` (the step `id` to resume
at). The reader's pick names the next step.

## Anchor rules

- **Literal substring only - no regex.** Keeps anchors trivial to hand-author and to
  reason about. Make an anchor precise by including enough surrounding text (e.g.
  `def from_map(` with the paren, not just `from_map`), and disambiguate repeats with
  `occurrence`.
- **First match wins** when `occurrence` is omitted; otherwise the `occurrence`-th
  match (1-based).
- The resolved **line number is never stored** - it is recomputed at present-time.
  Moving the anchored code does not break the walkthrough; the line just re-resolves.
- **A missing anchor is a maintenance signal, not a crash.** If `anchor` is not found
  in `file`, the presenter emits a clear warning naming the step and continues. That
  is the cue that the anchored symbol was deleted or renamed and the walkthrough needs
  an edit.

## Branch model

A walkthrough is a **DAG**: any step may `goto` any step `id`, including one already
reachable from elsewhere (**re-convergence** is allowed). The presenter just follows
`goto` and stops at `choices`; cycles should be avoided by authors (the format does
not enforce acyclicity, but a cyclic path will loop the reader).

## Deferred: runtime values (Phase 3)

A future revision adds an optional `eval` field per step carrying an inspection
expression, paired at present-time with a live value read from the running app via an
MCP eval tool. It is **not** part of this spec version; see the `present-walkthrough`
skill's `## next`. When added, `eval` is **inspection-only** (reads, never mutation).
