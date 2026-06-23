defmodule CB.OkfConformanceTest do
  @moduledoc """
  The OKF/Knowledge format conformance gate.

  The standard ships the format as behaviour under `okf/conformance/`: `fixtures/`
  (valid + invalid bundles) and `expected/<name>.json` (the normative
  `{ok, errors, warnings}` object, with findings sorted by `(code, path)`). This test
  is the single implementation's conformance gate — for every fixture, the Elixir
  validator's `to_contract/2` output must equal the recorded expectation.

  The corpus is an in-repo asset (folded in from the former `knowledge` standard repo),
  resolved from `okf/conformance` relative to the repo root. If it is somehow absent the
  gate skips so the suite still passes, but in this repo it is always present.
  """
  use ExUnit.Case, async: true

  alias CB.Knowledge.Validate

  @conformance Path.expand("okf/conformance", File.cwd!())

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
      flunk("OKF conformance corpus not found at #{@conformance}")
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
