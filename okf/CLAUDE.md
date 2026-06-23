# CLAUDE.md — okf/ (the OKF integration extension)

This directory is the **Knowledge methodology**: a portable OKF-based format for knowledge
across all my repos and productivity domains, with Composable Beliefs as an opt-in
rigor ceiling. It is **CB's OKF integration extension**, folded into composable-beliefs
beside the tooling that implements it (it used to be the standalone `knowledge` repo).

If you are a fresh agent pointed here:

- **"Adopt this methodology"** → read [`ADOPT.md`](ADOPT.md).
- **"Convert an existing store"** → read [`CONVERT.md`](CONVERT.md).
- **Understand the format** → read [`standard/KNOWLEDGE.md`](standard/KNOWLEDGE.md) first, then
  `standard/types.md`, `standard/frontmatter.md`, `standard/tiers.md`.
- **Understand why it's shaped this way** → [`meta/`](meta/) is the foundational design
  record (the originating session, the OKF-vs-CB analysis, the two-tier decision).
- **See it used** → [`demo/`](demo/) is a synthetic example bundle; start at
  [`demo/manifest.json`](demo/manifest.json).

The tooling lives alongside this directory in composable-beliefs (`mix knowledge.*`,
`lib/cb/knowledge/*`) as CB's OKF integration layer; run the mix tasks **from the repo
root** against a bundle path under `okf/`. After any change to an OKF bundle, regenerate
its manifest, e.g. `mix knowledge.manifest okf/demo` (and `… okf/meta`). Validate with
`mix knowledge.validate okf/<bundle>`.

**`okf/beliefs.json` is not an OKF bundle** — it (with `okf/manifest.json`) is the
methodology's own CB belief graph (the `okfx:` collection), read and written via the CB
graph tooling (`mix bs …`, the `cb.preflight`/`import` write flow), never the OKF tooling.
The handling rule is a consumer-owned operational directive in that graph, not restated
here (per [`standard/KNOWLEDGE.md`](standard/KNOWLEDGE.md) §1.1): `okfx:a003` —
`mix bs show okfx:a003 --beliefs okf/beliefs.json`.

This is a **standard, not an app**: [`conformance/`](conformance/) defines the
format as behaviour (fixtures + normative `expected/*.json`). The single implementation
(`mix knowledge.manifest`/`validate`, plus the `knowledge.emit`/`knowledge.ingest`
bridge) is held to that corpus by the repo's ExUnit conformance test
(`test/cb/okf_conformance_test.exs`), which must stay green.

Core rule: everything defaults to the **OKF floor** (plain markdown + frontmatter +
generated manifest). Promote a document to the **CB ceiling** (`tier: cb`, `id`, `deps`)
only when it trips the boundary test in `standard/tiers.md`.
