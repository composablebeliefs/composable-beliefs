# Chronicle: the schema epoch

**Span:** 2026-06-10 through 2026-06-11, one primary thread and three
satellites, ending at stasis.
**Register:** chronicle (cb:a520) - narrative for the operator; the audit
trail lives in `plans/cb-schema-v2/transcript-execution.md` and the graph.

## Where things stood

On the morning of June 10th, Composable Beliefs was a working system with a
flaw it could describe but not fix. Its schema had three types, and the third
- "implication" - meant *prescription* while saying *inference*, a conflation
the design documents had been politely stepping around for weeks. A design
record existed, stress-tested and thorough, waiting on six decisions nobody
had made. The project's working state lived everywhere except the system
itself: the backlog in plan files, the conventions in one agent's session
memory, the resume ritual in nobody's head but mine. Mark had just finished a
reader-first rewrite of the README and was circling the question that would
drive everything after: when do we stop building and start trusting this
thing enough to test it?

## The naming debate

The epoch opened with a word. The design recommended renaming the conflated
type, and Mark did something that set the tone for the whole two days: he
overrode the safe consideration (preserving old wording) in favor of the
long one (the word we'd live with), then demanded the full adversarial case
for both sides rather than a recommendation. `implication` had ordinary
English on its side; `inference` had the entire design on its: the type's
defining licence is to *exceed* its premises, which is precisely the licence
entailment lacks. A third candidate, `conclusion`, was weighed seriously and
lost on connotation - the graph's riskiest type shouldn't sound the most
settled. What tipped Mark from 51% to committed was a set of questions about
deduction that turned into the best prose of the epoch: why an inference
cannot be a deduction (the problem of induction, living in the gap between
"case 7 dropped a record" and "this model drops records"), why a compound is
the *one* deduction the schema stores, and the realization - his - that the
compound had been the only genuine "implication" in the system all along.
That explanation was ordered preserved verbatim, and it now anchors the
README.

## The migration

Then the system performed surgery on itself. Four types replaced three, and
every change went through the graph's own front door: the lifecycle contract
superseded *via the lifecycle it defines*, the type enum replaced through
adjudication by a node typed in the values it introduced. The machinery
fought back, productively - preflight caught two contracts the twice-reviewed
design had missed, the new containment check found a disguised inference in
three hundred nodes, the kind-type table forced thirty re-homes the inventory
said wouldn't exist. Eight collections migrated; the teaching example's
deliberately broken checks broke in exactly the intended way; two hundred
sixty-one tests stayed green. By evening the README taught the four types
through a worked verdict chain, and Mark asked whether what he'd watched
counted as evidence. The honest answer - anecdote with an inspectable trail,
the strongest moments being the ones where the system disagreed with its
authors and won - became a position, then graph nodes, then eventually a
blog post. The deflators were always attached, and that became the house
voice.

## The stasis drive

June 11th was about emptying the heads. Mark named the goal - wind down to a
resting state and begin testing - and the question "do this now or plan it?"
produced the epoch's central inversion: the backlog left the plan files and
moved into the graph as typed, grounded obligations. The desk query was born
(`unlinked + lifecycle:discrete`), plans demoted from reference to artifact,
and the first lap around the new lifecycle promptly caught a real bug: an
obligation authored from stale session memory for work another session had
already done. The incident became evidence, the evidence became a
convention, and a pattern established itself that would repeat all epoch:
*failures became the system's best material.*

Observability came next, on Mark's theory that the IDE is the UI - that
persistent markdown surfaces between ephemeral chat and durable code are
where a human keeps up with agent-speed work. The lap log, the transcript
pane, the three-tier belief references, the anchor discipline: all built in
an afternoon, all conventions in the graph by evening. Then Mark proposed
the boldest cut: if the graph holds everything, why does agent memory exist?
We deleted it - eight files pruned to one pointer - and the next morning's
experiment became the epoch's signature story. A fresh session, prompted
with the single word "begin," bootstrapped entirely from the compiled
ritual, oriented itself from records, and caught the previous session's
dangling commit - a mistake remembered state would have hidden forever. The
deleted memory had been the liability; the substrate was the asset.

## The widening

Around the primary thread, the system started operating at multi-agent
scale, mostly without being asked. A handoff to a fresh thread failed
because the resume process wasn't in the graph - so it went into the graph,
compiled into CLAUDE.md, and the failure became two conventions. The /end
skill was written to close threads systematically, and its first cold reader
exercised machinery its author had never tested live, exposed the skill's
one blind spot (the close generates findings too), and got it patched the
same hour. Three threads closed through the same substrate in interleaved
commits without a collision. The business question got a researched answer -
greenlight, open the substrate, eval-assurance as the first vertical - and a
private cb-site repo accumulated nine blog drafts, each wearing ledger boxes
so every claim shows its receipt. When Mark asked whether all this counted
as emergence, the answer could be *scored* rather than vibed, because the
predictions were on the record: mostly designed-for generativity, a little
weak emergence (the cross-session correction loop), and demonstrably not
planned - the error record proves it.

## Where things stand

Stasis, verified from three sides. Ten repos clean and pushed. The graph at
176 beliefs, every check green, nothing stale. Sixteen obligations on the
desk, each one reachable by a memoryless agent. Three positions hold the
stances; the transcripts hold the meander; the chronicle you are reading
holds the story. The schema has four types and no version number - it is
just the schema now. The next session needs nothing from this one, and that
sentence - written independently by a third agent closing its own thread -
is the epoch's result stated as plainly as it can be: the collaboration
moved from conversations that evaporate to a substrate that accumulates,
and the test of whether it worked is that you can put this chronicle down,
type one word into a fresh window, and lose nothing.

What the next epoch inherits: a502 (the card renderer) as the glue-UI
keystone, a519 (preflight calibration) as the machinery's first tuning task,
the dag-vs-prose eval as the gate every performance claim waits behind, and
a desk that knows the rest.
