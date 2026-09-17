defmodule Tiannara.Lineage.StoreTest do
  use ExUnit.Case, async: false

  alias Tiannara.Lineage.{Entry, Store}

  @moduletag :lineage_store

  setup do
    path = Path.join(System.tmp_dir!(), "lineage_#{System.unique_integer([:positive])}.log")
    on_exit(fn -> File.rm(path) end)
    {:ok, path: path}
  end

  test "persist and reconstruct a lineage chain", %{path: path} do
    e1 = Entry.new(%{stage: :observation, id: :obs_1}, :observation)
    e2 = Entry.new(%{stage: :hypothesis, id: :hyp_1}, :hypothesis, e1.entry_hash)
    e3 = Entry.new(%{stage: :candidate, id: :cand_1}, :candidate, e2.entry_hash)
    e4 = Entry.new(%{stage: :authorization, human: :human_1}, :authorization, e3.entry_hash)

    Enum.each([e1, e2, e3, e4], &Store.persist(&1, path))

    assert {:ok, entries} = Store.reconstruct(path)
    assert length(entries) == 4
    assert List.last(entries).entry_hash == Store.head_hash(entries)
  end

  test "tampering with an entry breaks the chain", %{path: path} do
    e1 = Entry.new(%{stage: :observation}, :observation)
    e2 = Entry.new(%{stage: :hypothesis}, :hypothesis, e1.entry_hash)

    Store.persist(e1, path)
    Store.persist(e2, path)

    # Tamper with the file (append a corrupted entry)
    tampered = %Entry{e2 | payload: %{stage: :malicious}}
    Store.persist(tampered, path)

    assert {:error, _} = Store.reconstruct(path)
  end

  test "a broken parent link is detected", %{path: path} do
    e1 = Entry.new(%{stage: :observation}, :observation)
    # e2 is properly hashed but points to a WRONG parent hash
    e2 = Entry.new(%{stage: :hypothesis}, :hypothesis, String.duplicate("f", 64))

    Store.persist(e1, path)
    Store.persist(e2, path)

    assert {:error, {:broken_chain, _, _}} = Store.reconstruct(path)
  end

  test "an empty lineage reconstructs to empty", %{path: path} do
    assert {:ok, []} = Store.reconstruct(path)
  end

  test "the full Ω lineage chain survives restart", %{path: path} do
    # Build the complete lineage: observation → hypothesis → experiment →
    # candidate → sandbox → certification → explanation → authorization
    chain_data = [
      {%{stage: :observation, id: :obs_1}, :observation},
      {%{stage: :hypothesis, id: :hyp_1}, :hypothesis},
      {%{stage: :experiment, id: :exp_1}, :experiment},
      {%{stage: :candidate, id: :cand_1}, :candidate},
      {%{stage: :sandbox, id: :sb_1}, :sandbox},
      {%{stage: :certification, id: :cert_1}, :certification},
      {%{stage: :explanation, id: :expl_1}, :explanation},
      {%{stage: :authorization, human: :human_1}, :authorization}
    ]

    {entries, _} =
      Enum.map_reduce(chain_data, Entry.genesis_hash(), fn {payload, type}, parent_hash ->
        entry = Entry.new(payload, type, parent_hash)
        Store.persist(entry, path)
        {entry, entry.entry_hash}
      end)

    # Simulate restart: reload from disk
    assert {:ok, reconstructed} = Store.reconstruct(path)
    assert length(reconstructed) == 8

    # Verify the chain is intact and the authorization is the head
    assert List.last(reconstructed).lineage_type == :authorization
    assert Store.head_hash(reconstructed) == List.last(entries).entry_hash
  end
end