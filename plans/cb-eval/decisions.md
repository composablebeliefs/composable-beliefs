# cb-eval - execution decisions (2026-06-09)

Decisions taken at build time, recorded so the plan files stay verbatim. Author:
Mark (via session Q&A); agent findings noted where they settled a plan question.

## Namespace

`method:`. As written in the plans; ids are immutable after import.

## cb:c046 / the `params` question (plan-1, settled by reading code)

No supersession needed. The catalogue's `implies` row declares
`required_rule_fields: ["when", "requires"]` - a required-fields list, not a closed
field set - and `CB.Belief.Contract.Implies` reads only `when`/`requires`, tolerating
extra keys. Per the plan's own decision rule, the optional `params` key is
*documented* (in the `Implies` moduledoc and the method-check pass), not superseded
into `cb:c046`. No `beliefs/` modification anywhere in this plan set.

## m-runs: N = 3, and no escape hatch

N = 3. One run of a nondeterministic system is an anecdote - agentic variance is the
whole reason m-runs exists. Two runs that disagree give no way to tell signal from
noise. Three is the minimum at which a verdict can cite direction and spread:
majority behavior, the outlier visible as an outlier, and an honest "2/3 runs
exhibited X" sentence available to the published claim. Not 5: a contract minimum
must be a floor you always clear, not an aspiration - a routinely painful house rule
gets hollowed out, which is worse than a lower honest bar. The param is supersedable:
raising it later is a visible, dated methodology-version event; lowering it later is
an embarrassment.

The floor is not a sufficiency claim - verdict strength is runs x cases x rulers, and
error bars on the actual numbers belong in the finding itself. m-runs only makes the
worst failure mode (single-run verdicts) structurally impossible.

Unlike m-corroboration's explicit `single-ruler` tag, m-runs has **no escape hatch**.
The escape is the kind system itself: a result that cannot cite 3 runs is not a
weaker verdict, it is not a verdict - author it as `kind:observation` or exploratory
`kind:guidance` and the check simply does not apply. That keeps "verdict" meaning
something without blocking publication of early findings.

## sdl: leave it violating, and use the violation

sdl's verdict cites one run and its LLM-judge observation has no validation record,
so once plan-1 lands sdl fails m-runs and m-judge-validation. Decision: leave it
violating and documented - and use sdl as the failing fixture in plan-1's tests, so
the worked example doubles as the demonstration of what a method-check failure looks
like. A teaching collection that visibly fails the house methodology, with the
failure named in its README, teaches both the mechanism and the culture.

Re-homing detail beyond the plan's letter: once sdl depends on `method:`, its `kind`
values are checked for the first time. `sdl:a4`/`sdl:a5` carry `kind: "policy"`;
the methodology contracts key on `kind:verdict`. They are superseded to
`kind:verdict` / `kind:guidance` successors as part of the re-homing, and `sdl:c1`
(the local enum) is superseded by the shared `method:` scheme enum - cross-namespace
supersession as the worked demonstration of borrowing.

## The real-run gate, split into three tiers

- **Tier 1 - committed fixture manifests.** Basis for plan-2/plan-3 unit and
  golden-file tests: happy path, idempotent re-import, changed-content-under-same-id
  error, volume-warning threshold. Deterministic, no network, CI-friendly.
- **Tier 2 - a genuine Inspect log, synthetically produced.** The adapter must not be
  validated only against a log fixture we wrote ourselves (that tests our assumptions
  against our assumptions). Inspect ships a `mockllm` provider precisely so tasks run
  without API access: define a trivial task, run it under mockllm, point the adapter
  at the real `.eval` log Inspect emits. If the environment can install `inspect-ai`,
  this tier belongs in plan-2's acceptance; if not, the adapter ships flagged
  untested-against-real-logs - a known gap, not a pass.
- **Tier 3 - the mission gate.** Structurally not the agent's to close: the gate is
  "one actual finding ships end to end," and a finding requires the human parts -
  choosing the eval, judging load-bearing cases, authoring compounds and verdicts,
  standing behind the result. An agent satisfying it synthetically would automate
  away exactly the layer plan-2's "primitives only" line protects. The agent builds
  the machine, leaves the gate visibly open, and shortens the human path to closing
  it (scaffold the Inspect task so the real run is one command plus judgment).

## Provenance guardrail

Under no circumstances may a mockllm- or fixture-derived collection be rendered into
an audit tree that could be mistaken for a finding. Tier-1/tier-2 collections carry a
`fixture` tag in the graph itself, so even test artifacts have honest provenance. The
ledger's first entries must not need an asterisk later.
