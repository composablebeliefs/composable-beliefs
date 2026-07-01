defmodule CB.CommitsTest do
  use ExUnit.Case, async: true

  alias CB.{Belief, Commits}

  @sha_a String.duplicate("a", 40)
  @sha_b String.duplicate("b", 40)

  defp b(fields), do: struct(Belief, Map.merge(%{status: "active", deps: []}, Map.new(fields)))

  test "citations/1 collects commit: URIs from own artifact and evidence, and only those" do
    beliefs = [
      b(id: "x:a001", artifact: "commit:" <> @sha_a),
      b(
        id: "x:a002",
        artifact: "session:2026-07-01",
        evidence: [
          %{"date" => "2026-07-01", "detail" => "discharged", "artifact" => "commit:" <> @sha_b},
          %{"date" => "2026-07-01", "detail" => "unrelated", "artifact" => "document:x.md"}
        ]
      ),
      b(id: "x:a003", artifact: "document:notes.md")
    ]

    assert Commits.citations(beliefs) == [
             %{belief_id: "x:a001", uri: "commit:" <> @sha_a, site: :artifact},
             %{belief_id: "x:a002", uri: "commit:" <> @sha_b, site: :evidence}
           ]
  end

  test "unresolved/2 reports parse failures and resolver misses, passes the rest" do
    beliefs = [
      b(id: "x:a001", artifact: "commit:" <> @sha_a),
      b(id: "x:a002", artifact: "commit:deadbeef"),
      b(id: "x:a003", artifact: "commit:" <> @sha_b)
    ]

    resolver = fn
      %{sha: @sha_a} -> :ok
      _ -> {:error, :not_found}
    end

    assert [
             {%{belief_id: "x:a002"}, :invalid_sha},
             {%{belief_id: "x:a003"}, :not_found}
           ] = Commits.unresolved(beliefs, resolver)
  end

  test "trailer_refs/1 parses the git log format, tolerating trailer-less commits" do
    log = """
    #{@sha_a}|cb:a545
    #{@sha_b}|
    #{String.duplicate("c", 40)}|cb:a561,cb:a562
    """

    assert Commits.trailer_refs(log) == [
             {@sha_a, "cb:a545"},
             {String.duplicate("c", 40), "cb:a561"},
             {String.duplicate("c", 40), "cb:a562"}
           ]
  end

  test "dead_trailer_refs/2 flags only refs naming absent beliefs" do
    refs = [{@sha_a, "cb:a545"}, {@sha_b, "cb:a999"}]
    beliefs = [b(id: "cb:a545")]

    assert Commits.dead_trailer_refs(refs, beliefs) == [{@sha_b, "cb:a999"}]
  end
end
