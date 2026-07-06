defmodule CB.Derived.Index do
  @moduledoc """
  The derived structural index: symbol spans plus compiler-verified
  call edges, regenerable from source, stored outside the graph.

  ## Doctrine (why this module is shaped the way it is)

  cb's graph is *asserted* knowledge: every node is a claim someone
  chose to make, immutable, superseded rather than re-derived. Code
  structure is the opposite kind of knowledge - *derived*, mechanical,
  changing with every commit - so it must never live in the graph
  (thousands of ceremonial supersessions per commit to track what a
  re-index gives for free). This module is the disposable layer under
  the durable one: its artifact is regenerable, gitignored
  (`#{".cb-derived/index.json"}`), and never written under `beliefs/`.

  Its purpose is the two places cb's own contracts forbid an external
  (subprocess) substrate:

  - **Anchor verification** - `CB.Anchor` resolves a literal substring
    to a line; `enclosing_symbol/3` says which module/function that
    line sits in, so drift ("the anchor left the symbol it was minted
    against") becomes detectable.
  - **Structural codepath predicates** - routed predicates must be
    zero-arity, in-process, inspection-only (cb:b050). With this index
    loaded in the same BEAM, "these codepath stops form a real call
    chain" (`call_chain?/2`) is a legal predicate.

  There are no confidence scores anywhere in the index: symbols come
  from the real AST and call edges from the compiler's own resolution
  (`CB.Derived.Tracer`), so every row is deterministic - the derived
  form cb:b448 points to, not the synthesized kind it bans.

  ## Freshness

  The index records a sha256 per indexed file. `stale_files/2` compares
  those against the working tree, so a consumer (a predicate, the
  anchor resolver, `mix cb.index --status`) can refuse to trust a stale
  index instead of silently answering from it.

  Building is orchestrated by `mix cb.index`; this module stays pure -
  `build/2` takes the call edges as input rather than running the
  compiler itself, which keeps every function here testable without a
  recompile.
  """

  alias CB.Derived.Symbols

  @relpath ".cb-derived/index.json"
  @format_version 1

  defstruct version: @format_version,
            paths: ["lib"],
            files: %{},
            calls: []

  @typedoc """
  `files` maps a repo-relative path to
  `%{sha256: String.t(), error: String.t() | nil, symbols: [Symbols.symbol()]}`;
  `calls` is the edge list as `CB.Derived.Tracer.edges/0` shapes it.
  """
  @type t :: %__MODULE__{
          version: pos_integer(),
          paths: [String.t()],
          files: %{String.t() => map()},
          calls: [map()]
        }

  @doc "Repo-relative location of the persisted index."
  @spec relpath() :: String.t()
  def relpath, do: @relpath

  # --- build / persist ---

  @doc """
  Build an index for the `.ex` files under `opts[:paths]` (default
  `["lib"]`) relative to `root`, with `opts[:calls]` as the edge list
  (default `[]` - the mix task supplies tracer output).

  Returns `{index, warnings}`; a file that does not parse is indexed
  with its hash, an empty symbol list, and the parse error recorded on
  its entry (and echoed as a warning), so staleness tracking still
  covers it.
  """
  @spec build(String.t(), keyword()) :: {t(), [String.t()]}
  def build(root, opts \\ []) do
    paths = Keyword.get(opts, :paths, ["lib"])
    calls = Keyword.get(opts, :calls, [])

    {files, warnings} =
      paths
      |> Enum.flat_map(&Path.wildcard(Path.join([root, &1, "**/*.ex"])))
      |> Enum.sort()
      |> Enum.reduce({%{}, []}, fn abs_path, {files, warnings} ->
        rel = Path.relative_to(abs_path, root)
        source = File.read!(abs_path)

        {symbols, error} =
          case Symbols.extract(source) do
            {:ok, symbols} -> {symbols, nil}
            {:error, reason} -> {[], reason}
          end

        entry = %{sha256: sha256(source), error: error, symbols: symbols}
        warnings = if error, do: ["#{rel}: #{error}" | warnings], else: warnings
        {Map.put(files, rel, entry), warnings}
      end)

    index = %__MODULE__{
      version: @format_version,
      paths: paths,
      files: files,
      calls: Enum.filter(calls, &Map.has_key?(files, &1.caller.file))
    }

    {index, Enum.reverse(warnings)}
  end

  @doc "Encode and atomically write the index under `root`. Returns `{:ok, path}` or `{:error, reason}`."
  @spec save(t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def save(%__MODULE__{} = index, root) do
    CB.JSON.write_atomic_raw(Path.join(root, @relpath), encode(index))
  end

  @doc "Load the persisted index from under `root`."
  @spec load(String.t()) :: {:ok, t()} | {:error, term()}
  def load(root) do
    case CB.JSON.read(Path.join(root, @relpath)) do
      {:ok, %{"version" => @format_version} = data} -> {:ok, from_map(data)}
      {:ok, %{"version" => v}} -> {:error, {:unsupported_version, v}}
      {:ok, _} -> {:error, :malformed_index}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Files whose working-tree content no longer matches the index: a list
  of `{path, :changed | :missing | :unindexed}` rows, empty when fresh.
  `:unindexed` marks `.ex` files now present under the indexed paths
  that the index has never seen.
  """
  @spec stale_files(t(), String.t()) :: [{String.t(), :changed | :missing | :unindexed}]
  def stale_files(%__MODULE__{} = index, root) do
    known =
      Enum.flat_map(index.files, fn {rel, entry} ->
        case File.read(Path.join(root, rel)) do
          {:ok, source} -> if sha256(source) == entry.sha256, do: [], else: [{rel, :changed}]
          {:error, _} -> [{rel, :missing}]
        end
      end)

    new =
      index.paths
      |> Enum.flat_map(&Path.wildcard(Path.join([root, &1, "**/*.ex"])))
      |> Enum.map(&Path.relative_to(&1, root))
      |> Enum.reject(&Map.has_key?(index.files, &1))
      |> Enum.map(&{&1, :unindexed})

    Enum.sort(known ++ new)
  end

  # --- symbol queries ---

  @doc "All symbol rows for `path`, or `[]`."
  @spec symbols_in(t(), String.t()) :: [Symbols.symbol()]
  def symbols_in(%__MODULE__{files: files}, path) do
    case files[path] do
      %{symbols: symbols} -> symbols
      nil -> []
    end
  end

  @doc """
  The innermost symbol whose span contains `line` in `path` - a def
  clause when the line is inside one, else the enclosing module - or
  nil when the line sits outside every indexed span.
  """
  @spec enclosing_symbol(t(), String.t(), pos_integer()) :: Symbols.symbol() | nil
  def enclosing_symbol(%__MODULE__{} = index, path, line) when is_integer(line) do
    index
    |> symbols_in(path)
    |> Enum.filter(&(&1.line <= line and line <= &1.end_line))
    |> Enum.min_by(&(&1.end_line - &1.line), fn -> nil end)
  end

  @doc "Whether `module` defines `name`/`arity` (any def kind) in the index."
  @spec defines?(t(), module() | String.t(), atom() | String.t(), non_neg_integer()) :: boolean()
  def defines?(%__MODULE__{files: files}, module, name, arity) do
    {m, f} = normalize(module, name)

    Enum.any?(files, fn {_, entry} ->
      Enum.any?(entry.symbols, &(&1.module == m and &1.name == f and &1.arity == arity))
    end)
  end

  # --- call queries ---

  @doc "Edges whose caller is `{module, function, arity}`."
  @spec calls_from(t(), {module() | String.t(), atom() | String.t(), non_neg_integer()}) :: [
          map()
        ]
  def calls_from(%__MODULE__{calls: calls}, {module, function, arity}) do
    {m, f} = normalize(module, function)

    Enum.filter(
      calls,
      &(&1.caller.module == m and &1.caller.function == f and &1.caller.arity == arity)
    )
  end

  @doc "Edges whose callee is `{module, function, arity}`."
  @spec calls_to(t(), {module() | String.t(), atom() | String.t(), non_neg_integer()}) :: [map()]
  def calls_to(%__MODULE__{calls: calls}, {module, function, arity}) do
    {m, f} = normalize(module, function)

    Enum.filter(
      calls,
      &(&1.callee.module == m and &1.callee.function == f and &1.callee.arity == arity)
    )
  end

  @doc "Whether the compiler saw a direct call from `from` to `to` (both `{m, f, a}`)."
  @spec call_edge?(t(), tuple(), tuple()) :: boolean()
  def call_edge?(%__MODULE__{} = index, from, {to_m, to_f, to_a}) do
    {m, f} = normalize(to_m, to_f)

    index
    |> calls_from(from)
    |> Enum.any?(&(&1.callee.module == m and &1.callee.function == f and &1.callee.arity == to_a))
  end

  @doc """
  The consecutive pairs in `mfas` with no recorded call edge - `[]`
  means the chain is real. This is the structural spine check for a
  codepath: each stop's `{m, f, a}` should be reachable from the one
  before it.
  """
  @spec chain_gaps(t(), [tuple()]) :: [{tuple(), tuple()}]
  def chain_gaps(%__MODULE__{} = index, mfas) when is_list(mfas) do
    mfas
    |> Enum.zip(Enum.drop(mfas, 1))
    |> Enum.reject(fn {from, to} -> call_edge?(index, from, to) end)
  end

  @doc "Whether every consecutive pair in `mfas` has a recorded call edge."
  @spec call_chain?(t(), [tuple()]) :: boolean()
  def call_chain?(%__MODULE__{} = index, mfas), do: chain_gaps(index, mfas) == []

  # --- encoding ---
  #
  # Key order is pinned via Jason.OrderedObject (the okf modules'
  # idiom) and files/symbols/calls are sorted at build time, so the
  # same tree always serializes to the same bytes - a diffable,
  # cache-like artifact.

  defp encode(%__MODULE__{} = index) do
    files =
      index.files
      |> Enum.sort_by(fn {path, _} -> path end)
      |> Enum.map(fn {path, entry} ->
        {path,
         ordered(
           sha256: entry.sha256,
           error: entry.error,
           symbols: Enum.map(entry.symbols, &symbol_object/1)
         )}
      end)
      |> Jason.OrderedObject.new()

    ordered(
      version: index.version,
      paths: index.paths,
      files: files,
      calls: Enum.map(index.calls, &call_object/1)
    )
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
  end

  defp symbol_object(s) do
    ordered(
      kind: s.kind,
      module: s.module,
      name: s.name,
      arity: s.arity,
      line: s.line,
      end_line: s.end_line
    )
  end

  defp call_object(c) do
    ordered(
      kind: c.kind,
      caller:
        ordered(
          module: c.caller.module,
          function: c.caller.function,
          arity: c.caller.arity,
          file: c.caller.file,
          line: c.caller.line
        ),
      callee:
        ordered(
          module: c.callee.module,
          function: c.callee.function,
          arity: c.callee.arity
        )
    )
  end

  defp ordered(pairs),
    do: Jason.OrderedObject.new(Enum.map(pairs, fn {k, v} -> {Atom.to_string(k), v} end))

  # --- decoding ---

  defp from_map(data) do
    %__MODULE__{
      version: data["version"],
      paths: data["paths"] || ["lib"],
      files: Map.new(data["files"] || %{}, fn {path, entry} -> {path, file_entry(entry)} end),
      calls: Enum.map(data["calls"] || [], &call_entry/1)
    }
  end

  defp file_entry(entry) do
    %{
      sha256: entry["sha256"],
      error: entry["error"],
      symbols: Enum.map(entry["symbols"] || [], &symbol_entry/1)
    }
  end

  defp symbol_entry(s) do
    %{
      kind: s["kind"],
      module: s["module"],
      name: s["name"],
      arity: s["arity"],
      line: s["line"],
      end_line: s["end_line"]
    }
  end

  defp call_entry(c) do
    %{
      kind: c["kind"],
      caller: %{
        module: c["caller"]["module"],
        function: c["caller"]["function"],
        arity: c["caller"]["arity"],
        file: c["caller"]["file"],
        line: c["caller"]["line"]
      },
      callee: %{
        module: c["callee"]["module"],
        function: c["callee"]["function"],
        arity: c["callee"]["arity"]
      }
    }
  end

  # Modules and functions are stored as strings (`inspect/1` form for
  # modules), so queries accept atoms or strings and normalize here -
  # nothing on the read path ever creates an atom from index data.
  defp normalize(module, function) do
    m = if is_atom(module), do: inspect(module), else: module
    f = if is_atom(function), do: Atom.to_string(function), else: function
    {m, f}
  end

  defp sha256(content), do: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
end
