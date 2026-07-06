# Linking tests to prescriptions, and describing tests in the DSL

Date: 2026-07-06

A design exploration following the [matklad testing-philosophy review](2026-07-06-matklad-testing-philosophy-review.md). Two questions:

1. How do we link ExUnit tests to the prescriptions they enforce, so the graph knows how a commitment is backed and the suite knows why a test exists?
2. How far should the graph's DSL go in *describing* tests, rather than merely pointing at them?

## What already exists

Every raw part of the answer is already in the repo; what is missing is the link layer that composes them.

| Mechanism | Where | What it gives us |
|---|---|---|
| Routed predicates | `implies` rules `{"when": ..., "requires": "name?", "params": ...}`; bodies in `CB.Eval.Predicates` (arity-2, pure, static pass) and `CB.Codepath.Predicates` (zero-arity, dynamic pass) | Tests whose *routing lives in data* and whose implementation lives in code (cb:c047), inspection-only by construction (cb:c050) |
| Codepaths as suites | `mix cb.verify.codepath`; contract-grade stops carry `requires` rules | Whole test suites that are themselves belief collections |
| `code:` locator | `CB.CodeLocator`; `code:<path>#<anchor>[@N]` | Verifiable anchors into source files - including test files; a missing anchor is a maintenance signal |
| Test-run recording | `CB.Materializer.Sink.Test` + `cb.verify.codepath --record` | Dated pass/fail history on a belief's `materialized` field - the mutable action-history axis, orthogonal to immutable status |
| Dogfooded contract tests | `test/cb/schema_contracts_test.exs` | An ExUnit suite that already loads the graph and verifies the code against named contracts (b053, b039/b043, b041) |
| Provenance loop | `mix cb.verify.commits` | The precedent: a bidirectional link (belief -> commit artifact, commit -> Belief: trailer) verified mechanically in both directions |
| Externalized corpus | `okf/conformance/` fixtures + normative `expected/*.json` | The house pattern for tests described entirely as data |

The gap is visible in `schema_contracts_test.exs` itself: its moduledoc names the contracts it discharges (b053, b039, b043, b041), but that linkage is prose. The graph cannot answer "which prescriptions are test-backed?", and the suite cannot answer "which test breaks if cb:b053 is superseded?".

## Part 1: the link layer

### Direction 1 - test to prescription: ExUnit tags

The cheapest machine-readable link is a tag convention:

```elixir
@moduletag verifies: "cb:b053"          # whole file discharges one contract
# or per test:
@tag verifies: "cb:b039"
test "every active belief's kind is a declared enum value" do ...
```

Colocated with the test, zero ceremony, and already queryable through ExUnit metadata. `mix test --only verifies:...` falls out for free (run exactly the tests backing one prescription).

What makes tags trustworthy is a sweep that verifies them - the same move as `cb.verify.commits`:

- every `verifies:` value parses as a belief id and resolves in the graph;
- the target is a prescription (or contract-grade belief), not an arbitrary node;
- the target is **active**. A tag pointing at a superseded belief is the interesting case: the prescription changed and its test has not been re-pointed. That is staleness extended from the graph into the suite - the test equivalent of `mix bs stale`, and the mechanism that keeps links from rotting.

The sweep itself should be an ExUnit test (matklad: automate every project invariant as a test; house precedent: `generated_claude_md_test.exs` is exactly this shape for doc drift).

### Direction 2 - prescription to test: `code:` anchors

The reverse link uses the artifact scheme that already exists. A prescription that claims mechanical enforcement carries (as an evidence entry's artifact, via `mix cb.evidence`) an anchor into the test that enforces it:

```
code:test/cb/schema_contracts_test.exs#cb:b053 state machine
```

`CB.CodeLocator` already parses this; anchor resolution already distinguishes "moved" from "gone"; a renamed or deleted test surfaces as a maintenance signal the next time anchors are verified, exactly as it does for codepath stops. `mix bs show cb:b053` then displays where the enforcement lives, with a clickable path.

Evidence is the right container (not `deps`, not a new field): the sanctioned in-place growth point, dated, and carrying an artifact URI. No schema change.

### Closing the loop, and the scoping decision

A reconciliation pass - `mix cb.verify.tests`, or better, a methodology contract routed through the existing `CB.Method.Checks` machinery (`{"when": {"verify": "collection"}, "requires": "prescriptions_test_backed?"}`) so it runs inside `mix cb.verify.collection` with no new subsystem - asserts both directions agree.

The scoping decision matters more than the mechanism: **not every prescription should be test-linked.** Most prescriptions are doctrine (conventions, policies, design principles) whose enforcement is judgment, not mechanism. Demanding universal test linkage would either fail permanently or force junk tests. The house convention already handles this shape: make the *claim of enforcement* explicit. A prescription that asserts mechanical backing declares it - a tag such as `enforcement:exunit` - and only those are gated:

- `enforcement:exunit` and no live `verifies:` tag anywhere -> fail (the house claims backing it does not have);
- a `verifies:` tag pointing at a non-active or non-prescription node -> fail (rotted link);
- everything else -> out of scope, no vacuous pass pretending coverage.

This gives `mix bs list prescription` an honest third column: enforced-by-test, enforced-by-verifier (schema contracts, route tags, commits - already machine-checked), or held-by-doctrine.

### What test results should NOT become

The tempting move is to append a `cb.evidence` entry on every green run. That is the digest antipattern wearing a new hat (cb:b386): cached greenness whose freshness depends on remembering to refresh it, plus unbounded node growth duplicating what CI already records. The repo has already drawn this boundary correctly:

- **evidence** records durable events - the test was authored, a failure taught something, an anchor was re-pointed;
- **materialized** records the latest run - `Sink.Test` refs, dated, where a re-run *replaces* the prior record. `cb.verify.codepath --record` does this today; a `--record` on the reconciliation pass extends the same convention to prescription-linked ExUnit runs if wanted;
- **liveness** stays live: "is cb:b053 enforced right now" is answered by running the suite, never by reading a stored flag.

## Part 2: how far the DSL should describe tests

The graph already describes tests at three depths, and the depths form a gradient worth making explicit:

1. **The contract IS the test data.** Enum-registry, state-machine, and table contracts are interpreted directly; `schema_contracts_test` and the verifier are interpreters over them. Nothing to add - this is the deepest and most successful tier.
2. **The routing is data, the body is code.** `implies` rules name predicates; `CB.Eval.Predicates` / `CB.Codepath.Predicates` implement them (cb:c047). The `params` map already makes these parameterizable test cases (`min_runs_met?` with `{"min": 3}`).
3. **The suite is a collection.** Codepaths run as test suites; the OKF conformance corpus is a test suite that exists only as fixtures plus normative expected output.

### The extension: a feature-check tier

The matklad review's headline gap was the untested CLI feature surface, with a `check` function (`argv, graph -> {output_lines, exit_status}`) as the remedy. That check function is precisely an *interpreter for tests described as data* - which means the DSL can describe those tests without any new interpretation machinery beyond what tier 2 already has:

```json
{
  "when":     {"verify": "feature"},
  "requires": "cli_check?",
  "params": {
    "task":    "bs",
    "argv":    ["list", "prescription", "-v"],
    "fixture": "test/fixtures/graphs/small",
    "expect":  "test/fixtures/golden/bs_list_prescription_v.txt"
  }
}
```

- The rule lives on the prescription that *mandates the behavior* - e.g. the belief behind "ids may be bare or namespaced" carries the feature cases that pin bare-id resolution. Grounding is structural: the test case is a dep-level consequence of the commitment, not a file that happens to mention it.
- `CB.Belief.Contract.Implies` reads only `when`/`requires`, and the contract-shape catalogue (cb:c046) treats those as required-not-closed, so the extra params and the new route value are tolerated by construction - the same extensibility `CB.Method.Checks` already relies on. No catalogue supersession needed.
- The predicate body (`cli_check?`) is the check function behind the `PredicateGate`: named in data, implemented in code, inspection-only. Golden files stay on disk as artifacts referenced by path - the graph stores pointers, never blobs.
- Routing on `{"verify": "feature"}` keeps the determinism boundary legible: schema checks stay static, feature checks invoke the halt-free task cores (pure, in-memory graph fixtures - still on the fast, deterministic side, but a distinct pass so `verify.schema` stays runtime-free).

This tier passes matklad's neural-network test by construction: argv in, expected text out, implementation swappable.

### Where the DSL should stop

The essays' friction argument cuts against moving everything into the graph, and it should be taken seriously:

- **Algorithmic edge cases stay in ExUnit.** `resolve_id` ambiguity, cycle termination, store round-trips - these want `mix test path:line`, assertion diffs, IDE navigation, async, and cheap iteration. Describing them as graph rules would add authoring ceremony (preflight/import per case) to the exact activity the philosophy says must be frictionless. Link them with `verifies:` tags; do not migrate them.
- **One case-shape per tier.** The feature-check params schema should stay as small as the OKF corpus's contract (input ref, expected ref, done). The moment `params` grows conditionals or setup steps it has become a worse ExUnit, in JSON.
- **The graph indexes; corpora hold the bulk.** For anything with many cases (the conformance corpus, future CLI goldens), the collection-level pattern is one prescription grounding the corpus via its directory artifact, with discovery mechanical - not one belief per case. Beliefs are for commitments; cases are data under the commitment.

The rule of thumb that falls out: **the DSL describes a test when the test is the discharge of a named commitment and is expressible as input -> expected output; everything else is ExUnit, linked by tag.**

## Suggested order of work

1. **Tag convention + sweep test** (no schema change, immediate): adopt `verifies:` tags, retrofit `schema_contracts_test` / `route_tags_test` / `generated_claude_md_test` / `okf_conformance_test` whose discharged contracts are currently only prose, add the sweep asserting tags resolve to active prescriptions.
2. **Anchors on the enforced prescriptions** (write-flow, needs authorization for `beliefs/`): `mix cb.evidence` entries carrying `code:test/...#...` anchors on the handful of prescriptions with named enforcement, plus `enforcement:exunit` tags on those beliefs.
3. **Reconciliation predicate** `prescriptions_test_backed?` routed through `CB.Method.Checks` so `mix cb.verify.collection` closes the loop both ways; surface an "enforced by" line in `mix bs show` and extend staleness reporting to tests pointing at superseded prescriptions.
4. **Feature-check tier** (after the halt-free-core refactor from the review): `cli_check?` predicate wrapping the check function, `{"verify": "feature"}` rules on the prescriptions that mandate CLI behavior, goldens on disk.
5. Optionally, `--record` on the reconciliation pass via the `Sink.Test` ref shape, keeping run history on `materialized` and out of evidence.

## Verdict

Linking tests to prescriptions is not a new subsystem; it is the `verify.commits` pattern applied to a second artifact class, using tags outbound, `code:` anchors inbound, and a routed predicate to reconcile. The DSL should describe tests exactly as deep as it already successfully does - contracts interpreted directly, cases routed by name with data params, corpora externalized - extended by one tier (feature checks over the halt-free task cores) that the matklad review independently motivates. The discipline to keep is the one the graph already teaches: commitments in beliefs, mechanisms in code, bulk data in corpora, and liveness answered by running, never by caching.
