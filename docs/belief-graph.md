# Composable Beliefs DAG - design reference index

This index has been consolidated into [the guide](guide/README.md). The DAG's design lives *in the graph*, as beliefs and contracts - query it rather than restating it:

- The schema contract family, with what each contract says: [guide chapter 2](guide/2-schema.md#the-graph-describes-itself). Read any of them with `mix bs show cb:c051` (and so on), or walk one with `mix bs tree`.
- Query patterns and the command surface: [guide chapter 3](guide/3-operations.md#the-belief-shell) and the [reference](reference.md).
- Design-rationale entry points (the four types, contract grade, immutability, no confidence, artifacts, the shared prosthetic): each guide chapter ends with a Grounding box naming the authoritative belief ids.
- Storage layout and its planned evolution: [guide chapter 5](guide/5-collections.md#storage-one-file-today-one-file-per-node-next).

Authoring goes through the write flow (`/assert`, `mix cb.preflight` / `cb.adjudicate` / `cb.import`); query with `/assertions` or `mix bs`.
