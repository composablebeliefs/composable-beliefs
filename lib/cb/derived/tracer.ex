defmodule CB.Derived.Tracer do
  @moduledoc """
  Collect call edges as the compiler resolves them.

  This is the derived layer's answer to heuristic call-graph
  extraction: instead of parsing 15 languages from the outside and
  scoring each resolution, the Elixir compiler is asked to report every
  call it actually resolves. An edge recorded here is
  compiler-verified - there is no confidence to synthesize (dynamic
  dispatch and `apply/3` are simply invisible, which is the honest
  shape of that limitation).

  ## Why the tracer module is generated at runtime

  `mix cb.index` traces the project by force-recompiling it - and a
  forced recompile purges the project's own modules, so a tracer that
  lives in `lib/` vanishes mid-compile and the compiler crashes calling
  it. `install/0` therefore creates a fresh, uniquely named module at
  runtime whose `trace/2` is self-contained (core modules and one named
  ETS table only). That module is not part of the project app, so the
  recompile cannot purge it. It records raw event tuples; `edges/0`
  (this module, safely reloadable after the compile finishes) shapes
  them into edge maps.

  Collection state lives in a public named ETS table owned by the
  calling process, so it survives the purge/reload cycle; when the
  table is absent every callback is a no-op.
  """

  @table :cb_derived_tracer

  @doc "Create (or reset) the collection table."
  @spec start() :: :ok
  def start do
    stop()
    :ets.new(@table, [:named_table, :public, :duplicate_bag])
    :ok
  end

  @doc "Drop the collection table; installed tracers become no-ops."
  @spec stop() :: :ok
  def stop do
    if collecting?(), do: :ets.delete(@table)
    :ok
  end

  @doc "Whether a collection table currently exists."
  @spec collecting?() :: boolean()
  def collecting?, do: :ets.whereis(@table) != :undefined

  @doc """
  Create and return a purge-proof tracer module for the compiler's
  `:tracers` option. Each call mints a unique module name, so repeated
  index builds in one VM never redefine a live tracer.
  """
  @spec install() :: module()
  def install do
    name = Module.concat(__MODULE__, :"Session#{System.unique_integer([:positive])}")

    body =
      quote do
        @moduledoc false

        def trace({:remote_function, meta, module, name, arity}, env),
          do: record(:remote, module, name, arity, meta, env)

        def trace({:remote_macro, meta, module, name, arity}, env),
          do: record(:remote_macro, module, name, arity, meta, env)

        def trace({:imported_function, meta, module, name, arity}, env),
          do: record(:imported, module, name, arity, meta, env)

        def trace({:imported_macro, meta, module, name, arity}, env),
          do: record(:imported_macro, module, name, arity, meta, env)

        def trace({:local_function, meta, name, arity}, env),
          do: record(:local, env.module, name, arity, meta, env)

        def trace({:local_macro, meta, name, arity}, env),
          do: record(:local_macro, env.module, name, arity, meta, env)

        def trace(_event, _env), do: :ok

        defp record(kind, module, name, arity, meta, env) do
          if :ets.whereis(unquote(@table)) != :undefined do
            row =
              {kind, module, name, arity, meta[:line] || env.line, env.module, env.function,
               env.file}

            :ets.insert(unquote(@table), {:raw, row})
          end

          :ok
        end
      end

    {:module, ^name, _, _} = Module.create(name, body, Macro.Env.location(__ENV__))
    name
  end

  @doc """
  The edges collected so far, deduplicated and sorted by caller
  file/line. Each edge is a map with `kind`, `caller`
  (`module`/`function`/`arity`/`file`/`line`) and `callee`
  (`module`/`function`/`arity`); module names are strings as
  `inspect/1` renders them, so no atoms need creating on read.
  Module-body events with no enclosing module are dropped.
  """
  @spec edges() :: [map()]
  def edges do
    if collecting?() do
      cwd = File.cwd!()

      @table
      |> :ets.tab2list()
      |> Enum.flat_map(fn {:raw, row} -> shape(row, cwd) end)
      |> Enum.uniq()
      |> Enum.sort_by(fn e ->
        {e.caller.file, e.caller.line, e.callee.module, e.callee.function, e.callee.arity}
      end)
    else
      []
    end
  end

  defp shape({_kind, _mod, _name, _arity, _line, nil, _fun, _file}, _cwd), do: []

  defp shape({kind, module, name, arity, line, caller_mod, caller_fun, file}, cwd) do
    {fun, fun_arity} =
      case caller_fun do
        {f, a} -> {Atom.to_string(f), a}
        nil -> {nil, nil}
      end

    [
      %{
        kind: Atom.to_string(kind),
        caller: %{
          module: inspect(caller_mod),
          function: fun,
          arity: fun_arity,
          file: Path.relative_to(file, cwd),
          line: line
        },
        callee: %{
          module: inspect(module),
          function: Atom.to_string(name),
          arity: arity
        }
      }
    ]
  end
end
