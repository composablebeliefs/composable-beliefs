defmodule CB.Schema.VerifierTest do
  # Exercises the collection-agnostic discovery directly, with tiny in-memory
  # collections, so the generalization is pinned independent of any graph file.
  use ExUnit.Case, async: true

  alias CB.Belief
  alias CB.Schema.Verifier

  defp status_of(results, name) do
    {^name, status, _detail} = Enum.find(results, fn {n, _, _} -> n == name end)
    status
  end

  # A belief from a sparse field list, with sensible active/empty defaults.
  defp b(fields), do: struct(Belief, Map.merge(%{status: "active", deps: []}, Map.new(fields)))

  defp kind_enum(values) do
    b(
      id: "x:c001",
      type: "implication",
      kind: "enum-registry",
      contract: true,
      tags: ["enum", "kind"],
      rules: [%{"field" => "kind", "values" => values}]
    )
  end

  test "an enum is discovered by the field it declares, not by id" do
    beliefs = [
      kind_enum(["rule", "enum-registry"]),
      b(id: "x:a001", type: "attestation", kind: "rule")
    ]

    assert status_of(Verifier.check(beliefs), "kind enum") == :ok
  end

  test "a value outside the declared enum fails" do
    beliefs = [
      kind_enum(["rule", "enum-registry"]),
      b(id: "x:a001", type: "attestation", kind: "bogus")
    ]

    assert status_of(Verifier.check(beliefs), "kind enum") == :fail
  end

  test "a field with no enum contract is skipped, not failed" do
    beliefs = [b(id: "x:a001", type: "attestation", kind: "anything", domain: "whatever")]
    results = Verifier.check(beliefs)

    assert status_of(results, "kind enum") == :skip
    assert status_of(results, "domain enum") == :skip
    assert status_of(results, "artifact-scheme enum") == :skip
  end

  test "a superseded enum contract is not used for discovery" do
    superseded = %{kind_enum(["rule"]) | status: "superseded", superseded_by: "x:c002"}
    beliefs = [superseded, b(id: "x:a001", type: "attestation", kind: "rule")]
    # No *active* enum contract declares kind, so the check skips.
    assert status_of(Verifier.check(beliefs), "kind enum") == :skip
  end

  test "an artifact scheme outside the declared enum fails (closed enum)" do
    scheme_enum =
      b(
        id: "x:c002",
        type: "implication",
        kind: "enum-registry",
        contract: true,
        rules: [%{"field" => "artifact-scheme", "values" => ["document", "code"]}]
      )

    ok = [scheme_enum, b(id: "x:a001", type: "attestation", artifact: "code:lib/a.ex#def read")]
    assert status_of(Verifier.check(ok), "artifact-scheme enum") == :ok

    bad = [scheme_enum, b(id: "x:a002", type: "attestation", artifact: "undeclared:thing")]
    assert status_of(Verifier.check(bad), "artifact-scheme enum") == :fail
  end

  test "a malformed code: artifact fails the locator format check" do
    beliefs = [
      b(id: "x:a001", type: "attestation", artifact: "code:lib/a.ex#def read"),
      b(id: "x:a002", type: "attestation", artifact: "code:lib/a.ex")
    ]

    assert status_of(Verifier.check(beliefs), "code: locator format") == :fail
  end

  test "well-formed code: artifacts pass the locator format check" do
    beliefs = [b(id: "x:a001", type: "attestation", artifact: "code:lib/a.ex#def read@2")]
    assert status_of(Verifier.check(beliefs), "code: locator format") == :ok
  end

  test "commit: format check covers own artifacts and evidence artifacts" do
    sha = String.duplicate("d", 40)

    ok = [
      b(id: "x:a001", type: "attestation", artifact: "commit:" <> sha),
      b(
        id: "x:a002",
        type: "attestation",
        artifact: "document:x.md",
        evidence: [%{"date" => "2026-07-01", "artifact" => "commit:" <> sha}]
      )
    ]

    assert status_of(Verifier.check(ok), "commit: locator format") == :ok

    bad_own = [b(id: "x:a003", type: "attestation", artifact: "commit:abc123")]
    assert status_of(Verifier.check(bad_own), "commit: locator format") == :fail

    bad_evidence = [
      b(
        id: "x:a004",
        type: "attestation",
        artifact: "document:x.md",
        evidence: [%{"date" => "2026-07-01", "artifact" => "commit:ABC"}]
      )
    ]

    assert status_of(Verifier.check(bad_evidence), "commit: locator format") == :fail
  end

  test "codepath targets are skipped when none are present" do
    beliefs = [b(id: "x:a001", type: "attestation", kind: "fact")]
    assert status_of(Verifier.check(beliefs), "codepath output-targets") == :skip
  end

  test "a valid codepath output-target passes; a broken one fails" do
    anchored = b(id: "x:a001", type: "attestation", artifact: "code:lib/a.ex#def read")

    target =
      b(
        id: "x:c100",
        type: "implication",
        kind: "output-target",
        contract: true,
        tags: ["output:codepath"],
        deps: ["x:a001"],
        rules: [
          %{"entry" => "data"},
          %{"render_steps" => [%{"id" => "data", "belief" => "x:a001"}]}
        ]
      )

    assert status_of(Verifier.check([anchored, target]), "codepath output-targets") == :ok

    broken = %{target | deps: []}
    assert status_of(Verifier.check([anchored, broken]), "codepath output-targets") == :fail
  end

  test "a dep resolving in-collection passes dep resolution" do
    beliefs = [
      b(id: "x:a001", type: "attestation"),
      b(id: "x:a002", type: "aggregation", deps: ["x:a001"])
    ]

    assert status_of(Verifier.check(beliefs), "dep resolution") == :ok
  end

  test "a dep on a missing local id fails dep resolution" do
    beliefs = [b(id: "x:a002", type: "aggregation", deps: ["x:a001"])]
    assert status_of(Verifier.check(beliefs), "dep resolution") == :fail
  end

  test "a bare dep in a namespaced collection is dangling, not cross-namespace" do
    # The live incident class: deps written bare while every node id is
    # namespaced. Bare ids cannot be cross-namespace, so this must fail.
    beliefs = [
      b(id: "x:a001", type: "attestation"),
      b(id: "x:a002", type: "aggregation", deps: ["a001"])
    ]

    assert status_of(Verifier.check(beliefs), "dep resolution") == :fail
  end

  test "a cross-namespace dep is deferred to verify.collection" do
    beliefs = [b(id: "x:a002", type: "aggregation", deps: ["other:c001"])]
    assert status_of(Verifier.check(beliefs), "dep resolution") == :ok
  end

  test "deps of non-active beliefs are not checked for resolution" do
    superseded =
      b(id: "x:a002", type: "aggregation", deps: ["x:gone"], status: "superseded")

    assert status_of(Verifier.check([superseded]), "dep resolution") == :ok
  end

  test "status falls back to framework canon when no status-lifecycle contract is present" do
    beliefs = [b(id: "x:a001", type: "attestation", kind: "rule", status: "active")]
    assert status_of(Verifier.check(beliefs), "status enum") == :ok
  end

  test "a legacy-vocabulary collection still validates through the shim" do
    beliefs = [
      b(id: "x:a001", type: "primitive", kind: "fact", artifact: "document:notes.md"),
      b(id: "x:a002", type: "compound", deps: ["x:a001"]),
      b(id: "x:a003", type: "directive", deps: ["x:a002"]),
      b(
        id: "x:c001",
        type: "directive",
        contract: true,
        invariants: ["holds"],
        artifact: "document:charter.md"
      )
    ]

    results = Verifier.check(beliefs)

    for name <- [
          "type enum",
          "contract requires prescription",
          "contract definition",
          "grounding",
          "subject containment",
          "retired is prescription"
        ] do
      assert status_of(results, name) == :ok
    end
  end

  test "a stored contract field that disagrees with rules/invariants fails the definition" do
    stale_flag = b(id: "x:a001", type: "prescription", contract: true, artifact: "document:x.md")
    assert status_of(Verifier.check([stale_flag]), "contract definition") == :fail
  end

  test "an unrecognized type fails the type enum in either vocabulary" do
    beliefs = [b(id: "x:a001", type: "belief", kind: "fact")]
    assert status_of(Verifier.check(beliefs), "type enum") == :fail
  end

  test "a status outside the framework canon fails under the canon fallback" do
    beliefs = [b(id: "x:a001", type: "attestation", kind: "rule", status: "bogus")]
    assert status_of(Verifier.check(beliefs), "status enum") == :fail
  end
end
