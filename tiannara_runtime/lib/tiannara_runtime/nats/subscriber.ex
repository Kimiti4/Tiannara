defmodule TiannaraRuntime.NATS.Subscriber do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    state = %{
      subscriptions: [],
      received_count: 0
    }
    subscriptions = [
      "tiannara.simulation.grcc.>",
      "tiannara.simulation.fitness.>",
      "tiannara.simulation.niche.>",
      "tiannara.simulation.evolution.>"
    ]
    Enum.each(subscriptions, fn sub ->
      TiannaraRuntime.NATS.Bus.subscribe(sub)
    end)
    {:ok, %{state | subscriptions: subscriptions}}
  end

  def handle_message(subject, payload) do
    GenServer.cast(__MODULE__, {:message_received, subject, payload})
  end

  @impl true
  def handle_cast({:message_received, subject, payload}, state) do
    new_state = %{state | received_count: state.received_count + 1}
    {:noreply, new_state}
  end
end
