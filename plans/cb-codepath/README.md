# cb-codepath - a code-anchored materialization of composable-beliefs

A **codepath** is a code-anchored cb collection that reads as a narrated, branching
tour of real source files and runs as a test suite over them. Each node is a belief:
*where* = a `code:` anchor, *why* = the claim, *that* = a contract-routed named
predicate, *whence* = deps. Read it with assertions off and it is a guided walk; run
it with assertions on and it is a test suite. Same artifact, one gradient.

This plan set supersedes the standalone-plugin framing in
[`../interactive-walkthroughs-acp/`](../interactive-walkthroughs-acp/plan.md). That
thread landed on a domain-neutral plugin with its own format; this set folds the whole
thing into composable-beliefs as the schema authority, because the alignment turned out
to be total.

**Terminology:** "codepath" replaces "walkthrough" everywhere - in these plans and in
the current codebase (plan-0). "walkthrough" survives only inside historical
transcripts kept as a record.

## Why it collapsed into cb (decision record)

- **Full collapse.** A code-anchored claim with a contract assertion *is* a belief; an
  ordered, branching render over claim ids *is* an output-target (the exact shape of
  c042, which renders CLAUDE.md). Inventing a second format would create a second
  schema SSOT - the staleness antipattern cb's format/instance discipline exists to
  kill (cb:a386). So cb is the single schema authority; a codepath is a cb collection.
- **c037 forces named predicates.** Once tests live inside cb, c037 ("routing in data,
  implementation in code") forbids executable assertion strings in the DAG. The
  resolution is sharper than inline `eval`: predicate bodies are ordinary
  repo-resident functions; the contract stores only routing
  (`implies(When, Requires: "predicate_name")`); `eval` *invokes the named predicate*
  via MCP federation into the live app. The DAG names what must hold where; the repo
  implements it; the verifier runs it.
- **Three readings, three homes.** Navigation (`goto`/`choices`) lives in the mutable
  output-target render-spec, never in the immutable claim beliefs - so reordering a
  codepath never churns belief history or pollutes logical deps. Derivation lives in
  `deps`. Assertion lives in the contract's routed predicates. One node set, three
  layered readings.
- **Single language target.** General multi-language utility is explicitly dropped.
  The target is the cb codebase itself on BEAM, with Tidewave as the predicate-eval
  channel. Generality can come later, if ever.
- **Fold into cb.** The renderer is a `cb.generate.*` analog that lives in cb; the
  standalone `code-walkthrough` repo is archived. Codepath instances are cb collections
  hosted beside the code they walk.

## The series

| Plan | What it delivers | Touches `beliefs/`? | Runtime? |
|---|---|---|---|
| [plan-0](plan-0-fold-and-rename.md) | Fold `code-walkthrough` into cb; rename walkthrough -> codepath; archive the standalone repo | no | no |
| [plan-1](plan-1-schema-groundwork.md) | The `code:` locator + the codepath output-target shape in the cb schema | **yes** | no |
| [plan-2](plan-2-codepath-renderer.md) | `present-codepath`: the narrated, branching render of a cb collection (assertions off) | yes (new collection) | no |
| [plan-3](plan-3-assertions-runtime.md) | Named predicates + `Sink.Test` + a dynamic verifier (assertions on) | yes | **yes (Tidewave)** |

The collapse inverted the original cost curve: schema is now a *prerequisite* of even a
read-only codepath (plan-1 before plan-2), and the runtime test layer is last and
heaviest (plan-3). There is no cheap inline-`eval` shortcut anymore - c037 retired it.

## Locked decisions (from the design discussion)

- Locator: a new `code:` scheme in c040 (`code:<path>#<anchor>`); `document:` stays
  whole-file. `occurrence` is dropped in favor of precise anchors (optional `@N` in the
  URI if ever needed).
- Codepath render-spec: reuse the existing `output-target` kind (c042 mechanism) with
  navigation fields on its rows, not a new c035 kind.
- Verifier: the dynamic (live-assertional) runner is a **sibling** task, independently
  runnable from the static `verify.schema`, so cb's deterministic-traversal property
  stays intact.
- Authoring: a codepath render-spec is drafted outside the graph and `cb.import`-ed once
  settled, to avoid supersession churn on every reorder.
- Repo fate: fold the tooling into `composable-beliefs`; archive `code-walkthrough`.

## Non-goals (whole set)

Multi-language predicate execution; agent-driven auto-advance or sub-line highlighting;
a breakpoint debugger; general-public distribution. All deferred or declined.
