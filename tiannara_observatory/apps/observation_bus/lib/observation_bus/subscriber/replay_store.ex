defmodule ObservationBus.Subscriber.ReplayStore do
  @moduledoc """
  COB subscriber that notifies the Replay Store of new events.
  """

  use GenServer

  @topic_pattern "constitution.*:*.*:*"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    ObservationBus.SubscriptionRegistry.subscribe(self(), @topic_pattern)
    {:ok, %{notified: 0}}
  end

  @impl true
  def handle_info({:constitutional_event, %ObservationBus.Event{} = event, _topic}, state) do
    notify_replay_store(event)
    {:noreply, %{state | notified: state.notified + 1}}
  end

  defp notify_replay_store(%ObservationBus.Event{domain: domain, id: id} = event) do
    :telemetry.execute([:observation_bus, :replay, :new_event], %{count: 1}, %{
      event_id: id,
      domain: domain,
      global_sequence: event.global_sequence,
      timestamp: event.timestamp
    })

    :ok
  end
end
