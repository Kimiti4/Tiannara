defmodule ReplayStore.ArchaeologyEngine do
  @doc """
  Produces scientific narratives from replay data.
  Answers: "why did X happen?" with causal chains and evidence.
  """

  def explain_event(event_id) do
    event = EventStore.Reader.get(event_id)

    case event do
      nil -> {:error, :event_not_found}
      event -> build_narrative(event, :event)
    end
  end

  def explain_transition(from_timestamp, to_timestamp, domain \\ nil) do
    events = EventStore.Reader.list_by_time_range(from_timestamp, to_timestamp)
    filtered = if domain, do: Enum.filter(events, fn e -> e.domain == domain end), else: events
    build_transition_narrative(filtered, from_timestamp, to_timestamp)
  end

  def explain_discovery(discovery_id) do
    events = EventStore.Reader.list_by_domain("scientific/observation")

    discovery_events =
      Enum.filter(events, fn e ->
        e.payload[:discovery_id] == discovery_id || e.payload["discovery_id"] == discovery_id
      end)

    case discovery_events do
      [] -> {:error, :discovery_not_found}
      events -> build_discovery_narrative(events)
    end
  end

  def timeline_summary(domain, since \\ nil, until \\ nil) do
    events =
      EventStore.Reader.list_by_domain(domain)
      |> maybe_filter_since(since)
      |> maybe_filter_until(until)

    grouped = Enum.group_by(events, fn e -> e.payload[:type] || e.payload["type"] || :unknown end)

    summary =
      Enum.map(grouped, fn {type, evts} ->
        sorted = Enum.sort_by(evts, & &1.timestamp)
        first = if sorted != [], do: Map.get(hd(sorted), :timestamp), else: nil
        last = if sorted != [], do: Map.get(List.last(sorted), :timestamp), else: nil
        %{type: type, count: length(evts), first: first, last: last}
      end)

    %{
      domain: domain,
      total_events: length(events),
      event_types: map_size(grouped),
      summary: summary
    }
  end

  defp build_narrative(event, _kind) do
    ancestors = ReplayStore.CausalLineage.ancestors(event.id)
    descendants = ReplayStore.CausalLineage.descendants(event.id)

    %{
      subject: %{
        id: event.id,
        domain: event.domain,
        type: event.payload[:type] || event.payload["type"],
        timestamp: event.timestamp
      },
      causal_context: %{
        ancestors: length(ancestors),
        descendants: length(descendants),
        ancestor_ids: Enum.take(ancestors, 20),
        descendant_ids: Enum.take(descendants, 20)
      },
      narrative:
        "Event #{event.id} in #{event.domain} at #{event.timestamp} has #{length(ancestors)} causal ancestors and #{length(descendants)} descendants.",
      evidence_count: length(ancestors) + length(descendants)
    }
  end

  defp build_transition_narrative(events, from, to) do
    grouped = Enum.group_by(events, fn e -> e.domain end)

    changes =
      Enum.map(grouped, fn {domain, evts} ->
        types =
          Enum.map(evts, fn e -> e.payload[:type] || e.payload["type"] || :unknown end)
          |> Enum.uniq()

        %{domain: domain, event_count: length(evts), change_types: types}
      end)

    %{
      period: %{from: from, to: to, duration_seconds: DateTime.diff(to, from)},
      domains_changed: length(changes),
      changes: changes
    }
  end

  defp build_discovery_narrative(events) do
    sorted = Enum.sort_by(events, & &1.timestamp)
    first = List.first(sorted)
    last = List.last(sorted)

    hypothesis =
      Enum.find(sorted, fn e ->
        e.payload[:type] == "hypothesis" || e.payload["type"] == "hypothesis"
      end)

    experiments =
      Enum.filter(sorted, fn e ->
        e.payload[:type] == "experiment" || e.payload["type"] == "experiment"
      end)

    %{
      discovery_id: first.payload[:discovery_id] || first.payload["discovery_id"],
      timeline: %{
        started: first.timestamp,
        concluded: last.timestamp,
        duration_seconds: DateTime.diff(last.timestamp, first.timestamp)
      },
      evidence: %{
        events: length(sorted),
        observations: length(sorted) - length(experiments),
        experiments: length(experiments)
      },
      hypothesis_generated: hypothesis != nil,
      narrative:
        "Discovery spanning #{length(sorted)} events from #{first.timestamp} to #{last.timestamp} with #{length(experiments)} experiments."
    }
  end

  defp maybe_filter_since(events, nil), do: events

  defp maybe_filter_since(events, since) do
    Enum.filter(events, fn e -> DateTime.compare(e.timestamp, since) != :lt end)
  end

  defp maybe_filter_until(events, nil), do: events

  defp maybe_filter_until(events, until) do
    Enum.filter(events, fn e -> DateTime.compare(e.timestamp, until) != :gt end)
  end
end
