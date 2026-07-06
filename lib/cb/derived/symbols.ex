defmodule CB.Derived.Symbols do
  @moduledoc """
  Extract a symbol table - modules and function definitions with line
  spans - from Elixir source by parsing, never by compiling.

  Part of the derived layer (`CB.Derived.Index`): everything this module
  produces is mechanically regenerable from the source text, so nothing
  it produces is ever minted as a belief. `Code.string_to_quoted/2` with
  token metadata yields the real AST plus `end` positions, which is what
  lets a span say "resolve/2 occupies lines 31..46" without heuristics.

  ## What is extracted

  - `defmodule` - one `"module"` row per definition, nested modules
    concatenated the way the compiler concatenates them (`defmodule B`
    inside `defmodule A` yields `A.B`).
  - `def` / `defp` / `defmacro` / `defmacrop` - one row per clause,
    carrying the head's name and declared arity. Multiple clauses of the
    same function are deliberately kept as separate rows: each clause has
    its own span, and the innermost-span query in `CB.Derived.Index`
    wants clause granularity.

  Dynamic definitions (`def unquote(name)(...)`) have no static name and
  are skipped. A file that does not parse returns `{:error, reason}` -
  the caller decides whether that is fatal (an index build records it as
  a warning and indexes the file with no symbols).
  """

  @def_kinds [:def, :defp, :defmacro, :defmacrop]

  @typedoc """
  One symbol row. `kind` is `"module"` or the def kind; `name`/`arity`
  are nil for modules. Lines are 1-indexed and inclusive.
  """
  @type symbol :: %{
          kind: String.t(),
          module: String.t(),
          name: String.t() | nil,
          arity: non_neg_integer() | nil,
          line: pos_integer(),
          end_line: pos_integer()
        }

  @doc """
  Extract the symbol rows from `source`.

  Returns `{:ok, symbols}` sorted by start line, or `{:error, reason}`
  when the source does not parse.
  """
  @spec extract(String.t()) :: {:ok, [symbol()]} | {:error, String.t()}
  def extract(source) when is_binary(source) do
    case Code.string_to_quoted(source, token_metadata: true) do
      {:ok, ast} ->
        symbols =
          ast
          |> collect([], [])
          |> Enum.sort_by(&{&1.line, &1.end_line})

        {:ok, symbols}

      {:error, {meta, message, token}} ->
        line = if is_list(meta), do: meta[:line], else: meta
        {:error, "line #{line}: #{format_error(message, token)}"}
    end
  end

  # --- AST walk ---
  #
  # `stack` is the enclosing-module name parts (strings, outermost
  # first); `acc` accumulates symbol rows. Only module bodies are
  # walked - a def body cannot introduce a new static symbol.

  defp collect({:defmodule, meta, [name_ast, args]}, stack, acc) when is_list(args) do
    parts = module_parts(name_ast)
    full = stack ++ parts

    row = %{
      kind: "module",
      module: Enum.join(full, "."),
      name: nil,
      arity: nil,
      line: meta[:line],
      end_line: end_line(meta, args)
    }

    collect(Keyword.get(args, :do), full, [row | acc])
  end

  defp collect({kind, meta, [head | _]} = node, stack, acc) when kind in @def_kinds do
    case head_name_arity(head) do
      {name, arity} ->
        row = %{
          kind: Atom.to_string(kind),
          module: Enum.join(stack, "."),
          name: Atom.to_string(name),
          arity: arity,
          line: meta[:line],
          end_line: end_line(meta, node)
        }

        [row | acc]

      :dynamic ->
        acc
    end
  end

  defp collect({:__block__, _, exprs}, stack, acc),
    do: Enum.reduce(exprs, acc, &collect(&1, stack, &2))

  # Anything else at module scope (use/alias/attributes/conditionals)
  # is walked shallowly so a defmodule nested in, say, an `if` is still
  # found; def bodies never reach here because the def clause above
  # does not recurse.
  defp collect({_, _, args}, stack, acc) when is_list(args),
    do: Enum.reduce(args, acc, &collect(&1, stack, &2))

  defp collect(list, stack, acc) when is_list(list),
    do: Enum.reduce(list, acc, &collect(&1, stack, &2))

  defp collect({key, value}, stack, acc),
    do: collect(value, stack, collect(key, stack, acc))

  defp collect(_other, _stack, acc), do: acc

  # --- helpers ---

  defp module_parts({:__aliases__, _, parts}) do
    Enum.map(parts, fn
      part when is_atom(part) -> Atom.to_string(part)
      part -> Macro.to_string(part)
    end)
  end

  defp module_parts(atom) when is_atom(atom), do: [inspect(atom)]
  defp module_parts(other), do: [Macro.to_string(other)]

  defp head_name_arity({:when, _, [call | _]}), do: head_name_arity(call)

  defp head_name_arity({name, _, args}) when is_atom(name),
    do: {name, args |> List.wrap() |> length()}

  defp head_name_arity(_), do: :dynamic

  # `end` token metadata is present for do..end; a keyword-do form
  # (`def f, do: :ok`) has none, so fall back to the deepest line the
  # node's own metadata reaches.
  defp end_line(meta, node) do
    case meta[:end] do
      [{:line, line} | _] -> line
      _ -> max(meta[:line], max_meta_line(node))
    end
  end

  defp max_meta_line(node) do
    {_, max} =
      Macro.prewalk(node, 0, fn
        {_, meta, _} = n, acc when is_list(meta) ->
          {n, acc |> max(meta[:line] || 0) |> max(end_line_meta(meta))}

        n, acc ->
          {n, acc}
      end)

    max
  end

  defp end_line_meta(meta) do
    case meta[:end] do
      [{:line, line} | _] -> line
      _ -> meta[:closing][:line] || 0
    end
  end

  defp format_error(message, token) when is_binary(message) do
    String.trim("#{message} #{token}")
  end

  defp format_error({opening, closing}, token),
    do: String.trim("#{opening}#{token}#{closing}")
end
