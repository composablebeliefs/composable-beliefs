defmodule Mix.Tasks.Cb.Import.EvalTest do
  # async: false - the --write path routes through the app-env beliefs
  # path, like the bs --beliefs override.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias CB.Eval.Manifest
  alias Mix.Tasks.Cb.Import.Eval, as: Task

  @fixture Path.expand("../../fixtures/run_manifest_v1.json", __DIR__)

  defp collection(dir, namespace) do
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "manifest.json"), Jason.encode!(%{"namespace" => namespace}))
    Path.join(dir, "beliefs.json")
  end

  defp write_manifest(dir, map) do
    path = Path.join(dir, "manifest-under-test.json")
    File.write!(path, Jason.encode!(map))
    path
  end

  describe "process/2" do
    @tag :tmp_dir
    test "happy path: everything new, no warnings", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "fx"), "fx")

      assert {:ok, result} = Task.process(@fixture, beliefs_path)
      assert result.namespace == "fx"
      assert length(result.generated) == 20
      assert length(result.new) == 20
      assert result.noop == []
      assert result.warnings == []
    end

    @tag :tmp_dir
    test "the collection's namespace comes from its manifest", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "other"), "somens")
      assert {:ok, result} = Task.process(@fixture, beliefs_path)
      assert Enum.all?(result.new, &String.starts_with?(&1["id"], "somens:o-"))
    end

    @tag :tmp_dir
    test "a collection without a namespace is a named error", %{tmp_dir: dir} do
      ns_dir = Path.join(dir, "anon")
      File.mkdir_p!(ns_dir)
      File.write!(Path.join(ns_dir, "manifest.json"), Jason.encode!(%{}))

      assert {:error, {:no_namespace, _}} =
               Task.process(@fixture, Path.join(ns_dir, "beliefs.json"))
    end

    @tag :tmp_dir
    test "an invalid manifest surfaces the named validation error", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "fx"), "fx")

      bad =
        @fixture |> File.read!() |> Jason.decode!() |> Map.put("manifest_version", 99)

      path = write_manifest(dir, bad)
      assert {:error, {:unsupported_manifest_version, 99}} = Task.process(path, beliefs_path)
    end

    @tag :tmp_dir
    test "a changed manifest under the same run id errors loudly", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "fx"), "fx")

      capture_io(:stderr, fn ->
        capture_io(fn -> Task.run([@fixture, "--collection", beliefs_path, "--write"]) end)
      end)

      mutated = @fixture |> File.read!() |> Jason.decode!()
      [r1 | rest] = mutated["runs"]
      [s1 | srest] = r1["scorers"]
      changed = put_in(s1, ["aggregate", "outcome_counts"], %{"pass" => 40, "silent_loss" => 10})
      mutated = %{mutated | "runs" => [Map.put(r1, "scorers", [changed | srest]) | rest]}

      path = write_manifest(dir, mutated)
      assert {:error, {:identity_conflicts, [id]}} = Task.process(path, beliefs_path)
      assert String.starts_with?(id, "fx:o-")
    end

    @tag :tmp_dir
    test "a flood of beliefs trips the volume warning", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "fx"), "fx")

      flood_cases =
        for i <- 1..60 do
          %{"case_id" => "c#{i}", "outcome" => "fail"}
        end

      flood =
        @fixture
        |> File.read!()
        |> Jason.decode!()
        |> Map.put("runs", [
          %{
            "run_id" => "flood",
            "log" => "document:logs/flood.eval",
            "cases" => 60,
            "scorers" => [
              %{
                "ruler" => "det",
                "aggregate" => %{"outcome_counts" => %{"fail" => 60}},
                "load_bearing_cases" => flood_cases
              }
            ]
          }
        ])

      path = write_manifest(dir, flood)
      assert {:ok, result} = Task.process(path, beliefs_path)
      assert [warning] = result.warnings
      assert warning =~ "load-bearing case list is probably too broad"
    end
  end

  describe "run/1 --write (through the existing import path)" do
    @tag :tmp_dir
    test "writes, re-runs as a no-op, and the collection holds the beliefs", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "fx"), "fx")

      first =
        capture_io(:stderr, fn ->
          capture_io(fn -> Task.run([@fixture, "--collection", beliefs_path, "--write"]) end)
        end)

      assert first =~ "20 new, 0 already present"

      {:ok, on_disk} = CB.JSON.read(beliefs_path)
      assert length(on_disk) == 20

      generated =
        @fixture |> File.read!() |> Jason.decode!() |> Manifest.to_beliefs("fx")

      assert Enum.map(on_disk, & &1["id"]) == Enum.map(generated, & &1["id"])

      second =
        capture_io(:stderr, fn ->
          capture_io(fn -> Task.run([@fixture, "--collection", beliefs_path, "--write"]) end)
        end)

      assert second =~ "0 new, 20 already present"
      assert second =~ "No-op: nothing to import."

      {:ok, still} = CB.JSON.read(beliefs_path)
      assert length(still) == 20
    end

    @tag :tmp_dir
    test "dry run prints the canonical spec and writes nothing", %{tmp_dir: dir} do
      beliefs_path = collection(Path.join(dir, "fx"), "fx")

      stdout =
        capture_io(fn ->
          capture_io(:stderr, fn -> Task.run([@fixture, "--collection", beliefs_path]) end)
        end)

      assert %{"new_beliefs" => beliefs} = Jason.decode!(stdout)
      assert length(beliefs) == 20
      refute File.exists?(beliefs_path)
    end
  end
end
