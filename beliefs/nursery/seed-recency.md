---
type: concept
title: Recency and dating for adjudicating competing seeds
description: Covers datestamping seed docs (last-edited) and their thread excerpts so an agent can rank competing seed positions by recency - resolved as a soft prioritization hint, with explicit contested-links as the hard resolution; the frontmatter field is the open mechanic.
tags: [nursery, provenance, recency, schema]
status: active
timestamp: 2026-06-26
maturity: active
threads: [2026-06-26-nursery-workflow]
---

# Recency and dating for adjudicating competing seeds

## The focus
When two seed docs hold competing positions (nursery-architecture vs transcript-format on
Layer-1, right now), how does an agent tell which is the live one? Datestamp both the seed
doc (last-edited) and each excerpted thread exchange inside it, so recency is legible at a
glance.

## Where it stands - resolved in principle
- **Recency is a soft prioritization hint, not the arbiter.** The newer doc is the
  probable live lean; that lets a fresh agent prioritize without reading the whole bundle.
- **Explicit contested-links are the hard resolution.** Where two seeds genuinely conflict,
  one carries a `contested`/supersedes link to the other; recency never silently decides.
  This keeps the nursery aligned with CB's discipline - competing positions resolve by
  authored supersession, not "newest wins" (there are no confidence scores; `README.md`).
  Datestamping makes staleness *visible*; it must not become the *judge*.
- **Already a live gap.** The existing `timestamp:` is creation-only and drifts -
  `per-belief-files.md` read `2026-06-25` while being edited `2026-06-26`. So this fixes an
  extant bug, not only adds a feature.

## Open: the field mechanic
What carries last-edited? Options: redefine `timestamp:` as last-edited; add a distinct
`last_edited:`/`updated:` field; or a `## Provenance` body table (the OKF per-touch
pattern, `okf/standard/types.md`). Whichever lands must stay a checked frontmatter field
(the nursery validates format) and survive the every-turn hook rewrite. Provisional default
in force now: this bundle treats `timestamp:` as last-edited (bumped on substantive edit).
Excerpt-level dating is the cheaper half and ships first - label each excerpt with its date.

## Related
- [transcript-format](transcript-format.md) - owns the excerpt mechanism this dates.
- [seed-absorption](seed-absorption.md) - fold-and-evacuate means competing docs exist only
  transiently (during an open contest), so recency only has to disambiguate that window.

## Thread excerpts (2026-06-26)
**User:** "datestamping both the seed docs (last-edited) as well as the excerpted thread
exchanges within the seed docs would help agents such as yourself determine prioritiation of
competing seed doc positions - for example, in this case, transcript-format is the most
recent."

**Claude (the resolution):** recency as a soft prioritization hint; explicit contested-links
as the hard resolution. Recency-as-tiebreaker cuts against CB's supersession discipline -
positions resolve by explicit, linked supersession, not "newest wins." Datestamping makes
staleness visible; it shouldn't become the arbiter.

**User:** "'recency as a soft prioritization hint; explicit contested-links as the hard
resolution' - agree."
