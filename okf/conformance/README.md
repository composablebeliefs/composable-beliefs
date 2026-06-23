# Conformance suite

The single source of truth for what "a valid Knowledge bundle" means, defined as
behaviour rather than prose. It is the **spec corpus**: the format is pinned by these
fixtures and their normative results, not by whatever the implementation happens to
print. This keeps the spec implementation-independent — the (one) Elixir implementation
in `composable-beliefs` is held to the corpus, and any future port can be checked the
same way.

## The contract

For every fixture under `fixtures/`, a conformant validator must emit, in `--json`
mode, exactly the object recorded in `expected/<fixture>.json`:

```json
{ "ok": <bool>, "errors": [{"path","code"}...], "warnings": [{"path","code"}...] }
```

with `errors` and `warnings` sorted by `(code, path)`.

**Only the `(severity, code, path)` triples are normative.** Human-readable messages,
the bundle root path, and ordering beyond the defined sort are NOT part of the contract,
so an implementation is free to word findings differently. The stable `code` values are
documented in the `CB.Okf.Validate` moduledoc (`composable-beliefs`).

## Running

The corpus is asserted by the repo's ExUnit conformance test
(`test/cb/okf_conformance_test.exs`): for each fixture it runs the validator and
diffs the contract object against `expected/<fixture>.json`. From the `composable-beliefs`
repo root:

```sh
mix test test/cb/okf_conformance_test.exs
```

It resolves this corpus from the in-repo `okf/conformance` (the standard now lives beside
the implementation), and skips only if the corpus is somehow absent.

## Fixtures

`fixtures/valid/` must produce `ok: true`; `fixtures/invalid/` each isolate a single
hard-check failure so a divergence points straight at the responsible rule:

| Fixture | Asserts |
|---|---|
| `valid_minimal` | a minimal well-formed bundle passes |
| `valid_cb_ok` | CB-tier docs with ids + resolving deps pass with no warnings |
| `valid_id_format_warns` | a nonstandard id warns (`id_format_invalid`) but stays `ok: true` |
| `invalid_bad_type` | `type_not_in_taxonomy` |
| `invalid_weak_description` | `description_missing_or_short` |
| `invalid_placeholder` | `placeholder_in_frontmatter` |
| `invalid_status` | `invalid_status` |
| `invalid_timestamp` | `invalid_timestamp` |
| `invalid_broken_link` | `broken_link` |
| `invalid_cb_no_id` | `cb_tier_missing_id` |
| `invalid_dup_id` | `duplicate_id` |
| `invalid_stale_manifest` | `manifest_stale` |
| `invalid_missing_manifest` | `manifest_missing` |

## Changing the corpus

Fixtures and their `expected/*.json` are maintained by hand. When adding or changing a
fixture, author both the bundle (including a fresh `manifest.json`, via
`mix okf.manifest <fixture>`) and its expected result, then run the conformance
test. Each `expected/*.json` must reflect the fixture's *intended* outcome — review it,
don't just paste whatever the validator currently prints.

A fixture is one isolated failure: keep `fixtures/invalid/*` to a single hard-check each,
so a divergence points straight at the responsible rule.
