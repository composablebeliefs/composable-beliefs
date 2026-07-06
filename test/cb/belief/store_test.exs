defmodule CB.Belief.StoreTest do
  use ExUnit.Case, async: true

  alias CB.Belief
  alias CB.Belief.Store

  @moduletag :tmp_dir

  defp node_map(id, overrides \\ %{}) do
    Map.merge(
      %{
        "id" => id,
        "type" => "prescription",
        "kind" => "directive",
        "claim" => "Claim for #{id}.",
        "status" => "active",
        "created" => "2026-07-01"
      },
      overrides
    )
  end

  defp seed_file(dir, beliefs) do
    path = Path.join(dir, "beliefs.json")
    File.write!(path, Jason.encode!(beliefs, pretty: true) <> "\n")
    path
  end

  defp seed_dir(dir, beliefs) do
    node_dir = Path.join(dir, "cb")
    File.mkdir_p!(node_dir)

    Enum.each(beliefs, fn b ->
      File.write!(
        Path.join(node_dir, Store.node_filename(b["id"])),
        Jason.encode!(b, pretty: true) <> "\n"
      )
    end)

    node_dir
  end

  describe "read/1 - single-file layout" do
    test "reads an array file as structs in stored order", %{tmp_dir: dir} do
      path = seed_file(dir, [node_map("cb:b002"), node_map("cb:b001")])

      assert {:ok, [%Belief{id: "cb:b002"}, %Belief{id: "cb:b001"}]} = Store.read(path)
    end

    test "an explicit missing path is an error, not an empty collection", %{tmp_dir: dir} do
      assert {:error, :enoent} = Store.read(Path.join(dir, "absent.json"))
    end

    test "an existing single-file collection at an extensionless path stays single-file",
         %{tmp_dir: dir} do
      path = Path.join(dir, "graph")
      File.write!(path, Jason.encode!([node_map("cb:b001")]))

      assert {:ok, [%Belief{id: "cb:b001"} = belief]} = Store.read(path)
      # the layout read is the layout written back
      assert {:ok, ^path} = Store.write([belief], path)
      refute File.dir?(path)
      assert {:ok, [%Belief{id: "cb:b001"}]} = Store.read(path)
    end

    test "a non-array file is an error", %{tmp_dir: dir} do
      path = Path.join(dir, "beliefs.json")
      File.write!(path, Jason.encode!(%{"not" => "a list"}))

      assert {:error, :not_a_list} = Store.read(path)
    end
  end

  describe "read/1 - per-belief directory layout" do
    test "reads node files sorted naturally by id", %{tmp_dir: dir} do
      node_dir = seed_dir(dir, [node_map("cb:b100"), node_map("cb:b099"), node_map("cb:b1000")])

      assert {:ok, beliefs} = Store.read(node_dir)
      assert Enum.map(beliefs, & &1.id) == ["cb:b099", "cb:b100", "cb:b1000"]
    end

    test "an empty directory reads as the empty collection", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      File.mkdir_p!(node_dir)

      assert {:ok, []} = Store.read(node_dir)
    end

    test "a node file that is not a JSON object is an error", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      File.mkdir_p!(node_dir)
      File.write!(Path.join(node_dir, "b001.json"), Jason.encode!([1, 2]))

      assert {:error, {:bad_node, _}} = Store.read(node_dir)
    end

    test "a node file without a string id is an error, not a nil-id belief", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      File.mkdir_p!(node_dir)
      File.write!(Path.join(node_dir, "stray.json"), Jason.encode!(%{"namespace" => "cb"}))

      assert {:error, {:bad_node, _}} = Store.read(node_dir)
    end

    test "read_raw preserves source keys per node", %{tmp_dir: dir} do
      node_dir = seed_dir(dir, [node_map("cb:b001", %{"deps" => []})])

      assert {:ok, [raw]} = Store.read_raw(node_dir)
      assert Map.has_key?(raw, "deps")
    end
  end

  describe "write/2 - single-file layout" do
    test "rewrites the whole array atomically", %{tmp_dir: dir} do
      path = Path.join(dir, "beliefs.json")
      beliefs = Enum.map([node_map("cb:b001"), node_map("cb:b002")], &Belief.from_map/1)

      assert {:ok, ^path} = Store.write(beliefs, path)
      assert {:ok, [%Belief{id: "cb:b001"}, %Belief{id: "cb:b002"}]} = Store.read(path)
    end
  end

  describe "write/2 - per-belief directory layout" do
    test "writes one file per node into an existing directory", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      File.mkdir_p!(node_dir)
      beliefs = Enum.map([node_map("cb:b001"), node_map("cb:b002")], &Belief.from_map/1)

      assert {:ok, ^node_dir} = Store.write(beliefs, node_dir)
      assert File.exists?(Path.join(node_dir, "b001.json"))
      assert File.exists?(Path.join(node_dir, "b002.json"))
      assert {:ok, [%Belief{id: "cb:b001"}, %Belief{id: "cb:b002"}]} = Store.read(node_dir)
    end

    test "a path without a .json extension selects the directory layout", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "fresh")
      beliefs = [Belief.from_map(node_map("cb:b001"))]

      assert {:ok, ^node_dir} = Store.write(beliefs, node_dir)
      assert File.exists?(Path.join(node_dir, "b001.json"))
    end

    test "an untouched node's file is not rewritten", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      beliefs = Enum.map([node_map("cb:b001"), node_map("cb:b002")], &Belief.from_map/1)
      {:ok, _} = Store.write(beliefs, node_dir)

      untouched = Path.join(node_dir, "b001.json")
      %File.Stat{mtime: before} = File.stat!(untouched, time: :posix)

      changed = List.update_at(beliefs, 1, &%Belief{&1 | claim: "Changed."})
      {:ok, _} = Store.write(changed, node_dir)

      assert %File.Stat{mtime: ^before} = File.stat!(untouched, time: :posix)
      assert {:ok, [_, %Belief{claim: "Changed."}]} = Store.read(node_dir)
    end

    test "nodes absent from the written list are deleted", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      beliefs = Enum.map([node_map("cb:b001"), node_map("cb:b002")], &Belief.from_map/1)
      {:ok, _} = Store.write(beliefs, node_dir)

      {:ok, _} = Store.write(Enum.take(beliefs, 1), node_dir)

      refute File.exists?(Path.join(node_dir, "b002.json"))
      assert {:ok, [%Belief{id: "cb:b001"}]} = Store.read(node_dir)
    end

    test "duplicate ids are refused before any write", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      beliefs = Enum.map([node_map("cb:b001"), node_map("cb:b001")], &Belief.from_map/1)

      assert {:error, {:duplicate_node, ["b001.json"]}} = Store.write(beliefs, node_dir)
      # refused before the directory was even created
      assert {:error, :enoent} = Store.read(node_dir)
    end

    test "an id whose local part would escape the directory is refused", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      beliefs = [Belief.from_map(node_map("cb:../b999"))]

      assert {:error, {:bad_id, ["cb:../b999"]}} = Store.write(beliefs, node_dir)
      refute File.exists?(Path.join(dir, "b999.json"))
      # refused before the directory was even created
      assert {:error, :enoent} = Store.read(node_dir)
    end

    test "the deletion pass leaves foreign .json files alone", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      File.mkdir_p!(node_dir)
      manifest = Path.join(node_dir, "manifest.json")
      File.write!(manifest, Jason.encode!(%{"namespace" => "cb"}))

      beliefs = [Belief.from_map(node_map("cb:b001"))]
      assert {:ok, ^node_dir} = Store.write(beliefs, node_dir)

      assert File.exists?(manifest)
      # ...but the foreign file still poisons reads, by design
      assert {:error, {:bad_node, _}} = Store.read(node_dir)
    end

    test "a supersession round-trips: successor added, predecessor flipped", %{tmp_dir: dir} do
      node_dir = Path.join(dir, "cb")
      [old] = beliefs = [Belief.from_map(node_map("cb:b001"))]
      {:ok, _} = Store.write(beliefs, node_dir)

      flipped = %Belief{old | status: "superseded", superseded_by: "cb:b002"}
      successor = Belief.from_map(node_map("cb:b002"))
      {:ok, _} = Store.write([flipped, successor], node_dir)

      assert {:ok, [read_old, read_new]} = Store.read(node_dir)
      assert read_old.status == "superseded"
      assert read_old.superseded_by == "cb:b002"
      assert read_new.id == "cb:b002"
    end
  end

  describe "layout equivalence" do
    test "the same collection loads identically from either layout", %{tmp_dir: dir} do
      beliefs = [
        node_map("cb:b010", %{"tags" => ["storage"], "deps" => ["cb:b002"]}),
        node_map("cb:b002", %{"evidence" => [%{"date" => "2026-07-01", "detail" => "seen"}]})
      ]

      file_path = seed_file(dir, beliefs)
      node_dir = seed_dir(dir, beliefs)

      {:ok, from_file} = Store.read(file_path)
      {:ok, from_dir} = Store.read(node_dir)

      sorted = Enum.sort_by(from_file, & &1.id)
      assert Enum.map(from_dir, &Belief.to_map/1) == Enum.map(sorted, &Belief.to_map/1)
    end
  end
end
