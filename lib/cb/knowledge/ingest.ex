defmodule CB.Knowledge.Ingest do
  @moduledoc """
  Ingest an OKF bundle *up* into CB beliefs. Per the CB<->OKF analysis this direction is
  intentionally lossy: a generic OKF bundle carries no typed deps or evidence, so every
  document becomes a `primitive` belief grounded in `artifact: document:<path>`. Typed
  composition is not reconstructed - that is the discipline CB adds on top, by hand or
  via `/assert`, not something the up-conversion can invent.

  Returns CB belief maps (string-keyed) ready to encode or feed to preflight.
  """
  alias CB.Knowledge.{Frontmatter, Manifest}

  @doc "Ingest the bundle at `root` into a list of primitive belief maps under namespace `ns`."
  def beliefs(root, ns \\ "okf") do
    root = Path.expand(root)

    Manifest.doc_paths(root)
    |> Enum.map(fn {_full, rel} -> {rel, Frontmatter.parse(File.read!(Path.join(root, rel)))} end)
    |> Enum.reject(fn {_rel, fm} -> fm == %{} or fm["type"] == "index" end)
    |> Enum.map(fn {rel, fm} -> primitive(ns, rel, fm) end)
  end

  defp primitive(ns, rel, fm) do
    %{
      "id" => fm["id"] || ns <> ":" <> slug(rel),
      "type" => "primitive",
      "tags" => fm["tags"] || [],
      "claim" => fm["description"] || fm["title"] || "",
      "artifact" => "document:" <> rel,
      "evidence" => [],
      "deps" => [],
      "status" => fm["status"] || "active",
      "created" => fm["timestamp"] || Date.to_iso8601(Date.utc_today())
    }
    |> maybe_put("kind", fm["kind"])
    |> maybe_put("domain", fm["domain"])
  end

  defp slug(rel) do
    rel
    |> String.replace(~r/\.md$/, "")
    |> String.replace(~r/[^A-Za-z0-9]+/, "-")
  end

  defp maybe_put(m, _k, nil), do: m
  defp maybe_put(m, k, v), do: Map.put(m, k, v)
end
