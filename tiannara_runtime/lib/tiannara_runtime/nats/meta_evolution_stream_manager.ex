defmodule Tiannara.NATS.MetaEvolutionStreamManager do
  use GenServer
  require Logger

  @nats_url Application.get_env(:tiannara_runtime, :nats_url, "nats://127.0.0.1:4222")

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{connection: nil, connected: true, subscriptions: []}}
  end

  def publish_cortex_event(event_data) when is_map(event_data) do
    topic = case Map.get(event_data, :event) do
      :escalation -> "tiannara.cortex.freeze"
      :regulation -> "tiannara.cortex.regulation"
      :recovery -> "tiannara.cortex.recovery"
      _ -> "tiannara.cortex.world_metrics"
    end
    publish(topic, event_data)
  end

  def publish_regulation_command(command_data) when is_map(command_data) do
    publish("tiannara.cortex.regulation", command_data)
  end

  def publish_tensegrity_bound(event_data) when is_map(event_data) do
    publish("tiannara.meta.causal.tensegrity.bound", event_data)
  end

  def publish_causal_fracture(event_data) when is_map(event_data) do
    publish("tiannara.meta.causal.fracture.detected", event_data)
  end

  def publish_chrono_tensor_update(update_data) when is_map(update_data) do
    publish("tiannara.gpu.chrono_tensor.update", update_data)
  end

  def publish(topic, payload) when is_binary(topic) and is_map(payload) do
    GenServer.cast(__MODULE__, {:publish, topic, payload})
  end

  def subscribe(topic, handler_pid) do
    GenServer.cast(__MODULE__, {:subscribe, topic, handler_pid})
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def handle_cast({:publish, topic, payload}, state) do
    encoded = Jason.encode!(payload)
    TiannaraRuntime.NATS.Bus.publish(topic, encoded)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe, topic, handler_pid}, state) do
    TiannaraRuntime.NATS.Bus.subscribe(topic)
    {:noreply, %{state | subscriptions: [topic | state.subscriptions]}}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      connected: state.connected,
      url: "nats://127.0.0.1:4222",
      active_subscriptions: length(state.subscriptions),
      topics: state.subscriptions
    }
    {:reply, {:ok, status}, state}
  end
end
