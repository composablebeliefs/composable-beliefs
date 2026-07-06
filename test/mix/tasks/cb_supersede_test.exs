defmodule Mix.Tasks.Cb.SupersedeTest do
  use ExUnit.Case, async: true

  alias CB.Belief
  alias Mix.Tasks.Cb.Supersede, as: Task

  defp belief(id, status) do
    Belief.from_map(%{
      "id" => id,
      "type" => "prescription",
      "kind" => "action-item",
      "claim" => "stub #{id}",
      "status" => status
    })
  end

  defp graph do
    [
      belief("cb:a100", "active"),
      belief("cb:a200", "active"),
      belief("cb:a300", "superseded")
    ]
  end

  describe "plan/5" do
    test "an active belief and active successor yield one supersede mutation" do
      assert {:ok, plan} = Task.plan(graph(), "cb:a100", "cb:a200", "slug-1", "2026-07-06")

      assert plan.belief_id == "cb:a100"
      assert plan.successor_id == "cb:a200"

      assert [%{type: "supersede", belief_id: "cb:a100", successor: "cb:a200", id: "slug-1"}] =
               plan.mutations
    end

    test "bare ids resolve" do
      assert {:ok, plan} = Task.plan(graph(), "a100", "a200", "slug-1", "2026-07-06")
      assert plan.belief_id == "cb:a100"
      assert plan.successor_id == "cb:a200"
    end

    test "a non-active belief is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a300", "cb:a200", "slug-1", "2026-07-06")
      assert msg =~ "not active"
    end

    test "a non-active successor is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a100", "cb:a300", "slug-1", "2026-07-06")
      assert msg =~ "successor"
      assert msg =~ "not active"
    end

    test "self-supersession is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a100", "cb:a100", "slug-1", "2026-07-06")
      assert msg =~ "cannot supersede itself"
    end

    test "an unknown belief id is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a999", "cb:a200", "slug-1", "2026-07-06")
      assert msg =~ "no belief with id"
    end

    test "an unknown successor id is refused" do
      assert {:error, msg} = Task.plan(graph(), "cb:a100", "cb:a999", "slug-1", "2026-07-06")
      assert msg =~ "no belief with id"
    end
  end
end
