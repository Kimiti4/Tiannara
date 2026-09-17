defmodule TiannaraRuntime.NATS.WorldStreamManager do
  use GenServer
  require Logger

  @default_nats_url "nats://localhost:4222"
  @reconnect_delay_ms 1000
  @max_reconnect_attempts 10

  defstruct [
    connection: nil,
    nats_url: @default_nats_url,
    subscriptions: %{},
    reconnect_attempts: 0,
    connected: false
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def publish(topic, message) do
    GenServer.cast(__MODULE__, {:publish, topic, message})
  end

  def subscribe(topic, handler_pid) do
    GenServer.call(__MODULE__, {:subscribe, topic, handler_pid})
  end

  def unsubscribe(topic) do
    GenServer.call(__MODULE__, {:unsubscribe, topic})
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  def get_connection do
    GenServer.call(__MODULE__, :get_connection)
  end

  @impl true
  def init(opts) do
    nats_url = Keyword.get(opts, :nats_url, "nats://localhost:4222")
    state = %__MODULE__{
      nats_url: nats_url,
      connection: nil,
      subscriptions: %{},
      reconnect_attempts: 0,
      connected: true
    }
    {:ok, state}
  end

  @impl true
  def handle_cast({:publish, topic, message}, state) do
    json_payload = Jason.encode!(message)
    TiannaraRuntime.NATS.Bus.publish(topic, json_payload)
    {:noreply, state}
  end

  @impl true
  def handle_call({:subscribe, topic, handler_pid}, _from, state) do
    if Map.has_key?(state.subscriptions, topic) do
      {:reply, {:error, :already_subscribed}, state}
    else
      TiannaraRuntime.NATS.Bus.subscribe(topic)
      new_subscriptions = Map.put(state.subscriptions, topic, handler_pid)
      {:reply, :ok, %{state | subscriptions: new_subscriptions}}
    end
  end

  @impl true
  def handle_call({:unsubscribe, topic}, _from, state) do
    case Map.pop(state.subscriptions, topic) do
      {nil, _} ->
        {:reply, {:error, :not_subscribed}, state}
      {_handler_pid, remaining_subscriptions} ->
        TiannaraRuntime.NATS.Bus.unsubscribe(topic)
        {:reply, :ok, %{state | subscriptions: remaining_subscriptions}}
    end
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      connected: state.connected,
      url: state.nats_url,
      subscriptions: map_size(state.subscriptions),
      reconnect_attempts: state.reconnect_attempts
    }
    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_call(:get_connection, _from, state) do
    {:reply, {:ok, state.connection}, state}
  end
end
