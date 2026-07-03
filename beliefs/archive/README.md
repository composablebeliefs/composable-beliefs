# Archive shelf

Graduated proto-belief documents live here. A proto-belief document graduates when
its matter reaches a terminal maturity - `planted` (its mint-manifest rows carry
belief ids), `composted` (decided-against, negative planted first), or `grafted`
(merged into a survivor). Graduation historicizes the document (date-stamp,
terminal maturity, `minted:`/forward links) and moves it out of the live nursery to
this shelf, so the working nursery holds only live deliberation.

This location resolves **Q7 of the seed-lifecycle deliberation (cb:b577)**: the
archive shelf is `beliefs/archive/`, a sibling outside the nursery bundle. The
operator's invisibility requirement - archived architecture must not sit in the
working hierarchy confusing fresh agents - is satisfied structurally: `mix
okf.manifest beliefs/nursery` scans `nursery/` only, so nothing here appears on the
live nursery read surface, and no tooling change is needed. Decided by the operator
2026-07-03.

Graduated documents are **not deleted** - they are the mandatory provenance every
minted belief traces back through (`document:` citations). When a document
graduates, any `document:` citations that pointed at its nursery path are repointed
here.

## Contents

- [end-skill-redesign.md](end-skill-redesign.md) - planted 2026-07-03 (cb:b583,
  cb:b584); the /end turn-separation redesign. First graduation onto this shelf.
