# Plan 3 - Assertions on: named predicates, `Sink.Test`, and the dynamic verifier

Raise the gradient. A contract-grade claim belief routes to a repo-resident named
predicate; the predicate runs in the live app via Tidewave MCP; the result materializes
as test history bound to the immutable claim. The *same* `belief-pipeline` codepath that
plan-2 narrates now also runs. This is the heaviest plan - it needs the runtime channel -
and it is gated behind plans 1 and 2.

**Status:** Proposed 2026-06-09. Nothing built.
**Date:** 2026-06-09
**Depends on:** plan-1 (schema), plan-2 (renderer). Runtime depends on the open-source `tidewave` Phoenix package (no subscription) and a booted `cb-dashboard`.
**Touches:** repo-resident predicate functions (cb test support); contract routing on the `belief-pipeline` claim beliefs; `cb-dashboard/mix.exs` + `cb-dashboard/lib/cb_dashboard/endpoint.ex:63` (Tidewave mount); a new `CB.Materializer.Sink.Test`; a new dynamic verifier mix task.

## Context

c037 governs once tests live in cb: the DAG carries *which* predicate must hold *where*,
never the predicate body. That constraint produces the clean design - the "test DSL" is
pure routing over functions that already look like tests. The materializer already turns
an implication into artifacts through a pluggable `Sink` (`@callback persist/3`, only
`Sink.JSON` today); a test run is one more sink, not a new subsystem.

## Design

### Named predicates (c037-compliant)

Predicate bodies are ordinary functions in the cb codebase - reviewable, runnable,
version-controlled like any test (e.g. `belief_count_positive/0`,
`from_map_roundtrips?/0`). They are inspection/read predicates: they observe, they never
mutate.

### Contract routing

The relevant `belief-pipeline` claim beliefs become contract-grade, carrying rules that
route to predicate names - `implies(When, Requires: "predicate_name")` per the c035
registry and c037 boundary. The DAG names the predicate and the anchored site; the repo
implements it.

### `eval` = invoke the named predicate

`eval` is not "run this string"; it is "invoke the routed predicate via MCP federation
into the running app." For the cb codebase that channel is Tidewave into the
`cb-dashboard` BEAM (the structs, store, and materializer are already loaded there). The
predicate executes in the app under test; the DAG and the renderer stay code-free.

### `Sink.Test` (test run as materialization)

A new `CB.Materializer.Sink` implementation: `contract -> invoke routed predicates ->
pass/fail -> link to belief.materialized` with a date. Test history is bound to the
immutable claim for free; re-running supersedes the prior materialized record. The
materializer you already have is the executor.

### Dynamic verifier (sibling task)

A new mix task (e.g. `cb.verify.codepath`) runs the live-assertional checks. It is a
**sibling** of `verify.schema`, not a generalization of it: `verify.schema` stays static,
deterministic, and runtime-free; the dynamic verifier requires a booted app + Tidewave
and is where non-determinism is confined. Keeping them separate preserves cb's
pure-traversal property.

### Tidewave wiring

Per the original deferred runtime layer: add `{:tidewave, "~> 0.x", only: :dev}` (pin at
build time), mount it in the dev-only block at `cb-dashboard/lib/cb_dashboard/endpoint.ex:63`,
register the MCP server (Claude connects MCP only at startup - restart after), and run
`mix phx.server`. Wire it end to end in one pass; never ship routing that does not resolve
to a runnable predicate.

## Acceptance criteria

- The `belief-pipeline` codepath with **assertions on** runs its predicates against the
  live `cb-dashboard` app and records pass/fail to `belief.materialized` (dated; re-run
  supersedes).
- `present-codepath` with assertions on pairs each contract-grade stop's static
  `path:line - claim` with its live predicate result; non-contract stops still narrate
  only (the gradient).
- `cb.verify.codepath` runs the assertions as a batch suite and reports pass/fail.
- `mix cb.verify.schema` still runs independently, unchanged, with no runtime dependency.

## Risks and non-goals

- **Runtime dependency.** Requires a booted `cb-dashboard` + Tidewave + an MCP restart.
  This is the spine of the test capability now, not an optional stretch - accept it or
  plan-3 does not ship.
- **Determinism boundary.** Live predicate runs are non-deterministic; confine them to
  the dynamic verifier so `bs`/`verify.schema` stay pure.
- **Inspection only.** Predicates read, never mutate. Enforce by review convention and
  document it in the routing contract.
- **Non-goal:** multi-language predicate execution; a breakpoint debugger. Tidewave/BEAM
  is the one channel; REPL-style inspection is the chosen primitive.
