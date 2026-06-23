defmodule Mix.Tasks.Cb.RepointTest do
  use ExUnit.Case, async: true

  alias CB.Belief
  alias Mix.Tasks.Cb.Repoint, as: Task

  defp belief(id, deps) do
    Belief.from_map(%{
      "id" => id,
      "type" => "directive",
      "kind" => "action-item",
      "claim" => "stub #{id}",
      "deps" => deps,
      "status" => "active"
    })
  end

  defp graph do
    [
      belief("cb:a100", ["cb:c001", "cb:c002"]),
      belief("cb:c001", []),
      belief("cb:c002", []),
      belief("cb:c003", [])
    ]
  end

  describe "require_opt/2" do
    test "missing value is an error naming the flag" do
      assert {:error, msg} = Task.require_opt(nil, "--from")
      assert msg =~ "--from"
    end

    test "blank value is an error" do
      assert {:error, _} = Task.require_opt("  ", "--to")
    end

    test "non-empty value passes through" do
      assert {:ok, "cb:c003"} = Task.require_opt("cb:c003", "--to")
    end
  end

  describe "validate_date/1" do
    test "nil passes through" do
      assert {:ok, nil} = Task.validate_date(nil)
    end

    test "a valid ISO date passes" do
      assert {:ok, "2026-06-12"} = Task.validate_date("2026-06-12")
    end

    test "a malformed date is an error" do
      assert {:error, _} = Task.validate_date("06/12/2026")
    end
  end

  describe "plan/5 - happy path" do
    test "swaps from->to and emits a drop-dep + add-dep pair with absolute after.deps" do
      assert {:ok, plan} = Task.plan(graph(), "a100", "c001", "c003", "a100-repoint")

      assert plan.belief_id == "cb:a100"
      assert plan.from == "cb:c001"
      assert plan.to == "cb:c003"
      assert plan.before == ["cb:c001", "cb:c002"]
      assert plan.after == ["cb:c002", "cb:c003"]

      assert [drop, add] = plan.mutations
      assert %{type: "drop-dep", dep: "cb:c001", after: %{"deps" => ["cb:c002"]}} = drop
      assert %{type: "add-dep", dep: "cb:c003", after: %{"deps" => ["cb:c002", "cb:c003"]}} = add
      assert drop.belief_id == "cb:a100"
      assert drop.id == "a100-repoint"
    end

    test "bare and namespaced ids resolve identically" do
      assert {:ok, bare} = Task.plan(graph(), "a100", "c001", "c003", "s")
      assert {:ok, ns} = Task.plan(graph(), "cb:a100", "cb:c001", "cb:c003", "s")
      assert bare.mutations == ns.mutations
    end
  end

  describe "plan/5 - refusals" do
    test "refuses a dangling --to target (not a node in the graph)" do
      assert {:error, msg} = Task.plan(graph(), "a100", "c001", "c999", "s")
      assert msg =~ "dangling"
    end

    test "refuses when --from is not a current dep" do
      assert {:error, msg} = Task.plan(graph(), "a100", "c003", "c001", "s")
      assert msg =~ "not a dep"
    end

    test "refuses when --to is already a dep" do
      assert {:error, msg} = Task.plan(graph(), "a100", "c001", "c002", "s")
      assert msg =~ "already a dep"
    end

    test "refuses when from and to are the same node" do
      assert {:error, msg} = Task.plan(graph(), "a100", "c001", "c001", "s")
      assert msg =~ "same node"
    end

    test "refuses an unknown belief id" do
      assert {:error, msg} = Task.plan(graph(), "a999", "c001", "c003", "s")
      assert msg =~ "no belief"
    end
  end
end
