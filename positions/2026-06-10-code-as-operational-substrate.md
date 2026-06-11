# Position: Code is the operational substrate

**Type:** position
**Class:** design-policy
**Status:** active
**Authored:** 2026-06-10
**Origin:** agent discussion thread (amieval, 2026-06-10); stance passage preserved verbatim below, with emdashes transliterated to hyphens per repo formatting policy

The stance, verbatim:

> So I'd sharpen your phrasing: code isn't an abstraction layer that persists -
> it's the operational substrate, the only artifact in the system whose meaning
> is enforced by execution. NL discussion above it is fine, productive even,
> exactly when every claim terminates in an anchor into the substrate. What the
> IDE becomes is not the place humans write code - it's the adjudication
> surface, where claims meet the thing that actually runs. Reading code doesn't
> disappear; it gets re-scoped from "build a whole mental model" to "read the
> anchored stops that carry this argument." Which is what your Zed walkthrough
> already is: NL discussion terminating in code, rather than NL discussion
> instead of code.

This position states the design policy underlying the codepath machinery: it is
not self-documentation of what the graph contains but the philosophy that
licenses why the anchoring discipline exists at all. Claims below are staged
for extraction into the `cb:` collection; anchors point into this repo and
resolve against the repo root.

### Claim: Code is not an abstraction layer that persists; it is the operational substrate - the only artifact in the system whose meaning is enforced by execution.
**DAG status:** extracted
**Belief:** [[cb:a484]]

### Claim: NL discussion above the substrate is productive exactly when every claim terminates in an anchor into the substrate.
**DAG status:** extracted
**Belief:** [[cb:a485]]
**Anchor:** code:lib/cb/codepath.ex#defp resolve_anchor
**Anchor:** code:lib/cb/code_locator.ex#The resolved line number is never stored

### Claim: The editor's role shifts from authoring surface to adjudication surface - the place where claims meet the thing that actually runs.
**DAG status:** extracted
**Belief:** [[cb:a486]]
**Anchor:** code:skills/present-codepath/SKILL.md#the reader clicks, the editor navigates

### Claim: Reading code re-scopes from building a whole mental model to reading the anchored stops that carry an argument.
**DAG status:** extracted
**Belief:** [[cb:a487]]
**Anchor:** code:skills/present-codepath/SKILL.md#the reader reading the real file

### Claim: Agent claims about code must carry code: anchors that resolve at read time; an unresolvable anchor is an ungrounded claim.
**DAG status:** extracted
**Belief:** [[cb:a488]]
**Anchor:** code:lib/cb/codepath.ex#anchor "#{anchor}" not found in
