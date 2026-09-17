defmodule ObservationBus.Aggregator do
  @moduledoc """
  Event aggregator — merges multiple events into a single mission update.

  For example, 100 scientific discoveries in a window → single aggregated update.
  """

  alias ObservationBus.Event

  @doc """
  Aggregates events by domain, producing one summary event per domain.
  """
  @spec aggregate(list(Event.t())) :: list(Event.t())
  def aggregate(events) do
    events
    |> Enum.group_by(& &1.domain)
    |> Enum.map(fn {domain, domain_events} ->
      build_aggregate(domain, domain_events)
    end)
  end

  @doc """
  Merges two events by combining their payloads and evidence.
  """
  @spec merge(Event.t(), Event.t()) :: Event.t()
  def merge(%Event{} = a, %Event{} = b) do
    %Event{
      a
      | id: a.id,
        payload: Map.merge(as_map(a.payload), as_map(b.payload)),
        evidence: Enum.uniq(a.evidence ++ b.evidence),
        metadata: Map.merge(a.metadata, %{merged: true, merged_ids: [a.id, b.id]})
    }
  end

  defp build_aggregate(domain, events) do
    first = List.first(events)
    last = List.last(events)

    %Event{
      id: Event.new([]).id,
      domain: domain,
      source: "observation_bus.aggregator",
      priority: first.priority,
      payload: %{
        type: "aggregated",
        count: length(events),
        domain: domain,
        summary: aggregate_summary(events),
        time_span_ms: DateTime.diff(last.timestamp, first.timestamp, :millisecond),
      },
      evidence: Enum.flat_map(events, & &1.evidence),
      metadata: %{
        aggregated: true,
        source_ids: Enum.map(events, & &1.id),
        time_range: %{from: first.timestamp, to: last.timestamp}
      }
    }
  end

  defp aggregate_summary(events) do
    sources = events |> Enum.map(& &1.source) |> Enum.uniq()
    priorities = events |> Enum.map(& &1.priority) |> Enum.uniq() |> Enum.sort(:desc)
    %{
      source_count: length(sources),
      priority_range: {List.last(priorities), List.first(priorities)},
    }
  end

  defp as_map(p) when is_map(p), do: p
  defp as_map(_), do: %{}
end
