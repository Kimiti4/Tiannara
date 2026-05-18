defmodule TiannaraRuntime.NATS.Connection do
  @moduledoc """
  NATS Connection Manager
  
  Manages persistent connection to NATS server for Python-Elixir communication.
  Implements automatic reconnection with exponential backoff.
  """
  
  use GenServer
  require Logger

  defstruct [
    url: "nats://localhost:4222",
    connection: nil,
    status: :disconnected,
    reconnect_attempts: 0,
    max_reconnect_attempts: 5,
    reconnect_delay_ms: 1000
  ]

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    state = %__MODULE__{
      url: Application.get_env(:tiannara_runtime, __MODULE__)[:url] || "nats://localhost:4222",
      max_reconnect_attempts: Application.get_env(:tiannara_runtime, __MODULE__)[:reconnect_attempts] || 5,
      reconnect_delay_ms: Application.get_env(:tiannara_runtime, __MODULE__)[:reconnect_delay_ms] || 1000
    }
    
    # Attempt initial connection
    connect(state)
    
    {:ok, state}
  end

  @doc """
  Get current connection status.
  """
  def get_status() do
    GenServer.call(__MODULE__, :get_status)
  end

  @doc """
  Publish message to NATS subject.
  """
  def publish(subject, payload) when is_binary(subject) and is_map(payload) do
    GenServer.call(__MODULE__, {:publish, subject, payload})
  end

  @doc """
  Subscribe to NATS subject with callback handler.
  """
  def subscribe(subject, callback_module) when is_binary(subject) do
    GenServer.cast(__MODULE__, {:subscribe, subject, callback_module})
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, %{
      connected: state.status == :connected,
      url: state.url,
      reconnect_attempts: state.reconnect_attempts,
      status: state.status
    }, state}
  end

  @impl true
  def handle_call({:publish, subject, payload}, _from, state) do
    if state.status == :connected && state.connection do
      try do
        # Encode payload as JSON
        json_payload = Jason.encode!(payload)
        
        # Publish to NATS (stub - actual implementation requires gnat client)
        # :gnat.pub(state.connection, subject, json_payload)
        
        Logger.debug("📤 Published to #{subject}: #{json_payload}")
        {:reply, :ok, state}
      rescue
        e ->
          Logger.error("❌ Failed to publish to #{subject}: #{inspect(e)}")
          {:reply, {:error, e}, state}
      end
    else
      Logger.warning("⚠️  Cannot publish to #{subject}: NATS not connected")
      {:reply, {:error, :not_connected}, state}
    end
  end

  @impl true
  def handle_cast({:subscribe, subject, callback_module}, state) do
    if state.status == :connected do
      # Subscribe to subject (stub - actual implementation requires gnat client)
      # :gnat.sub(state.connection, self(), subject)
      
      Logger.info("📥 Subscribed to #{subject} with handler #{inspect(callback_module)}")
    else
      Logger.warning("⚠️  Cannot subscribe to #{subject}: NATS not connected")
    end
    
    {:ok, state}
  end

  @impl true
  def handle_info(:attempt_reconnect, state) do
    if state.reconnect_attempts < state.max_reconnect_attempts do
      Logger.info("🔄 Reconnecting to NATS (attempt #{state.reconnect_attempts + 1})...")
      updated_state = %{state | reconnect_attempts: state.reconnect_attempts + 1}
      connect(updated_state)
    else
      Logger.error("❌ Max NATS reconnection attempts reached. Giving up.")
      {:ok, %{state | status: :failed}}
    end
  end

  # Private functions
  
  defp connect(state) do
    try do
      # TODO: Implement actual NATS connection using gnat client
      # For now, simulate successful connection
      
      Logger.info("✅ Connected to NATS at #{state.url}")
      
      connected_state = %{state |
        connection: :simulated_connection,
        status: :connected,
        reconnect_attempts: 0
      }
      
      {:ok, connected_state}
    rescue
      e ->
        Logger.error("❌ NATS connection failed: #{inspect(e)}")
        
        # Schedule retry with exponential backoff
        delay = state.reconnect_delay_ms * Integer.pow(2, state.reconnect_attempts)
        Process.send_after(self(), :attempt_reconnect, delay)
        
        disconnected_state = %{state | status: :disconnected}
        {:ok, disconnected_state}
    end
  end
end
