defmodule CB.SchemaContractsTest do
  @moduledoc """
  Dogfooded verification suite for the self-referential schema contracts.

  Unlike `CB.Belief.ContractTest` (which exercises the interpreters against
  inline fixtures), this suite loads the *reshaped* schema contracts straight
  from the `cb:` belief graph (`beliefs/beliefs.json`), drives them through
  the contract interpreters, and asserts that `CB.Belief` and the live graph
  conform. This is the `verify_against_contract` pattern: the contract in the
  graph is the source of truth, and the code is checked against it.

  Covered:

  - cb:b053 (state-machine): the StateMachine-derived state set equals
    `CB.Belief.statuses()`, and each edge's `requires` matches the expected
    linkage slugs.
  - cb:b039 / cb:b043 / cb:b041 (enum-registry): `Enum.values_for/2` returns the
    expected vocabularies, and every active belief's kind / artifact-scheme /
    domain in the graph is a declared value (`valid_value?/3`). There is no
    `CB.Belief` code list for kind / domain / scheme - the contract is the SSOT.
    (cb:b043 superseded cb:b040 when the `code` scheme was added; the linkage
    is pinned here too.)
  """
  use ExUnit.Case, async: true

  alias CB.Belief
  alias CB.Belief.Store
  alias CB.Belief.Contract.{Enum, StateMachine}

  # Load the live graph once. Tests read the reshaped contracts from it.
  setup_all do
    {:ok, all} = Store.read()
    by_id = Map.new(all, &{&1.id, &1})
    {:ok, all: all, by_id: by_id}
  end

  defp fetch(by_id, id) do
    case Map.fetch(by_id, id) do
      {:ok, b} -> b
      :error -> flunk("contract #{id} not found in the belief graph")
    end
  end

  # Scheme of an artifact URI ("session:2026-..." -> "session").
  defp scheme(uri) when is_binary(uri) do
    case String.split(uri, ":", parts: 2) do
      [s, _] -> s
      _ -> ""
    end
  end

  describe "cb:b053 status lifecycle (state-machine)" do
    test "is an active state-machine contract", %{by_id: by_id} do
      b053 = fetch(by_id, "cb:b053")
      assert b053.kind == "state-machine"
      assert b053.status == "active"
      assert Belief.contract?(b053)
    end

    test "StateMachine-derived state set equals CB.Belief.statuses/0", %{by_id: by_id} do
      b053 = fetch(by_id, "cb:b053")

      derived =
        b053
        |> StateMachine.edges()
        |> Elixir.Enum.flat_map(fn e -> [e.from, e.to] end)
        |> Elixir.Enum.uniq()
        |> Elixir.Enum.sort()

      assert derived == Elixir.Enum.sort(Belief.statuses())
    end

    test "requires/2 returns the expected linkage slugs for each edge", %{by_id: by_id} do
      b053 = fetch(by_id, "cb:b053")

      assert StateMachine.requires(b053, {"active", "superseded"}) == {:ok, ["superseded_by"]}

      assert StateMachine.requires(b053, {"active", "retracted"}) ==
               {:ok, ["retracted_on", "retracted_reason"]}

      assert StateMachine.requires(b053, {"active", "retired"}) == {:ok, []}
    end

    test "all transitions originate from the active state", %{by_id: by_id} do
      b053 = fetch(by_id, "cb:b053")

      froms =
        b053 |> StateMachine.edges() |> Elixir.Enum.map(& &1.from) |> Elixir.Enum.uniq()

      assert froms == ["active"]
    end

    test "terminal states have no outgoing transitions", %{by_id: by_id} do
      b053 = fetch(by_id, "cb:b053")

      for terminal <- ~w(superseded retracted retired) do
        assert StateMachine.transitions_from(b053, terminal) == [],
               "expected #{terminal} to be terminal"
      end
    end

    test "every belief in the graph has a status the contract admits", %{
      all: all,
      by_id: by_id
    } do
      b053 = fetch(by_id, "cb:b053")

      admitted =
        b053
        |> StateMachine.edges()
        |> Elixir.Enum.flat_map(fn e -> [e.from, e.to] end)
        |> MapSet.new()

      bad =
        all
        |> Elixir.Enum.reject(&MapSet.member?(admitted, &1.status))
        |> Elixir.Enum.map(&{&1.id, &1.status})

      assert bad == []
    end
  end

  describe "cb:b039 kind enum-registry" do
    @expected_kinds [
      "policy",
      "rule",
      "action-item",
      "fact",
      "observation",
      "error",
      "error-pattern",
      "reasoning-error",
      "schema",
      "state-machine",
      "derivation-rule",
      "design-principle",
      "design-rationale",
      "design-observation",
      "design-property",
      "design-gap",
      "convention",
      "domain-rule",
      "domain-enum",
      "composable-belief",
      "agent-architecture",
      "analogical-claim",
      "architectural-synthesis",
      "audit-rule",
      "derivation-table",
      "edit-pair",
      "feedback-loop",
      "formatting-rule",
      "governance",
      "human-factor",
      "meta-observation",
      "outcome-claim",
      "output-target",
      "structural-parallel",
      "training-distribution",
      "training-incentive",
      "definition",
      "enum-registry"
    ]

    test "is an active enum-registry contract", %{by_id: by_id} do
      b039 = fetch(by_id, "cb:b039")
      assert b039.kind == "enum-registry"
      assert b039.status == "active"
    end

    test "values_for/2 returns the expected kind vocabulary", %{by_id: by_id} do
      b039 = fetch(by_id, "cb:b039")
      assert Enum.values_for(b039, "kind") == @expected_kinds
    end

    test "the self-referential enum-registry value is declared", %{by_id: by_id} do
      b039 = fetch(by_id, "cb:b039")
      assert Enum.valid_value?(b039, "kind", "enum-registry")
    end

    test "every active belief's kind is a declared value", %{all: all, by_id: by_id} do
      b039 = fetch(by_id, "cb:b039")

      bad =
        all
        |> Elixir.Enum.filter(&(&1.status == "active" and not is_nil(&1.kind)))
        |> Elixir.Enum.reject(&Enum.valid_value?(b039, "kind", &1.kind))
        |> Elixir.Enum.map(&{&1.id, &1.kind})

      assert bad == []
    end
  end

  describe "cb:b067 artifact-scheme enum-registry (supersedes cb:b066)" do
    @expected_schemes ["session", "user", "document", "source", "https", "plan", "code", "commit"]

    test "is an active enum-registry contract", %{by_id: by_id} do
      b067 = fetch(by_id, "cb:b067")
      assert b067.kind == "enum-registry"
      assert b067.status == "active"
    end

    test "the supersession chain b043 -> b066 -> b067 links forward", %{by_id: by_id} do
      b043 = fetch(by_id, "cb:b043")
      assert b043.status == "superseded"
      assert b043.superseded_by == "cb:b066"

      b066 = fetch(by_id, "cb:b066")
      assert b066.status == "superseded"
      assert b066.superseded_by == "cb:b067"
    end

    test "values_for/2 returns the expected scheme vocabulary including commit", %{by_id: by_id} do
      b067 = fetch(by_id, "cb:b067")
      assert Enum.values_for(b067, "artifact-scheme") == @expected_schemes
      assert Enum.valid_value?(b067, "artifact-scheme", "code")
      assert Enum.valid_value?(b067, "artifact-scheme", "commit")
      assert Enum.valid_value?(b067, "artifact-scheme", "session")
    end

    test "every active belief's artifact scheme is a declared value", %{all: all, by_id: by_id} do
      b067 = fetch(by_id, "cb:b067")

      bad =
        all
        |> Elixir.Enum.filter(&(&1.status == "active" and is_binary(&1.artifact)))
        |> Elixir.Enum.reject(&Enum.valid_value?(b067, "artifact-scheme", scheme(&1.artifact)))
        |> Elixir.Enum.map(&{&1.id, &1.artifact})

      assert bad == []
    end
  end

  describe "cb:b041 domain enum-registry" do
    @expected_domains ["system", "design", "agent", "ops", "dev"]

    test "is an active enum-registry contract", %{by_id: by_id} do
      b041 = fetch(by_id, "cb:b041")
      assert b041.kind == "enum-registry"
      assert b041.status == "active"
    end

    test "values_for/2 returns the expected domain vocabulary", %{by_id: by_id} do
      b041 = fetch(by_id, "cb:b041")
      assert Enum.values_for(b041, "domain") == @expected_domains
    end

    test "every active belief's domain is a declared value", %{all: all, by_id: by_id} do
      b041 = fetch(by_id, "cb:b041")

      bad =
        all
        |> Elixir.Enum.filter(&(&1.status == "active" and not is_nil(&1.domain)))
        |> Elixir.Enum.reject(&Enum.valid_value?(b041, "domain", &1.domain))
        |> Elixir.Enum.map(&{&1.id, &1.domain})

      assert bad == []
    end
  end
end
