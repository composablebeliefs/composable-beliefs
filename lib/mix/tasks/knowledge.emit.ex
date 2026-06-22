defmodule Mix.Tasks.Knowledge.Emit do
  @shortdoc "Project the CB belief graph to an OKF bundle"
  @moduledoc """
  #{@shortdoc}

      mix knowledge.emit <out-dir>

  Reads `beliefs/beliefs.json` and writes one `tier: cb` OKF document per belief
  (plus an index and manifest) at <out-dir>. The result is a valid Knowledge bundle -
  verify with `mix knowledge.validate <out-dir>`.
  """
  use Mix.Task

  alias CB.Belief.Store
  alias CB.Knowledge.Emit

  @impl Mix.Task
  def run(argv) do
    out = List.first(argv) || Mix.raise("usage: mix knowledge.emit <out-dir>")

    case Store.read() do
      {:ok, beliefs} ->
        {:ok, n} = Emit.bundle(beliefs, out)
        IO.puts("emitted #{n} beliefs to #{out} (validate with: mix knowledge.validate #{out})")

      {:error, reason} ->
        Mix.raise("could not read belief graph: #{inspect(reason)}")
    end
  end
end
