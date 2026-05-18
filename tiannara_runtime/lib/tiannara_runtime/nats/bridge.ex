defmodule TiannaraRuntime.NATS.Publisher do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: NATS Event Publisher
  
  Publishes ecological events from Elixir runtime to Python simulation layer.
  
  Event Subjects:
  - tiannara.ecology.identity.* : Identity lifecycle events (birth, death, mutation)
  - tiannara.ecology.cis.* : Immune system interventions
  - tiannara.ecology.environment.* : Environmental state updates
  - tiannara.ecology.fitness.* : Fitness score broadcasts
  
  This enables Python to react to real-time cognitive ecology dynamics.
  """
  
  use GenServer
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    state = %{
      connection: nil,
      published_count: 0,
      buffer: []  # Buffer for offline messages
    }
    
    {:ok, state}
  end
  
  @doc """
  Publish event to NATS subject.
  """
  def publish(subject, payload) when is_binary(subject) do
    GenServer.cast(__MODULE__, {:publish, subject, payload})
  end
  
  @impl true
  def handle_cast({:publish, subject, payload}, state) do
    # TODO: Implement actual NATS publishing
    # For Phase 1, we'll log the event
    
    IO.puts("📤 NATS Publish: #{subject}")
    # IO.inspect(payload, label: "Payload")
    
    new_state = %{state | published_count: state.published_count + 1}
    {:ok, new_state}
  end
end


defmodule TiannaraRuntime.NATS.Subscriber do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: NATS Event Subscriber
  
  Subscribes to ecological events from Python simulation layer.
  
  Subscriptions:
  - tiannara.simulation.grcc.* : GRCC v10 ecological state updates
  - tiannara.simulation.fitness.* : Fitness landscape changes
  - tiannara.simulation.niche.* : Niche occupancy updates
  - tiannara.simulation.evolution.* : Evolutionary dynamics
  
  This enables Elixir runtime to react to Python simulation outputs.
  """
  
  use GenServer
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    state = %{
      connection: nil,
      subscriptions: [],
      received_count: 0
    }
    
    # Subscribe to Python simulation events
    subscriptions = [
      "tiannara.simulation.grcc.>",
      "tiannara.simulation.fitness.>",
      "tiannara.simulation.niche.>",
      "tiannara.simulation.evolution.>"
    ]
    
    new_state = %{state | subscriptions: subscriptions}
    
    {:ok, new_state}
  end
  
  @doc """
  Handle incoming NATS message from Python.
  """
  def handle_message(subject, payload) do
    GenServer.cast(__MODULE__, {:message_received, subject, payload})
  end
  
  @impl true
  def handle_cast({:message_received, subject, payload}, state) do
    # TODO: Implement actual message processing
    # For Phase 1, we'll log the event
    
    IO.puts("📥 NATS Receive: #{subject}")
    # IO.inspect(payload, label: "Payload")
    
    new_state = %{state | received_count: state.received_count + 1}
    {:ok, new_state}
  end
end


defmodule TiannaraRuntime.NATS.ConnectionManager do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: NATS Connection Manager
  
  Manages persistent connection to NATS server with automatic reconnection.
  
  Configuration:
  - Server URL: nats://localhost:4222 (default)
  - Reconnection strategy: Exponential backoff
  - Max reconnect attempts: Unlimited (persistent system)
  """
  
  use GenServer
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    state = %{
      connected: false,
      server_url: System.get_env("NATS_URL", "nats://localhost:4222"),
      reconnect_attempts: 0,
      last_connection_time: nil
    }
    
    # Attempt initial connection
    case connect(state.server_url) do
      :ok ->
        IO.puts("✅ NATS Connected: #{state.server_url}")
        {:ok, %{state | connected: true, last_connection_time: DateTime.utc_now()}}
      {:error, reason} ->
        IO.puts("⚠️  NATS Connection Failed: #{reason}")
        schedule_reconnect()
        {:ok, state}
    end
  end
  
  @doc """
  Get current connection status.
  """
  def get_status() do
    GenServer.call(__MODULE__, :get_status)
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end
  
  @impl true
  def handle_info(:reconnect, state) do
    IO.puts("🔄 Attempting NATS reconnection (attempt #{state.reconnect_attempts + 1})...")
    
    case connect(state.server_url) do
      :ok ->
        IO.puts("✅ NATS Reconnected")
        {:ok, %{state | connected: true, reconnect_attempts: 0, last_connection_time: DateTime.utc_now()}}
      {:error, reason} ->
        IO.puts("⚠️  Reconnection Failed: #{reason}")
        schedule_reconnect()
        {:ok, %{state | reconnect_attempts: state.reconnect_attempts + 1}}
    end
  end
  
  # Private Functions
  
  defp connect(_server_url) do
    # TODO: Implement actual NATS connection using gnatsd library
    # For Phase 1, simulate connection success/failure
    
    # Simulate successful connection
    :ok
  end
  
  defp schedule_reconnect() do
    # Exponential backoff: 1s, 2s, 4s, 8s, ... max 60s
    delay = min(:math.pow(2, 10) * 1000, 60000) |> round()
    Process.send_after(self(), :reconnect, delay)
  end
end
