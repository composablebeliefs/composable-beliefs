defmodule CB.PredicateGate do
  @moduledoc """
  The shared resolve gate for routed predicate names.

  Contracts store predicate *names*; modules implement them (`cb:c047`).
  Whatever the predicate world - codepath (zero-arity, app-reading,
  dynamic) or collection (arity-2, graph-reading, static) - the gate
  between a name in the DAG and executable code is the same two checks,
  per the inspection-only discipline (`cb:c050`):

  1. the name matches the inspection-only invariant (`?` or `_check`
     suffix), and
  2. the name resolves to an exported function of the expected arity on
     the predicates module.

  Anything else is refused, so an executable string stored in a graph
  has nothing to grab onto. The two predicate worlds keep separate
  modules and separate runners; only this gate is shared.
  """

  @name_invariant ~r/(\?|_check)$/

  @doc """
  Resolve `name` to an exported `arity`-arity function atom on `module`.

  Returns `{:ok, fun_atom}`, `{:error, :bad_name}` (naming invariant
  violated), or `{:error, :unknown_predicate}` (no such exported
  function at that arity).
  """
  @spec resolve(module(), String.t(), non_neg_integer()) :: {:ok, atom()} | {:error, atom()}
  def resolve(module, name, arity) when is_binary(name) and is_integer(arity) do
    cond do
      not Regex.match?(@name_invariant, name) ->
        {:error, :bad_name}

      not exported?(module, name, arity) ->
        {:error, :unknown_predicate}

      true ->
        {:ok, String.to_existing_atom(name)}
    end
  end

  defp exported?(module, name, arity) do
    Code.ensure_loaded?(module) and
      Enum.any?(module.module_info(:exports), fn {f, a} ->
        a == arity and Atom.to_string(f) == name
      end)
  end
end
