defmodule CB.KnowledgeConformanceTest do
  @moduledoc """
  The Knowledge format conformance gate.

  The `knowledge` standard repo ships the format as behaviour: `conformance/fixtures/`
  (valid + invalid bundles) and `conformance/expected/<name>.json` (the normative
  `{ok, errors, warnings}` object, with findings sorted by `(code, path)`). This test
  is the single implementation's conformance gate — for every fixture, the Elixir
  validator's `to_contract/2` output must equal the recorded expectation.

  The corpus lives in the sibling standard repo; resolve it via `KNOWLEDGE_REPO`,
  defaulting to `../knowledge`. If it isn't checked out, the gate is skipped so this
  suite still passes in isolation (CI that needs the gate must provide the corpus).
  """
  use ExUnit.Case, async: true

  alias CB.Knowledge.Validate

  @conformance Path.join(
                 System.get_env("KNOWLEDGE_REPO", Path.expand("../knowledge", File.cwd!())),
                 "conformance"
               )

  fixtures =
    if File.dir?(Path.join(@conformance, "fixtures")) do
      [Path.join(@conformance, "fixtures/valid"), Path.join(@conformance, "fixtures/invalid")]
      |> Enum.flat_map(fn d -> if File.dir?(d), do: Path.wildcard(Path.join(d, "*")), else: [] end)
      |> Enum.filter(&File.dir?/1)
      |> Enum.map(&{Path.basename(&1), &1})
      |> Enum.sort()
    else
      []
    end

  if fixtures == [] do
    @tag :skip
    test "conformance corpus is available" do
      flunk("Knowledge corpus not found at #{@conformance}; set KNOWLEDGE_REPO")
    end
  end

  for {name, dir} <- fixtures do
    @dir dir
    @expected Path.join(@conformance, "expected/#{name}.json")

    test "conformance: #{name}" do
      {errors, warnings} = Validate.run(@dir)
      actual = Jason.decode!(Validate.to_contract(errors, warnings))

      assert File.exists?(@expected), "missing expected file: #{@expected}"
      expected = @expected |> File.read!() |> Jason.decode!()

      assert actual == expected
    end
  end
end
