defmodule CB.BeliefTest do
  use ExUnit.Case, async: true

  alias CB.Belief

  @attestation_map %{
    "id" => "a001",
    "type" => "attestation",
    "kind" => "rule",
    "domain" => "ops",
    "tags" => ["loan-policy"],
    "claim" => "Standard loan period is 21 days",
    "artifact" => "document:policy/loan-policy-v3.md",
    "evidence" => [
      %{
        "date" => "2024-09-01",
        "artifact" => "document:policy/loan-policy-v3.md",
        "detail" => "Section 4.1 verbatim"
      }
    ],
    "subjects" => [
      %{"ref" => "policy/loan-period", "type" => "policy"}
    ],
    "status" => "active",
    "created" => "2024-09-01"
  }

  @aggregation_map %{
    "id" => "a013",
    "type" => "aggregation",
    "kind" => "observation",
    "tags" => [],
    "claim" => "Combined policy meaning",
    "subjects" => [
      %{"ref" => "policy/loan-period", "type" => "policy"},
      %{"ref" => "policy/overdue-definition", "type" => "policy"}
    ],
    "deps" => ["a002", "a005"],
    "status" => "active",
    "created" => "2024-09-15"
  }

  @prescription_map %{
    "id" => "a015",
    "type" => "prescription",
    "kind" => "rule",
    "tags" => ["hold-queue", "lifecycle:recurring"],
    "claim" => "When a hold expires the item returns to available",
    "subjects" => [
      %{"ref" => "policy/hold-queue", "type" => "policy"}
    ],
    "deps" => ["a014"],
    "materialized" => nil,
    "status" => "active",
    "created" => "2024-09-15"
  }

  @contract_map %{
    "id" => "c001",
    "type" => "prescription",
    "kind" => "state-machine",
    "domain" => "ops",
    "tags" => ["loan-lifecycle"],
    "claim" => "Loan lifecycle state machine",
    "contract" => true,
    "rules" => [
      %{
        "scenario" => "Checkout",
        "given" => "available",
        "when" => "borrowed",
        "then" => "checked-out"
      }
    ],
    "invariants" => ["An item cannot be both checked-out and available"],
    "subjects" => [],
    "deps" => [],
    "status" => "active",
    "created" => "2024-09-20"
  }

  # --- Struct tests ---

  test "from_map/1 creates attestation struct with correct fields" do
    a = Belief.from_map(@attestation_map)
    assert a.id == "a001"
    assert a.type == "attestation"
    assert a.kind == "rule"
    assert a.domain == "ops"
    assert a.tags == ["loan-policy"]
    assert a.claim == "Standard loan period is 21 days"
    assert a.artifact == "document:policy/loan-policy-v3.md"
    assert length(a.evidence) == 1
    assert hd(a.evidence)["detail"] == "Section 4.1 verbatim"
    assert length(a.subjects) == 1
    assert hd(a.subjects)["ref"] == "policy/loan-period"
    assert a.status == "active"
  end

  test "from_map/1 creates aggregation struct with deps" do
    a = Belief.from_map(@aggregation_map)
    assert a.type == "aggregation"
    assert a.deps == ["a002", "a005"]
    assert length(a.subjects) == 2
  end

  test "from_map/1 creates prescription struct with materialized" do
    a = Belief.from_map(@prescription_map)
    assert a.type == "prescription"
    assert a.materialized == nil
    assert a.deps == ["a014"]
  end

  test "from_map/1 defaults tags to empty list when missing" do
    map = Map.delete(@attestation_map, "tags")
    a = Belief.from_map(map)
    assert a.tags == []
  end

  test "from_map/1 defaults subjects to empty list when missing" do
    map = Map.delete(@attestation_map, "subjects")
    a = Belief.from_map(map)
    assert a.subjects == []
  end

  # --- Contract tests ---

  test "contract?/1 returns true for prescriptions with rules/invariants" do
    a = Belief.from_map(@contract_map)
    assert Belief.contract?(a)
  end

  test "contract?/1 returns false for attestations" do
    a = Belief.from_map(@attestation_map)
    refute Belief.contract?(a)
  end

  test "contract?/1 returns false for aggregations" do
    a = Belief.from_map(@aggregation_map)
    refute Belief.contract?(a)
  end

  # --- Type/status tests ---

  test "types/0 returns the four structural types" do
    assert Belief.types() == ~w(attestation aggregation inference prescription)
  end

  test "statuses/0 returns the lifecycle statuses" do
    assert Belief.statuses() == ~w(active superseded retracted retired)
  end

  # --- Structural support ---

  test "support/1 counts artifacts, evidence, and deps" do
    a = Belief.from_map(@attestation_map)
    s = Belief.support(a)
    # one artifact, one evidence entry with the same artifact -> 1 distinct
    assert s.artifact_count == 1
    assert s.evidence_count == 1
    assert s.dep_count == 0
  end

  test "support/1 counts distinct artifacts across evidence entries" do
    map = %{
      @attestation_map
      | "evidence" => [
          %{"artifact" => "document:a.md", "detail" => "..."},
          %{"artifact" => "document:b.md", "detail" => "..."}
        ]
    }

    s = Belief.support(Belief.from_map(map))
    # top-level artifact (v3.md) + two evidence artifacts, all distinct -> 3
    assert s.artifact_count == 3
    assert s.evidence_count == 2
  end

  test "support/1 counts deps for aggregation" do
    a = Belief.from_map(@aggregation_map)
    s = Belief.support(a)
    assert s.dep_count == 2
  end

  # --- Schema hygiene: dropped fields ---

  test "from_map/1 drops stale confidence/source/implication keys" do
    stale =
      @attestation_map
      |> Map.put("confidence", 0.8)
      |> Map.put("source", "legacy")
      |> Map.put("implication", "legacy prose")

    a = Belief.from_map(stale)
    json = a |> Belief.to_map() |> Jason.encode!()
    refute String.contains?(json, "confidence")
    refute String.contains?(json, "source")
    refute String.contains?(json, "implication")
  end

  # --- Round-trip tests ---

  test "round-trip from_map -> to_map preserves data" do
    a = Belief.from_map(@attestation_map)
    map = Belief.to_map(a)
    json = Jason.encode!(map, pretty: true)
    decoded = Jason.decode!(json)

    for {key, val} <- @attestation_map do
      assert decoded[key] == val,
             "Mismatch on #{key}: #{inspect(decoded[key])} != #{inspect(val)}"
    end
  end

  test "round-trip preserves aggregation data" do
    a = Belief.from_map(@aggregation_map)
    decoded = a |> Belief.to_map() |> Jason.encode!(pretty: true) |> Jason.decode!()

    assert decoded["type"] == "aggregation"
    assert decoded["deps"] == ["a002", "a005"]
    assert decoded["subjects"] == @aggregation_map["subjects"]
  end

  test "round-trip preserves contract data" do
    a = Belief.from_map(@contract_map)
    decoded = a |> Belief.to_map() |> Jason.encode!(pretty: true) |> Jason.decode!()

    assert decoded["type"] == "prescription"
    assert decoded["contract"] == true
    assert decoded["rules"] == @contract_map["rules"]
    assert decoded["invariants"] == @contract_map["invariants"]
    assert decoded["tags"] == ["loan-lifecycle"]
  end

  test "missing key is omitted in output" do
    map = Map.delete(@attestation_map, "evidence")
    a = Belief.from_map(map)
    json = a |> Belief.to_map() |> Jason.encode!()
    refute String.contains?(json, "evidence")
  end

  test "null fields serialize as null, not omitted" do
    a = Belief.from_map(@prescription_map)
    json = a |> Belief.to_map() |> Jason.encode!(pretty: true)
    assert String.contains?(json, "\"materialized\": null")
  end

  test "field set after from_map serializes even when source JSON lacked the key" do
    map = Map.delete(@prescription_map, "materialized")
    a = Belief.from_map(map)
    materialized = %{"date" => "2026-06-11", "todos" => [%{"id" => "t0001", "action" => "do it"}]}

    decoded =
      %{a | materialized: materialized} |> Belief.to_map() |> Jason.encode!() |> Jason.decode!()

    assert decoded["materialized"] == materialized
  end

  # --- Legacy vocabulary compat (the epoch shim) ---

  @legacy_attestation_map %{
    "id" => "a001",
    "type" => "primitive",
    "kind" => "fact",
    "claim" => "Old-vocabulary node",
    "artifact" => "document:policy/loan-policy-v3.md",
    "status" => "active",
    "created" => "2024-09-01"
  }

  @legacy_contract_map %{
    "id" => "c001",
    "type" => "directive",
    "kind" => "state-machine",
    "claim" => "Old-vocabulary contract",
    "contract" => true,
    "rules" => [%{"scenario" => "Checkout"}],
    "invariants" => ["An invariant"],
    "status" => "active",
    "created" => "2024-09-20"
  }

  test "normalize_type/1 maps the legacy names and passes current names through" do
    assert Belief.normalize_type("primitive") == "attestation"
    assert Belief.normalize_type("compound") == "aggregation"
    assert Belief.normalize_type("directive") == "prescription"
    assert Belief.normalize_type("inference") == "inference"
    assert Belief.normalize_type("attestation") == "attestation"
    assert Belief.normalize_type("bogus") == "bogus"
  end

  test "from_map/1 normalizes a legacy type on read" do
    assert Belief.from_map(@legacy_attestation_map).type == "attestation"
    assert Belief.from_map(@legacy_contract_map).type == "prescription"
  end

  test "to_map/1 round-trips legacy data byte-for-byte, type and contract included" do
    for map <- [@legacy_attestation_map, @legacy_contract_map] do
      decoded = map |> Belief.from_map() |> Belief.to_map() |> Jason.encode!() |> Jason.decode!()

      for {key, val} <- map do
        assert decoded[key] == val,
               "Mismatch on #{key}: #{inspect(decoded[key])} != #{inspect(val)}"
      end
    end
  end

  test "contract?/1 derives from rules/invariants, not the stored field" do
    # A stored contract: true with an empty payload is not contract-grade.
    stale_flag = Belief.from_map(%{"id" => "x", "type" => "directive", "contract" => true})
    refute Belief.contract?(stale_flag)

    # A payload without the stored field is contract-grade.
    unflagged = Belief.from_map(%{"id" => "y", "type" => "prescription", "invariants" => ["i"]})
    assert Belief.contract?(unflagged)

    # Legacy data carrying both stays contract-grade (via the payload).
    assert Belief.contract?(Belief.from_map(@legacy_contract_map))
  end

  test "key ordering is canonical" do
    a = Belief.from_map(@attestation_map)
    ordered = Belief.to_map(a)
    keys = Enum.map(ordered.values, fn {k, _} -> k end)
    # id first, type second, created among the trailing fields
    assert hd(keys) == "id"
    assert Enum.at(keys, 1) == "type"
  end
end
