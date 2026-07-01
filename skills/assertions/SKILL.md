Traverse and query the composable beliefs DAG from `beliefs/beliefs.json`. Read-only.

See `docs/belief-graph.md` for the canonical system reference.

## Input

`$ARGUMENTS` is an optional filter or subcommand. Empty = all active beliefs.

**Subcommands:**
- `tree <id>` - render full dependency tree from a node
- `stale` - find aggregations with superseded/retracted deps

**Filters:**
- Type: `attestation`, `aggregation`, `inference`, `prescription` (structural form - attest, aggregate, infer, prescribe)
- Kind: `kind:<slug>` (semantic form, e.g. `kind:rule`, `kind:observation`)
- Tag: `tag:<tag>` or `--tag <tag>` (cross-cutting concerns)
- Domain: `domain:<domain>` (e.g. `domain:agent`, `domain:ops`)
- Status: `active`, `superseded`, `retracted`, `retired`, `all` (default: active only)
- `contracts` - only nodes with rules/invariants
- `unlinked` - unmaterialized prescriptions (no todos created yet)
- Subject ref path (e.g. `policy/loan-period`)
- Subject type (e.g. `subject_type:policy`)
- `-v` for verbose output

Multiple filters combine: `/assertions aggregation kind:rule`

## Steps

1. Run `mix bs list $ARGUMENTS` for the CLI output.
2. If the user asks for a tree, use `mix bs tree <id>`.
3. If the user asks about stale assertions, use `mix bs stale`.
4. For detail on a single assertion, use `mix bs show <id>`.
5. Interpret and explain results - especially for aggregations, inferences, and prescriptions, explain the reasoning chain and what the deps mean together. An aggregation states exactly what its deps jointly state; an inference exceeds them and is falsifiable on its own; a prescription prescribes and is violated or withdrawn, never falsified.

## Rules

- Read-only - never modify beliefs.json
- When showing trees, explain the reasoning chain in plain English
- Flag deps that are `superseded`/`retracted` as stale
- Flag unmaterialized prescriptions as candidates for `/materialize`
