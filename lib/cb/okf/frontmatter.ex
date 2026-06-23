defmodule CB.Okf.Frontmatter do
  @moduledoc """
  Parse the documented Knowledge/OKF frontmatter subset: scalars, inline `[a, b]`
  lists, `>`/`|` folded blocks, and `- item` block lists.

  This is NOT a full YAML parser. It parses the same subset the original Python
  reference parser (`tools/build_manifest.py`, since removed in the Elixir-only
  collapse) handled. The conformance corpus under `okf/conformance` is now the SSOT
  for that agreement.

  Returns a map with string keys, or `%{}` when there is no frontmatter block.
  """

  @doc "Parse frontmatter from full document text."
  def parse(text) when is_binary(text) do
    lines = String.split(text, "\n")

    case lines do
      [first | _] ->
        if String.trim(first) == "---" do
          case end_index(lines) do
            nil -> %{}
            idx -> do_parse(Enum.slice(lines, 1, idx - 1), nil, %{})
          end
        else
          %{}
        end

      _ ->
        %{}
    end
  end

  # Index of the closing `---` (first line at i>=1 whose trim == "---").
  defp end_index(lines) do
    lines
    |> Enum.with_index()
    |> Enum.find_value(fn {line, i} ->
      if i >= 1 and String.trim(line) == "---", do: i, else: nil
    end)
  end

  defp do_parse([], _key, acc), do: acc

  defp do_parse([line | rest], key, acc) do
    s = String.trim(line)

    cond do
      s == "" or String.starts_with?(s, "#") ->
        do_parse(rest, key, acc)

      String.starts_with?(s, "- ") and key != nil ->
        val = scalar(String.trim(String.slice(s, 2..-1//1)))
        do_parse(rest, key, append_list(acc, key, val))

      not String.contains?(s, ":") ->
        do_parse(rest, key, acc)

      true ->
        {k, v} = split_kv(s)

        cond do
          v == ">" or v == "|" ->
            {block, rest2} = take_block(rest, [])
            do_parse(rest2, k, Map.put(acc, k, block))

          v == "" ->
            do_parse(rest, k, Map.put(acc, k, []))

          true ->
            do_parse(rest, k, Map.put(acc, k, scalar(v)))
        end
    end
  end

  defp append_list(acc, key, val) do
    case Map.get(acc, key) do
      list when is_list(list) -> Map.put(acc, key, list ++ [val])
      nil -> Map.put(acc, key, [val])
      _scalar -> acc
    end
  end

  defp split_kv(s) do
    [k | rest] = String.split(s, ":", parts: 2)
    {String.trim(k), String.trim(Enum.at(rest, 0, ""))}
  end

  defp take_block([], acc), do: {Enum.join(acc, " "), []}

  defp take_block([line | rest] = all, acc) do
    cond do
      String.trim(line) == "" -> take_block(rest, acc)
      String.starts_with?(line, " ") or String.starts_with?(line, "\t") ->
        take_block(rest, acc ++ [String.trim(line)])
      true -> {Enum.join(acc, " "), all}
    end
  end

  defp scalar(v) do
    v = String.trim(v)

    if String.starts_with?(v, "[") and String.ends_with?(v, "]") do
      inner = String.trim(String.slice(v, 1..-2//1))

      if inner == "" do
        []
      else
        inner |> String.split(",") |> Enum.map(&strip_quotes(String.trim(&1)))
      end
    else
      strip_quotes(v)
    end
  end

  defp strip_quotes(s) do
    if String.length(s) >= 2 do
      first = String.first(s)
      last = String.last(s)
      if first == last and first in ["'", "\""], do: String.slice(s, 1..-2//1), else: s
    else
      s
    end
  end
end
