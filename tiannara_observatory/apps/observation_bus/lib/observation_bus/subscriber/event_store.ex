defmodule ObservationBus.Subscriber.EventStore do
  @moduledoc """
  COB subscriber that writes constitutional events to the EventStore.
  """

  use GenServer

  @topic_pattern "constitution.*:*.*:*"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    ObservationBus.SubscriptionRegistry.subscribe(self(), @topic_pattern)
    {:ok, %{written: 0}}
  end

  @impl true
  def handle_info({:constitutional_event, %ObservationBus.Event{} = event, _topic}, state) do
    write_to_event_store(event)
    {:noreply, %{state | written: state.written + 1}}
  end

  defp write_to_store(%ObservationBus.Event{} = cob_event) do
    attrs = %{
      id: cob_event.id,
      domain: cob_event.domain,
      source: cob_event.source,
      timestamp: DateTime.to_iso8601(cob_event.timestamp),
      payload: cob_event.payload,
      metadata: cob_event.metadata,
    }

    EventStore.Writer.write(attrs)
  end

  defp write_to_event_store(%ObservationBus.Event{domain: "audit"} = _event), do: :ok
  defp write_to_event_store(%ObservationBus.Event{} = event), do: write_to_store(event)
end
