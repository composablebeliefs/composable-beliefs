# Chronicle: the desk meets reality

**Span:** 2026-06-23, a short desk-status review continuing the plan-app /
provenance arc.
**Register:** chronicle (cb:a520) - narrative for the operator; the records are
the a537 discharge, the a535 scope evidence, and the operations.md discharge
procedure.

## Where things stood

A previous close had left a handful of desk items the operator wanted
re-checked against the live repos: the four directives this arc minted or
flagged (a535 collection-split, a536 firewall-predicate, a541
plan-as-directive-view, a542 status mis-bucket), plus a red test and a537,
which a concurrent session had touched. Two days of other sessions had moved
the repos on - the knowledge: collection and the OKF standard had landed, and
cb:a518 had advanced - so the question "are these still needed?" was real.

## The arc

The review resolved each item against the repo rather than memory. The c043
schema test, flagged red last session, was green again: a sibling had fixed it
after the c043 -> c066 artifact-scheme supersession. a537's tool (`mix
cb.repoint`) had shipped at ac3e199, so a537 was effectively done but still
active on the desk.

The discharge of a537 ran into the first incident worth keeping: there is no
clean "mark discharged" verb for work that shipped out-of-band. The honest
path - verify the shipped code against the directive's spec from source,
materialize with a single action-item naming the discharging commit, then close
the todo - is now written into operations.md so the next session does not
rediscover it. a537 verified clean (atomic drop+add, dry-run default,
dangling-target refusal) and discharged.

The second incident was a concurrency one, and a live demonstration of why
cb:a538 sits on the desk: a one-line evidence append on a537 had to wait
because beliefs.json carried another session's three uncommitted beliefs
(a549-a551), and the single JSON file cannot be partially staged. The write
deferred until that session committed and the tree went clean - exactly the
commit-hygiene friction a538 names.

The operator drove the close discipline throughout, repeatedly asking the
persistence question in different forms (is it a node, is it a plan artifact,
will /end catch it). The one genuinely chat-only nugget that surfaced: a535's
scope has widened since it was minted - with the knowledge: collection now in
belief-collections, the split is a whole collection-to-org topology decision,
not just method:/eval-provenance. That refinement is now evidence on a535.

## Where things stand

a537 is discharged and off the desk. a535 carries its widened scope. a536
(blocked on the verifier predicate), a541 (a real plan-app feature awaiting a
focused session), and a542 (a trivial fix-choice) stay as active nodes -
nothing about them was lost, since their own claims already carry what a review
would add.

## What the next session inherits

a541 is still the thread to pull for the plan-app dashboard. a535, when picked
up, is now correctly scoped as the full collection-to-org map. And the desk is
one item lighter and one degree closer to reality.
