---
type: concept
title: Retired vocabulary pollutes the agent read surface
description: Covers the gap the proto-belief rename left open - immutable claims and unswept living docs keep teaching retired registers (focus, brief, directive) to every agent that reads them, and agents echo the pollution silently. Candidate fix is render-time vocabulary aliasing on the id-alias precedent; a deprecated-graph-directory evacuation was considered and rejected.
tags: [nursery, vocabulary, observability, read-surface]
status: active
timestamp: 2026-07-03
maturity: active
threads: [2026-07-02-fold-chronicle-into-threads]
---

# Retired vocabulary pollutes the agent read surface

## The matter

The rename epochs (structural types, cb:b051 evidence; proto-belief vocabulary, cb:b569)
keep history immutable: claims minted before a rename carry their day's vocabulary
forever, and the house rule is "readers translate" (the guide's note on ids). The
2026-07-02/03 fold-chronicle session demonstrated that agents fail that rule silently: an
agent that had just implemented a cb:b578 supersession read cb:b567 ("focus brief") and
cb:b572 ("focus doc"), plus unswept living docs, and echoed the retired register straight
into its report - despite cb:b569 being live in the same graph. Translation-by-vigilance
is exactly the awareness-is-not-a-fix pattern (cb:b386, the Meehl argument in the README)
the framework exists to replace with structure. The read surface, not the storage, is the
problem: what an agent ingests by default should speak the current vocabulary.

## Where things stand

Three pollution sources, ranked by observed effect in the incident session:

1. **Unswept living docs** - freely editable, no immutability constraint; their rewrite
   is already desk-tracked (cb:b570) and simply unexecuted. Prerequisite to everything
   else: no render-time machinery can compensate for current docs teaching old words.
2. **Active load-bearing claims** minted just before a rename (cb:b567, cb:b572) - the
   hard case. They are current rules, not history; they cannot be evacuated or hidden,
   and superseding every claim on vocabulary grounds would churn identity to chase
   wording (the cost b051's label-migration-as-evidence precedent avoided).
3. **Superseded claims** - minor in practice; their status banner already frames them as
   history.

**Candidate fix: render-time vocabulary aliasing.** The graph solved the identical
problem for ids: the legacy letter-swap alias (cb:b566) translates at resolution time -
history stays immutable, the reading surface stays current, exact matches win. Code has a
second precedent: `CB.Belief.normalize_type/1` already accepts both type vocabularies for
the compat epoch. Vocabulary needs the same move at the shell's render layer: a curated
retired-register table (focus doc -> proto-belief document, brief -> proto-belief
document, directive -> prescription, primitive -> attestation, compound -> aggregation)
applied when `mix bs show`/`list` render claim prose. Substitution is riskier than the id
swap - "focus" is an ordinary English word - so the safer form is **annotation, not
rewriting**: render the retired term with its current equivalent alongside (e.g.
`focus doc [now: proto-belief document]`), so the agent ingests the translation without
the output misquoting the immutable claim.

**Considered and rejected: a deprecated graph directory.** Evacuating historical nodes to
a directory the graph does not load, with an instruction not to read them, fails three
ways. It amputates the audit trail - supersession chains, `mix bs history`, staleness
cascades, and the audit tree's struck-through-with-successor rendering all require
superseded nodes present in the graph; visible correction is the product, not a side
effect. It misses the main pollution source - the offending claims (b567, b572) are
active, not deprecated, and cannot be evacuated. And "an explicit command to the agent
not to read them" is procedural surfacing, the b386 pattern again; the incident happened
while reading permitted, active material. The kernel worth keeping from the idea is
default-read-surface hygiene: agents should not ingest retired registers by default -
which is what render-time aliasing achieves without moving a single node.

## Open

- Annotation format: inline bracket, footnote block after the claim, or a flag
  (`--translate`) - and whether annotation is default-on for agents.
- Where the alias table lives: as data the shell reads (a small JSON beside the graph),
  or as a contract-grade prescription whose rules are the table, so the mapping itself is
  a belief with provenance.
- Scope discipline: phrase-level entries only (the id-alias exact-match lesson); never
  bare common words.
- ~~Whether the worst active offenders (b567, b572) additionally warrant supersession~~ -
  executed 2026-07-03 as the option-2 test; findings below.

## The option-2 test (2026-07-03): executed, findings

Operator-decided ("I lean towards 2 as a test"): cb:b567 and cb:b572 were superseded by
meaning-identical re-issues in current vocabulary - cb:b581 and cb:b582 - through the
sanctioned doors. What two wording-only supersessions actually cost:

1. **Preflight is re-paid in full.** The re-issued claims re-triggered the known
   schema-token contract overlaps (cb:b052/b059 contract-level, cb:b398/b399 dag-schema),
   each re-adjudicated as topical overlap per the cb:b569 mint precedent - adjudication
   the original mints had already paid, repeated for zero new content.
2. **The cascade is transitive.** Two supersessions flagged five nodes: cb:b569 and
   cb:b578 directly, and cb:b570, cb:b577, cb:b540 through them. Two repoint passes
   (cb:b569 -> b581, cb:b578 -> b582) cleared it; each repoint stamped evidence on the
   repointed node.
3. **The mirrors leak.** The wording fix escaped the graph: the glossary's
   referenced-beliefs entries needed their dep lines and source line numbers re-done, and
   the nursery index and both documents' descriptions gained re-issue notes. Every
   surface that mirrors graph state is a maintenance obligation per supersession.
4. **Forward links now hop.** The minting documents' `minted:` records and manifest
   Minted cells still point at the originals (kept deliberately - they record the plant
   event), so every dereference passes through a superseded-see-successor banner,
   permanently.
5. **The ledger.** Per node: one preflight adjudication, one supersession write, one or
   more repoints, two-plus commits, and mirror maintenance - linear in nodes swept,
   transitive in dependents. Both conventions now read in current vocabulary at the top
   of `mix bs show`, which is what the test bought.

Net: confirms the scaling argument - re-issue is affordable for a handful of central
nodes and unaffordable as a rename-epoch policy. The class fix remains render-time
annotation or [graph-refounding](graph-refounding.md), which would launder vocabulary
wholesale at the milestone.

## Related

- [proto-belief-rename](proto-belief-rename.md) - the vocabulary settlement this gap
  trails; its spike item 2 became the cb:b570 sweep.
- cb:b570 - the residual sweep of living surfaces; prerequisite, desk-tracked.
- cb:b566 - the id letter-swap alias; the resolution-time-translation precedent.
- cb:b386 - the digest/awareness antipattern this doc applies to vocabulary.
