defmodule CB.Derived.SymbolsTest do
  use ExUnit.Case, async: true

  alias CB.Derived.Symbols

  test "extracts a module with def spans from do..end metadata" do
    {:ok, symbols} =
      Symbols.extract("""
      defmodule Sample do
        def read do
          :data
        end

        defp helper(x) do
          x
        end
      end
      """)

    assert [
             %{kind: "module", module: "Sample", name: nil, arity: nil, line: 1, end_line: 9},
             %{kind: "def", module: "Sample", name: "read", arity: 0, line: 2, end_line: 4},
             %{kind: "defp", module: "Sample", name: "helper", arity: 1, line: 6, end_line: 8}
           ] = symbols
  end

  test "keyword-do defs span their own expression" do
    {:ok, symbols} =
      Symbols.extract("""
      defmodule Sample do
        def tiny, do: :ok
      end
      """)

    assert [%{kind: "module"}, %{kind: "def", name: "tiny", arity: 0, line: 2, end_line: 2}] =
             symbols
  end

  test "multiple clauses stay as separate rows and guards unwrap" do
    {:ok, symbols} =
      Symbols.extract("""
      defmodule Sample do
        def pick(x) when is_atom(x), do: x
        def pick(_x), do: :other
      end
      """)

    assert [_module, first, second] = symbols
    assert %{name: "pick", arity: 1, line: 2} = first
    assert %{name: "pick", arity: 1, line: 3} = second
  end

  test "nested modules concatenate like the compiler" do
    {:ok, symbols} =
      Symbols.extract("""
      defmodule Outer do
        defmodule Inner.Leaf do
          def f, do: :ok
        end
      end
      """)

    assert Enum.map(symbols, &{&1.kind, &1.module}) == [
             {"module", "Outer"},
             {"module", "Outer.Inner.Leaf"},
             {"def", "Outer.Inner.Leaf"}
           ]
  end

  test "defmacro rows carry their kind" do
    {:ok, symbols} =
      Symbols.extract("""
      defmodule Sample do
        defmacro __using__(_opts) do
          quote do: :ok
        end
      end
      """)

    assert [_module, %{kind: "defmacro", name: "__using__", arity: 1}] = symbols
  end

  test "dynamic definition heads are skipped, not crashed on" do
    {:ok, symbols} =
      Symbols.extract("""
      defmodule Sample do
        for name <- [:a, :b] do
          def unquote(name)(), do: unquote(name)
        end

        def static, do: :ok
      end
      """)

    assert [%{kind: "module"}, %{kind: "def", name: "static"}] = symbols
  end

  test "unparseable source returns an error with the line" do
    assert {:error, reason} = Symbols.extract("defmodule Broken do\n  def oops(\nend\n")
    assert reason =~ "line"
  end
end
