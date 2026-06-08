# Contracts as the Intermediary Layer Between Domain Expertise and Code

**Date:** 2026-03-22
**Context:** Conversation about what abstraction layer replaces code when a human operates as architect/auditor rather than developer, using an agent-based operational system as test case.

---

## The Problem

Code and file trees are the wrong abstraction layer for a person straddling domain expertise and agentic coding supervision. Literal code/file structure is too low-level. Plain English does not have guarantees. There should be something in between.

## The Gap

An agent-based operational system already has implicit contracts scattered across multiple representations:

- A struct defines shape but not behavioral invariants.
- A skill defines a workflow but not its guarantees to callers.
- A rules file defines policy but can't be mechanically verified.

The gap is that these contracts are implicit and scattered. What's needed is an explicit layer where a domain expert can author commitments and a machine can enforce them.

## What Contracts Look Like

```
contract SyncRecords {
  input: data source with active label
  guarantees:
    - record created or updated in local store
    - downstream outputs reflect current model state
    - no data deleted, only added or updated
  requires:
    - read access to source
    - write access to local store
  violates_if:
    - record exists in output but not in model
    - model has fields not traceable to a source
}
```

This isn't code and isn't prose. It's a composable unit of system behavior that a domain expert can write, an architect agent can verify, and a coding agent can implement against. The domain expert doesn't need to know how sync works internally. The coding agent doesn't need to understand why these guarantees matter. The architect agent checks that implementations satisfy contracts and that contracts cover the domain.

## Contracts and Assertions: Two Sides of the Same Coin

Assertions encode beliefs about the world - facts grounded in evidence. Contracts would encode promises about system behavior - invariants that must hold across state transitions.

These are two sides of the same coin. An assertion says "this is true." A contract says "this will remain true." Together they form a complete system: assertions are the state, contracts are the invariants over that state.

Here's where it gets powerful: contracts can be assertions, and assertions can generate contracts.

A contract like "every confirmed record must have a source document" is both a system invariant and a domain belief. It lives in both worlds. You could express it as an assertion with an implication that materializes into a todo when violated - which is exactly what the `/materialize` operation already does.

Going the other direction: when you assert something enough times with enough consistency, that pattern is a candidate contract. If every sync operation for six months has preserved the invariant "no record deleted without explicit user action," that's an emergent contract worth codifying.

## Three Layers of the DAG

The assertion DAG evolves from two layers (assertions + implications) into three:

### Layer 1: Assertions
Beliefs about current state, sourced from evidence.
- "Record X has value Y, per source document Z"
- "Transaction confirmed per notification"
- Grounded in source documents, data feeds, manual input
- Can become stale, can be superseded

### Layer 2: Contracts
Invariants that must hold across state transitions.
- "Sync never deletes, only adds or updates"
- "Every confirmed record has a source document"
- "A core data struct always has required fields populated"
- Can apply to code (struct shape), skills (workflow guarantees), or domain rules (business logic)
- Verifiable mechanically - an architect agent can check them

### Layer 3: Implications
The edges connecting assertions and contracts, defining what happens when state changes or invariants are violated.
- "If this contract is violated, materialize a todo"
- "If this assertion changes, re-verify these contracts"
- "If this pattern holds for N iterations, propose it as a contract"

## Contracts Span Both Code and Skills

A key insight: contracts work as the abstraction layer for both implementation code and agent skills. A contract over an Elixir module (a core struct must always have required fields) and a contract over a skill (a sync skill guarantees no data deletion) use the same representation. This means a single system can express guarantees across the entire stack - from struct definitions to multi-step agent workflows - without requiring the domain expert to understand either layer's internals.

## Contracts as New Node Type vs. Assertion Subtype

Lean: new node type in the DAG, not `type: invariant` on existing assertions. Reason: assertions are claims about the world that can become stale and get superseded. Contracts are structural commitments that get violated or upheld - they have a fundamentally different lifecycle. An assertion that "record X has value Y" can be superseded by new information. A contract that "sync never deletes data" isn't superseded - it's either enforced or intentionally relaxed. Mixing them would muddy the semantics of both. But they should be first-class participants in the same graph, connected by implications, queryable by the same tools.
