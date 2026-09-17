defmodule ObservationBus.Splitter do
  @moduledoc """
  Event splitter — one event to many subscribers with optional transformations.

  Each subscriber can receive the event with subscriber-specific metadata.
  """

  alias ObservationBus.Event

  @doc """
  Splits an event into multiple events, one per subscriber pid.
  """
  @spec split(Event.t(), list(pid())) :: list(Event.t())
  def split(%Event{} = event, pids) do
    Enum.map(pids, fn pid ->
      %{event | metadata: Map.put(event.metadata, :target_pid, pid)}
    end)
  end

  @doc """
  Splits an event into multiple domain-specific events.
  Useful when a single payload affects multiple domains.
  """
  @spec split_by_domain(Event.t(), list(String.t())) :: list(Event.t())
  def split_by_domain(%Event{} = event, domains) do
    Enum.map(domains, fn domain ->
      %{event | id: Event.new([]).id, domain: domain, metadata: Map.put(event.metadata, :parent_id, event.id)}
    end)
  end
end
