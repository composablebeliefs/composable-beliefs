defmodule Mix.Tasks.Okf.Validate do
  @shortdoc "Validate a Knowledge (OKF) bundle (--json for machine output)"
  @moduledoc """
  #{@shortdoc}

      mix okf.validate <bundle-root>          # human output
      mix okf.validate <bundle-root> --json   # stable conformance object

  Part of CB's OKF integration layer. Conformant with the `knowledge` standard's
  conformance suite: run it there with
  `VALIDATE_CMD="<cb>/bin/knowledge-validate" ./conformance/run.sh`.
  Exits 1 when any hard check fails.
  """
  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, rest, _} = OptionParser.parse(argv, switches: [json: :boolean])
    root = List.first(rest) || Mix.raise("usage: mix okf.validate <bundle-root> [--json]")
    {errors, warnings} = CB.Okf.Validate.run(root)

    if opts[:json] do
      IO.puts(CB.Okf.Validate.to_contract(errors, warnings))
    else
      Enum.each(warnings, fn w -> IO.puts("WARN: #{w.path}: #{w.msg}") end)
      Enum.each(errors, fn e -> IO.puts("FAIL: #{e.path}: #{e.msg}") end)
      IO.puts("\n#{length(errors)} error(s), #{length(warnings)} warning(s) in #{root}")
    end

    if errors != [], do: System.halt(1)
  end
end
