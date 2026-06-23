defmodule Mix.Tasks.Okf.Emit do
  @shortdoc "Project the CB belief graph to an OKF bundle"
  @moduledoc """
  #{@shortdoc}

      mix okf.emit <out-dir>

  Reads `beliefs/beliefs.json` and writes one `tier: cb` OKF document per belief
  (plus an index and manifest) at <out-dir>. The result is a valid Knowledge bundle -
  verify with `mix okf.validate <out-dir>`.
  """
  use Mix.Task

  alias CB.Belief.Store
  alias CB.Okf.Emit

  @impl Mix.Task
  def run(argv) do
    out = List.first(argv) || Mix.raise("usage: mix okf.emit <out-dir>")

    case Store.read() do
      {:ok, beliefs} ->
        {:ok, n} = Emit.bundle(beliefs, out)
        IO.puts("emitted #{n} beliefs to #{out} (validate with: mix okf.validate #{out})")

      {:error, reason} ->
        Mix.raise("could not read belief graph: #{inspect(reason)}")
    end
  end
end
