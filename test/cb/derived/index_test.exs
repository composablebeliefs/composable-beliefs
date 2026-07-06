defmodule CB.Derived.IndexTest do
  use ExUnit.Case, async: true

  alias CB.Derived.Index

  @moduletag :tmp_dir

  setup %{tmp_dir: root} do
    File.mkdir_p!(Path.join(root, "lib"))

    File.write!(Path.join(root, "lib/sample.ex"), """
    defmodule Sample do
      def entry do
        Sample.Helper.step()
      end
    end

    defmodule Sample.Helper do
      def step do
        :ok
      end
    end
    """)

    {:ok, root: root}
  end

  defp edge(from_m, from_f, from_a, to_m, to_f, to_a) do
    %{
      kind: "remote",
      caller: %{module: from_m, function: from_f, arity: from_a, file: "lib/sample.ex", line: 3},
      callee: %{module: to_m, function: to_f, arity: to_a}
    }
  end

  test "build indexes symbols per file with content hashes", %{root: root} do
    {index, []} = Index.build(root)

    assert %{sha256: sha, error: nil, symbols: symbols} = index.files["lib/sample.ex"]
    assert String.length(sha) == 64
    assert Enum.count(symbols, &(&1.kind == "module")) == 2
    assert Enum.count(symbols, &(&1.kind == "def")) == 2
  end

  test "build records a parse error as a warning and indexes the file hash-only", %{root: root} do
    File.write!(Path.join(root, "lib/broken.ex"), "defmodule Broken do\n  def oops(\nend\n")

    {index, [warning]} = Index.build(root)

    assert warning =~ "lib/broken.ex"
    assert %{error: error, symbols: []} = index.files["lib/broken.ex"]
    assert error =~ "line"
  end

  test "build keeps only call edges whose caller file is indexed", %{root: root} do
    kept = edge("Sample", "entry", 0, "Sample.Helper", "step", 0)
    dropped = %{kept | caller: %{kept.caller | file: "lib/elsewhere.ex"}}

    {index, []} = Index.build(root, calls: [kept, dropped])

    assert index.calls == [kept]
  end

  test "save/load roundtrips the index", %{root: root} do
    {index, []} =
      Index.build(root, calls: [edge("Sample", "entry", 0, "Sample.Helper", "step", 0)])

    assert {:ok, _path} = Index.save(index, root)
    assert {:ok, loaded} = Index.load(root)
    assert loaded == index
  end

  test "load without an index reports enoent", %{root: root} do
    assert {:error, :enoent} = Index.load(root)
  end

  test "stale_files is empty on a fresh tree and reports changed/missing/unindexed", %{root: root} do
    {index, []} = Index.build(root)
    assert Index.stale_files(index, root) == []

    File.write!(Path.join(root, "lib/sample.ex"), "defmodule Sample do\nend\n")
    File.write!(Path.join(root, "lib/new.ex"), "defmodule New do\nend\n")

    assert Index.stale_files(index, root) == [
             {"lib/new.ex", :unindexed},
             {"lib/sample.ex", :changed}
           ]

    File.rm!(Path.join(root, "lib/sample.ex"))
    assert {"lib/sample.ex", :missing} in Index.stale_files(index, root)
  end

  test "enclosing_symbol picks the innermost span, module when between defs", %{root: root} do
    {index, []} = Index.build(root)

    assert %{kind: "def", name: "entry"} = Index.enclosing_symbol(index, "lib/sample.ex", 3)
    assert %{kind: "module", module: "Sample"} = Index.enclosing_symbol(index, "lib/sample.ex", 5)
    assert Index.enclosing_symbol(index, "lib/sample.ex", 999) == nil
    assert Index.enclosing_symbol(index, "lib/gone.ex", 1) == nil
  end

  test "defines? accepts atoms or strings", %{root: root} do
    {index, []} = Index.build(root)

    assert Index.defines?(index, "Sample", "entry", 0)
    assert Index.defines?(index, Sample, :entry, 0)
    refute Index.defines?(index, Sample, :entry, 1)
    refute Index.defines?(index, Sample, :vanished, 0)
  end

  test "call queries and chain checks work over supplied edges", %{root: root} do
    {index, []} =
      Index.build(root, calls: [edge("Sample", "entry", 0, "Sample.Helper", "step", 0)])

    assert [%{callee: %{module: "Sample.Helper"}}] = Index.calls_from(index, {Sample, :entry, 0})
    assert [%{caller: %{module: "Sample"}}] = Index.calls_to(index, {Sample.Helper, :step, 0})

    assert Index.call_edge?(index, {Sample, :entry, 0}, {Sample.Helper, :step, 0})
    refute Index.call_edge?(index, {Sample.Helper, :step, 0}, {Sample, :entry, 0})

    assert Index.call_chain?(index, [{Sample, :entry, 0}, {Sample.Helper, :step, 0}])

    assert Index.chain_gaps(index, [
             {Sample, :entry, 0},
             {Sample.Helper, :step, 0},
             {Sample, :entry, 0}
           ]) == [{{Sample.Helper, :step, 0}, {Sample, :entry, 0}}]
  end

  test "the persisted artifact is byte-stable across rebuilds", %{root: root} do
    {index, []} = Index.build(root)
    {:ok, path} = Index.save(index, root)
    first = File.read!(path)

    {rebuilt, []} = Index.build(root)
    {:ok, ^path} = Index.save(rebuilt, root)

    assert File.read!(path) == first
  end
end
