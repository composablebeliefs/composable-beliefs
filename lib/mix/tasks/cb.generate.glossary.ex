defmodule Mix.Tasks.Cb.Generate.Glossary do
  @moduledoc """
  Generate the glossary's two rendered views from its canonical source.

  The source of truth is `docs/glossary.data.json` (slug -> {name, short, def,
  also?, see?}). This task renders it into:

    * `docs/glossary.md` - the readable doc, with every term name and belief id
      cross-linked as a same-file `#anchor` (the only jump Zed's markdown preview
      follows) and a "Referenced beliefs" appendix carrying each cited belief's
      claim, deps, and its source line in the graph.
    * `../cb-tut/assets/glossary-data.js` - the tutorial's `window.GLOSSARY`.

  Both outputs are generated; do not hand-edit them. Edit `glossary.data.json`
  and rerun. Referenced beliefs are resolved across collections via
  `../belief-collections/collections.json`.

  ## Usage

      mix cb.generate.glossary          - write both outputs
      mix cb.generate.glossary --check  - rebuild in memory, diff, write nothing

  ## Exit codes

  0 = generated or check passed, 1 = check found drift
  """
  @shortdoc "Generate the glossary doc and cb-tut data from glossary.data.json"

  use Mix.Task

  @ref_re ~r/[a-z][a-z0-9-]*:[abc]\d+/

  @impl true
  def run(args) do
    check? = "--check" in args
    docs = Path.join(CB.repo_root(), "docs")
    amieval = Path.expand("..", CB.repo_root())

    raw_json = File.read!(Path.join(docs, "glossary.data.json"))
    glossary = Jason.decode!(raw_json)
    index = load_belief_index(amieval, docs)

    md = build_md(glossary, index)
    js = build_js(raw_json)

    md_path = Path.join(docs, "glossary.md")
    js_path = Path.join([amieval, "cb-tut", "assets", "glossary-data.js"])

    if check? do
      drift =
        [{md_path, md}, {js_path, js}]
        |> Enum.filter(fn {p, content} -> File.read(p) != {:ok, content} end)
        |> Enum.map(&elem(&1, 0))

      if drift == [] do
        Mix.shell().info("glossary: up to date")
      else
        Mix.shell().error("glossary: stale, rerun `mix cb.generate.glossary`:\n  " <> Enum.join(drift, "\n  "))
        exit({:shutdown, 1})
      end
    else
      File.write!(md_path, md)
      File.write!(js_path, js)
      refs = Regex.scan(~r/^### /m, md) |> length()
      Mix.shell().info("glossary: wrote docs/glossary.md and cb-tut/assets/glossary-data.js (#{map_size(glossary)} terms, #{refs} referenced beliefs)")
    end
  end

  # ---- cb-tut/assets/glossary-data.js: the canonical json verbatim ----
  defp build_js(raw_json) do
    header = """
    // Glossary data for cb-tut. Each entry: slug -> { name, short, def, also?, see? }
    // House style: hyphens only, never em/en dashes (cb:a455).
    // GENERATED from composable-beliefs/docs/glossary.data.json (the canonical source);
    // do not edit by hand - edit the json and run `mix cb.generate.glossary`.
    // Loaded by wiki.js as window.GLOSSARY; rendered alphabetically by name on glossary.html.
    """

    header <> "window.GLOSSARY = " <> String.trim_trailing(raw_json) <> ";\n"
  end

  # ---- belief index: id -> %{belief, line, file} across all collections ----
  defp load_belief_index(amieval, docs) do
    coldir = Path.join(amieval, "belief-collections")
    reg = Jason.decode!(File.read!(Path.join(coldir, "collections.json")))["collections"]

    Enum.reduce(reg, %{}, fn {_ns, rel}, acc ->
      file = Path.expand(rel, coldir)

      if File.exists?(file) do
        raw = File.read!(file)
        line_of = line_index(raw)
        rel_to_docs = rel_path(docs, file)

        raw
        |> Jason.decode!()
        |> Enum.reduce(acc, fn b, a ->
          id = b["id"]
          if Map.has_key?(a, id), do: a, else: Map.put(a, id, %{belief: b, line: line_of[id], file: rel_to_docs})
        end)
      else
        acc
      end
    end)
  end

  defp line_index(raw) do
    raw
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reduce(%{}, fn {ln, i}, acc ->
      case Regex.run(~r/"id"\s*:\s*"([^"]+)"/, ln) do
        [_, id] -> Map.put_new(acc, id, i)
        _ -> acc
      end
    end)
  end

  # path of `to_file` relative to directory `from_dir`, emitting ../ like JS path.relative
  defp rel_path(from_dir, to_file) do
    from = Path.split(Path.expand(from_dir))
    to = Path.split(Path.expand(to_file))
    common = common_len(from, to, 0)
    ups = List.duplicate("..", length(from) - common)
    Path.join(ups ++ Enum.drop(to, common))
  end

  defp common_len([h | t1], [h | t2], n), do: common_len(t1, t2, n + 1)
  defp common_len(_, _, n), do: n

  # ---- github-style slugger ----
  defp slug(text, seen) do
    s =
      text
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9 _-]/, "")
      |> String.replace(" ", "-")

    case seen do
      %{^s => n} -> {"#{s}-#{n + 1}", Map.put(seen, s, n + 1)}
      _ -> {s, Map.put(seen, s, 0)}
    end
  end

  defp assign_anchors(keys, name_fun, seen) do
    Enum.reduce(keys, {%{}, seen}, fn k, {map, sn} ->
      {a, sn2} = slug(name_fun.(k), sn)
      {Map.put(map, k, a), sn2}
    end)
  end

  # ---- glossary.md ----
  defp build_md(glossary, index) do
    term_keys = glossary |> Map.keys() |> Enum.sort_by(&String.downcase(glossary[&1]["name"]))

    referenced =
      Enum.reduce(term_keys, MapSet.new(), fn k, acc ->
        no_code = Regex.replace(~r/<code>.*?<\/code>/s, glossary[k]["def"], " ")

        Regex.scan(@ref_re, no_code)
        |> Enum.reduce(acc, fn [r], a -> if Map.has_key?(index, r), do: MapSet.put(a, r), else: a end)
      end)

    ref_list =
      referenced
      |> MapSet.to_list()
      |> Enum.sort_by(fn id ->
        [ns, local] = String.split(id, ":", parts: 2)
        rank = if String.starts_with?(local, "a"), do: "0", else: "1"
        {ns, rank <> String.pad_leading(String.slice(local, 1..-1//1), 6, "0")}
      end)

    {term_anchor, seen1} = assign_anchors(term_keys, &glossary[&1]["name"], %{})
    {belief_anchor, _} = assign_anchors(ref_list, & &1, seen1)

    header = [
      "# Glossary",
      "",
      "Every technical term across the Composable Beliefs codebase and design graph, defined for",
      "a reader meeting it for the first time. This is the canonical home of the glossary; the",
      "[cb-tut guide](../../cb-tut/glossary.html) renders the same content, generated from the",
      "shared source `glossary.data.json` beside this file.",
      "",
      "Term names in a definition link to that term's entry, and belief ids (`cb:a478`, `cb:c051`,",
      "`method:c7`, ...) link to the [Referenced beliefs](#referenced-beliefs) section at the end,",
      "where each carries its claim and its source line in the graph. In Zed, open the Markdown",
      "preview (`markdown: open preview`) so the in-document links are clickable.",
      "",
      "Generated by `mix cb.generate.glossary` from `glossary.data.json`; do not edit by hand.",
      "",
      "---",
      ""
    ]

    terms =
      Enum.flat_map(term_keys, fn k ->
        g = glossary[k]
        also = if g["also"], do: ["*Also: #{g["also"]}*", ""], else: []

        see =
          case g["see"] do
            s when is_list(s) and s != [] ->
              links = Enum.map_join(s, ", ", fn r -> if glossary[r], do: "[#{glossary[r]["name"]}](##{term_anchor[r]})", else: r end)
              ["**See also:** " <> links, ""]

            _ ->
              []
          end

        ["## #{g["name"]}", ""] ++ also ++ [def_to_md(g["def"], term_anchor, belief_anchor), ""] ++ see
      end)

    appendix_head = [
      "---",
      "",
      "## Referenced beliefs",
      "",
      "Every belief id cited above, with its claim and the line it lives on in the graph source.",
      "The source path is relative to this file; in Zed you can cmd-click `path:line` (or run",
      "`mix bs show <id>` in the `composable-beliefs` repo) to open the record.",
      ""
    ]

    appendix =
      Enum.flat_map(ref_list, fn id ->
        %{belief: b, line: line, file: file} = index[id]

        meta =
          [b["type"] && "**#{b["type"]}**", b["kind"], b["status"] && "_#{b["status"]}_", b["contract"] && "contract"]
          |> Enum.reject(&(&1 in [nil, false]))
          |> Enum.join(" · ")

        claim = b["claim"] |> Kernel.||("") |> unesc() |> link_refs(belief_anchor)

        deps =
          case b["deps"] do
            d when is_list(d) and d != [] ->
              ["deps: " <> Enum.map_join(d, ", ", fn x -> if belief_anchor[x], do: "[#{x}](##{belief_anchor[x]})", else: "`#{x}`" end)]

            _ ->
              []
          end

        src_loc = if line, do: "`#{file}:#{line}`", else: "`#{file}`"
        facts = Enum.join(deps ++ ["source: #{src_loc}  ·  `mix bs show #{id}`"], "  \n")
        ["### #{id}", "", meta, "", claim, "", facts, ""]
      end)

    (header ++ terms ++ appendix_head ++ appendix)
    |> Enum.join("\n")
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.replace(~r/[\x{2014}\x{2013}]/u, "-")
    |> Kernel.<>("\n")
  end

  defp def_to_md(def, term_anchor, belief_anchor) do
    {protected, restore} = protect_code(def)

    protected
    |> replace_fun(~r/<a\s+href=['"]glossary\.html#([^'"]+)['"]\s*>(.*?)<\/a>/s, fn _full, key, txt ->
      if term_anchor[key], do: "[#{txt}](##{term_anchor[key]})", else: txt
    end)
    |> replace_fun(~r/<a\s+href=['"][^'"]*['"]\s*>(.*?)<\/a>/s, fn _full, txt -> txt end)
    |> String.replace(~r/<\/?strong>/, "**")
    |> link_refs(belief_anchor)
    |> unesc()
    |> restore_code(restore)
    |> String.trim()
  end

  # pipe-friendly Regex.replace/3 with a replacement function
  defp replace_fun(subject, regex, fun), do: Regex.replace(regex, subject, fun)

  defp link_refs(text, belief_anchor) do
    Regex.replace(@ref_re, text, fn ref -> if belief_anchor[ref], do: "[#{ref}](##{belief_anchor[ref]})", else: ref end)
  end

  defp protect_code(def) do
    Regex.scan(~r/<code>(.*?)<\/code>/s, def)
    |> Enum.with_index()
    |> Enum.reduce({def, %{}}, fn {[full, inner], i}, {acc, map} ->
      ph = "\x00C#{i}\x00"
      {String.replace(acc, full, ph, global: false), Map.put(map, ph, "`" <> unesc(inner) <> "`")}
    end)
  end

  defp restore_code(text, restore) do
    Enum.reduce(restore, text, fn {ph, val}, acc -> String.replace(acc, ph, val) end)
  end

  defp unesc(s) do
    s
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&rarr;", "->")
    |> String.replace("&larr;", "<-")
    |> String.replace("&harr;", "<->")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end
end
