defmodule Tiannara.NATS.WorldEntanglementStreams do
  use GenServer
  require Logger

  @hlt_stream "tiannara.world.hlt.events"
  @merge_stream "tiannara.world.merge.events"
  @lock_stream "tiannara.world.entangle.lock"
  @speciation_raw_stream "tiannara.analytics.speciation.raw"
  @speciation_processed_stream "tiannara.analytics.speciation.processed"

  defstruct [
    :nats_connection,
    subscriptions: %{}
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def publish_hlt_event(event_data) do
    GenServer.cast(__MODULE__, {:publish, @hlt_stream, event_data})
  end

  def publish_merge_event(event_data) do
    GenServer.cast(__MODULE__, {:publish, @merge_stream, event_data})
  end

  def publish_lock_event(event_data) do
    GenServer.cast(__MODULE__, {:publish, @lock_stream, event_data})
  end

  def subscribe_to_speciation_results do
    GenServer.call(__MODULE__, {:subscribe, @speciation_processed_stream})
  end

  def list_subscriptions do
    GenServer.call(__MODULE__, :list_subscriptions)
  end

  @impl true
  def init(opts) do
    nats_connection = Keyword.get(opts, :nats_connection)
    {:ok, %__MODULE__{
      nats_connection: nats_connection,
      subscriptions: %{}
    }}
  end

  @impl true
  def handle_cast({:publish, topic, event_data}, state) do
    payload = Jason.encode!(event_data)
    TiannaraRuntime.NATS.Bus.publish(topic, payload)
    {:noreply, state}
  end

  @impl true
  def handle_call({:subscribe, topic}, _from, state) do
    TiannaraRuntime.NATS.Bus.subscribe(topic)
    subscription_ref = make_ref()
    new_subscriptions = Map.put(state.subscriptions, topic, subscription_ref)
    {:reply, {:ok, subscription_ref}, %{state | subscriptions: new_subscriptions}}
  end

  @impl true
  def handle_call(:list_subscriptions, _from, state) do
    {:reply, {:ok, state.subscriptions}, state}
  end

  @impl true
  def handle_info({:msg, %{topic: topic, body: body}}, state) do
    {:noreply, state}
  end
end
