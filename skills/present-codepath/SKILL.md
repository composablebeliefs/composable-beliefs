---
name: present-codepath
description: Present an interactive, branching codepath from a codepath JSON file - resolve each step's literal anchor to a current path:line, narrate it, and stop at branch points for the reader to choose. Read-only.
---

Present an interactive codepath: lead a reader through real source files via
clickable `path:line` references, narrating each stop and pausing at branch points for
the reader to choose. The codepath file is pure data; this skill holds all the
interpretation logic. Read-only - this skill never edits source or the codepath file.

**Format authority (interim):** the standalone JSON shape this skill currently reads is
documented in `plans/cb-codepath/spec-notes.md`, carried over from the archived
standalone plugin repo - with one interim rename applied to the instance: the top-level
key is now `"codepaths"`. It is not a lasting format authority - plan-2 of
`plans/cb-codepath/` reauthors codepaths as cb collections, with the cb schema as the
single authority, and rewrites this skill against that schema.

## Input

`$ARGUMENTS` is `<file> [<codepath-id>]`:

- `<file>` - path to a codepath JSON file.
- `<codepath-id>` - which codepath in that file to present. If omitted, list the
  available `id` + `title` pairs and stop.

## Path resolution

A codepath's step `file` paths are written relative to some **base directory** the
author chose - usually the project root, or, when a codepath spans several sibling
repos, the directory that contains them. This skill does not assume any particular
layout:

1. Resolve `<file>` and step `file` paths against the **current working directory**
   first.
2. If `<file>` itself does not exist relative to cwd, or the `entry` step's `file` does
   not resolve, **ask the reader** which directory the paths should resolve from (the
   project root / the directory the instance's paths were authored against), then use
   their answer as the base for the rest of the run.
3. Do not hardcode or guess a project name or layout - derive the base from cwd or the
   reader's answer.

Launch the agent from that base directory when you can, so the editor host (e.g.
Zed-over-ACP) linkifies the emitted `path:line` refs against the same root and clicking
navigates correctly.

## Steps

1. Read `<file>` and parse the JSON (resolving its path per "Path resolution" above). If
   `<codepath-id>` is omitted or not found, list every codepath's `id` - `title`
   and stop.
2. Select the codepath by id. Begin at its `entry` step.
3. For the current step:
   a. Resolve the anchor: grep `file` for the **literal substring** `anchor` and take
      the `occurrence`-th match (1-based; default the first). Use a fixed-string search
      (`grep -nF`), not regex.
   b. If a match is found, emit one line: `` `file:line` - note `` (backtick the
      `file:line` so the host linkifies it; the reader clicks, the editor navigates).
   c. If no match is found, emit `! step <id>: anchor "<anchor>" not found in <file>`
      and continue - this is a maintenance signal that the codepath needs an edit,
      not a reason to stop.
4. Advance:
   - If the step has `choices`, emit each `label` as a numbered option and **stop**,
     waiting for the reader to pick. The reader's pick names the next step (`goto`);
     resume at step 3 with it.
   - Else if the step has `goto`, follow it automatically and repeat step 3.
   - Else the path ends; say so briefly.
5. Keep narration tight - the `note` plus your own one-line framing per stop. The value
   is the reader reading the real file, not a wall of agent prose.

## Rules

- Read-only - never modify the codepath file or any source it points at.
- Never hardcode a project name, repo, or directory layout - resolve from cwd, and ask
  the reader when paths do not resolve.
- Emit `file:line` exactly as resolved this run; never reuse a cached line number, and
  never invent a line for a missing anchor.
- Resolve anchors as literal substrings (fixed-string grep), never regex.
- Follow `goto` automatically; **always stop and wait at `choices`** - the human drives
  the branch. Do not auto-pick a branch.
- A missing anchor warns and continues; it is never a crash.

## next (assertions on - planned, do not half-wire)

The assertion gradient pairs each contract-grade stop with a predicate result; the
design is `plans/cb-codepath/plan-3-assertions-runtime.md` (named predicates routed by
contract per c037, invoked directly for pure predicates, via Tidewave federation only
when live app state is genuinely needed). Constraint preserved from the original design:
predicate evaluation is **inspection-only** (reads, never mutation). Wire it end to end
or leave it absent - never ship routing that does not resolve to a runnable predicate.
