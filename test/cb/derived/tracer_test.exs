defmodule CB.Derived.TracerTest do
  # The tracer's table is a named ETS table - one per node - so these
  # tests are deliberately not async.
  use ExUnit.Case, async: false

  alias CB.Derived.Tracer

  setup do
    Tracer.start()
    on_exit(fn -> Tracer.stop() end)
    {:ok, tracer: Tracer.install()}
  end

  defp env(fun \\ {:resolve, 2}) do
    %{__ENV__ | module: FakeCaller, function: fun, file: Path.join(File.cwd!(), "lib/fake.ex")}
  end

  test "install mints a unique module per call", %{tracer: tracer} do
    other = Tracer.install()
    assert tracer != other
    assert function_exported?(tracer, :trace, 2)
  end

  test "remote calls are recorded with caller attribution", %{tracer: tracer} do
    assert :ok = tracer.trace({:remote_function, [line: 12], File, :read, 1}, env())

    assert [edge] = Tracer.edges()
    assert edge.kind == "remote"

    assert edge.caller == %{
             module: "FakeCaller",
             function: "resolve",
             arity: 2,
             file: "lib/fake.ex",
             line: 12
           }

    assert edge.callee == %{module: "File", function: "read", arity: 1}
  end

  test "local calls attribute the callee to the caller's module", %{tracer: tracer} do
    assert :ok = tracer.trace({:local_function, [line: 3], :helper, 0}, env())

    assert [%{kind: "local", callee: %{module: "FakeCaller", function: "helper", arity: 0}}] =
             Tracer.edges()
  end

  test "module-body calls (no enclosing function) record a nil caller function", %{tracer: tracer} do
    assert :ok = tracer.trace({:remote_function, [line: 1], Enum, :map, 2}, env(nil))

    assert [%{caller: %{function: nil, arity: nil}}] = Tracer.edges()
  end

  test "events outside any module are dropped", %{tracer: tracer} do
    outside = %{env(nil) | module: nil}
    assert :ok = tracer.trace({:remote_function, [line: 1], Enum, :map, 2}, outside)

    assert Tracer.edges() == []
  end

  test "edges are deduplicated and unrelated events ignored", %{tracer: tracer} do
    event = {:remote_function, [line: 12], File, :read, 1}
    assert :ok = tracer.trace(event, env())
    assert :ok = tracer.trace(event, env())
    assert :ok = tracer.trace({:alias_reference, [line: 2], File}, env())

    assert length(Tracer.edges()) == 1
  end

  test "callbacks are no-ops when collection is stopped", %{tracer: tracer} do
    Tracer.stop()

    assert :ok = tracer.trace({:remote_function, [line: 12], File, :read, 1}, env())
    assert Tracer.edges() == []
    refute Tracer.collecting?()
  end
end
