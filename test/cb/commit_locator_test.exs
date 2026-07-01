defmodule CB.CommitLocatorTest do
  use ExUnit.Case, async: true

  alias CB.CommitLocator

  @sha "83b5692c7144d7e739114fd3473b81b5692c6174"

  test "parses a full 40-hex sha" do
    assert {:ok, %{sha: @sha}} = CommitLocator.parse("commit:" <> @sha)
    assert CommitLocator.valid?("commit:" <> @sha)
  end

  test "rejects abbreviated shas - short hashes go ambiguous as the repo grows" do
    assert {:error, :invalid_sha} = CommitLocator.parse("commit:83b5692")
    refute CommitLocator.valid?("commit:83b5692")
  end

  test "rejects uppercase, non-hex, empty, and overlong shas" do
    assert {:error, :invalid_sha} = CommitLocator.parse("commit:" <> String.upcase(@sha))
    assert {:error, :invalid_sha} = CommitLocator.parse("commit:" <> String.replace(@sha, "8", "g"))
    assert {:error, :invalid_sha} = CommitLocator.parse("commit:")
    assert {:error, :invalid_sha} = CommitLocator.parse("commit:" <> @sha <> "0")
  end

  test "rejects other schemes" do
    assert {:error, :not_commit_scheme} = CommitLocator.parse("code:lib/a.ex#def read")
    refute CommitLocator.valid?(nil)
  end

  test "resolve/2 finds a real commit in this repository and rejects a fabricated one" do
    {head, 0} = System.cmd("git", ["rev-parse", "HEAD"])
    head = String.trim(head)

    assert :ok = CommitLocator.resolve(%{sha: head})
    assert {:error, :not_found} = CommitLocator.resolve(%{sha: String.duplicate("0", 40)})
  end
end
