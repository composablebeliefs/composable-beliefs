defmodule Mix.Tasks.Cb.RetractTest do
  use ExUnit.Case, async: true

  alias CB.Belief
  alias Mix.Tasks.Cb.Retract, as: Task

  defp belief(id, status) do
    Belief.from_map(%{
      "id" => id,
      "type" => "directive",
      "kind" => "action-item",
      "claim" => "stub #{id}",
      "status" => status
    })
  end

  defp graph do
    [belief("cb:a100", "active"), belief("cb:a200", "superseded")]
  end

  describe "require_opt/2" do
    test "missing value is an error naming the flag" do
      assert {:error, msg} = Task.require_opt(nil, "--reason")
      assert msg =~ "--reason"
    end

    test "blank value is rejected" do
      assert {:error, _} = Task.require_opt("   ", "--reason")
    end

    test "present value passes" do
      assert {:ok, "why"} = Task.require_opt("why", "--reason")
    end
  end

  describe "validate_date/1" do
    test "nil passes through" do
      assert {:ok, nil} = Task.validate_date(nil)
    end

    test "a valid ISO date passes" do
      assert {:ok, "2026-06-22"} = Task.validate_date("2026-06-22")
    end

    test "a non-date is rejected" do
      assert {:error, msg} = Task.validate_date("yesterday")
      assert msg =~ "ISO date"
    end
  end

  describe "plan/5" do
    test "an active belief yields one retract mutation carrying date and reason" do
      assert {:ok, plan} =
               Task.plan(graph(), "cb:a100", "moot", "slug-1", "2026-06-22")

      assert plan.belief_id == "cb:a100"
      assert [%{type: "retract", belief_id: "cb:a100", id: "slug-1", after: after_}] = plan.mutations
      assert after_["retracted_on"] == "2026-06-22"
      assert after_["retracted_reason"] == "moot"
    end

    test "a non-active belief is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a200", "moot", "slug-1", "2026-06-22")
      assert msg =~ "not active"
      assert msg =~ "superseded"
    end

    test "an unknown id is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a999", "moot", "slug-1", "2026-06-22")
      assert msg =~ "no belief with id"
    end
  end
end
