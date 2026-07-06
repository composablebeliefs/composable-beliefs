# 8 · Beyond the ledger

The last chapter built an audit ledger: typed observations grounded down to a raw run, verdicts that supersede when a newer snapshot lands, a methodology that checks itself. This capstone recontextualizes that work. The ledger is one of three faces of the same substrate, and the other two run *forward* - out of records and into artifacts a system can run and consult.

## The ledger was one face

Everything chapter 7 taught has a single shape underneath it: knowledge flows *inward*. The world produces a run; the graph takes it in, types it, and holds it still so a later reader can check it. That is CB's **receptive face** - record, supersede, audit - and it is the entire reason a belief graph beats a spreadsheet for verdicts. It is also only part of what the substrate can do.

One framing discipline before the table, because it keeps the claims honest: the substrate has faces, and a *host system* is what puts them to work. CB is defined knowing nothing of any consumer, so the honest sentence is always "a host uses CB's capability to do X", never "CB is the X". Nothing here replaces the ledger; the move is additive - two more faces that were in the schema all along.

| Face | The operation | In a host's hands |
| --- | --- | --- |
| **Receptive** - record, supersede, audit | knowledge flows in: a run is recorded as typed beliefs and held still | the eval ledger of chapter 7: observations compose to a verdict you can traverse down to the raw run |
| **Generative** - specify, deduce, actualize | knowledge flows out: typed claims compose into contracts that compile to artifacts - runnable checks and instruction files | a pre-registered eval rubric authored as a contract that compiles to the runnable checks *and* to the writeup |
| **Self-referential** - take the agent as subject | a claim's subject is a system's own failure modes | a system with a queryable model of how it tends to fail, consulted before acting |

Both new faces rest on schema you have already seen: contracts are rules-and-invariants beliefs ([chapter 2](2-schema.md#contracts-prescriptions-with-teeth)), and a claim whose subject is the agent is just an ordinary belief with a subject of type `agent` (`cb:b115`).

## The hinge: an eval-spec is a contract

The cleanest place to see the generative face is a seam already crossed. The six methodology contracts of chapter 7 are graph-shape checks that route through named predicates - the forward direction already running. The general form: a **pre-registered rubric is a contract**. "Pre-registered" means the criteria are committed before the run, so the goalposts cannot quietly move; and the contract's typed fields are exactly the slots a rubric needs - what must hold, what must be present, what makes it fail.

The payoff is the compile step. From one typed source, a tool mechanically generates two outputs: the executable pass/fail checks a machine runs, and the human-readable account of what was tested and why. Author the criteria once and both fall out of the same source, so they can never drift apart. This is the hinge that joins the guide's two halves: a contract from chapter 2 is schema-as-data; an eval from chapter 7 is a measured finding; fuse them and the rubric becomes one artifact with two outputs.

**Codepaths are the deepest form of the signature property.** The substrate's signature move is that from a published claim you can traverse down to the exact thing that grounds it. The audit tree walks a verdict down to a raw scorer log; a [codepath](4-code.md) walks a claim down into the running source itself, as one artifact that is both a narrated causal explanation and a test that re-runs. A behavioral verdict anchored to the narrated code that caused it extends "traverse from verdict to the exact raw run" one level deeper - into the code.

## The ladder: specify, deduce, actualize

Read as a sequence, the generative face is a three-rung ladder rising out of the ledger:

```
ACTUALIZE   self-referential claims a system queries before
            acting, so it resists the next failure
    ^       vision horizon
    |
DEDUCE      remediation read off the belief network the
            findings accumulate into
    ^       vision horizon
    |
SPECIFY     the eval as a contract -> compiled checks + writeup
    ^       near-term: the one rung a v1 eval already needs
    |
------------------------------------------------------------
THE LEDGER  record / supersede / audit  (the receptive face,
            where you have been standing)
```

**Specify** is the eval-spec-as-contract above. **Deduce** reads remediation off the accumulated belief network. **Actualize** closes the loop: a system's own failures become self-referential claims it queries before it acts, so its model of how it tends to fail starts steering it away from the next one - the full argument is the [actualization essay](../actualization.md).

The order is *build-order, not architecture*: a capability is exercised only when a real use pulls it. Only the specify rung touches a current build, and only because a pre-registered eval needs a machine-checkable spec anyway. The metaphor worth keeping: the receptive face is a **thermometer** (it measures and reports), the generative face is a **thermostat** (it acts on a reading and generates control) - and the contract is the shared spine under both, since the same typed spec can compile to a check that measures and a guardrail that steers.

> **Caveat.** This forward arc is a vision argument disciplined by build-order, not a shipped roadmap. Deduce and actualize are where the capability *could* go; the published verdicts of the receptive face stay evidence-only meanwhile.

## The proving ground

A reader who came up through the [orientation](0-orientation.md) may feel a tension. CB was introduced as a substrate for persistent reasoning across sessions, and the guide then spent a full chapter on something as specific as grading model runs. Did the grand idea shrink into an eval tool?

The narrow scope is a proving ground for the broad one, and the link is the self-referential face. A single agent that queries a model of its own failure modes - catching itself agreeing reflexively, or treating its own speculation as ground truth - is running the individual-scale version of the failure the eval domain studies at group scale, where a population of agents collapses into conformity. Same epistemic failure, two magnifications, continuous in between. Building the substrate that grounds a group-scale eval *is* building the substrate that models a single agent's self-knowledge: typed claims, traversable provenance, contracts that compile, self-referential subjects - the same machinery at a different zoom.

## Closing: what you were actually learning

You opened this guide to understand a way of grounding claims, and you spent the late chapters learning to publish an audit ledger a reader can traverse from a verdict down to a raw run. That ledger is real, and it is the receptive face of something larger. The same typed primitives, the same supersession, the same provenance you now know how to operate are the inward half of a substrate whose generative face compiles typed claims into tests and instruction files, and whose self-referential face reaches all the way to a system that holds a model of its own failure modes and corrects against it before acting. The reach is wide and the discipline is narrow on purpose: sequenced by need, never sold as a promise.

From here the substrate is yours to operate. Return to the [orientation](0-orientation.md) to re-read the thesis with the whole picture in view, or start querying: `mix bs stats`.

> **Grounding.**
> - In the graph: `cb:b115` (a belief can take the agent itself as subject - the schema basis of the self-referential face), `cb:b046`/`cb:b047` (contracts as data and the routing boundary - the generative machinery), `cb:b049`/`cb:b050` (the codepath render-spec and inspection-only predicates - explain-and-verify in one artifact), and the `method:` contracts (the eval-spec-as-contract already instantiated).
> - In the docs: [actualization.md](../actualization.md) (the self-referential face in full), [the thesis](../composable-beliefs-thesis.md) (the paradigm argument and its falsification condition).
