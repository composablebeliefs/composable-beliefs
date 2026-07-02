Materialize a belief prescription into concrete work items in the task collection.

A prescription identifies work that needs doing. Materializing it means turning that into concrete action items, handing them to the configured sink, and linking the belief back to the items it produced so it is never materialized twice.

## Input

`$ARGUMENTS` is a belief ID, bare (`b820`) or namespaced (`cb:b820`) - a bare id resolves when exactly one belief matches, the same resolution `mix bs` and `mix cb.evidence` carry. It must resolve to a `prescription` node (you do not materialize a theory: inferences and aggregations describe, prescriptions prescribe).

## Steps

1. **Read the node** (`mix bs show $ARGUMENTS`). Verify it is:
   - Type: `prescription`
   - Status: `active`
   - Not already materialized (`materialized: null`)

2. **Read the belief's deps** to understand the full reasoning chain. Use `mix bs tree $ARGUMENTS` for context.

3. **Reason about what action items to create.** This is the LLM judgment step:
   - What concrete actions does the prescription demand?
   - On which objects, if the host sink couples items to objects?
   - Anything the sink needs (owner, due date, priority) carried as extra keys.

4. **Present the materialization plan** to the user for confirmation:
   ```
   ## Materialize: b820

   Claim: When a hold expires, return item to available and notify next member in queue

   Proposed action items:
     1. Implement hold-expiry state transition handler
     2. Wire notification to next-in-queue on expiry

   This will:
   - Append 2 items via the configured sink (default: todos JSON)
   - Set b820.materialized to record the link
   ```

5. **After user confirmation**, write a temp `.exs` file and run via `mix run`:

   ```elixir
   spec = %{
     "belief_id" => "b820",
     "action_items" => [
       %{"action" => "Implement hold-expiry state transition handler",
         "notes" => "hold expires after 7 days; item returns to available and next member in queue is notified"}
     ]
   }

   case CB.Belief.Materializer.materialize(spec) do
     {:ok, result} -> IO.puts("Materialized #{result.belief_id} (#{length(result.entries)} item(s)).")
     {:error, reason} -> IO.puts(:stderr, "Error: #{inspect(reason)}")
   end
   ```

   The module:
   - Validates the node is an unmaterialized `prescription`
   - Hands the action items to the sink (default `CB.Materializer.Sink.JSON`, which appends `{id, action, notes, source, created, status}` todo records to `CB.Config.todos_path/0`)
   - Records the returned refs on the belief's `materialized` field (date + entries)

6. **Verify** by reading back the task collection and the belief (`mix bs show $ARGUMENTS`).

## Spec Format

The spec map passed to `CB.Belief.Materializer.materialize/1`:

```elixir
%{
  "belief_id" => "b820",
  "action_items" => [
    %{
      "action" => "Implement hold-expiry state transition handler",
      "notes" => "context linking back to the prescription's reasoning"
    }
  ]
}
```

Each action item:
- `action` (required): the action text.
- `notes`: traceability back to the prescription's reasoning. The default JSON sink persists a non-empty `notes` on both the todo record and the `materialized` link-back ref.
- any other keys (e.g. `owner`, `due`, `object`) pass through to the sink untouched. The default JSON sink ignores them; a host that needs richer items supplies its own sink implementing the `CB.Materializer.Sink` behaviour.

`action_items` may also be supplied under the legacy key `todos`.

## Closing Items

The flip back is not this skill's job, but it has a sanctioned front door too: when an item is discharged, close it with `mix cb.todo.close <todo-id> --notes "..." --write` (dry run without `--write`). Never flip `status` with a hand-rolled script.

## Rules

- Never materialize without user confirmation
- Never materialize a belief that is already materialized
- Only materialize prescriptions (never attestations, aggregations, or inferences)
- The skill reasons about what action items to create; the module writes deterministically
- Notes on each item should reference the prescription's reasoning for traceability
