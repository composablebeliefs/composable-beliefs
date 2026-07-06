# Testing review: this repo against matklad's testing philosophy

Date: 2026-07-06

An assessment of the test suite against two essays by Alex Kladov (matklad):

- [Unit and Integration Tests](https://matklad.github.io/2022/07/04/unit-and-integration-tests.html) - replaces the unit/integration split with two orthogonal axes: **purity** (how much generalized I/O a test performs) and **extent** (how much of the codebase it exercises). Prescription: optimize purity ruthlessly, accept whatever extent falls out naturally, never shrink extent artificially with mocks.
- [How to Test](https://matklad.github.io/2021/05/31/how-to-test.html) - the quality of a test suite is measured by how easy it makes changing the software. Test **features, not code** (the "neural network test": would the suite survive the implementation being swapped for an opaque black box?); minimize test friction with a single `check` function per feature; prefer data-driven and expect/golden tests; separate computation from I/O so big-extent tests stay fast; automate every project invariant as a test.

## Current state

- 465 tests across 39 files (~6,400 test lines over 72 lib files), finishing in ~1.4s, 35 of 39 files `async: true`.
- Zero mocking - no Mox, no meck, no hand-rolled test doubles anywhere in `test/`.
- All file I/O in tests goes through ExUnit's `@moduletag :tmp_dir` (hermetic, per-test directories), except two files that shell out to `git` against the ambient repo.
- CI (`.github/workflows/composable-beliefs.yml`) runs compile with warnings-as-errors, the suite, `cb.verify.schema`, `cb.verify.commits`, and the generated-docs freshness gates.

## Where the suite already embodies the philosophy

The suite is unusually well aligned. Most of matklad's positive prescriptions are already standing practice here:

1. **Purity is near the bottom of the impurity ladder.** Almost every test is single-threaded pure computation over in-memory `%Belief{}` fixtures (`graph_test`, `filter_test`, `conflict_test`, `contract_test`, the mix-task `plan/5` tests). Where the filesystem is genuinely the subject (`store_test`, `collection_test`), tests use tmp_dir - impure but hermetic and deterministic. Result: 465 tests in 1.4s, and flakiness is structurally impossible for the bulk of the suite.

2. **Extent is accepted naturally, never mocked down.** Tests exercise the real `Store`, `Graph`, `Contract` interpreters, and `Materializer` together. Nothing stubs an internal module to isolate a "unit". This is exactly the essay's "don't reduce extent artificially" rule.

3. **Expect/golden tests exist and have an update mode.** `render/audit_test.exs` compares JSON and HTML renders against committed goldens and regenerates them with `GOLDEN_UPDATE=1` - textbook expect-testing, including the byte-identical re-render determinism check.

4. **Externalized, data-driven test corpora.** `okf_conformance_test.exs` walks `okf/conformance/fixtures/{valid,invalid}` and asserts the validator's output equals the normative `expected/<name>.json` - matklad's "externalized tests" pattern exactly. Codepaths go further: `mix cb.verify.codepath` runs a data collection as a test suite, i.e. test suites themselves are data.

5. **"Automate everything as tests."** `generated_claude_md_test.exs` is a drift gate for every graph-compiled CLAUDE.md; `schema_contracts_test.exs` loads the live graph and verifies the code against the graph's own schema contracts (the contract is the SSOT, the code is checked against it). CI adds the provenance-loop and freshness gates. These are precisely the "not-tests-but-run-as-tests" invariants the essay recommends.

6. **Functional core, imperative shell - partially.** The write-flow tasks expose pure planning functions (`Supersede.plan/5`, `Import.namespace_violations/2`) tested in memory, and `CB.Belief.Formatter` returns line lists rather than printing. The architecture largely already separates computation from I/O, which is why the suite is fast.

## Where it diverges, and what to adjust

Ordered by how much each matters.

### 1. The user-facing feature surface is untested (the one big gap)

Both essays converge on the same test: does the suite exercise *features* at the boundary a user sees? Here it mostly does not:

- **`mix bs` (lib/mix/tasks/bs.ex, 570 lines) has zero tests.** This is the primary query interface, named first in CLAUDE.md. Its flag parser (`extract_flags`, `resolve_since`), command dispatch, the bare-id fallback (`mix bs b029` behaving as `show`), and every `cmd_*` renderer are uncovered.
- **No test invokes `run/1` of any of the 23 mix tasks.** The tested surface is internal helpers (`plan/5`, `namespace_violations/2`). Those tests are good functional-core tests, but they are coupled to internal function names - rename `plan/5` during a refactor and tests break even though `mix cb.supersede` still works perfectly. That is exactly the ossification "How to Test" warns about. They also leave the shell layer (arg parsing, dry-run-by-default, `--write` gating, exit codes, printed output) unverified - and the shell layer *is* the feature.

**Root cause is a design obstacle matklad names explicitly:** `System.halt` appears at ~60 call sites across the tasks (9 in `bs.ex` alone). A function that halts the VM cannot be called from a test, so `run/1` is structurally untestable in-process. The fix is the same move the codebase already made for `Formatter`:

- Refactor each task to a pure core with the shape `argv, graph -> {output_lines, exit_status}` (or `{:ok, lines} | {:error, lines}`), with `run/1` reduced to reading the store, calling the core, printing, and halting. No behavior change; just moving the `IO.puts`/`System.halt` to the rim.
- Then add **one `check` function** (the essay's central idiom) in `test/support/`:

  ```elixir
  # conceptually:
  check_bs(graph_fixture, ~w(list prescription -v), expect: golden("bs_list_verbose.txt"))
  check_task(Cb.Supersede, graph_fixture, ~w(cb:a100 --by cb:a200), exit: 0, expect: golden(...))
  ```

  Data-driven (argv in, text out), golden-backed, and it passes the neural-network test: the entire implementation behind the CLI could be rewritten and the suite would still be valid. Purity stays maximal because the graph fixture is in-memory or tmp_dir - extent grows to cover dispatch, filtering, formatting, and store round-trips in one test, which is exactly what the purity/extent framing says to want.

### 2. `CB.Belief.Formatter` (319 lines, pure) is untested - the cheapest win

It already returns lists of strings, so golden tests cost almost nothing and would pin the `bs` output format independently of item 1. Reuse the `assert_golden`/`GOLDEN_UPDATE=1` helper from `audit_test.exs` - and since two files now need it, promote that helper into `test/support/`.

Other pure, untested modules worth covering opportunistically: the four `Contract.*` interpreters are only tested indirectly (via `contract_test`'s checker and the dogfooded `schema_contracts_test`), `CB.Belief.EditPairs`, `CB.Codepath.Predicates`, `CB.Json`, and `CB.Okf.Emit`/`Frontmatter` (the latter partially covered via `okf_test` and the conformance corpus).

### 3. Test friction: every file hand-rolls its own belief fixture

`node_map/2`, `belief/2`, `spec/1`, inline maps - at least a dozen slightly different fixture builders across the suite. Each is small, but the divergence means writing a new test starts with re-deriving the minimal valid belief shape. matklad's point: friction, not coverage, is what kills testing in practice. Adjustment: one shared builder in `test/support/` (note `mix.exs` already declares `elixirc_paths(:test)` to include `test/support` - the directory just doesn't exist yet):

```elixir
CB.Fixtures.belief("cb:a100", type: "prescription", deps: ["cb:a001"])
CB.Fixtures.graph([...])   # list of specs -> [%Belief{}]
```

Keep it a data builder, not a DSL - the essays are explicit that fluent test frameworks are a bad trade.

### 4. Two tests depend on the ambient git repo (the only real impurity)

`commit_locator_test.exs` and `cb_todo_close_test.exs` run `git rev-parse HEAD` against the working checkout. That is two rungs up the impurity ladder (multi-process + dependent on uncontrolled external state): they fail in a non-git context (tarball, shallow/partial clone oddities) and their inputs change with every commit. Adjustment: `git init` a throwaway repo inside `tmp_dir` with one synthetic commit, and resolve against that. Still multi-process, but hermetic and deterministic - and the parse-level tests in the same files are already pure and stay as they are. Tag the process-spawning tests (`@tag :subprocess`) so the pure majority is separable if it ever matters.

### 5. The conformance gate can silently skip

`okf_conformance_test.exs` passes vacuously if `okf/conformance/` is absent. The corpus is an in-repo asset, so absence is corruption, not an environment condition - assert the directory exists (and that the fixture count is nonzero) instead of skipping. A gate that can quietly not run is the failure mode expect-style suites must avoid.

### 6. `async: false` islands trace to process-global config

Four files serialize because they mutate the `:cb` app env / `CB_BELIEFS` OS env (`config_test`, `materializer_test`, `import_eval_test`, `codepath/assertions_test`). `config_test` legitimately tests that global surface. The other three only need a beliefs path; threading it as an explicit parameter (most of the internals already accept one) removes the global write and lets them run async. Minor at 1.4s total, but it is the purity axis applied to shared mutable state.

### 7. Not present, and mostly fine to defer

- **Property-based testing**: no StreamData. The graph algorithms are natural targets - `resolve_id` (bare vs namespaced), cycle termination in traversals, supersession-chain invariants (acyclicity, forward-only linking, `status` transitions matching the b053 state machine), `Filter.parse_args` round-tripping. One dev-only dep, a handful of properties over the same in-memory fixtures. Worthwhile, second-tier.
- **Coverage marks**: the codebase has few "invisible branch taken for the right reason" situations; the bare-id dispatch fallback in `bs` is the one spot a mark would earn its keep once item 1 lands. Skip until then.
- **Slow-test visibility / timing discipline**: moot at 1.4s; ExUnit's `--slowest` exists if it ever regresses.

## Suggested order of work

1. Halt-free cores for the mix tasks + a `check` helper + golden CLI tests, starting with `bs` (closes the features-not-code gap; everything else layers on it).
2. Golden tests for `Formatter` and promotion of `assert_golden` to `test/support/` (immediate, independent of 1).
3. `CB.Fixtures` shared builder in `test/support/`; migrate files opportunistically as they are touched (never a big-bang rewrite - the essays would call that churn).
4. Hermetic git fixtures for the two ambient-repo tests.
5. Corpus-presence assertion in the OKF conformance gate.
6. StreamData properties for `Graph`/`Filter`/supersession invariants.

## Verdict

On matklad's own scoring axis - "how easy does the suite make changing the software" - this repo is already in the top tier for its pure core: fast, deterministic, mock-free, golden-backed, with project invariants automated as tests and even test-suites-as-data (codepaths, the OKF corpus). The one systemic miss is that the imperative shell around that core - the mix-task CLI surface, which is what a user of this framework actually touches - sits outside the suite entirely, held there by `System.halt`. Fixing that (item 1) is a refactor the philosophy directly prescribes and the architecture is already 90% shaped for; the rest is polish.
