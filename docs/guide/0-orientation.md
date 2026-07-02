# 0 · Orientation: why a belief graph

Frontier agents already know an enormous amount. They fail at a different thing: surfacing the one consideration that matters at the moment a decision is made, and giving the person who runs them something to inspect afterward. This chapter makes the case for storing an agent's reasoning as a graph, and previews the four moves the rest of the guide teaches in full.

## The problem: attention, not storage

Reach for a belief graph because of a specific, observed failure. Frontier models already know most things; the gap is rarely what they have stored but whether the relevant claim surfaces at the instant a choice is made. A bigger context window or a better recall store keeps more around, and the relevant fact can still fail to arrive when the agent needs it. The graph exists to be a shared prosthetic for both a human's bounded attention and an agent's context loss: one queryable structure that makes the right node findable on demand (`cb:b460`).

The usual way to steer an agent makes this worse, because it leaves nothing to check. The status quo is a hand-written instruction file in plain English - a `CLAUDE.md`, a set of skills. A flat instruction like "always verify sources" tells the agent what to do and tells the operator nothing about why it is there, on what grounds, or whether it still holds. There is no source to read back to, no dependency to follow, no history of how the rule changed. A belief carrying its source, its dependencies, and its lifecycle gives you all three, so a human can audit why an agent decided something rather than taking the instruction on faith.

A second failure is invisible from inside any single session. In the system this framework grew out of, several agent sessions held conflicting facts across different contexts and none surfaced the conflict, because each session saw only its own slice. A prompt is one session; a belief graph is all of them at once. Putting the claims in a shared, persistent structure turns a contradiction into something structural - a thing a query can find rather than a thing a human has to remember to look for.

```
A flat instruction              A belief
------------------              --------
"always verify sources"         claim:    "verify sources"
                                grounded: a named source
- one session's view            - its deps and full history
- nothing to audit              - you can audit the grounds
- contradictions hide           - conflicts become queryable
```

> **Pitfall.** "The fix is more memory." Because the symptom looks like forgetting, the instinct is to add a larger context window or a recall system. Those address storage. When the real failure is that the right consideration never surfaced, or that two sessions silently disagreed, more storage leaves it untouched. The lever is structure that makes the relevant claim findable and makes contradiction detectable.

## What Composable Beliefs is

> **Key idea.** Composable Beliefs (CB) is a directed acyclic graph of immutable, source-grounded, composable claims that gives an agent persistent, inspectable reasoning across session boundaries. Every node names the source it came from, every change leaves a trace instead of overwriting, and the path that reads the graph is plain deterministic traversal with no model in the loop (`cb:b478`, `cb:b539`).

The unit of the graph is a [belief](../glossary.md#belief): a single atomic claim that carries a structural type, a kind, a domain, the claim text, either its provenance or its dependencies, what it is about, and a lifecycle status (`cb:b478`; in code, the `%CB.Belief{}` struct in `lib/cb/belief.ex`). Each of those fields earns a section later; the shape to hold now is that a belief is small, structured, and self-describing.

Three adjectives in the definition are load-bearing. **Source-grounded** means every claim traces to where it came from, so a later reader can ask the only question that keeps a graph honest: does this claim actually follow from that source? **Immutable** means a change is a new node that supersedes the old one rather than an edit in place, so history stays intact and drift shows up as a stale dependency you can detect rather than vanishing silently. **Composable** is the heart of the name, and gets its own section below.

"Directed acyclic graph" unpacked, for a reader new to the term: nodes joined by arrows, each arrow running from a claim to the earlier claim or source it was built on. Directed means each arrow points one way; acyclic means the arrows never loop, so following support backward always bottoms out at original sources. "Deterministic traversal with no model in the loop" describes how an answer is read out: you mechanically follow arrows, and nothing - no language model, no ranking, no similarity guess - sits between the question and the result. The same query always returns the same answer, and a person can re-check the path by hand.

## The four moves, previewed

Every belief records exactly one of four epistemic operations, and the operation it records is its structural type - a closed enum, one value per operation, that determines which other fields even apply (`cb:b051`, design rationale `cb:b470`). One operation per type is the whole design, not an accident of naming. Chapter 1 teaches each in full; here is the map.

| Operation | Structural type | What it records |
| --- | --- | --- |
| attest | `attestation` | one atomic statement of what a single source said |
| aggregate | `aggregation` | a conjunction stating exactly what its deps jointly state |
| infer | `inference` | a conclusion licensed to exceed what its deps state, paid for by being independently falsifiable |
| prescribe | `prescription` | a rule, policy, or guidance the house stands behind |

The split does real work. Attest and aggregate stay inside their sources: an attestation says what one source said, and an aggregation says only what its parts already say together. Infer is the one move allowed to generalize past its evidence, and it pays for that licence by being falsifiable on its own. Prescribe is the only move that says what *should* happen rather than what *is*.

## Why "composable"

The name points at the move that carries the value. The graph is not built to find a fact you already filed; it is built to conclude what follows from combining facts that live in different places. A composition can state something true that no single source ever states, and that conclusion is exactly the kind of consideration a single session tends to miss (`cb:b462`).

```
  attestation A               attestation B
  "source 1 said X"           "source 2 said Y"
          \                       /
           \  deps         deps  /
            v                   v
      +-------------------------------+
      | Z: concluded from A and B     |
      | together, stated by neither   |
      | alone                         |
      +-------------------------------+
```

> **Why this matters.** Retrieval and composition answer different questions. "What did we already record about X?" is retrieval. "What follows, given everything we have recorded?" is composition over retrieval, and it is the question that catches the conflict no single document contains (`cb:b462`, `cb:b539`). The two are not rivals at one job; the graph sits a layer above whatever stores the raw material.

## What CB refuses to be

A system is defined as much by what it declines to do. Composable Beliefs is a reasoning and audit substrate, not a memory system, and that boundary is itself a codified prescription in the graph rather than a preference (`cb:b539`). Vector memory, model calls, recall and retrieval, and the execution of any downstream task all stay outside its scope. CB layers over whatever memory or recall system you already run rather than growing into one.

The reason is concrete. Building retrieval into the read path would put a model, a ranker, or a similarity search between a question and the answer the graph returns. That would forfeit the single property the framework exists to provide: a deterministic, model-free read path, where traversing the graph yields the same answer every time and a human can re-check it by hand.

> **Caveat.** "Substrate" is a precise claim, not modesty. CB is the layer that holds typed, grounded, supersedable claims. It is not the store of raw documents, and whatever holds the underlying material - a wiki, a document store, a vector index - is a source below CB, privileged by nothing in the schema. CB composes over memory systems rather than competing with them.

## Where it came from

Composable Beliefs was not designed on a whiteboard. It was extracted from a real production agent system running a live operation, where the agent's own instruction file was compiled from a belief graph rather than written by hand. Each prescription the agent followed was a pointer into the graph, carrying the source it rested on and the record of how it had changed. The framework is what remained once that machinery was generalized and lifted out of the application it grew up inside.

That origin sets the altitude of this whole guide. CB is defined by its mechanism - typed, immutable, source-grounded, composable claims on a dependency graph with a deterministic read path - never by any single thing it has been used for. The mechanism is the part you can check against the code and the graph. The applications live downstream of it; the first of them, grounding model-evaluation findings, is [chapter 7](7-eval-ledger.md).

---

Next: [chapter 1, the epistemic core](1-epistemics.md) - the four types in full, the licensing idea, immutability, and why there are no confidence scores.

> **Grounding.**
> - In the graph: `cb:b460` (the shared-prosthetic framing), `cb:b462` (composition over retrieval - the value is reasoning, not lookup), `cb:b539` (CB is a reasoning and audit substrate, not a memory system, with a deterministic LLM-free read path), `cb:b478` (the one-paragraph definition of the mechanism), `cb:b051` / `cb:b470` (the four types, one per epistemic operation).
> - In the code: `lib/cb/belief.ex` (the `%CB.Belief{}` struct and its enums).
