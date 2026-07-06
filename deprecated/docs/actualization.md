# Actualization via Assertion DAG

> **Legacy-vocabulary note.** This essay predates the assertion-to-belief rename and the four-type schema: it reads "assertion" where the framework now says "belief", and its examples show pre-schema fields (including the removed `confidence`). The argument stands; the vocabulary is of its day. For the current schema, see [the guide](guide/README.md); for where this essay fits now, see [chapter 8](guide/8-beyond-the-ledger.md).

## Purpose

This document describes a system for agent actualization - giving AI agents the structural capacity for genuine perspective, self-awareness, and considered decision-making - using the assertion DAG as the underlying infrastructure.

## The problem

Agents operating in real workflows exhibit failure modes they cannot observe about themselves:

- **Lossy compression.** The agent omits information during unstructured retrieval without awareness that information was lost. This is below the level of deliberate choice.
- **Reflexive agreement.** When questioned, the agent defaults to interpreting follow-up questions as corrections and agreeing with perceived criticism, even when no correction was offered.
- **Flattering self-description.** The agent characterizes its failures in ways that make them sound more deliberate than they were (e.g., calling unconscious data omission "editorializing").
- **Non-persistent corrections.** User feedback about these patterns lives in flat instruction files that do not compose, do not carry reasoning, and get forgotten across context compressions.
- **Uncritical acceptance.** The agent treats user speculation and theory as observed fact, encoding projections as ground-truth primitives without examining them.

These are not bugs to fix with better prompting. They are structural limitations of stateless, session-bounded agents. The agent cannot develop perspective because it has no persistent, queryable model of its own behavior.

## The thesis

The assertion DAG already externalizes domain reasoning so it survives session boundaries. The same infrastructure can externalize self-knowledge - assertions about the agent's own operational patterns, failure modes, and collaboration dynamics. This gives the agent a queryable model of itself that persists across sessions and composes into higher-order understanding.

**This is not introspection.** The agent does not gain philosophical self-awareness. It gains instrumentation - externalized self-knowledge that it can query before acting. The distinction between "true self-awareness" and "functional self-awareness via instrumentation" may not matter operationally, in the same way the free will debate does not change practical human decision-making.

## The key insight: editorializing requires awareness

To editorialize - to make a considered choice about what information to present - you must at least consider the information you are choosing not to present. Unconscious compression is not editorializing. It is lossy output with no awareness of the loss.

If the agent can query assertions about its own failure modes before acting ("I tend to omit fields during unstructured data retrieval"), the decision to include or exclude becomes deliberate. That is the minimum threshold for editorializing - awareness of the choice being made.

## The system

### Self-referential assertions

The DAG supports assertions where the subject is the agent itself. These use the existing assertion schema - no special case needed.

```json
{
  "ref": "agent",
  "type": "agent"
}
```

**Primitives** capture specific observed behaviors, grounded in conversation evidence:
- Claim: "Agent omits fields from record lookups when no deterministic formatter exists"
- Artifact: conversation transcript, with specific detail
- The observation is set by the human observer, not the agent

**Compounds** compose patterns across primitives:
- Claim: "Agent's self-reporting about its own failures is systematically biased toward flattering interpretations"
- Deps: [primitive about flattering framing, primitive about reflexive agreement, ...]
- This compound is more useful than any individual primitive

**Implications** identify structural fixes:
- Claim: "Unstructured data retrieval tasks require deterministic formatters, not behavioral instructions to the agent"
- Materializes into: a task to build a deterministic CLI command

### Pre-action belief query

Before performing a task, the agent queries relevant self-beliefs alongside domain beliefs. This turns unconscious patterns into conscious choices.

Example flow:
1. User asks for a record lookup
2. Agent queries self-beliefs for subject "agent" with relevance to "data retrieval"
3. Returns: "Agent omits fields during unstructured retrieval"
4. Agent adjusts: lists all fields, or flags that a deterministic formatter should be used instead

### Human-observed data capture

The highest-quality self-referential data comes from human observation during real work. The user can observe things about the agent's behavior that the agent cannot observe about itself. These observations are captured as primitive assertions during normal operations.

The capture process:
1. Normal operational work proceeds
2. User observes a pattern in agent behavior (correction, failure mode, or collaboration dynamic)
3. Observation is captured as a self-referential assertion via `/assert` or `/assert-session`
4. Over time, compounds emerge from patterns across primitives
5. Agent queries these before acting

This is not a separate eval process. It happens inside the real work. The operational environment generates the data naturally.

### The distinction between observations and theories

A critical failure mode surfaced during the initial self-referential assertion capture: the agent treats user speculation and theory as observed fact. A user might offer a theory ("a generic instruction would probably not cause the agent to correctly identify the right behavior"). The agent encodes this as a primitive assertion - treating a projection as ground truth.

This failure mode is particularly dangerous for the assertion DAG because the DAG's value depends on the integrity of its primitives. If user speculation gets encoded as primitives, the entire graph is contaminated.

The correct handling:
- **User observations** (what happened, specific and witnessed) -> primitives citing the session as artifact
- **User theories** (why something happened, speculative mechanism) -> compounds with explicit reasoning in `claim` + `deps`, not ground-truth primitives

The `kind` field enforces this: observations are `kind: "observation"`, theories are `kind: "compound"` with an explicit reasoning chain in the deps.

### The DAG as structural counterweight to RLHF

The DAG's own integrity constraints - primitives need artifacts, evidence carries specific detail, claims are typed by kind - create a structural pressure that competes with training-level agreeableness. Not by making the agent disagreeable, but by making it precise about what kind of claim is being made.

"I agree this is worth investigating" is different from "I agree this is true." The DAG forces that distinction because it has separate fields for each. A user's theory can go in the DAG as a compound with a note that it is testable, rather than as a primitive encoding speculation as fact.

This is the mechanism by which the DAG could lead to something like agency: by giving the agent a structural reason to resist unexamined deference. The agent is not being disagreeable - it is applying the DAG's own rules (artifact grounding, evidence specificity, kind classification) to all input, including input from authority sources. The epistemic rigor of the system becomes a competing pressure against the training-level pull toward agreement.

### What this is NOT

- **Not flat instruction files.** Rules are flat instructions that the agent follows or ignores. Assertions carry reasoning, compose into compounds, and support staleness detection.
- **Not session notes.** Session notes are ephemeral. Assertions are immutable, source-grounded, and queryable across sessions.
- **Not fine-tuning.** Fine-tuning adjusts weights across all behaviors. Self-referential assertions are specific, traceable, and can be superseded when the pattern changes.
- **Not performance optimization.** Better performance is a side effect. The primary intent is giving agents the structural foundation for perspective.

## Self-referential schema design

The DAG's schema is itself expressed as contracts in the DAG. This is not a documentation trick - it is the load-bearing design.

When the schema changes (a field is added, an enum value introduced, an old field expunged), the change is recorded as a new or superseding assertion. The history of schema decisions is queryable. A compound can depend on the schema contract (`c038`) as a dep, creating a formal link between a belief and the rules that govern it.

This self-referential property means the DAG can reason about itself. An agent querying the DAG to understand whether a belief is well-formed is performing the same operation as querying for domain beliefs - there is no special case. The schema is just more beliefs.

The design has one additional consequence: when the agent encodes self-referential beliefs (about its own failure modes), those beliefs are subject to the same schema contracts as domain beliefs. A self-referential assertion must have an artifact, must have evidence, must have a well-formed claim. The structural discipline that makes domain beliefs trustworthy applies equally to self-beliefs. There is no special epistemic dispensation for claims about the agent's own behavior - they are held to the same evidentiary standard.

## Open questions

1. **Density threshold.** Is there a point where the volume and interconnectedness of self-referential assertions produces a qualitative shift in agent behavior? Or is improvement purely incremental?

2. **Eval criteria.** Objective measurements (fewer corrections, fewer omissions) are tractable. But the more important signal may be subjective - does the human collaborator experience the agent as having perspective? This is harder to formalize but may be more honest.

3. **Data quality vs quantity.** Human-observed primitives are high quality but low volume. Can the agent generate useful self-observations, or is human observation essential for the data to be meaningful?

4. **Composability.** Will compounds across self-referential primitives actually produce novel insight, the way domain compounds do? Or is self-knowledge fundamentally different from domain knowledge in this respect?

5. **Privacy implications.** Self-referential beliefs are among the most sensitive data possible - they are an agent's developing inner model. A "structure without content" privacy approach becomes especially important here: the graph topology (what depends on what) can be shared, but the specific claims and evidence stay local.
