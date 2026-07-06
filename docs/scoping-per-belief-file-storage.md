# Scoping: converting the belief graph from one flat file to belief-per-file

Status: scoping report, 2026-07-06. No code, graph, or `beliefs/` content was
changed in producing this report.

## Headline

The conversion is already decided, designed, and partially validated inside the
graph itself. cb:b554 (attestation, 2026-06-25) records the decision - one JSON
file per node at `beliefs/<ns>/<local>.json` - and six active prescriptions
(cb:b555 through cb:b560) carry the dep-chained implementation plan, grounded in
a discarded worktree spike that proved the read path loads byte-identically and
passes the schema gates. The deliberation record is
`beliefs/nursery/per-belief-files.md` (planted).

So the scoping question is not "what design" but "what remains, how big is it,
and what did the planted plan miss". Short answer: the code work is small and
low-risk (the store is a near-sole I/O chokepoint, ~45 lines of `Store` plus
three bypass readers), the migration itself is mechanical, and the real cost
sits in the tail: collection-registry semantics, the codepath collection whose
anchors point into `beliefs/beliefs.json`, the self-description sweep
(CLAUDE.md, docs, skills), and a handful of semantic decisions (ordering,
atomicity, path convention) that the prescriptions name but do not settle.

Estimate: roughly 3 to 5 focused sessions. Steps 1-3 are ordinary code PRs that
change nothing on disk under `beliefs/`; step 4 (the split) and step 6 (graph
supersessions and regenerated surfaces) modify `beliefs/` and therefore need
explicit operator authorization under the Data Protection rule.

## Current state (verified this session)

- `beliefs/beliefs.json`: one JSON array, 248 beliefs (206 active, 41
  superseded, 1 retracted), ids cb:b098 through cb:b587, ~496 KB.
- Two more single-file collections live in this repo and are *not* targets of
  the split: `okf/beliefs.json` and `codepath/beliefs.json`. External
  collections live outside this repo behind a registry
  (`collections.json`: namespace -> relative path to a `beliefs.json`).
- All belief I/O funnels through `CB.Belief.Store.read/0` and `Store.write/2`
  (`lib/cb/belief/store.ex`, 44 lines), which resolve the path via
  `CB.Config.beliefs_path/0` (app env > `CB_BELIEFS` > default) and write
  atomically via tmp+rename (`CB.JSON.write_atomic_raw/2`). Roughly 40 call
  sites across the mix tasks and library use `Store.read`/`Store.write`.
- Exactly three readers bypass the store, as cb:b555 records:
  `lib/cb/codepath/predicates.ex:90`, `lib/cb/belief/edit_pairs.ex:21`, and the
  race-guard re-read in `lib/cb/belief/adjudication.ex:136`.
- Two more path-parameterized readers exist that cb:b555 does not name:
  `CB.Collection.load/2` (`lib/cb/collection.ex:145`) and
  `Mix.Tasks.Cb.Import.Eval.read_collection/1`
  (`lib/mix/tasks/cb.import.eval.ex:146`). Both decode an arbitrary
  collection's `beliefs.json` by explicit path and expect a JSON array.
- Baseline: `mix test` green (407 tests, 0 failures); `mix bs stats` healthy.

## The settled plan (cb:b554-b560), sized

The six prescriptions, in dependency order, with what each takes:

1. **cb:b555 - centralize I/O.** Route the three bypass readers through
   `Store.read`. Small but not purely mechanical: `EditPairs` and
   `Codepath.Predicates` work on raw decoded maps (string keys), while
   `Store.read` returns `%Belief{}` structs, so those call sites adapt to
   struct access (or `Belief.to_map/1`). The adjudication re-read takes an
   explicit path for tests, so `Store.read` grows an optional path argument
   mirroring `Store.write/2`. Half a day including tests. This step is pure
   refactor - safe to land first and independently.

2. **cb:b556 - directory-aware read.** When the configured graph location is a
   per-belief directory, glob `<ns>/<local>.json` and parse each; keep the
   single-file array as the fallback so unsplit collections (okf, codepath,
   external ones) keep working unchanged. Prototype-proven at ~25 lines.
   Half a day including tests. Two decisions to settle here (see "Decisions"
   below): what the configured path points at, and what order the loaded list
   carries.

3. **cb:b557 - per-file write.** `Store.write/2` currently rewrites the whole
   array; per-file it must diff the incoming list against the on-disk state:
   write changed or new nodes, delete removed ones (deletion effectively only
   matters for tests and future compaction - the live graph never removes
   nodes, it supersedes them). Each file written via the existing tmp+rename
   helper. This is the step with the real design content - the atomicity
   decision cb:b557 explicitly leaves open. About a day including tests.

4. **cb:b558 - one-time migration task.** A mix task (e.g.
   `mix cb.migrate.split`) that reads the array, writes each node as canonical
   `Belief.to_map/1` JSON to `beliefs/cb/<local>.json`, removes
   `beliefs/beliefs.json`, and verifies the round trip: directory load equals
   the prior single-file load, `mix cb.verify.schema` and
   `mix cb.generate.claude_md --check` green. Dry-run by default, `--write` to
   apply, matching the house style of the other write doors. Half a day. The
   actual execution against `beliefs/` is gated on operator authorization and
   should land as a single commit (see "Operational notes").

5. **cb:b559 - simplify `_keys`.** The `_keys` MapSet on `CB.Belief` exists to
   keep whole-array rewrites byte-stable so untouched records do not churn in
   git; per-file writes make that rationale moot. What survives is
   absent-vs-null round-trip fidelity. Mostly a doc/rationale trim plus
   possibly narrowing the mechanism; a couple of hours, rides along with
   step 3.

6. **cb:b560 - self-description sweep.** Regenerate CLAUDE.md, revise every
   surface that says the graph is one JSON file, and supersede cb:b112 (the old
   per-entity-files rejection) with cb:b554. Note CLAUDE.md is *generated from
   the graph*, so the "(`beliefs/beliefs.json`)" text in it traces to belief
   claims (cb:b454 among them) - updating it means superseding those beliefs
   through the sanctioned write flow, not editing prose. This step is graph
   writes plus a docs sweep; a session of its own once the code is landed.

## What the planted plan missed (the delta this scoping adds)

These are real work items not covered by cb:b555-b560:

- **`CB.Collection.load/2` and the registry convention.** The registry maps
  namespace -> path-to-`beliefs.json`, and `Collection.load` reads that path
  directly, expecting an array. Once `cb:` is split, its registry entry (and
  any future split collection's) must resolve to a directory. Recommendation:
  extract one shared "load a collection from a file or a per-belief directory"
  function and have both `Store.read` and `Collection.load` call it, so the
  layout knowledge lives in exactly one place. Same treatment for
  `cb.import.eval`'s `read_collection/1`. Without this, `mix
  cb.verify.collection` and the external-collections workflow break the moment
  the split lands. (+ a few hours, belongs inside step 2.)

- **The codepath collection breaks and must be re-authored, not just fixed.**
  `codepath/beliefs.json`'s data stop anchors
  `code:beliefs/beliefs.json#"id":@1` and its claim narrates "The whole graph
  is this one file." After the split the file does not exist:
  `mix cb.verify.codepath` fails on anchor resolution and the tour's opening
  claim is false. The store stop's anchor (`code:lib/cb/belief/store.ex#def
  read do`) likely survives, but its claim ("decodes the JSON array") goes
  stale too. This means belief writes in the `codepath:` namespace
  (supersessions through the write flow) plus re-anchoring - fold it into
  step 6 or schedule it immediately after step 4. (+ half a day.)

- **Ordering is a semantic change, not a no-op.** The current array is *not*
  id-sorted (verified this session) - it carries append/mutation order. The
  planned directory read is "sorted by id", so `mix bs list`, rendered
  surfaces, and any order-sensitive consumer see a reordering after the split.
  The prototype's byte-identical claim holds for canonical per-node
  serialization, not for aggregate order. Also: locals are 3-digit today
  (b098-b587); plain lexical sort misorders once serials reach 4 digits
  (b1000 sorts between b099 and b101). Decide now: declare id order canonical
  and sort *numerically* by serial, or preserve stored order via an explicit
  index. Recommendation: sorted-by-numeric-serial as the new canonical order -
  order was never load-bearing in the schema, and deriving it aligns with the
  anti-digest principle. Nail this in step 2 and state it in the migration
  task's verification.

- **Atomicity strategy needs an actual decision (cb:b557 lists options).**
  A supersession becomes two file writes (successor written, predecessor
  status-flipped) instead of one atomic array rewrite. At local single-writer
  scale a crash between the two is recoverable (`git status` shows the torn
  pair; re-run or `git restore`). Recommendation: per-file tmp+rename per node
  (reusing `write_atomic_raw`), ordered so the new node lands before the
  predecessor flips - a crash then leaves a duplicate-claim conflict the
  preflight tooling already detects, rather than a dangling reference. The
  temp-dir directory-swap variant buys little here and complicates the
  common single-node append. Document the choice in the module doc and in the
  evidence appended to cb:b557.

- **Tests.** Existing tests mostly seed temp single-file graphs and keep
  passing through the fallback - good. New coverage needed: directory read,
  per-file write diffing (add/change/delete), migration round-trip, and the
  mixed case (directory graph + single-file dependency collection in one
  union). Two assertions change meaning: `test/cb/config_test.exs:40` pins the
  default path suffix, and `test/cb/generated_claude_md_test.exs` parametrizes
  over `beliefs/beliefs.json` - both follow whatever path convention step 2
  picks.

- **Concurrency payoff worth recording.** cb:b538's hazard - a mid-session
  commit staging the whole graph file sweeps another session's in-flight
  writes into a torn commit - is largely dissolved by per-file storage for
  non-overlapping mints: sessions staging disjoint `beliefs/cb/*.json` files
  no longer sweep each other. That is evidence to append to cb:b538 when the
  migration lands, not a reason to skip its gate discipline (overlapping
  writes to the same node still race).

## Decisions to settle before or during step 2

1. **Path convention.** Does `CB.Config.beliefs_path/0` keep returning
   `.../beliefs/beliefs.json` with the store falling back to a sibling
   `cb/` directory, or does it return the collection directory (`.../beliefs`)
   with the store detecting file-vs-directory? Recommendation: the configured
   path names the collection root (directory), detection by `File.dir?/1`;
   a path ending in `.json` stays a single-file collection. This keeps
   `--beliefs PATH` and `CB_BELIEFS` working for both layouts with no new
   flags.
2. **Canonical order** (numeric-by-serial recommended, above).
3. **Filename mapping.** `cb:b554` -> `beliefs/cb/b554.json` - namespace from
   the directory, local part as filename. All current locals are safe
   filenames; state the rule so future namespaces stay within it.
4. **What stays put.** `beliefs/manifest.json`, `beliefs/todos.json`,
   `beliefs/nursery/`, `beliefs/archive/` are untouched by the split.

## Suggested sequencing

1. PR 1 (no graph changes): step 1 + step 2 + the shared collection loader.
   Everything still reads the single file via fallback; tests prove the
   directory path against fixtures.
2. PR 2 (no graph changes): step 3 + step 5. Writes still target the single
   file until the split exists on disk.
3. Migration commit (authorized, single commit): run `mix cb.migrate.split
   --write`, gates green against the staged tree per cb:b538 discipline,
   committed alone so the 248-file rename-shaped diff is not entangled with
   code.
4. Follow-up session: step 6 (CLAUDE.md/docs/skills sweep, supersede cb:b112
   and the stale-path beliefs, close b555-b560 with evidence) plus the
   codepath re-authoring.

## Operational notes

- **Authorization gates.** Steps 1-3 touch only `lib/` and `test/`. The
  migration (step 4) and the graph writes in step 6 modify `beliefs/` and mint
  through the write doors - both need explicit operator authorization per the
  Data Protection rule. This report deliberately performs neither.
- **Provenance.** Historical `commit:` artifacts and prose references to
  `beliefs/beliefs.json` at old SHAs remain resolvable through git history;
  only working-tree `code:` anchors (the codepath item) need re-authoring. No
  history rewriting is involved anywhere in this plan.
- **Prescription bookkeeping.** As each of cb:b555-b559 lands, append evidence
  via `mix cb.evidence` (authorized) rather than leaving the desk stale;
  cb:b560 closes the arc by superseding cb:b112 exactly when the claim becomes
  true on disk - the ordering cb:b554 was explicit about.
