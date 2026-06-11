# Position: Obligation lives in the graph; plans are its artifacts

**Type:** position
**Class:** design-policy
**Status:** active
**Authored:** 2026-06-11
**Origin:** the cb-schema-v2 execution thread (amieval, 2026-06-10/11), in the
wrap-up-to-stasis discussion; stance passages preserved verbatim below. The
user direction: persist the stance as a position document and extract each
point into the `cb:` graph - and home the document in this repo, since the
policy is the system's own.

The stance, verbatim (on whether plans-as-primary-work-reference has migrated
to graph nodes):

> **The graph becomes the index of obligation.** A directive is the framework's
> answer to "what must happen": grounded in deps or a stipulation, scoped by
> subjects, conflict-audited against its siblings, flagged stale when its
> premises fall, and queryable (`bs list unlinked` is the native backlog view).
> After [the four-type change] this is cleaner than it ever was, because the
> work-bearing type no longer shares a label with theories - a falsifiable
> conclusion structurally cannot be a todo anymore.
>
> **Plans demote from reference to artifact.** Look at what the schema already
> says: a382 defines `materialized` as `{plan, date, last_verified}` - *the
> plan is what a directive materializes into*. That's the relationship, and
> cb-schema-v2 itself ran in exactly this shape even before anyone named it:
> the obligation and its rationale landed in the graph (the canon beliefs, the
> contract supersessions), while `plans/cb-schema-v2/` holds what the graph
> can't carry at claim granularity - the worked stress-test, the choreography,
> the deviations, the transcript. The graph cites those files as `document:`
> and `plan:` artifacts; the files justify and record, the graph obligates and
> tracks. So plans/ stops being a parallel work-tracking system and becomes the
> library of designs and executions that directives point into and out of.

And on retention, from the follow-up exchange:

> Nothing about the demotion deletes or archives anything. The plan files stay
> exactly where they are, permanently, as source documents - they're the
> artifacts that `materialized.plan` fields, `document:`/`plan:` URIs, and
> evidence entries cite. The change is only in *direction of reference*: today
> you open plans/ to find out what to do; after the inversion you query the
> graph to find out what to do, and the graph points into plans/ for the how
> and the history.

This position extends standing canon rather than replacing it: `cb:a382`
("plans should encode intent, not implementation... intent lives in the DAG as
beliefs... everything else is a DAG assertion") stated the authoring-side half
in the era before the four-type schema gave obligation its own structural type.
What is new here is the obligation-index half, the retention rule, the backlog
query discipline, and the homing rule for documents like this one.

### Claim: The graph is the index of obligation - work to do lives as directives; plans/ and docs/ hold records of designs and executions, never live todos.
**DAG status:** extracted
**Belief:** [[cb:a489]]

### Claim: A plan is what a large directive materializes into; plan files are retained permanently as source documents, and the direction of reference inverts - query the graph for what is next, follow it into plans/ for how and history.
**DAG status:** extracted
**Belief:** [[cb:a490]]
**Anchor:** code:skills/assert/SKILL.md#materialized` field

### Claim: The lifecycle tag is load-bearing for the graph-as-backlog - recurring directives are standing rules that never materialize; the backlog query is unlinked plus lifecycle:discrete.
**DAG status:** extracted
**Belief:** [[cb:a491]]

### Claim: Framework-policy position documents live in this repo, because cb: beliefs ground in repo-relative document: URIs and a distributable framework must resolve every artifact its own graph cites; the homing boundary is unchanged - claims about CB-the-system land in cb:, claims about the world or mission land in collections.
**DAG status:** extracted
**Belief:** [[cb:a492]]

### Claim: The graph-as-work-index holds at authoring time and is untested at working time; whether sessions reach for the unlinked backlog rather than plan files is behavioral, and the stasis-then-test phase is the experiment that decides it.
**DAG status:** extracted
**Belief:** [[cb:a493]]
