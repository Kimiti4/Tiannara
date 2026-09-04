defmodule Tiannara.Executive.Persistence do
  @moduledoc """
  Persistence operations for Executive Memory.

  Handles flushing, checkpointing, serialization, and
  checkpoint metadata management.
  """

  require Logger

  @doc "Flushes all cached entries from ETS to DETS."
  def flush(state) do
    Tiannara.Executive.ETSCache.sync_to_dets(state.name, state.dets_ref)
    state = %{state | last_flush: DateTime.utc_now()}
    Tiannara.Executive.Telemetry.emit_sync(state.name, :ok)
    state
  end

  @doc "Creates a checkpoint: flushes, syncs DETS, and records metadata."
  def checkpoint(state, reason \\ :periodic) do
    state = flush(state)
    :dets.sync(state.dets_ref)

    metadata = %{
      timestamp: DateTime.utc_now(),
      reason: reason,
      record_count: Tiannara.Executive.DetsStore.count(state.dets_ref),
      checksum: Tiannara.Executive.CorruptionDetector.checksum(:erlang.term_to_binary(state.metrics))
    }

    checkpoint_key = {:checkpoint, DateTime.utc_now() |> DateTime.to_unix()}
    :dets.insert(state.dets_ref, {checkpoint_key, metadata})

    state = %{state | last_checkpoint: DateTime.utc_now(), metrics: %{state.metrics | checkpoint_count: state.metrics.checkpoint_count + 1}}
    Tiannara.Executive.Telemetry.emit_checkpoint(state.name)
    state
  end

  @doc "Serializes a value to binary for storage."
  def serialize(value), do: :erlang.term_to_binary(value)

  @doc "Deserializes a binary back to a term."
  def deserialize(bin), do: :erlang.binary_to_term(bin)

  @doc "Loads checkpoint metadata from DETS."
  def load_checkpoint_metadata(ref) do
    matches = :dets.match_object(ref, {:checkpoint, :_})
    matches
    |> Enum.map(fn {_, meta} -> meta end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
  end
end
