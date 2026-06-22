defmodule CB.KnowledgeTest do
  use ExUnit.Case, async: true

  alias CB.Knowledge.{Frontmatter, Manifest, Validate}

  setup do
    root = Path.join(System.tmp_dir!(), "kn_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf(root) end)
    {:ok, root: root}
  end

  defp write(root, rel, contents) do
    path = Path.join(root, rel)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end

  defp doc(fields, body \\ "Body.\n") do
    fm = Enum.map_join(fields, "\n", fn {k, v} -> "#{k}: #{v}" end)
    "---\n#{fm}\n---\n\n#{body}"
  end

  test "frontmatter parses the documented subset" do
    fm =
      Frontmatter.parse("""
      ---
      type: concept
      title: T
      description: >
        folded line one
        line two
      tags: [a, b]
      deps:
        - x:1
        - x:2
      ---
      body
      """)

    assert fm["type"] == "concept"
    assert fm["description"] == "folded line one line two"
    assert fm["tags"] == ["a", "b"]
    assert fm["deps"] == ["x:1", "x:2"]
  end

  test "no frontmatter yields empty map" do
    assert Frontmatter.parse("# just markdown\n") == %{}
  end

  test "valid bundle passes with fresh manifest", %{root: root} do
    write(root, "index.md", doc(type: "index", title: "Idx",
      description: "Use when orienting to this valid test bundle root index."))

    File.write!(Path.join(root, "manifest.json"), Manifest.render(root))
    {errors, warnings} = Validate.run(root)
    assert errors == []
    assert warnings == []
  end

  test "flags bad type, short description, stale manifest", %{root: root} do
    write(root, "index.md", doc(type: "gizmo", title: "Bad", description: "short"))
    File.write!(Path.join(root, "manifest.json"), "{}\n")

    {errors, _warnings} = Validate.run(root)
    codes = MapSet.new(errors, & &1.code)
    assert "type_not_in_taxonomy" in codes
    assert "description_missing_or_short" in codes
    assert "manifest_stale" in codes
  end

  test "cb-tier doc without id is flagged; resolving deps pass", %{root: root} do
    write(root, "index.md", doc(type: "index", title: "Idx",
      description: "Use when orienting to the CB-tier test bundle index page."))
    write(root, "base.md", doc(type: "concept", title: "Base",
      description: "Use when you need the base belief the derived one depends upon.",
      tier: "cb", id: "t:base"))
    write(root, "derived.md", doc(type: "concept", title: "Derived",
      description: "Use when you need the derived belief composed from the base one.",
      tier: "cb", id: "t:derived", deps: "[t:base]"))

    File.write!(Path.join(root, "manifest.json"), Manifest.render(root))
    {errors, warnings} = Validate.run(root)
    assert errors == []
    assert warnings == []

    # now break the id on base
    write(root, "base.md", doc(type: "concept", title: "Base",
      description: "Use when you need the base belief the derived one depends upon.",
      tier: "cb"))
    File.write!(Path.join(root, "manifest.json"), Manifest.render(root))
    {errors, warnings} = Validate.run(root)
    assert Enum.any?(errors, &(&1.code == "cb_tier_missing_id"))
    assert Enum.any?(warnings, &(&1.code == "dep_unresolved_in_bundle"))
  end

  test "to_contract is deterministic and sorted", %{root: root} do
    write(root, "index.md", doc(type: "gizmo", title: "Bad", description: "short"))
    File.write!(Path.join(root, "manifest.json"), Manifest.render(root))
    {errors, warnings} = Validate.run(root)
    json = Validate.to_contract(errors, warnings)
    decoded = Jason.decode!(json)

    assert decoded["ok"] == false
    codes = Enum.map(decoded["errors"], & &1["code"])
    assert codes == Enum.sort(codes)
  end
end
