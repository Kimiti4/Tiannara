defmodule Tiannara.Lineage.Store do
  @moduledoc """
  A durable, cryptographically-chained lineage store. Persists lineage entries
  to disk so the entire chain — from observation through hypothesis, experiment,
  candidate, sandbox, certification, explanation, and human authorization —
  SURVIVES RESTART and is auditable/reconstructable.

  The chain is append-only and hash-chained. Any tampering breaks the chain and
  is detected by `verify_chain/1`. On restart, `reconstruct/1` rebuilds the
  chain from durable storage and verifies integrity.

  Constitutional basis: "Every architectural decision should remain traceable",
  "Maintain audit trails", "Support reproducibility", "Preserve previous stable
  states."
  """

  alias Tiannara.Lineage.Entry

  @doc """
  Persist a lineage entry to durable storage. `path` is the lineage file.
  Entries are appended as length-prefixed serialized terms, one per record.
  """
  def persist(%Entry{} = entry, path) do
    File.mkdir_p!(Path.dirname(path))
    serialized = :erlang.term_to_binary(entry)
    File.write(path, [<<byte_size(serialized)::32>>, serialized], [:append])
  end

  @doc "Load all lineage entries from durable storage, in order."
  def load_all(path) do
    case File.read(path) do
      {:ok, content} ->
        {:ok, decode_records(content)}

      {:error, :enoent} ->
        {:ok, []}

      {:error, _} = e ->
        e
    end
  end

  defp decode_records(<<>>), do: []

  defp decode_records(<<size::32, term::binary-size(size), rest::binary>>) do
    [:erlang.binary_to_term(term) | decode_records(rest)]
  end

  defp decode_records(_truncated), do: []

  @doc """
  Verify the entire chain's integrity. Returns :ok if every entry's hash is
  valid AND each entry's parent_hash matches the previous entry's entry_hash.
  Otherwise returns {:error, reason}.
  """
  def verify_chain(entries) when is_list(entries) do
    do_verify(entries, Entry.genesis_hash())
  end

  defp do_verify([], _expected_parent), do: :ok

  defp do_verify([entry | rest], expected_parent) do
    cond do
      not Entry.verify(entry) ->
        {:error, {:hash_mismatch, entry.entry_id}}

      entry.parent_hash != expected_parent ->
        {:error, {:broken_chain, entry.entry_id, expected: expected_parent, got: entry.parent_hash}}

      true ->
        do_verify(rest, entry.entry_hash)
    end
  end

  @doc """
  Reconstruct the lineage chain from durable storage and verify integrity.
  Returns {:ok, entries} if valid, {:error, reason} if the chain is broken.
  """
  def reconstruct(path) do
    with {:ok, entries} <- load_all(path),
         :ok <- verify_chain(entries) do
      {:ok, entries}
    end
  end

  @doc "Return the head (latest) entry hash, or the genesis hash if empty."
  def head_hash(entries) do
    case List.last(entries) do
      nil -> Entry.genesis_hash()
      %Entry{entry_hash: h} -> h
    end
  end
end