defmodule Mix.Tasks.Cb.Generate.Kb do
  @moduledoc """
  Generate the markdown knowledge base from the belief graph.

  Renders one page per belief plus an index into `docs/kb/`, via
  `CB.Render.Kb`. The output is a deterministic projection of the graph:
  same graph, same bytes. The generated tree is read-only; edits are
  overwritten on the next run, and CI keeps the committed tree fresh with
  `--check` - the same gate CLAUDE.md uses, so the mirror can never quietly
  drift from the graph (the cb:b386 digest antipattern, answered the same
  way).

  ## Usage

      mix cb.generate.kb            - generate docs/kb/
      mix cb.generate.kb --check    - diff against the committed tree; no write

  `--beliefs PATH` points the generator at an alternate belief graph for one
  invocation, the same override the belief shell takes.

  Write mode prunes: a `.md` file under `docs/kb/` that the build no longer
  produces is deleted, so pages for renamed or removed nodes cannot linger.

  ## Exit codes

  0 = generated or check passed, 1 = check failed
  """
  @shortdoc "Generate the markdown knowledge base from the belief graph"

  use Mix.Task

  alias CB.Belief.Store
  alias CB.Render.Kb

  @out_rel "docs/kb"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [check: :boolean, beliefs: :string])

    if path = opts[:beliefs], do: Application.put_env(:cb, :beliefs_path, path)

    root = Path.join(CB.repo_root(), @out_rel)
    {:ok, beliefs} = Store.read()
    pages = Kb.build(beliefs)

    if opts[:check] do
      run_check(root, pages)
    else
      run_write(root, pages)
    end
  end

  defp run_write(root, pages) do
    Enum.each(pages, fn {rel, content} ->
      abs = Path.join(root, rel)
      File.mkdir_p!(Path.dirname(abs))
      File.write!(abs, content)
    end)

    pruned = prune(root, pages)

    IO.puts(:stderr, "Generated #{@out_rel}/: #{length(pages)} pages#{pruned_note(pruned)}")
  end

  defp prune(root, pages) do
    keep = MapSet.new(pages, fn {rel, _} -> Path.join(root, rel) end)

    Path.wildcard(Path.join(root, "**/*.md"))
    |> Enum.reject(&MapSet.member?(keep, &1))
    |> Enum.map(fn stray ->
      File.rm!(stray)
      stray
    end)
  end

  defp pruned_note([]), do: ""
  defp pruned_note(pruned), do: ", pruned #{length(pruned)} stray"

  defp run_check(root, pages) do
    expected = Map.new(pages, fn {rel, content} -> {Path.join(root, rel), content} end)

    on_disk = Path.wildcard(Path.join(root, "**/*.md")) |> MapSet.new()

    diffs =
      Enum.flat_map(expected, fn {abs, content} ->
        case File.read(abs) do
          {:ok, ^content} -> []
          {:ok, _} -> ["stale: #{Path.relative_to(abs, CB.repo_root())}"]
          {:error, _} -> ["missing: #{Path.relative_to(abs, CB.repo_root())}"]
        end
      end)

    strays =
      on_disk
      |> Enum.reject(&Map.has_key?(expected, &1))
      |> Enum.map(&"stray: #{Path.relative_to(&1, CB.repo_root())}")

    case Enum.sort(diffs ++ strays) do
      [] ->
        IO.puts(:stderr, "#{@out_rel}/ is up to date")

      problems ->
        Enum.each(problems, &IO.puts(:stderr, "  " <> &1))
        IO.puts(:stderr, "#{@out_rel}/ is out of date - run `mix cb.generate.kb`")
        System.halt(1)
    end
  end
end
