defmodule CB.GeneratedClaudeMdTest do
  @moduledoc """
  Drift gate for every graph-compiled CLAUDE.md output-target.

  Each `output:claude-md` contract declares an `output_path` and renders its
  beliefs into that file; the file is read-only doctrine (hand-edits are
  overwritten on the next generation). This test is the library-level
  equivalent of `mix cb.generate.claude_md [--beliefs PATH] --check`: for
  every store that carries an `output:claude-md` contract, the on-disk file
  must equal what the contract compiles right now. It guards the framework
  CLAUDE.md (cb:c065) and okf/CLAUDE.md (okfx:c001) against the hand-edit/
  drift the output-target doctrine forbids.

  Selection mirrors `CB.OutputTarget.find_targets/1` but reads each store
  file explicitly rather than through the global `:beliefs_path` config, so
  the test stays side-effect-free and safe to run async.
  """
  use ExUnit.Case, async: true

  alias CB.{Belief, JSON, OutputTarget}

  @claude_md_tag "output:claude-md"

  # {store path relative to repo root, expected output_path}
  @targets [
    {"beliefs/beliefs.json", "CLAUDE.md"},
    {"okf/beliefs.json", "okf/CLAUDE.md"}
  ]

  for {store_rel, file_rel} <- @targets do
    @store_rel store_rel
    @file_rel file_rel

    test "#{@file_rel} is freshly compiled from #{@store_rel}" do
      all = load_store(Path.join(CB.repo_root(), @store_rel))

      targets = Enum.filter(all, &claude_md_target?/1)

      assert length(targets) == 1,
             "#{@store_rel} must carry exactly one active #{@claude_md_tag} contract, found #{length(targets)}"

      [target] = targets

      assert :ok == OutputTarget.validate_deps_match_sections(target),
             "#{target.id} deps do not equal the union of its render_sections' beliefs"

      assert {:ok, @file_rel, content} = OutputTarget.compile(target, all)

      abs = Path.join(CB.repo_root(), @file_rel)

      assert File.read!(abs) == content,
             "#{@file_rel} is stale - run `mix cb.generate.claude_md" <>
               unless(@store_rel == "beliefs/beliefs.json", do: " --beliefs #{@store_rel}", else: "") <>
               "` to regenerate"
    end
  end

  defp load_store(path) do
    {:ok, data} = JSON.read(path)
    Enum.map(data, &Belief.from_map/1)
  end

  defp claude_md_target?(%Belief{status: "active", kind: "output-target", tags: tags}),
    do: @claude_md_tag in (tags || [])

  defp claude_md_target?(_), do: false
end
