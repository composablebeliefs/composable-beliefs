# ADOPT — bootstrapping a repo onto the Knowledge methodology

You are an agent told: *"adopt this methodology for this repo."* Work through the steps.
**Each mutating step ends in a gate you run — do not proceed past a failing gate.** The
tooling lives in the `composable-beliefs` repo (the OKF integration layer beside this
`okf/` directory); run these from the repo root against the target bundle path:

```
mix okf.manifest <root>   # (re)generate <root>/manifest.json
mix okf.validate <root>   # exit 0 = pass; prints FAIL: lines + a count
```

`mix okf.validate` is the source of truth for "did that step actually work." Treat
a non-zero exit, or any `FAIL:` line, as a stop condition. `WARN:` lines are advisory.

## 0. Read the spec
Read in order: [`standard/KNOWLEDGE.md`](standard/KNOWLEDGE.md), [`standard/types.md`](standard/types.md),
[`standard/frontmatter.md`](standard/frontmatter.md), [`standard/tiers.md`](standard/tiers.md). Skim
[`demo/`](demo/) for a worked example and [`meta/`](meta/) for this repo's design record.

**Gate (self-check):** before continuing, you must be able to answer without re-reading:
(a) which field is the relevance hook, (b) the boundary test that promotes a doc to the
CB tier, (c) what `manifest.json` is for. If you can't, re-read.

## 1. Decide the bundle root
Pick where knowledge lives in the target repo — typically `knowledge/` or `docs/`. This
is the **bundle root** (`<root>` below). No tooling is copied into the target repo: the
`mix okf.*` tasks in the `composable-beliefs` repo operate on any bundle path.

**Gate:** from the `composable-beliefs` repo root, `mix help okf.validate` prints usage
(confirms the tasks are available).

## 2. Create the skeleton
```
<root>/
├── index.md            # type: index — what this repo's knowledge covers
├── <domain>/           # one folder per natural domain
│   └── index.md
└── meta/               # threads, plans, analyses, positions about the repo itself
    └── index.md
```
Copy [`templates/`](templates/) as starting points. **Fill every `<placeholder>`** —
unfilled `<...>` in frontmatter is a hard failure. Default every doc to the **OKF floor**
(omit `tier`); reach for `tier: cb` only when [`standard/tiers.md`](standard/tiers.md)'s boundary
test trips (and then the doc needs an `id`).

**Gate:**
```
mix okf.manifest <root> && mix okf.validate <root>
```
Must exit 0. Fix every `FAIL:` (missing `type`, weak `description`, leftover placeholder,
broken link) before continuing.

## 3. Author the entry index
`<root>/index.md`'s `description` is the relevance hook for the **whole repo's
knowledge** — one line that tells a fresh agent whether this repo is relevant to its task.
Link from it to each domain's `index.md`.

**Gate:** re-run step 2's command (exit 0). Then confirm `manifest.json`'s first entry
for `index.md` has a `description` you'd be willing to route on.

## 4. Backfill initial content
Populate domains with real `concept`/`reference`/`source` docs (not just indexes). Every
new or changed file means a regenerate + validate.

**Gate (the loop):** after any edit, run
`mix okf.manifest <root> && mix okf.validate <root>` until it exits 0 with zero `FAIL:`.

## 5. The standing workflow (day-to-day, after adoption)
- **End of a working session** → write one `type: thread` doc in `meta/`; its
  `description` is the outcome, linking to what it produced. (Stops ad-hoc threads.)
- **New external input** → capture as `type: source` (immutable), then **update the
  relevant `type: concept` docs** — don't let sources pile up unsynthesized.
- **A settled stance** → `type: position`; consider CB-tier promotion.
- **After any change** → `mix okf.manifest <root> && mix okf.validate <root>`, exit 0.
- **Wire it so it can't drift:** add `mix okf.validate <root>` to CI or a pre-commit
  hook. (`mix okf.manifest <root> --check` alone catches only manifest staleness;
  `mix okf.validate` catches that *and* schema/link breakage.)

## 6. Done when (acceptance test)
Adoption is complete only when **all** hold:
1. `mix okf.validate <root>` exits 0 (no `FAIL:`).
2. `<root>/manifest.json` exists and lists every doc with a real `description`.
3. Pick **three** task-shaped questions a future agent might ask this repo. Each must be
   answerable by reading `manifest.json` + at most two docs it points to. If not, the
   `description`s are too vague — fix them (not the bodies) and re-run.
4. Report to the human: doc counts by `type`, which docs went CB-tier and why, and the
   entry `index.md` description.
