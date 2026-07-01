defmodule CB.Okf.Emit do
  @moduledoc """
  Project a CB belief graph *down* to an OKF bundle (the "CB serializes to OKF"
  direction). Each belief becomes one `tier: cb` OKF document: its claim is the
  description, its `deps` become both frontmatter and body cross-links, supersession
  carries over. The emitted bundle is designed to pass `mix okf.validate`.

  This is a lossy projection - nested evidence/subjects are not represented in the
  frontmatter subset; the canonical store remains `beliefs/beliefs.json`. The CB
  structural type is preserved in a `cb_type` field so a CB-aware reader can recover it.

  OKF's published type vocabulary (`okf/standard/types.md`) is its own and does not
  follow CB renames: this module is a translation map at the boundary. CB types are
  normalized to the current vocabulary (legacy names accepted) before translation,
  and `cb_type` records the normalized CB name.
  """
  alias CB.Okf.Manifest

  # cb structural type (current vocabulary) -> OKF published type.
  @type_map %{
    "attestation" => "reference",
    "aggregation" => "concept",
    "inference" => "analysis",
    "prescription" => "position"
  }
  @status_map %{
    "active" => "active",
    "superseded" => "superseded",
    "retracted" => "retracted",
    "retired" => "retracted"
  }

  @doc "Emit `beliefs` (CB.Belief structs or string-keyed maps) as an OKF bundle at `out_dir`."
  def bundle(beliefs, out_dir) do
    File.mkdir_p!(out_dir)
    beliefs = Enum.map(beliefs, &to_string_map/1)
    ids = MapSet.new(beliefs, & &1["id"])

    Enum.each(beliefs, fn b -> File.write!(Path.join(out_dir, filename(b["id"])), doc(b, ids)) end)
    File.write!(Path.join(out_dir, "index.md"), index_doc(length(beliefs)))
    File.write!(Path.join(out_dir, "manifest.json"), Manifest.render(out_dir))
    {:ok, length(beliefs)}
  end

  @doc "Filename for a belief id: `cb:a098` -> `cb-a098.md`."
  def filename(id), do: String.replace(id, ":", "-") <> ".md"

  # The description is a relevance hook, not the full claim. Angle-bracket tokens
  # (e.g. CLI notation like `<id>` that appears verbatim in claim bodies) are swapped
  # to parens so the hook never trips the standard's unfilled-placeholder check; the
  # verbatim claim is preserved in the document body.
  defp hook(claim) do
    claim
    |> String.replace("<", "(")
    |> String.replace(">", ")")
  end

  defp doc(b, ids) do
    deps = b["deps"] || []
    cb_type = CB.Belief.normalize_type(b["type"])

    fm =
      [
        {"type", Map.get(@type_map, cb_type, "concept")},
        {"title", "Belief #{b["id"]}"},
        {"description", {:fold, hook(b["claim"])}},
        {"status", Map.get(@status_map, b["status"] || "active", "active")},
        {"timestamp", b["created"]},
        {"tier", "cb"},
        {"id", b["id"]},
        {"cb_type", cb_type}
      ]
      |> opt("kind", b["kind"])
      |> opt("domain", b["domain"])
      |> opt("artifact", b["artifact"])
      |> opt("superseded_by", b["superseded_by"])
      |> list_field("tags", b["tags"])
      |> list_field("deps", deps)

    body =
      ["# Belief #{b["id"]}", "", b["claim"]] ++ depends_section(deps, ids)

    render(fm, Enum.join(body, "\n") <> "\n")
  end

  defp depends_section(deps, ids) do
    present = Enum.filter(deps, &MapSet.member?(ids, &1))

    case present do
      [] -> []
      _ -> ["", "## Depends on"] ++ Enum.map(present, fn d -> "- [#{d}](#{filename(d)})" end)
    end
  end

  defp index_doc(count) do
    fm = [
      {"type", "index"},
      {"title", "CB belief graph (OKF projection)"},
      {"description",
       {:fold, "Use when you need the OKF projection of the Composable Beliefs graph: #{count} tier:cb docs, one per belief, with deps as cross-links."}},
      {"status", "active"},
      {"timestamp", Date.to_iso8601(Date.utc_today())},
      {"tags", {:list, ["cb", "okf", "index"]}}
    ]

    render(fm, "# CB belief graph (OKF projection)\n\nGenerated from beliefs.json by `mix okf.emit`.\n")
  end

  # ---- frontmatter rendering ----

  defp render(fm_pairs, body), do: "---\n" <> Enum.map_join(fm_pairs, "\n", &line/1) <> "\n---\n\n" <> body

  defp line({k, {:fold, v}}), do: "#{k}: >\n  #{v}"
  defp line({k, {:list, items}}), do: "#{k}: [#{Enum.join(items, ", ")}]"
  defp line({k, v}), do: "#{k}: #{v}"

  defp opt(pairs, _k, nil), do: pairs
  defp opt(pairs, _k, ""), do: pairs
  defp opt(pairs, k, v), do: pairs ++ [{k, v}]

  defp list_field(pairs, _k, nil), do: pairs
  defp list_field(pairs, _k, []), do: pairs
  defp list_field(pairs, k, items), do: pairs ++ [{k, {:list, items}}]

  # ---- input normalization ----

  defp to_string_map(%CB.Belief{} = b) do
    b
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn
      {:_keys, _}, acc -> acc
      {k, v}, acc -> Map.put(acc, Atom.to_string(k), v)
    end)
  end

  defp to_string_map(m) when is_map(m), do: Map.new(m, fn {k, v} -> {to_string(k), v} end)
end
