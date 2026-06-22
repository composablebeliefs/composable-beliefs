defmodule CB.Knowledge.Validate do
  @moduledoc """
  Validate a Knowledge (OKF) bundle. Faithful port of the Python reference
  (`tools/validate.py`); findings carry stable `code` values so the conformance
  suite can compare implementations. Human messages are not normative.

  `run/1` returns `{errors, warnings}`, each a list of `%{path:, code:, msg:}`.
  `to_contract/2` renders the root-independent `{ok, errors, warnings}` JSON object
  that the conformance suite diffs.
  """
  alias CB.Knowledge.{Frontmatter, Manifest}

  @types ~w(source concept thread plan analysis position decision reference index spec)
  @statuses ~w(active superseded retracted draft)
  @date ~r/^\d{4}-\d{2}-\d{2}$/
  @placeholder ~r/<[A-Za-z][^>\n]*>/
  @link ~r/\[[^\]]*\]\((?!https?:|#|mailto:)([^)#]+\.md)(?:#[^)]*)?\)/
  # Soft convention: ids are namespace:local (lowercase). A CB-dialect addition, not
  # OKF-native; warned, not failed.
  @id_format ~r/^[a-z][a-z0-9]*:[a-z0-9-]+$/

  def run(root) do
    root = Path.expand(root)

    st =
      Manifest.doc_paths(root)
      |> Enum.reduce(%{errors: [], warnings: [], ids: %{}, cb_deps: [], dirs: %{}}, fn {full, rel}, acc ->
        check_file(full, rel, acc)
      end)

    errors = Enum.reverse(st.errors) ++ manifest_check(root)
    warnings = Enum.reverse(st.warnings) ++ dep_warnings(st.cb_deps, st.ids) ++ dir_warnings(st.dirs)
    {errors, warnings}
  end

  @doc "Render the normative conformance object."
  def to_contract(errors, warnings) do
    oo =
      Jason.OrderedObject.new([
        {"ok", errors == []},
        {"errors", sorted_pairs(errors)},
        {"warnings", sorted_pairs(warnings)}
      ])

    Jason.encode!(oo, pretty: true)
  end

  defp sorted_pairs(list) do
    list
    |> Enum.map(fn f -> {f.code, f.path} end)
    |> Enum.sort()
    |> Enum.map(fn {code, path} -> Jason.OrderedObject.new([{"path", path}, {"code", code}]) end)
  end

  # ---- per-file checks ----

  defp check_file(full, rel, st) do
    text = File.read!(full)
    fm = Frontmatter.parse(text)
    st = track_dir(st, rel)

    if fm == %{} do
      add_err(st, rel, "no_frontmatter", "no YAML frontmatter")
    else
      st
      |> check_type(rel, fm)
      |> check_description(rel, fm)
      |> check_placeholders(rel, fm)
      |> check_status(rel, fm)
      |> check_timestamp(rel, fm)
      |> check_id(rel, fm)
      |> check_cb(rel, fm)
      |> check_links(rel, full, text)
    end
  end

  defp check_type(st, rel, fm) do
    case Map.get(fm, "type") do
      nil -> add_err(st, rel, "missing_type", "missing required `type`")
      t -> if t in @types, do: st, else: add_err(st, rel, "type_not_in_taxonomy", "type '#{t}' not in taxonomy")
    end
  end

  defp check_description(st, rel, fm) do
    desc = Map.get(fm, "description", "")

    if is_binary(desc) and String.length(String.trim(desc)) >= 20 do
      st
    else
      add_err(st, rel, "description_missing_or_short", "`description` missing or too short (relevance hook)")
    end
  end

  defp check_placeholders(st, rel, fm) do
    Enum.reduce(fm, st, fn {k, v}, acc ->
      vals = if is_list(v), do: v, else: [v]

      if Enum.any?(vals, &(is_binary(&1) and Regex.match?(@placeholder, &1))) do
        add_err(acc, rel, "placeholder_in_frontmatter", "unfilled template placeholder in `#{k}`")
      else
        acc
      end
    end)
  end

  defp check_status(st, rel, fm) do
    case Map.get(fm, "status") do
      nil -> st
      s -> if s in @statuses, do: st, else: add_err(st, rel, "invalid_status", "status '#{s}' invalid")
    end
  end

  defp check_timestamp(st, rel, fm) do
    case Map.get(fm, "timestamp") do
      nil -> st
      ts -> if Regex.match?(@date, to_string(ts)), do: st, else: add_err(st, rel, "invalid_timestamp", "timestamp '#{ts}' is not YYYY-MM-DD")
    end
  end

  defp check_id(st, rel, fm) do
    case Map.get(fm, "id") do
      nil ->
        st

      id ->
        st =
          if Regex.match?(@id_format, id),
            do: st,
            else: add_warn(st, rel, "id_format_invalid", "id '#{id}' is not namespace:local form")

        if Map.has_key?(st.ids, id) do
          add_err(st, rel, "duplicate_id", "duplicate id '#{id}' (also in #{st.ids[id]})")
        else
          %{st | ids: Map.put(st.ids, id, rel)}
        end
    end
  end

  defp check_cb(st, rel, fm) do
    if Map.get(fm, "tier") == "cb" do
      st = if Map.get(fm, "id"), do: st, else: add_err(st, rel, "cb_tier_missing_id", "tier: cb requires an `id`")

      deps =
        case Map.get(fm, "deps") do
          nil -> []
          d when is_list(d) -> d
          d -> [d]
        end

      st = %{st | cb_deps: st.cb_deps ++ [{rel, deps}]}

      if Map.get(fm, "status") == "superseded" and is_nil(Map.get(fm, "superseded_by")) do
        add_err(st, rel, "superseded_missing_superseded_by", "status superseded but no `superseded_by`")
      else
        st
      end
    else
      st
    end
  end

  defp check_links(st, rel, full, text) do
    Regex.scan(@link, text)
    |> Enum.reduce(st, fn [_full, target | _], acc ->
      resolved = Path.expand(Path.join(Path.dirname(full), target))
      if File.exists?(resolved), do: acc, else: add_err(acc, rel, "broken_link", "broken link -> #{target}")
    end)
  end

  # ---- cross-file checks ----

  defp manifest_check(root) do
    man = Path.join(root, "manifest.json")
    expected = Manifest.render(root)

    cond do
      not File.exists?(man) -> [finding("manifest.json", "manifest_missing", "missing (run mix knowledge.manifest)")]
      File.read!(man) != expected -> [finding("manifest.json", "manifest_stale", "stale (run mix knowledge.manifest)")]
      true -> []
    end
  end

  defp dep_warnings(cb_deps, ids) do
    for {rel, deps} <- cb_deps, dep <- deps, not Map.has_key?(ids, dep) do
      finding(rel, "dep_unresolved_in_bundle", "dep '#{dep}' not found in this bundle")
    end
  end

  defp dir_warnings(dirs) do
    for {d, bases} <- Enum.sort(dirs), not MapSet.member?(bases, "index.md") do
      finding(d, "dir_missing_index", "directory has docs but no index.md")
    end
  end

  # ---- helpers ----

  defp track_dir(st, rel) do
    d = Path.dirname(rel)
    base = Path.basename(rel)
    %{st | dirs: Map.update(st.dirs, d, MapSet.new([base]), &MapSet.put(&1, base))}
  end

  defp add_err(st, path, code, msg), do: %{st | errors: [finding(path, code, msg) | st.errors]}

  defp add_warn(st, path, code, msg), do: %{st | warnings: [finding(path, code, msg) | st.warnings]}

  defp finding(path, code, msg), do: %{path: path, code: code, msg: msg}
end
