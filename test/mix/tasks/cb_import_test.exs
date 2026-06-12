defmodule Mix.Tasks.Cb.ImportTest do
  use ExUnit.Case, async: true

  alias CB.Belief
  alias Mix.Tasks.Cb.Import, as: Task

  defp existing(ids), do: Enum.map(ids, &struct(Belief, id: &1))

  defp spec(ids), do: Enum.map(ids, &%{"id" => &1})

  describe "namespace_violations/2" do
    test "bare ids in a namespaced graph are violations" do
      assert {"cb", ["a484"]} =
               Task.namespace_violations(spec(["a484"]), existing(["cb:a001"]))
    end

    test "ids carrying the graph's namespace pass" do
      assert {"cb", []} =
               Task.namespace_violations(
                 spec(["cb:a484", "cb:c062"]),
                 existing(["cb:a001", "cb:c001"])
               )
    end

    test "ids in a foreign namespace are violations" do
      assert {"cb", ["lib:a001"]} =
               Task.namespace_violations(spec(["lib:a001"]), existing(["cb:a001"]))
    end

    test "an empty graph declares no namespace - vacuous pass" do
      assert {nil, []} = Task.namespace_violations(spec(["a484"]), [])
    end

    test "a mixed-id graph declares no namespace - vacuous pass" do
      assert {nil, []} =
               Task.namespace_violations(spec(["a484"]), existing(["cb:a001", "a002"]))
    end

    test "an all-bare graph declares no namespace - vacuous pass" do
      assert {nil, []} =
               Task.namespace_violations(spec(["a484"]), existing(["a001", "a002"]))
    end
  end
end
