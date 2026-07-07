defmodule Mix.Tasks.Cb.Migrate.AtomizeTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias CB.Belief.Store
  alias Mix.Tasks.Cb.Migrate.Atomize, as: Task

  @moduletag :tmp_dir

  # A minimal lane: a conjunctive attestation (aggregate), an inference
  # whose claim restates its dep (trim), an atomic attestation (keep),
  # and a prescription outside the descriptive lane entirely.
  defp seed_graph(dir) do
    graph = Path.join(dir, "cb")

    beliefs =
      Enum.map(
        [
          %{
            "id" => "cb:b001",
            "type" => "attestation",
            "kind" => "design-observation",
            "tags" => ["x"],
            "claim" => "First assertion. Second assertion.",
            "artifact" => "document:notes",
            "evidence" => [
              %{"date" => "2026-01-01", "detail" => "Original event.", "artifact" => "document:notes"}
            ],
            "subjects" => [%{"ref" => "thing", "type" => "system"}],
            "status" => "active",
            "created" => "2026-01-01"
          },
          %{
            "id" => "cb:b002",
            "type" => "inference",
            "kind" => "design-rationale",
            "claim" => "Because b001 says so, therefore the conclusion.",
            "deps" => ["cb:b001"],
            "status" => "active",
            "created" => "2026-01-02"
          },
          %{
            "id" => "cb:b003",
            "type" => "attestation",
            "kind" => "fact",
            "claim" => "One atomic statement.",
            "artifact" => "document:notes",
            "status" => "active",
            "created" => "2026-01-03"
          },
          %{
            "id" => "cb:b004",
            "type" => "prescription",
            "kind" => "policy",
            "claim" => "Something must hold.",
            "artifact" => "session:stipulation",
            "status" => "active",
            "created" => "2026-01-04"
          }
        ],
        &CB.Belief.from_map/1
      )

    {:ok, _} = Store.write(beliefs, graph)
    graph
  end

  defp seed_spec(dir, overrides \\ %{}) do
    spec = %{
      "version" => 1,
      "date" => "2026-07-07",
      "id_base" => 900,
      "nodes" =>
        Map.merge(
          %{
            "cb:b001" => %{
              "disposition" => "aggregate",
              "atoms" => ["First assertion.", "Second assertion."]
            },
            "cb:b002" => %{"disposition" => "trim", "claim" => "The conclusion."},
            "cb:b003" => %{"disposition" => "keep"}
          },
          overrides
        )
        |> Map.reject(fn {_, v} -> v == nil end)
    }

    path = Path.join(dir, "spec.json")
    File.write!(path, Jason.encode!(spec, pretty: true))
    path
  end

  defp quietly(fun), do: capture_io(:stderr, fun)

  test "dry run reports the plan and writes nothing", %{tmp_dir: dir} do
    graph = seed_graph(dir)
    spec = seed_spec(dir)
    target = Path.join(dir, "cb-atomic")

    quietly(fn ->
      assert {:ok, %{applied: false, aggregated: 1, trimmed: 1, kept: 1, atoms: 2, total: 6}} =
               Task.atomize(spec, graph, target, false)
    end)

    refute File.dir?(target)
  end

  test "write emits the retyped parallel graph", %{tmp_dir: dir} do
    graph = seed_graph(dir)
    spec = seed_spec(dir)
    target = Path.join(dir, "cb-atomic")

    quietly(fn ->
      assert {:ok, %{applied: true, total: 6}} = Task.atomize(spec, graph, target, true)
    end)

    # The aggregate keeps id and claim but retypes in the stored JSON,
    # not only in the normalized struct (regression: _raw_type).
    raw = Jason.decode!(File.read!(Path.join(target, "b001.json")))
    assert raw["type"] == "aggregation"
    assert raw["claim"] == "First assertion. Second assertion."
    assert raw["deps"] == ["cb:b900", "cb:b901"]
    assert [%{"detail" => "Original event."}, %{"detail" => migration}] = raw["evidence"]
    assert migration =~ "cb:b900"

    # Atoms inherit grounding and carry no null/[] keys the parent lacked.
    atom = Jason.decode!(File.read!(Path.join(target, "b900.json")))
    assert atom["type"] == "attestation"
    assert atom["claim"] == "First assertion."
    assert atom["kind"] == "design-observation"
    assert atom["artifact"] == "document:notes"
    assert atom["subjects"] == [%{"ref" => "thing", "type" => "system"}]
    refute Map.has_key?(atom, "domain")

    # Trim rewrites the claim and records the previous one in evidence.
    trimmed = Jason.decode!(File.read!(Path.join(target, "b002.json")))
    assert trimmed["claim"] == "The conclusion."
    assert [%{"detail" => detail}] = trimmed["evidence"]
    assert detail =~ "Because b001 says so"

    # Keeps and out-of-lane nodes are byte-identical to the source.
    for local <- ["b003.json", "b004.json"] do
      assert File.read!(Path.join(target, local)) == File.read!(Path.join(graph, local))
    end
  end

  test "refuses a spec that does not cover the lane", %{tmp_dir: dir} do
    graph = seed_graph(dir)
    spec = seed_spec(dir, %{"cb:b003" => nil})
    target = Path.join(dir, "cb-atomic")

    quietly(fn ->
      assert {:error, message} = Task.atomize(spec, graph, target, false)
      assert message =~ "cb:b003"
    end)
  end

  test "refuses atom ids that collide with existing nodes", %{tmp_dir: dir} do
    graph = seed_graph(dir)

    collider =
      CB.Belief.from_map(%{
        "id" => "cb:b900",
        "type" => "attestation",
        "kind" => "fact",
        "claim" => "Occupies the allocation range.",
        "artifact" => "document:notes",
        "status" => "active",
        "created" => "2026-01-05"
      })

    {:ok, existing} = Store.read(graph)
    {:ok, _} = Store.write(existing ++ [collider], graph)

    spec = seed_spec(dir, %{"cb:b900" => %{"disposition" => "keep"}})
    target = Path.join(dir, "cb-atomic")

    quietly(fn ->
      assert {:error, message} = Task.atomize(spec, graph, target, false)
      assert message =~ "cb:b900"
      assert message =~ "id_base"
    end)
  end
end
