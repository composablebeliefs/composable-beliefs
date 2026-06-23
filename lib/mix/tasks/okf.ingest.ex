defmodule Mix.Tasks.Okf.Ingest do
  @shortdoc "Ingest an OKF bundle into CB primitive beliefs (lossy up-conversion)"
  @moduledoc """
  #{@shortdoc}

      mix okf.ingest <bundle-root> [--ns NS] [--out FILE]

  Reads a Knowledge/OKF bundle and emits CB belief JSON - one `primitive` per document,
  grounded in `artifact: document:<path>`. Prints to stdout, or writes to FILE.
  Typed composition is NOT reconstructed (use /assert for that); this only lands the
  documents as attributable primitives.
  """
  use Mix.Task

  alias CB.Belief
  alias CB.Okf.Ingest

  @impl Mix.Task
  def run(argv) do
    {opts, rest, _} = OptionParser.parse(argv, switches: [ns: :string, out: :string])
    root = List.first(rest) || Mix.raise("usage: mix okf.ingest <bundle-root> [--ns NS] [--out FILE]")
    ns = opts[:ns] || "okf"

    ordered =
      root
      |> Ingest.beliefs(ns)
      |> Enum.map(&(&1 |> Belief.from_map() |> Belief.to_map()))

    content = Jason.encode!(ordered, pretty: true) <> "\n"

    case opts[:out] do
      nil ->
        IO.puts(content)

      path ->
        File.write!(path, content)
        IO.puts("wrote #{length(ordered)} primitives to #{path}")
    end
  end
end
