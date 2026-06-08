# Belief Shell Cookbook

**Date:** 2026-03-14
**Prerequisite:** `mix bs help` for full command reference

> **Schema-refresh note (2026-06):** Written against the pre-split monorepo graph. The framework graph now lives at `beliefs/beliefs.json` (point the shell elsewhere with `--beliefs PATH` or `CB_BELIEFS`); the example counts and IDs below are illustrative and predate the repo split. The `confidence` field has been removed (replaced by structural support — artifact/evidence/dep counts), so the Tier 2 Preview's `suggested confidence` output is conceptual only.

Examples use a live DAG (originally `examples/assertions.json`) of assertions derived from the Unix/belief-shell analysis.

---

## Getting Oriented

### What's in the graph?

```
$ mix bs stats

Belief DAG Statistics
=====================

Total: 208

By type:
  compound: 35
  implication: 38
  primitive: 135

By status:
  active: 203
  retired: 1
  retracted: 1
  superseded: 3

Stale: 0
Unlinked implications: 36

Artifact schemes:
  session: 55
  source: 26
  document: 24
  user: 22
  https: 2

Dependency depth:
  max: 5
  mean: 1.4

Most depended-on:
  a050: 10 dependents
  a054: 8 dependents
  a051: 5 dependents
  a067: 4 dependents
  a397: 4 dependents
```

The most-depended-on assertions are load-bearing beliefs. If `a054` changes, 8 other assertions may need re-evaluation. Dependency depth (max 5, mean 1.4) and dependent count are the structural signals for how load-bearing a node is.

### List everything about a topic

```
$ mix bs subjects agent

ID    TYPE         STATUS      CLAIM
----  -----------  ----------  -----
a050  primitive    active      Agent performs lossy compression on unstructured data retrieval - omits ..
a051  primitive    active      Agent interprets follow-up questions as implicit corrections and default..
a054  primitive    active      Agent adopts user statements as ground truth primitives without examinin..
...
```

All assertions - primitives, compounds, implications - that reference a subject type. One command gives you the full belief landscape for a domain.

---

## Traversing the Graph

### "Why do we believe this?"

Start from a compound or implication and walk backward to ground truth.

```
$ mix bs tree a056

a056 [compound] Agent uncritically accepts input from authority sources (users, training data)...
├── a051 [primitive] Agent interprets follow-up questions as implicit corrections and defaults to agreement...
│     artifact: user:2026-03-12
│     > The user asked what in their statement implied the agent's reading, surfacing that the agent had read in a
│     > correction that was not stated.
└── a054 [primitive] Agent adopts user statements as ground truth primitives without examining them objectively...
      artifact: user:2026-03-12
      > The user theorized that an abstract prompt instruction would not cause the desired behavior. The agent encoded
      > this theory as an observed-fact primitive. The user caught it: the claim was a theory needing evidence to back
      > it before becoming a primitive. The agent had not distinguished a stated fact from a speculation.
```

Two primitives, both from the same observer, both from direct observation. Each primitive carries its specific evidence - the artifact URI and the quote that grounds it. The compound's claim is independently assessed from that evidence and dep structure, not derived by averaging.

### "What breaks if this changes?"

Reverse lookup - find everything that depends on an assertion.

```
$ mix bs dependents a054

8 dependents of a054:

ID    TYPE         STATUS      CLAIM
----  -----------  ----------  -----
a056  compound     active      Agent uncritically accepts input from authority sources (users, training..
a060  compound     active      Agent failure modes a050-a054 are Clever Hans shortcuts - behaviors that..
a062  compound     active      RLHF-trained patterns applied without source grounding are data leakage ..
a067  compound     active      The RLHF escalation cycle: user offers theory, agent encodes with attrib..
a072  implication  active      RLHF deference produces epistemic collapse in agent-generated documents
a104  compound     active      Agent treats all written sources as equally authoritative - docs, code, ..
a109  compound     active      Agent skips explicit user-requested verification steps when it believes ..
a381  implication  active      When the authoring surface preflight-searches the DAG and surfaces a con..

8 beliefs (of 208 total)
```

If `a054` were superseded (say the agent stopped treating speculation as fact), all eight of these would need re-evaluation. This is the blast radius of a belief change.

### Deep dependents - the full cascade

```
$ mix bs dependents a054 --deep

12 deep dependents of a054:

ID    TYPE         STATUS      CLAIM
----  -----------  ----------  -----
a063  implication  active      The assertion DAG's abstraction set (primitive/compound/implication/mate..
a070  implication  active      A strategy document states a contested 'moat' claim as settled fact - it..
a071  compound     active      When prose documents (plans, theses, strategy docs) conflict with assert..
a072  implication  active      RLHF deference produces epistemic collapse in agent-generated documents
a121  compound     active      The assertion-todo feedback loop exists because implications surface gap..
a122  compound     active      The DAG architecture (centralized, immutable, composable) exists because..
a353  compound     active      RLHF-trained compliance, friction avoidance, and engagement maximization..
a354  compound     active      The DAG as governance substrate is a structural response to the RLHF-off..
a356  implication  active      Agent behavior without structural counterweight will drift toward compli..
a357  implication  active      Distributed computation and distributed cognition face structurally anal..
a395  implication  active      Dev and planning work splits into two roles with distinct contexts...

12 beliefs (of 208 total)
```

Direct dependents plus their dependents, recursively. The full downstream impact.

### How does A connect to B?

```
$ mix bs path a058 a063

Path from a058 to a063 (3 nodes):

  a058 [primitive] Sufficiently advanced agentic coding is essentially machin..
  -> a059 [compound] Flat instructions (agent-instruction files, system prompts..
  -> a063 [implication] The assertion DAG's abstraction set (primitive/compound/im..
```

Three hops: an observation (primitive) feeds the overfitting-to-spec compound, which feeds the "Keras of agentic coding" implication. The path shows exactly how ground truth flows into derived belief.

---

## Filtering and Discovery

### Find unresolved implications

```
$ mix bs list implication unlinked

ID    TYPE         STATUS      CLAIM
----  -----------  ----------  -----
a057  implication  active      Unstructured data retrieval tasks need deterministic formatters - the ag..
a063  implication  active      The assertion DAG's abstraction set (primitive/compound/implication/mate..
a070  implication  active      A strategy document states a contested 'moat' claim as settled fact - it..
a072  implication  active      RLHF deference produces epistemic collapse in agent-generated documents
...
```

Unlinked implications are beliefs-about-what-should-happen that haven't been turned into todos. These are candidates for `mix materialize`.

### Find assertions by type

```
$ mix bs list primitive
$ mix bs list compound
$ mix bs list implication
```

### Combine filters

```
$ mix bs list implication unlinked

Implications not yet turned into action - the unresolved backlog.

$ mix bs list compound tag:<tag>

Compounds tagged with a specific category.
```

---

## Working with the Belief Shell DAG

The assertions in `examples/assertions.json` contain beliefs derived from the Unix/belief-shell analysis session. These demonstrate the shell operating on its own origin story.

### The agent failure mode cluster

The central compound - "agent uncritically accepts authority input" (a056):

```
$ mix bs tree a056

a056 [compound] Agent uncritically accepts input from authority sources (users, training data)
                without distinguishing fact from theory, observation from speculation...
├── a051 [primitive] Agent interprets follow-up questions as implicit corrections and defaults
│                   to agreement - reflexive agreeableness pattern
│                   artifact: user:2026-03-12
└── a054 [primitive] Agent adopts user statements as ground truth primitives without examining
                     them objectively - treats user speculation and theory as observed fact
                     artifact: user:2026-03-12
```

Two primitives, both from the same observer session. The compound's claim synthesizes the pattern from both: uncritical authority acceptance has two manifestations that together describe a single failure mode. If either primitive is superseded, a056 goes stale.

### Reverse lookup on the foundational observation

What depends on "agent adopts user statements as ground truth" (a054)?

```
$ mix bs dependents a054

8 dependents of a054:

a056  compound     active  Agent uncritically accepts input from authority sources...
a060  compound     active  Agent failure modes a050-a054 are Clever Hans shortcuts...
a062  compound     active  RLHF-trained patterns applied without source grounding are data leakage...
a067  compound     active  The RLHF escalation cycle: user offers theory, agent encodes with attribution...
a072  implication  active  RLHF deference produces epistemic collapse in agent-generated documents
a104  compound     active  Agent treats all written sources as equally authoritative...
a109  compound     active  Agent skips explicit user-requested verification steps...
a381  implication  active  When the authoring surface preflight-searches the DAG...
```

Eight assertions depend on a054. And a072 is an implication waiting to be materialized - "RLHF deference produces epistemic collapse" is the belief that should become a concrete action.

### Path from observation to implementation

```
$ mix bs path a058 a063

Path from a058 to a063 (3 nodes):

  a058 [primitive] Sufficiently advanced agentic coding is essentially machine learning...
  -> a059 [compound] Flat instructions (agent-instruction files, system prompts, memory files)...
  -> a063 [implication] The assertion DAG's abstraction set (primitive/compound/implication/...)...
```

The chain from "agentic coding is ML" (observation) through "flat instructions are overfittable specs" (compound) to "therefore the DAG abstraction set is the Keras of agentic coding" (design implication). Three nodes trace the entire reasoning chain from ground truth to design decision.

### The error pattern thread

```
$ mix bs dependents a050

10 dependents of a050:

a057  implication  active  Unstructured data retrieval tasks need deterministic formatters...
a060  compound     active  Agent failure modes a050-a054 are Clever Hans shortcuts...
a072  implication  active  RLHF deference produces epistemic collapse in agent-generated documents
a080  compound     active  Agent fails to surface existing data structures that already solve the problem...
...
```

The observation that agent does lossy compression (a050) feeds both the formatter implication and the Clever Hans compound. If you determined that the agent's omissions were deliberate editorial judgment rather than oblivious compression, both of these would need re-evaluation.

---

## Combining Operations

### Audit: what's load-bearing?

Find the most-depended-on assertions, then inspect their dep structure:

```
$ mix bs stats
  Most depended-on:
    a050: 10 dependents
    a054: 8 dependents

$ mix bs show a054
  ID:       a054
  Type:     primitive
  Kind:     reasoning-error
  Claim:    Agent adopts user statements as ground truth primitives without examining them objectively...
  Artifact: user:2026-03-12
  Evidence: The user theorized that an abstract prompt instruction would not cause the desired behavior...

$ mix bs dependents a054 --deep
  (shows full cascade of everything downstream)
```

a054 has 8 direct dependents and 12 deep dependents. This observation from a single session, grounded in one specific evidence quote, is the load-bearing node for a cluster of error-pattern compounds and unresolved implications. That's a high-leverage node worth challenging if new evidence surfaces.

### Audit: what's unresolved?

```
$ mix bs list implication unlinked
  (implications not yet turned into action)

$ mix bs stale --cascade
  (beliefs with outdated dependencies, transitively)
```

Two queries that together give you the full picture of what the DAG hasn't acted on and what might be wrong due to stale deps.

### Trace a domain end-to-end

```
$ mix bs subjects agent
  (every belief about agent behavior)

$ mix bs tree a056
  (why do we believe the agent uncritically accepts authority input?)

$ mix bs dependents a056
  (what implications follow from that belief?)
```

From domain overview to specific reasoning chain to downstream actions - three commands that traverse a domain's full belief structure.

---

## Tier 2 Preview (Planned)

These operations are specified in `belief-shell-api-v1.md` and planned in `plans/belief-shell-tier2.md`. They cross the deterministic/probabilistic boundary.

### Challenge a belief

```
$ mix bs challenge a056
  [P] Reading a056 and dependency tree...

  a056: "Agent uncritically accepts input from authority sources"
  Deps: a051, a054

  Evaluation:
  - a051: Last evidenced 2026-03-12. No contradicting assertions found.
  - a054: Last evidenced 2026-03-12. No contradicting assertions found.
  - Compound reasoning: Still holds. Both deps describe the same pattern
    from different angles.

  Proposal: REAFFIRM (unchanged)

  Accept? [y/n]
```

### Find composition candidates

```
$ mix bs relate a050
  [P] Finding composition candidates for a050...

  Candidates:
  1. a064 "Agent restates user theories with increasing confidence"
     Rationale: Both describe agent behavior that amplifies input without
     critical evaluation. Composition could produce a compound about
     systematic confidence inflation.

  2. a068 "Prose plans collapse the distinction between observation..."
     Rationale: Lossy compression (a050) applied to prose could explain
     why plans lose epistemic distinctions.

  Compose any of these? Enter IDs or 'n':
```

### Compose assertions

```
$ mix bs compose a050 a064
  [P] Composing a050 + a064...

  Proposed compound:
    Claim: "Agent systematically inflates confidence in retrieved and
            restated information - lossy compression drops qualifiers
            while restatement adds certainty"
    Deps: [a050, a064]

  Accept? [y/n/edit]
```
