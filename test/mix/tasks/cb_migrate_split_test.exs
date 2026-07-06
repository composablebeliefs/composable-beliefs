defmodule Mix.Tasks.Cb.Migrate.SplitTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias CB.Belief.Store
  alias Mix.Tasks.Cb.Migrate.Split, as: Task

  @moduletag :tmp_dir

  defp node_map(id) do
    %{
      "id" => id,
      "type" => "prescription",
      "kind" => "directive",
      "claim" => "Claim for #{id}.",
      "status" => "active",
      "created" => "2026-07-01"
    }
  end

  defp seed(dir, beliefs) do
    path = Path.join(dir, "beliefs.json")
    File.write!(path, Jason.encode!(beliefs, pretty: true) <> "\n")
    path
  end

  defp quietly(fun), do: capture_io(:stderr, fun)

  test "dry run plans the split and writes nothing", %{tmp_dir: dir} do
    path = seed(dir, [node_map("cb:b002"), node_map("cb:b001")])

    quietly(fn ->
      assert {:ok, %{namespace: "cb", count: 2, applied: false}} = Task.split(path, false)
    end)

    assert File.exists?(path)
    refute File.dir?(Path.join(dir, "cb"))
  end

  test "write splits, verifies, and removes the single file", %{tmp_dir: dir} do
    beliefs = [node_map("cb:b002"), node_map("cb:b001"), node_map("cb:b010")]
    path = seed(dir, beliefs)
    {:ok, original} = Store.read(path)

    quietly(fn ->
      assert {:ok, %{namespace: "cb", count: 3, applied: true, target: target}} =
               Task.split(path, true)

      assert Path.basename(target) == "cb"
    end)

    refute File.exists?(path)
    node_dir = Path.join(dir, "cb")

    assert node_dir |> File.ls!() |> Enum.sort() == ["b001.json", "b002.json", "b010.json"]

    {:ok, reloaded} = Store.read(node_dir)

    assert Enum.map(reloaded, & &1.id) == ["cb:b001", "cb:b002", "cb:b010"]

    assert Enum.sort_by(Enum.map(original, &CB.Belief.to_map/1), & &1["id"]) ==
             Enum.map(reloaded, &CB.Belief.to_map/1)
  end

  test "refuses a collection with mixed namespaces", %{tmp_dir: dir} do
    path = seed(dir, [node_map("cb:b001"), node_map("lib:b001")])

    quietly(fn ->
      assert {:error, msg} = Task.split(path, true)
      assert msg =~ "mixed id namespaces"
    end)

    assert File.exists?(path)
  end

  test "refuses duplicate ids", %{tmp_dir: dir} do
    path = seed(dir, [node_map("cb:b001"), node_map("cb:b001")])

    quietly(fn ->
      assert {:error, msg} = Task.split(path, true)
      assert msg =~ "duplicate ids"
    end)
  end

  test "refuses an empty collection", %{tmp_dir: dir} do
    path = seed(dir, [])

    quietly(fn ->
      assert {:error, msg} = Task.split(path, true)
      assert msg =~ "empty"
    end)
  end

  test "refuses when the target directory is non-empty", %{tmp_dir: dir} do
    path = seed(dir, [node_map("cb:b001")])
    node_dir = Path.join(dir, "cb")
    File.mkdir_p!(node_dir)
    File.write!(Path.join(node_dir, "stray.json"), "{}")

    quietly(fn ->
      assert {:error, msg} = Task.split(path, true)
      assert msg =~ "already exists"
    end)

    assert File.exists?(path)
  end

  test "refuses a directory path", %{tmp_dir: dir} do
    quietly(fn ->
      assert {:error, msg} = Task.split(dir, true)
      assert msg =~ "already a per-belief directory"
    end)
  end

  test "refuses a missing path", %{tmp_dir: dir} do
    quietly(fn ->
      assert {:error, msg} = Task.split(Path.join(dir, "absent.json"), true)
      assert msg =~ "no collection"
    end)
  end
end
