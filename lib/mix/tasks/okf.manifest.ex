defmodule Mix.Tasks.Okf.Manifest do
  @shortdoc "Generate manifest.json for a Knowledge (OKF) bundle"
  @moduledoc """
  #{@shortdoc}

      mix okf.manifest <bundle-root>          # write <root>/manifest.json
      mix okf.manifest <bundle-root> --check  # exit 1 if the manifest is stale

  Part of CB's OKF integration layer. Byte-compatible with the Python reference
  tool in the `knowledge` standard repo.
  """
  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, rest, _} = OptionParser.parse(argv, switches: [check: :boolean])
    root = List.first(rest) || Mix.raise("usage: mix okf.manifest <bundle-root> [--check]")
    content = CB.Okf.Manifest.render(root)
    out = Path.join(root, "manifest.json")

    if opts[:check] do
      current = if File.exists?(out), do: File.read!(out), else: ""

      if current == content do
        IO.puts("ok: #{out} up to date")
      else
        IO.puts(:stderr, "stale: #{out} (run mix okf.manifest #{root})")
        System.halt(1)
      end
    else
      CB.JSON.write_atomic_raw(out, content)
      IO.puts("wrote #{out}")
    end
  end
end
