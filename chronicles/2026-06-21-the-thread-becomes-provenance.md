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

## The continuation: cb:a518 lands, and grows a standard

A later same-day session set out to evaluate Google's just-published Open
Knowledge Format (OKF) - markdown plus YAML frontmatter, one required field,
untyped cross-links - as a generalized knowledge base across all the repos, and
to place it relative to CB. The layering came out clean: OKF is a transport
layer (how do I ship knowledge documents portably), CB the epistemic layer above
it (what does a claim mean, what does it depend on, is it still true). CB
serializes down to OKF; OKF cannot reconstruct CB up without inventing exactly
the discipline CB adds. The positioning - CB as a conformant OKF dialect, not a
rival format - went to cb-direction.

That evaluation turned into building it. A new standalone standard repo
(ob6to8/knowledge) defines an OKF profile with a two-tier rule (OKF floor for
cheap portable knowledge, CB ceiling opt-in where time-truth and audit matter),
a self-verifying validator, and a conformance suite that pins the format as
behaviour so more than one implementation can be checked for equivalence. CB
then grew its OKF integration layer: byte-equal Elixir ports of the manifest and
validate tools that pass the suite, plus the bridge - mix knowledge.emit projects
the 202-belief graph to an OKF bundle that validates clean, mix knowledge.ingest
lands a bundle as attributable primitives.

The arc's own theme paid off literally. cb:a540 had named itself the bridge
"until cb:a518 makes the real transcript resolvable" - and this session landed
cb:a518's mechanism: /end step 5 now duplicates the real session JSONL
byte-for-byte rather than reconstructing it, homed as a type:source per the new
standard. The thread stops being a faithful retelling and becomes the actual
file. This very session is the first to persist that way.

One operator correction worth carrying: the agent twice defaulted to keeping
only a summary and dismissed per-doc provenance backlinks as "too heavy" - the
same lossy-compression reflex, choosing the condensed artifact over the source.
The operator pushed back both times; the standard now keeps the raw source
beside the summary and records origin threads in frontmatter. Preserve the
source, derive the summary, never the reverse.

## Where things stand now

cb:a518 is advanced, not closed: new sessions are resolvable going forward, but
the retroactive registry mapping old session: slugs to their JSONL files is not
built, so it stays on the desk. The knowledge methodology got its own graph -
the knowledge: collection, co-located in the knowledge repo, registered and
verifying - so its obligations finally have a home that is not cb:. Four new desk
items fell out: knowledge:a001 (CONVERT pilot on SECOND-BRAIN), knowledge:a002
(apply the threads:[] convention repo-wide), cb:a543 (a global dotfiles directive
graph compiling to the global CLAUDE.md, the home for genuinely cross-project
obligations a cold agent should see), and cb:a544 (run the dag-vs-prose eval with
an OKF wiki as the prose-baseline arm).

## What the next session inherits

The standard is built and dogfooded but untested on a real foreign store: the
CONVERT pilot (knowledge:a001) is the proof it converts without losing
provenance, and the first exercise of the wikilink-to-deps transform. The
plan-as-directive-view (a541) still waits as the plan-app thread. And the
homelessness that surfaced this session - non-CB obligations having nowhere to
live until cb:a543 builds the global graph - is the structural gap to close next.
