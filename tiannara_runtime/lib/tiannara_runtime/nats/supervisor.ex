defmodule TiannaraRuntime.NATS.Supervisor do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v21: Phase 2 NATS Bridge Supervisor
  
  Bridges Python simulation layer with Elixir runtime via NATS event bus.
  
  This implements the "event nervous system" from elixir.md where:
  - NATS handles low-latency cognitive signaling (transient cognition streams)
  - Kafka handles durable analytics and historical event lineage
  - Phoenix PubSub handles real-time ecological monitoring
  
  The bridge enables bidirectional communication:
  - Python → Elixir: Ecological state updates, fitness scores, niche data
  - Elixir → Python: Identity actions, immune interventions, orchestration commands
  
  Module Structure:
  - Connection: Manages persistent NATS connection with auto-reconnect
  - Publisher: Sends events from Elixir to Python cortex
  - Subscriber: Receives events from Python to Elixir runtime
  
  This is critical for Phase 2 closed-loop cognitive control system.
  """
  
  use Supervisor
  
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    children = [
      # NATS Connection Manager - maintains connection to NATS server
      {TiannaraRuntime.NATS.Connection, []},
      
      # NATS Publisher - sends events from Elixir to Python
      {TiannaraRuntime.NATS.Publisher, []},
      
      # NATS Subscriber - receives events from Python to Elixir
      {TiannaraRuntime.NATS.Subscriber, []}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
