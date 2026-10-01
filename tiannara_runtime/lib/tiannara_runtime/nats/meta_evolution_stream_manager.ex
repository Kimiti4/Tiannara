defmodule Tiannara.NATS.MetaEvolutionStreamManager do
  use GenServer
  require Logger

  @nats_url Application.get_env(:tiannara_runtime, :nats_url, "nats://127.0.0.1:4222")

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    case TiannaraRuntime.NATS.Bus.subscribe_all() do
      :ok -> {:ok, %{connection: nil, connected: true, subscriptions: []}}
      {:error, reason} -> {:ok, %{connection: nil, connected: false, subscriptions: [], init_error: reason}}
    end
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
    GenServer.call(__MODULE__, {:publish, topic, payload})
  end

  def subscribe(topic, handler_pid) do
    GenServer.cast(__MODULE__, {:subscribe, topic, handler_pid})
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def handle_call({:publish, topic, payload}, _from, state) do
    encoded = Jason.encode!(payload)

    case TiannaraRuntime.NATS.Bus.publish(topic, encoded) do
      :ok ->
        {:reply, :ok, state}

      {:ok, _} = result ->
        {:reply, result, state}

      {:error, reason} ->
        {:reply, {:error, reason}, %{state | connected: false}}

      other ->
        {:reply, {:error, {:unexpected_publish_result, other}}, state}
    end
  end

  @impl true
  def handle_cast({:subscribe, topic, handler_pid}, state) do
    Process.monitor(handler_pid)
    subscriptions = Enum.uniq([{topic, handler_pid} | state.subscriptions])
    {:noreply, %{state | subscriptions: subscriptions}}
  end

  @impl true
  def handle_info({:nats_message, topic, payload}, state) do
    Enum.each(state.subscriptions, fn
      {sub_topic, pid} ->
        if topic_matches?(sub_topic, topic) and Process.alive?(pid) do
          send(pid, {:nats_message, topic, payload})
        end
      _ ->
        :ok
    end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    subscriptions = Enum.reject(state.subscriptions, fn
      {_topic, ^pid} -> true
      _ -> false
    end)
    {:noreply, %{state | subscriptions: subscriptions}}
  end

  defp topic_matches?(pattern, topic) do
    pattern == topic or
      (String.ends_with?(pattern, ".>") and
         String.starts_with?(topic, String.trim_trailing(pattern, ".>") <> "."))
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      connected: state.connected,
      url: @nats_url,
      active_subscriptions: length(state.subscriptions),
      topics: Enum.map(state.subscriptions, fn
        {topic, _pid} -> topic
        topic -> topic
      end)
    }
    {:reply, {:ok, status}, state}
  end
end
