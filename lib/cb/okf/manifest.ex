defmodule CB.Okf.Manifest do
  @moduledoc """
  Build and render a Knowledge bundle manifest.

  Byte-compatible with the Python reference (`tools/build_manifest.py`): same field
  order, same document ordering (by path segments, matching Python `sorted(rglob)`),
  and the same pretty JSON as `json.dumps(indent=2, ensure_ascii=False)` (Jason's
  `pretty: true` is byte-identical, verified).
  """
  alias CB.Okf.Frontmatter

  @fields ~w(path type title description tags status timestamp id deps tier kind resource artifact)

  @doc "Sorted `[{full_path, rel_path}]` for every .md doc under root (shared with the validator)."
  def doc_paths(root) do
    root = Path.expand(root)

    (Path.wildcard(Path.join(root, "*.md")) ++ Path.wildcard(Path.join(root, "**/*.md")))
    |> Enum.uniq()
    |> Enum.map(fn p -> {p, Path.relative_to(p, root)} end)
    |> Enum.sort_by(fn {_p, rel} -> Path.split(rel) end)
  end

  @doc "Build the manifest as a `Jason.OrderedObject`."
  def build(root) do
    root = Path.expand(root)

    docs =
      doc_paths(root)
      |> Enum.map(fn {full, rel} -> {rel, Frontmatter.parse(File.read!(full))} end)
      |> Enum.reject(fn {_rel, fm} -> fm == %{} end)
      |> Enum.map(&entry/1)

    Jason.OrderedObject.new([
      {"bundle", Path.basename(root)},
      {"count", length(docs)},
      {"docs", docs}
    ])
  end

  @doc "Render the manifest as pretty JSON with a trailing newline."
  def render(root), do: Jason.encode!(build(root), pretty: true) <> "\n"

  defp entry({rel, fm}) do
    pairs =
      [{"path", rel}] ++
        for f <- @fields, f != "path", Map.has_key?(fm, f), do: {f, Map.get(fm, f)}

    Jason.OrderedObject.new(pairs)
  end
end
