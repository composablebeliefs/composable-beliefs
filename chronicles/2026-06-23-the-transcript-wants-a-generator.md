# 2026-06-23 - The transcript wants a generator

**Span:** a returning thread - refreshing the eval worked-example doc against a repo that moved underneath it, and minting the obligation that the refresh keeps recurring.
**Register:** chronicle (cb:a520); receipts in `cb:a549` (the obligation), commits `29a2471` and `9ea6433` (the two refreshes of `docs/worked-example-eval-verdict.md`).
**Verbatim record:** [`2026-06-23-the-transcript-wants-a-generator.jsonl`](2026-06-23-the-transcript-wants-a-generator.jsonl) - a byte-for-byte copy of the Claude Code session log (session `823e19fc`), the immutable provenance; this chronicle is the readable summary. The session spans more than this chronicle's arc (it carries the earlier eval-provenance and worked-example build); the chronicle narrates its tail. Stored beside the chronicle rather than in a plan set because the thread was not plan-scale - the open question that `cb:a552` exists to settle.

## Where things stood

The worked example (`docs/worked-example-eval-verdict.md`) is a hand-pasted transcript: real `mix bs` / `mix cb.verify` output quoted verbatim, walking a reader from an eval verdict down to its raw logs. The thread that built it paused; the repo then moved - the okf-fold landed, the artifact-scheme enum was superseded twice (`c040 -> c043 -> c066`, the latter dropping the `gmail:` scheme as a connector-in-the-core cleanup), and the `method:` collection grew.

## The arc

Returning cold, the first instinct - "commit the tutorial" - was wrong twice over. The working tree had lost the old README edit, `/tmp` was cleared, and the doc had in fact already been regenerated weeks earlier into `docs/`. Surfacing that instead of committing a stale artifact was the right move. The real drift was narrow and split in two: the verify-transcript counts (from committed `method:` growth, safe to refresh) and the `cb:` supersession section (`c043` superseded by `c066`, uncommitted at the time, now committed). Refreshing the latter sharpened it rather than just patching it: the enum's history now teaches both an addition (`code:` via `c043`) and a removal (`gmail:` via `c066`) - one whole-contract supersession mechanism in both directions.

## Where things stand

The doc is current against committed HEAD again. But this is the second refresh of the same doc in one thread, and the cause is structural: pasted command output drifts whenever the graph moves. That is the `cb:a386` antipattern - freshness by procedural remembering - applied to a doc instead of a digest. Minted `cb:a549`: generate the transcript blocks from the graph, or add a doctest-style CI check that fails when a block goes stale, rather than hand-maintaining them.

## What the next session inherits

`cb:a549` on the desk. The fix is a generator or a verifier, not another manual pass - the next manual refresh is the signal it is overdue. The generator-vs-checker tradeoffs and a leaning (start with the CI checker, promote to a generator only if reproducing the doc's curated/elided blocks proves cheap) are recorded as evidence on the node, so the choice arrives analyzed, not just posed.
