defmodule CB.RouteTags do
  @moduledoc """
  Verify route tags and the excerpt logs they materialize (route-tagging spec).

  A finalized thread body carries `<routes ref="...">` regions - per-paragraph,
  multi-ref, keyed on canonical artifact ids. Document refs are aggregating
  sinks: each referenced proto-belief document carries the region in an
  append-only, per-thread, date-stamped excerpt log. Belief ids (`cb:bNNN`)
  and code paths are non-aggregating back-links.

  The log is a write-once materialization of the tags, so its freshness
  guarantee is structural only if something re-derives it: this module
  re-derives each sink's per-thread block from the current tags and reports
  divergence, converting the guarantee from procedural (remember to append,
  remember to propagate a tag correction) to structural. Tag *coverage* -
  whether every paragraph that feeds a matter was tagged - has no mechanical
  oracle and stays editorial; a routing-ledger cross-check lifts it to row
  granularity and reports (never fails) at warn level.

  Checks, in order:

  - **tag wellformedness** - regions are line-anchored and outside fenced
    code, balanced, never nested, never crossing a `## User`/`## Assistant`
    turn boundary, and carry a non-empty ref set.
  - **ref resolution** - every ref resolves: `cb:` ids to live graph nodes,
    bare slugs to a proto-belief document (`beliefs/nursery/` or
    `beliefs/archive/`), path refs to files in the repository.
  - **sink logs** - every document sink referenced by a tagged thread carries
    a dated block for that thread in its route-tagged log section.
  - **log fidelity** - each block matches its re-derivation from the current
    tags (count line, region order, full ref-sets, whole-region content with
    ATX headers demoted to bold); blocks naming threads that no longer tag
    the sink are orphans and fail.
  - **ledger cross-check** (warn) - each tagged thread's routing-ledger rows
    that route to a document sink are covered by at least one tag; threads
    with routing rows but no tags at all are reported once.
  """

  @log_section_re ~r/^## Thread excerpts - route-tagged log/
  @open_re ~r/^<routes ref="([^"]*)">\s*$/
  @close_re ~r/^<\/routes>\s*$/
  @turn_re ~r/^## (User|Assistant)\b/
  @date_re ~r/^\d{4}-\d{2}-\d{2}/

  @type status :: :ok | :fail | :warn
  @type result :: {String.t(), status, String.t()}

  @doc """
  Run all checks. `root` is the repository root; `belief_ids` is the set of
  live graph node ids (for `cb:` ref resolution). Returns results in check
  order; a check that cannot run because an earlier one failed is still
  reported, on whatever it could see.
  """
  @spec run_checks(String.t(), MapSet.t()) :: [result]
  def run_checks(root, belief_ids) do
    threads = scan_threads(root)
    sinks = scan_sinks(root)

    [
      check_wellformedness(threads),
      check_ref_resolution(threads, root, belief_ids),
      check_sink_logs(threads, sinks),
      check_log_fidelity(threads, sinks),
      check_ledger_coverage(threads)
    ]
  end

  # ---------------------------------------------------------------------
  # Thread scanning: tags
  # ---------------------------------------------------------------------

  @doc "All finalized threads (excluding index and raw .sessions renders), parsed."
  def scan_threads(root) do
    dir = Path.join(root, "beliefs/nursery/threads")

    Path.wildcard(Path.join(dir, "*.md"))
    |> Enum.reject(&(Path.basename(&1) == "index.md"))
    |> Enum.sort()
    |> Enum.map(fn path ->
      slug = Path.basename(path, ".md")
      {regions, problems} = parse_regions(File.read!(path))

      %{
        slug: slug,
        path: path,
        date: thread_date(slug),
        regions: regions,
        problems: problems
      }
    end)
  end

  defp thread_date(slug) do
    case Regex.run(@date_re, slug) do
      [date] -> date
      nil -> nil
    end
  end

  @doc """
  Parse `<routes ref="...">` regions out of a markdown body.

  Tags count only when line-anchored and outside fenced code, so prose and
  code-block mentions of the syntax are not tags. Returns `{regions, problems}`;
  each region is `%{refs: [...], line: n, content: [...]}` with content the
  raw lines between the tags.
  """
  def parse_regions(markdown) do
    lines = String.split(markdown, "\n")

    state = %{fence: false, open: nil, regions: [], problems: []}

    state =
      lines
      |> Enum.with_index(1)
      |> Enum.reduce(state, &parse_line/2)

    state =
      case state.open do
        nil -> state
        {refs, line, _} -> problem(state, "unclosed <routes> opened at line #{line} (refs: #{Enum.join(refs, " ")})")
      end

    {Enum.reverse(state.regions), Enum.reverse(state.problems)}
  end

  defp parse_line({line, n}, state) do
    cond do
      String.starts_with?(String.trim_leading(line), "```") ->
        %{state | fence: not state.fence}

      state.fence ->
        state

      match = Regex.run(@open_re, line) ->
        [_, ref_string] = match
        refs = String.split(ref_string)

        state =
          if refs == [],
            do: problem(state, "empty ref set at line #{n}"),
            else: state

        case state.open do
          nil -> %{state | open: {refs, n, []}}
          {_, opened, _} -> problem(state, "nested <routes> at line #{n} (already open since line #{opened})")
        end

      Regex.match?(@close_re, line) ->
        case state.open do
          nil ->
            problem(state, "unmatched </routes> at line #{n}")

          {refs, opened, content} ->
            region = %{refs: refs, line: opened, content: Enum.reverse(content)}
            %{state | open: nil, regions: [region | state.regions]}
        end

      Regex.match?(@turn_re, line) ->
        case state.open do
          nil ->
            state

          {refs, opened, _} ->
            state
            |> problem("region opened at line #{opened} (refs: #{Enum.join(refs, " ")}) crosses a turn boundary at line #{n}")
            |> Map.put(:open, nil)
        end

      state.open != nil ->
        {refs, opened, content} = state.open
        %{state | open: {refs, opened, [line | content]}}

      true ->
        state
    end
  end

  defp problem(state, text), do: %{state | problems: [text | state.problems]}

  # ---------------------------------------------------------------------
  # Ref classification and resolution
  # ---------------------------------------------------------------------

  @doc "Classify a ref: `cb:` id, path (contains a slash), or document slug."
  def classify_ref("cb:" <> _ = ref), do: {:belief, ref}

  def classify_ref(ref) do
    if String.contains?(ref, "/"), do: {:path, ref}, else: {:doc, ref}
  end

  @doc "Document sinks (aggregating refs) of a region, in ref order."
  def doc_refs(refs), do: Enum.filter(refs, &match?({:doc, _}, classify_ref(&1)))

  defp resolve_doc(root, slug) do
    Enum.find(
      [
        Path.join(root, "beliefs/nursery/#{slug}.md"),
        Path.join(root, "beliefs/archive/#{slug}.md")
      ],
      &File.exists?/1
    )
  end

  # ---------------------------------------------------------------------
  # Sink scanning: materialized logs
  # ---------------------------------------------------------------------

  @doc """
  All proto-belief documents carrying a route-tagged log section, mapped
  `slug => %{path: ..., blocks: %{thread_slug => block_lines}}`.
  """
  def scan_sinks(root) do
    ["beliefs/nursery/*.md", "beliefs/archive/*.md"]
    |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
    |> Enum.sort()
    |> Enum.flat_map(fn path ->
      case parse_log_section(File.read!(path)) do
        nil -> []
        blocks -> [{Path.basename(path, ".md"), %{path: path, blocks: blocks}}]
      end
    end)
    |> Map.new()
  end

  @doc """
  Extract the route-tagged log section's per-thread blocks from a document.
  Returns `nil` when the document carries no log section, else a map of
  `thread_slug => block_lines` (from the `###` header to the section's end).
  """
  def parse_log_section(markdown) do
    lines = String.split(markdown, "\n")

    case Enum.split_while(lines, &(!Regex.match?(@log_section_re, &1))) do
      {_, []} ->
        nil

      {_, [_header | rest]} ->
        rest
        |> Enum.take_while(&(!String.starts_with?(&1, "## ")))
        |> split_blocks()
    end
  end

  defp split_blocks(lines) do
    lines
    |> Enum.chunk_while(
      [],
      fn line, acc ->
        if String.starts_with?(line, "### ") and acc != [],
          do: {:cont, Enum.reverse(acc), [line]},
          else: {:cont, [line | acc]}
      end,
      fn acc -> {:cont, Enum.reverse(acc), []} end
    )
    |> Enum.filter(fn block -> match?(["### " <> _ | _], block) end)
    |> Map.new(fn ["### " <> header | _] = block ->
      slug = header |> String.split(" (") |> hd()
      {slug, block}
    end)
  end

  # ---------------------------------------------------------------------
  # Derivation: what a sink's block must contain, given the current tags
  # ---------------------------------------------------------------------

  @doc """
  Re-derive sink `sink`'s dated block for a thread from its tagged regions:
  the `###` header, the count line, and each region lifted whole (ATX headers
  demoted to bold) under its full ref-set, in document order.
  """
  def derive_block(sink, thread, regions) do
    entries =
      Enum.map(regions, fn region ->
        co_feeds = region.refs -- [sink]

        header =
          case co_feeds do
            [] -> "**[`#{sink}`]**"
            _ -> "**[`#{sink}`]**  (co-feeds: `#{Enum.join(co_feeds, " ")}`)"
          end

        header <> "\n\n" <> (region.content |> demote_headers() |> trim_blank_edges() |> Enum.join("\n"))
      end)

    """
    ### #{thread.slug} (#{thread.date})

    #{length(regions)} tagged region(s), lifted whole. Refs shown are the full ref-set of each region (this matter plus any it co-feeds).

    #{Enum.join(entries, "\n\n---\n\n")}
    """
  end

  @doc "Demote ATX headers to bold, outside fenced code."
  def demote_headers(lines) do
    {out, _fence} =
      Enum.map_reduce(lines, false, fn line, fence ->
        cond do
          String.starts_with?(String.trim_leading(line), "```") -> {line, not fence}
          fence -> {line, fence}
          match = Regex.run(~r/^#{"#"}{1,6} (.+)$/, line) -> {"**#{Enum.at(match, 1)}**", fence}
          true -> {line, fence}
        end
      end)

    out
  end

  defp trim_blank_edges(lines) do
    lines
    |> Enum.drop_while(&(String.trim(&1) == ""))
    |> Enum.reverse()
    |> Enum.drop_while(&(String.trim(&1) == ""))
    |> Enum.reverse()
  end

  defp normalize(text) when is_binary(text), do: normalize(String.split(text, "\n"))

  defp normalize(lines) do
    lines
    |> Enum.map(&String.trim_trailing/1)
    |> trim_blank_edges()
    |> Enum.join("\n")
  end

  # ---------------------------------------------------------------------
  # Checks
  # ---------------------------------------------------------------------

  defp tagged(threads), do: Enum.filter(threads, &(&1.regions != []))

  defp check_wellformedness(threads) do
    problems =
      for t <- threads, p <- t.problems, do: "#{t.slug}: #{p}"

    tagged = tagged(threads)
    regions = tagged |> Enum.map(&length(&1.regions)) |> Enum.sum()

    if problems == [] do
      {"tag wellformedness", :ok,
       "#{regions} region(s) across #{length(tagged)} tagged thread(s), balanced, none crossing a turn boundary"}
    else
      {"tag wellformedness", :fail, Enum.join(problems, "\n        ")}
    end
  end

  defp check_ref_resolution(threads, root, belief_ids) do
    refs =
      for t <- tagged(threads), r <- t.regions, ref <- r.refs, uniq: true, do: ref

    unresolved =
      Enum.reject(refs, fn ref ->
        case classify_ref(ref) do
          {:belief, id} -> MapSet.member?(belief_ids, id)
          {:doc, slug} -> resolve_doc(root, slug) != nil
          {:path, path} -> File.exists?(Path.join(root, path))
        end
      end)

    kinds = Enum.frequencies_by(refs, &elem(classify_ref(&1), 0))

    if unresolved == [] do
      {"ref resolution", :ok,
       "#{length(refs)} distinct ref(s) all resolve (#{kinds[:doc] || 0} documents, #{kinds[:belief] || 0} beliefs, #{kinds[:path] || 0} paths)"}
    else
      {"ref resolution", :fail, "unresolved ref(s): #{Enum.join(unresolved, ", ")}"}
    end
  end

  # Every (tagged thread, document sink) pair demands a dated block in the sink.
  defp feeding_pairs(threads) do
    for t <- tagged(threads),
        sink <- t.regions |> Enum.flat_map(&doc_refs(&1.refs)) |> Enum.uniq(),
        do: {t, sink}
  end

  defp check_sink_logs(threads, sinks) do
    missing =
      for {t, sink} <- feeding_pairs(threads),
          get_in(sinks, [sink, :blocks, t.slug]) == nil,
          do: "#{sink}: no dated block for #{t.slug}#{if sinks[sink], do: "", else: " (no route-tagged log section)"}"

    pairs = feeding_pairs(threads)

    if missing == [] do
      {"sink logs", :ok,
       "#{length(pairs)} thread-to-sink append(s) all present"}
    else
      {"sink logs", :fail, Enum.join(missing, "\n        ")}
    end
  end

  defp check_log_fidelity(threads, sinks) do
    by_slug = Map.new(threads, &{&1.slug, &1})

    divergent =
      for {t, sink} <- feeding_pairs(threads),
          block = get_in(sinks, [sink, :blocks, t.slug]),
          block != nil,
          regions = Enum.filter(t.regions, &(sink in doc_refs(&1.refs))),
          normalize(block) != normalize(derive_block(sink, t, regions)),
          do: "#{sink}: block for #{t.slug} diverges from its re-derivation from the tags"

    orphans =
      for {sink, %{blocks: blocks}} <- sinks,
          {slug, _} <- blocks,
          t = by_slug[slug],
          t == nil or not Enum.any?(t.regions, &(sink in doc_refs(&1.refs))),
          do: "#{sink}: block for #{slug} but #{if t, do: "the thread no longer tags this sink", else: "no such thread"}"

    problems = divergent ++ orphans
    checked = feeding_pairs(threads) |> Enum.count(fn {t, sink} -> get_in(sinks, [sink, :blocks, t.slug]) != nil end)

    if problems == [] do
      {"log fidelity", :ok, "#{checked} materialized block(s) match their re-derivation from the tags"}
    else
      {"log fidelity", :fail, Enum.join(problems, "\n        ")}
    end
  end

  defp check_ledger_coverage(threads) do
    warnings =
      threads
      |> Enum.filter(&(&1.date != nil))
      |> Enum.flat_map(fn t ->
        routed = ledger_doc_sinks(t)
        tagged_sinks = t.regions |> Enum.flat_map(&doc_refs(&1.refs)) |> Enum.uniq()

        cond do
          routed == [] ->
            []

          t.regions == [] ->
            ["#{t.slug}: routing ledger routes to #{length(routed)} document(s) but the body carries no route tags"]

          true ->
            case routed -- tagged_sinks do
              [] -> []
              uncovered -> ["#{t.slug}: ledger row(s) routed to #{Enum.join(uncovered, ", ")} but no region tags them"]
            end
        end
      end)

    if warnings == [] do
      {"ledger cross-check", :ok, "every doc-routed ledger row is covered by a tag"}
    else
      {"ledger cross-check", :warn, Enum.join(warnings, "\n        ")}
    end
  end

  @doc """
  Document sinks a thread's routing ledger routes to: markdown links in the
  `Routed to` column that resolve into `beliefs/nursery/` or `beliefs/archive/`
  (never `threads/`; never a README or index, which are shelf infrastructure,
  not proto-belief documents), as slugs.
  """
  def ledger_doc_sinks(thread) do
    thread.path
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "|"))
    |> Enum.flat_map(fn row ->
      case String.split(row, "|") do
        [_, _topic, _state, routed_to | _] ->
          Regex.scan(~r/\[[^\]]*\]\(([^)]+)\)/, routed_to, capture: :all_but_first)

        _ ->
          []
      end
    end)
    |> Enum.map(fn [target] ->
      thread.path |> Path.dirname() |> Path.join(target) |> Path.expand()
    end)
    |> Enum.filter(fn path ->
      Path.extname(path) == ".md" and
        Path.basename(path) not in ["README.md", "index.md"] and
        not String.contains?(path, "/threads/") and
        (String.contains?(path, "/beliefs/nursery/") or String.contains?(path, "/beliefs/archive/"))
    end)
    |> Enum.map(&Path.basename(&1, ".md"))
    |> Enum.uniq()
  end
end
