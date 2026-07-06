defmodule Mix.Tasks.Cb.Index do
  @moduledoc """
  Build or check the derived structural index (`CB.Derived.Index`).

  The index - symbol spans from the real AST, call edges from the
  compiler's own resolution - is the disposable layer under the
  asserted graph: regenerable on demand, written to
  `.cb-derived/index.json` (gitignored), never under `beliefs/`. It
  exists to feed the two in-process consumers cb's contracts forbid an
  external substrate for: anchor drift detection and structural
  codepath predicates.

  ## Usage

      mix cb.index                 # build: symbols + call edges (forces a recompile)
      mix cb.index --no-calls      # build symbols only, no recompile
      mix cb.index --status        # freshness report; exit 1 when stale or absent
      mix cb.index --json          # emit the build/status summary as JSON

  ## Options

  - `--paths lib,test` - comma-separated roots to index (default `lib`)
  - `--no-calls` - skip the tracer recompile; the index carries no
    call edges (symbol queries still work)
  - `--status` - do not build; compare the persisted index against the
    working tree and report per-file drift
  - `--json` - machine-readable summary on stdout

  ## Exit codes

  Build: 0 on success (parse errors in indexed files are warnings, not
  failures - the file is indexed hash-only). Status: 0 fresh, 1 stale
  or no index.
  """
  @shortdoc "Build or check the derived symbol/call-edge index"

  use Mix.Task

  alias CB.Derived.Index
  alias CB.Derived.Tracer

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [paths: :string, no_calls: :boolean, status: :boolean, json: :boolean]
      )

    root = File.cwd!()
    paths = parse_paths(opts[:paths])

    if opts[:status] do
      status(root, opts)
    else
      build(root, paths, opts)
    end
  end

  # --- build ---

  defp build(root, paths, opts) do
    calls = if opts[:no_calls], do: [], else: trace_calls()

    {index, warnings} = Index.build(root, paths: paths, calls: calls)

    case Index.save(index, root) do
      {:ok, path} ->
        report_build(index, warnings, path, opts)

      {:error, reason} ->
        halt("cannot write index: #{inspect(reason)}")
    end
  end

  # Force a recompile with a runtime-generated tracer installed (a
  # project-app tracer would be purged mid-compile; see
  # `CB.Derived.Tracer.install/0`). The edges land in the tracer's ETS
  # table, which survives the purge/reload cycle. Compiler options are
  # restored afterwards so the task leaves no global state behind.
  defp trace_calls do
    Tracer.start()
    previous = Code.get_compiler_option(:tracers) || []
    Code.put_compiler_option(:tracers, [Tracer.install() | previous])

    try do
      Mix.Task.rerun("compile.elixir", ["--force"])
      Tracer.edges()
    after
      Code.put_compiler_option(:tracers, previous)
      Tracer.stop()
    end
  end

  defp report_build(index, warnings, path, opts) do
    file_count = map_size(index.files)
    symbol_count = index.files |> Enum.map(fn {_, e} -> length(e.symbols) end) |> Enum.sum()

    if opts[:json] do
      IO.puts(
        Jason.encode!(%{
          path: path,
          files: file_count,
          symbols: symbol_count,
          calls: length(index.calls),
          warnings: warnings
        })
      )
    else
      Enum.each(warnings, &Mix.shell().info("warning: #{&1}"))

      Mix.shell().info(
        "indexed #{file_count} file(s), #{symbol_count} symbol(s), " <>
          "#{length(index.calls)} call edge(s) -> #{Index.relpath()}"
      )
    end
  end

  # --- status ---

  defp status(root, opts) do
    case Index.load(root) do
      {:ok, index} ->
        stale = Index.stale_files(index, root)
        report_status(stale, opts)
        unless stale == [], do: System.halt(1)

      {:error, :enoent} ->
        halt("no index at #{Index.relpath()} - run `mix cb.index`")

      {:error, reason} ->
        halt("cannot load index: #{inspect(reason)}")
    end
  end

  defp report_status(stale, opts) do
    if opts[:json] do
      rows = Enum.map(stale, fn {path, state} -> %{path: path, state: state} end)
      IO.puts(Jason.encode!(%{fresh: stale == [], stale: rows}))
    else
      case stale do
        [] ->
          Mix.shell().info("index fresh")

        rows ->
          Enum.each(rows, fn {path, state} -> Mix.shell().info("#{state}: #{path}") end)
          Mix.shell().info("#{length(rows)} file(s) drifted - run `mix cb.index`")
      end
    end
  end

  defp parse_paths(nil), do: ["lib"]
  defp parse_paths(paths), do: paths |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

  defp halt(message) do
    Mix.shell().error(message)
    System.halt(1)
  end
end
