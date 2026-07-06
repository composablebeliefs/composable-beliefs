defmodule Mix.Tasks.Cb.Verify.RouteTags do
  @moduledoc """
  Verify route tags and the excerpt logs they materialize.

  Thin IO wrapper over `CB.RouteTags` - see that module for the check
  semantics. In brief: `<routes ref="...">` regions in finalized thread
  bodies must be well-formed and resolve every ref; each document sink a
  tagged thread feeds must carry a dated block in its route-tagged log
  section; and each block must match its re-derivation from the current
  tags, so the log's completeness is checked structurally rather than
  depending on the `/route` append having been remembered (the residual
  cb:b386 exposure the route-tagging spec names).

  Tag coverage stays editorial: the routing-ledger cross-check reports
  doc-routed ledger rows no tag covers at warn level, which does not fail
  the run unless `--strict`.

  ## Usage

      mix cb.verify.route_tags             - verify the host repository
      mix cb.verify.route_tags --root PATH - verify another checkout
      mix cb.verify.route_tags --strict    - warnings also fail

  ## Exit codes

  0 = clean (warnings allowed unless --strict), 1 = failures
  """
  @shortdoc "Verify route tags resolve and excerpt logs match their re-derivation"

  use Mix.Task

  alias CB.Belief.Store, as: BeliefStore
  alias CB.RouteTags

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [root: :string, strict: :boolean])
    root = opts[:root] || "."

    case BeliefStore.read() do
      {:ok, beliefs} ->
        belief_ids = MapSet.new(beliefs, & &1.id)
        results = RouteTags.run_checks(root, belief_ids)
        Enum.each(results, &print_result/1)

        failures = Enum.count(results, fn {_, status, _} -> status == :fail end)
        warnings = Enum.count(results, fn {_, status, _} -> status == :warn end)
        passes = Enum.count(results, fn {_, status, _} -> status == :ok end)

        IO.puts("")
        IO.puts("#{passes} passed, #{failures} failed, #{warnings} warning(s) (#{length(results)} checks)")

        if failures > 0 or (opts[:strict] && warnings > 0), do: System.halt(1)

      {:error, reason} ->
        IO.puts(:stderr, "cannot read belief graph: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp print_result({name, :ok, detail}), do: IO.puts("  PASS  #{name} - #{detail}")

  defp print_result({name, :fail, detail}) do
    IO.puts("  FAIL  #{name}")
    IO.puts("        #{detail}")
  end

  defp print_result({name, :warn, detail}) do
    IO.puts("  WARN  #{name}")
    IO.puts("        #{detail}")
  end
end
