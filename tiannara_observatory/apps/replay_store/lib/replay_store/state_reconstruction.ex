defmodule ReplayStore.StateReconstruction do
  @domains [
    :runtime,
    :scientific,
    :engineering,
    :knowledge,
    :planetary,
    :civilization,
    :evolution,
    :governance,
    :certification
  ]

  def reconstruct_domain(domain, timestamp) do
    events =
      EventStore.Reader.list_by_time_range(
        ~U[2020-01-01 00:00:00Z],
        timestamp
      )
      |> Enum.filter(fn e -> e.domain == domain end)

    state =
      Enum.reduce(events, %{}, fn e, acc ->
        Map.put(acc, e.id, e.payload)
      end)

    %{
      domain: domain,
      timestamp: timestamp,
      events_processed: length(events),
      state_entries: map_size(state),
      state: state
    }
  end

  def reconstruct_all(timestamp) do
    Enum.map(@domains, fn domain ->
      {domain, reconstruct_domain(Atom.to_string(domain), timestamp)}
    end)
    |> Map.new()
  end

  def reconstruct_at_generation(domain, generation) do
    events = EventStore.Reader.list_by_domain(domain)

    filtered =
      Enum.filter(events, fn e ->
        gen = e.payload["generation"] || e.payload[:generation]
        not is_nil(gen) and gen <= generation
      end)

    state =
      Enum.reduce(filtered, %{}, fn e, acc ->
        Map.put(acc, Map.get(e.payload, :key, e.id), e.payload)
      end)

    %{domain: domain, generation: generation, events: length(filtered), state: state}
  end

  def domains, do: @domains
end
