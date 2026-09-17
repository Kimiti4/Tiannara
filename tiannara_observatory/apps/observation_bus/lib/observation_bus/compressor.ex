defmodule ObservationBus.Compressor do
  @moduledoc """
  Event compressor — reduces bandwidth by sending summaries + deltas.

  Instead of sending 1000 individual runtime updates, sends:
    * Runtime Summary (latest state snapshot)
    * Delta (changes since last summary)

  Uses zlib compression for payloads > 1KB.
  """

  alias ObservationBus.Event

  @doc """
  Compresses a list of events into a summary.
  """
  @spec compress(list(Event.t())) :: map()
  def compress(events) when is_list(events) do
    %{
      count: length(events),
      first: List.first(events),
      last: List.last(events),
      domains: events |> Enum.map(& &1.domain) |> Enum.uniq(),
      time_span: time_span(events),
      compressed_payload: maybe_compress(events),
      original_size: byte_size(:erlang.term_to_binary(events)),
      compressed_size: :erlang.term_to_binary(events) |> :zlib.zip() |> byte_size()
    }
  end

  @doc """
  Computes the delta between two events.
  """
  @spec delta(Event.t(), Event.t()) :: map()
  def delta(%Event{} = from, %Event{} = to) do
    %{
      from_id: from.id,
      to_id: to.id,
      from_timestamp: from.timestamp,
      to_timestamp: to.timestamp,
      from_sequence: from.global_sequence,
      to_sequence: to.global_sequence,
      payload_diff: payload_delta(from.payload, to.payload)
    }
  end

  defp time_span(events) do
    timestamps = Enum.map(events, & &1.timestamp)
    {min, max} = Enum.min_max(timestamps)
    DateTime.diff(max, min, :millisecond)
  end

  defp maybe_compress(events) do
    binary = :erlang.term_to_binary(events)
    if byte_size(binary) > 1024 do
      {:ok, :zlib.zip(binary)}
    else
      {:passthrough, binary}
    end
  end

  defp payload_delta(p1, p2) when is_map(p1) and is_map(p2) do
    added = Map.drop(p2, Map.keys(p1))
    removed = Map.drop(p1, Map.keys(p2))
    changed = Map.filter(p2, fn {k, v} -> Map.get(p1, k) != v end)

    %{
      added: added,
      removed: Map.keys(removed),
      changed: Map.keys(changed)
    }
  end

  defp payload_delta(_, p2), do: %{changed: p2}
end
