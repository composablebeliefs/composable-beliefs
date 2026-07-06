defmodule CB.RouteTagsTest do
  use ExUnit.Case, async: true

  alias CB.RouteTags

  # ---------------------------------------------------------------------
  # parse_regions/1
  # ---------------------------------------------------------------------

  describe "parse_regions/1" do
    test "extracts a balanced region with its ref set and content" do
      body = """
      ## Assistant

      <routes ref="some-doc cb:b001">

      First paragraph.

      Second paragraph.

      </routes>
      """

      {[region], []} = RouteTags.parse_regions(body)
      assert region.refs == ["some-doc", "cb:b001"]
      assert region.line == 3
      assert Enum.join(region.content, "\n") =~ "First paragraph."
    end

    test "ignores tag syntax mentioned inside fenced code" do
      body = """
      The syntax looks like:

      ```
      <routes ref="example">
      ... a paragraph ...
      </routes>
      ```
      """

      assert {[], []} = RouteTags.parse_regions(body)
    end

    test "ignores tag syntax not anchored at line start" do
      body = """
      Scan threads for `<routes ref="thisdoc">` to find regions.
      """

      assert {[], []} = RouteTags.parse_regions(body)
    end

    test "reports an unclosed region" do
      body = """
      <routes ref="some-doc">
      dangling
      """

      {[], [problem]} = RouteTags.parse_regions(body)
      assert problem =~ "unclosed"
      assert problem =~ "line 1"
    end

    test "reports an unmatched close" do
      {[], [problem]} = RouteTags.parse_regions("</routes>\n")
      assert problem =~ "unmatched </routes> at line 1"
    end

    test "reports nesting" do
      body = """
      <routes ref="a">
      <routes ref="b">
      </routes>
      """

      {[region], [problem]} = RouteTags.parse_regions(body)
      assert problem =~ "nested"
      # the outer open survives; the close pairs with it
      assert region.refs == ["a"]
    end

    test "reports a region crossing a turn boundary" do
      body = """
      <routes ref="some-doc">
      tail of one turn

      ## User

      next turn
      """

      {[], [problem]} = RouteTags.parse_regions(body)
      assert problem =~ "crosses a turn boundary at line 4"
    end

    test "reports an empty ref set" do
      body = """
      <routes ref="">
      </routes>
      """

      {_, [problem]} = RouteTags.parse_regions(body)
      assert problem =~ "empty ref set"
    end
  end

  # ---------------------------------------------------------------------
  # classification
  # ---------------------------------------------------------------------

  describe "classify_ref/1" do
    test "cb: ids are beliefs, slash-bearing refs are paths, bare slugs are documents" do
      assert RouteTags.classify_ref("cb:b573") == {:belief, "cb:b573"}
      assert RouteTags.classify_ref("docs/operations.md") == {:path, "docs/operations.md"}
      assert RouteTags.classify_ref("end-skill-redesign") == {:doc, "end-skill-redesign"}
    end

    test "doc_refs keeps only document sinks, in ref order" do
      refs = ["end-skill-redesign", "cb:b583", "transcript-format", "skills/end/SKILL.md"]
      assert RouteTags.doc_refs(refs) == ["end-skill-redesign", "transcript-format"]
    end
  end

  # ---------------------------------------------------------------------
  # derivation
  # ---------------------------------------------------------------------

  describe "demote_headers/1" do
    test "demotes ATX headers to bold" do
      assert RouteTags.demote_headers(["## The close, verified", "prose"]) ==
               ["**The close, verified**", "prose"]
    end

    test "leaves headers inside fenced code untouched" do
      lines = ["```", "## not a header", "```", "## a header"]
      assert RouteTags.demote_headers(lines) == ["```", "## not a header", "```", "**a header**"]
    end
  end

  describe "derive_block/3" do
    setup do
      thread = %{slug: "2026-07-03-example-thread", date: "2026-07-03"}

      regions = [
        %{refs: ["some-doc"], line: 1, content: ["Only this matter."]},
        %{
          refs: ["some-doc", "cb:b001", "other-doc"],
          line: 9,
          content: ["", "## Inner header", "", "Shared paragraph.", ""]
        }
      ]

      %{thread: thread, regions: regions}
    end

    test "renders header, count line, co-feeds, and demoted content", ctx do
      block = RouteTags.derive_block("some-doc", ctx.thread, ctx.regions)

      assert block =~ "### 2026-07-03-example-thread (2026-07-03)"
      assert block =~ "2 tagged region(s), lifted whole."
      assert block =~ "**[`some-doc`]**\n\nOnly this matter."
      assert block =~ "**[`some-doc`]**  (co-feeds: `cb:b001 other-doc`)"
      assert block =~ "**Inner header**\n\nShared paragraph."
      refute block =~ "## Inner header"
    end

    test "each sink sees the region under its own key with the rest as co-feeds", ctx do
      block = RouteTags.derive_block("other-doc", ctx.thread, [Enum.at(ctx.regions, 1)])
      assert block =~ "**[`other-doc`]**  (co-feeds: `some-doc cb:b001`)"
    end
  end

  # ---------------------------------------------------------------------
  # log-section parsing
  # ---------------------------------------------------------------------

  describe "parse_log_section/1" do
    test "returns nil when the document carries no log section" do
      assert RouteTags.parse_log_section("## Thread excerpts (hand-picked)\n\nquote\n") == nil
    end

    test "splits per-thread blocks and stops at the next section" do
      doc = """
      ## Thread excerpts - route-tagged log (route-tagging spec)

      Preamble kept out of any block.

      ### 2026-07-01-first-thread (2026-07-01)

      1 tagged region(s), lifted whole.

      **[`some-doc`]**

      A block.

      ### 2026-07-02-second-thread (2026-07-02)

      more

      ## Related

      - not part of the log
      """

      blocks = RouteTags.parse_log_section(doc)
      assert Map.keys(blocks) |> Enum.sort() == ["2026-07-01-first-thread", "2026-07-02-second-thread"]
      assert Enum.join(blocks["2026-07-01-first-thread"], "\n") =~ "A block."
      refute Enum.join(blocks["2026-07-02-second-thread"], "\n") =~ "Related"
    end
  end

  # ---------------------------------------------------------------------
  # run_checks/2 on a fixture tree
  # ---------------------------------------------------------------------

  describe "run_checks/2" do
    @tag :tmp_dir
    setup %{tmp_dir: root} do
      File.mkdir_p!(Path.join(root, "beliefs/nursery/threads"))
      File.mkdir_p!(Path.join(root, "beliefs/archive"))
      File.mkdir_p!(Path.join(root, "docs"))
      File.write!(Path.join(root, "docs/code.md"), "code artifact\n")
      %{root: root}
    end

    defp write_thread(root, slug, body) do
      File.write!(Path.join(root, "beliefs/nursery/threads/#{slug}.md"), body)
    end

    defp write_doc(root, slug, body) do
      File.write!(Path.join(root, "beliefs/nursery/#{slug}.md"), body)
    end

    defp statuses(results), do: Map.new(results, fn {name, status, _} -> {name, status} end)

    defp green_fixture(root) do
      write_thread(root, "2026-07-03-example-thread", """
      ## Routing

      | Topic | State | Routed to | Dangling |
      |---|---|---|---|
      | The matter | closed | [some-doc](../some-doc.md) | - |

      ## Assistant

      <routes ref="some-doc cb:b001 docs/code.md">

      The paragraph.

      </routes>
      """)

      write_doc(root, "some-doc", """
      # Some doc

      ## Thread excerpts - route-tagged log (route-tagging spec)

      ### 2026-07-03-example-thread (2026-07-03)

      1 tagged region(s), lifted whole. Refs shown are the full ref-set of each region (this matter plus any it co-feeds).

      **[`some-doc`]**  (co-feeds: `cb:b001 docs/code.md`)

      The paragraph.
      """)
    end

    @tag :tmp_dir
    test "a consistent corpus passes every check", %{root: root} do
      green_fixture(root)
      results = RouteTags.run_checks(root, MapSet.new(["cb:b001"]))
      assert Enum.all?(results, fn {_, status, _} -> status == :ok end), inspect(results)
    end

    @tag :tmp_dir
    test "an unresolved ref fails resolution", %{root: root} do
      green_fixture(root)
      results = RouteTags.run_checks(root, MapSet.new())
      assert statuses(results)["ref resolution"] == :fail
    end

    @tag :tmp_dir
    test "a tagged sink without a dated block fails sink logs", %{root: root} do
      green_fixture(root)
      write_doc(root, "some-doc", "# Some doc\n\nno log section\n")
      results = RouteTags.run_checks(root, MapSet.new(["cb:b001"]))
      assert statuses(results)["sink logs"] == :fail
    end

    @tag :tmp_dir
    test "a block that diverges from its re-derivation fails fidelity", %{root: root} do
      green_fixture(root)
      path = Path.join(root, "beliefs/nursery/some-doc.md")
      File.write!(path, String.replace(File.read!(path), "The paragraph.", "A trimmed paraphrase."))
      results = RouteTags.run_checks(root, MapSet.new(["cb:b001"]))
      assert statuses(results)["log fidelity"] == :fail
    end

    @tag :tmp_dir
    test "a block for a thread that no longer tags the sink is an orphan", %{root: root} do
      green_fixture(root)

      write_doc(root, "other-doc", """
      ## Thread excerpts - route-tagged log

      ### 2026-07-03-example-thread (2026-07-03)

      stale block
      """)

      results = RouteTags.run_checks(root, MapSet.new(["cb:b001"]))
      {_, :fail, detail} = Enum.find(results, &(elem(&1, 0) == "log fidelity"))
      assert detail =~ "other-doc"
      assert detail =~ "no longer tags this sink"
    end

    @tag :tmp_dir
    test "a doc-routed ledger row with no covering tag warns, not fails", %{root: root} do
      green_fixture(root)
      write_doc(root, "uncovered-doc", "# Uncovered\n")

      write_thread(root, "2026-07-04-second-thread", """
      ## Routing

      | Topic | State | Routed to | Dangling |
      |---|---|---|---|
      | Another matter | open | [uncovered-doc](../uncovered-doc.md) | - |

      ## Assistant

      Untagged body.
      """)

      results = RouteTags.run_checks(root, MapSet.new(["cb:b001"]))
      {_, :warn, detail} = Enum.find(results, &(elem(&1, 0) == "ledger cross-check"))
      assert detail =~ "2026-07-04-second-thread"
      assert Enum.count(results, fn {_, s, _} -> s == :fail end) == 0
    end
  end

  # ---------------------------------------------------------------------
  # the live corpus
  # ---------------------------------------------------------------------

  describe "the host repository" do
    test "carries no route-tag failures" do
      {:ok, beliefs} = CB.Belief.Store.read()
      results = RouteTags.run_checks(".", MapSet.new(beliefs, & &1.id))

      failures = Enum.filter(results, fn {_, status, _} -> status == :fail end)
      assert failures == [], inspect(failures, pretty: true)
    end
  end
end
