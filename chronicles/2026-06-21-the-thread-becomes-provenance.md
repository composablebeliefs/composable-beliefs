# Chronicle: the thread becomes provenance

**Span:** 2026-06-21, a short methodology-and-tooling session continuing an
earlier governance arc.
**Register:** chronicle (cb:a520) - narrative for the operator; the durable
record is cb:a540 with the /end skill patch, and cb:a541/a542 on the desk.

## Where things stood

A prior close had, for the first time, persisted a decision thread *verbatim*
into a private direction repo and retro-paired every belief it minted back to
it - following the a504/a507 precedent rather than any standing rule. The
operator asked the obvious next question: should that be a general policy, or
was it a one-off?

## The arc

The answer was yes, but scoped. A verbatim thread earns its cost only for
decision-weight sessions - ones that mint or supersede beliefs from a
stipulation, settle a stance, or adjudicate contradictions - not for routine
work, which the proportionality gate (cb:a496) already keeps light. The
mechanism was already most of the way there: cb:a520 mandates a transcript and
chronicle at every substantive close, and cb:a507 already pairs stipulations
with readable document pointers. The increment was small and real - a520's
transcript is the *condensed* record triggered by plan-scale work, so it does
not catch a strategy thread that mints directives but writes no plan, and it
does not require *verbatim*. cb:a540 composes on both: the verbatim
requirement plus the decision-weight trigger, homed by subject, with every
minted belief retro-paired. The /end skill step 5 now enforces it, and a540
names itself the bridge until cb:a518 makes the real JSONL transcript
resolvable.

The session's second half tested a related belief the operator held: that
plans had been decomposed into directive nodes, with the directives as the
SSOT. Half right. Reading plan-app (the federated planning dashboard) and the
materialize skill confirmed there is no plan-to-directive pipeline - plans are
standalone records that name beliefs only in prose, and the single mechanical
decomposition is directive-to-todos. But the deeper instinct was already graph
canon: cb:a489 ("the graph is the index of obligation; plans hold records,
never live todos") and cb:a382 ("plans encode intent, not implementation;
intent lives in the DAG as beliefs") say exactly that the directive is the SSOT
and the plan is a view. The provenance chain the operator proposed (thread ->
plan -> directives) was right as grounding but inverted in emphasis: the
directive is the deliverable, the plan optional scaffolding warranted only at
plan-scale.

## Where things stand

cb:a540 is live and enforced. plan-app's federated registry now includes
cb-direction (its one plan renders, confirmed against a running server). Two
desk items fell out: cb:a541 (render a plan as a live view over its directive
nodes, reusing the PlanApp.BeliefJoin machinery positions already use) and
cb:a542 (classify/1 anchors status patterns with ^, so a "largely superseded"
header mis-buckets as pending). The verbatim thread of this continuation was
appended to the governance arc's existing thread record in amieval-direction,
which a540, a541, and a542 all cite.

## What the next session inherits

The plan-as-directive-view (a541) is the substantive thread to pull if plan-app
is to become the auditable dashboard the operator wants - it turns a plan page
from a static doc into a live status board over the obligations it grounds. The
desk carries it alongside the older items; the strategy obligations
(belief-collections org split, firewall predicate upgrade) still wait on the
operator.
