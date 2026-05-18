defmodule TiannaraRuntime.NATS.Supervisor do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: NATS Bridge Supervisor
  
  Bridges Python simulation layer with Elixir runtime via NATS event bus.
  
  This implements the "event nervous system" from elixir.md where:
  - NATS handles low-latency cognitive signaling (transient cognition streams)
  - Kafka handles durable analytics and historical event lineage
  - Phoenix PubSub handles real-time ecological monitoring
  
  The bridge enables bidirectional communication:
  - Python → Elixir: Ecological state updates, fitness scores, niche data
  - Elixir → Python: Identity actions, immune interventions, orchestration commands
  
  This is critical for Phase 1 hybrid architecture where Python continues
  handling GRCC v10 ML/simulation while Elixir manages cognitive runtime.
  """
  
  use Supervisor
  
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    children = [
      # NATS Connection Manager - maintains connection to NATS server
      {TiannaraRuntime.NATS.ConnectionManager, []},
      
      # NATS Publisher - sends events from Elixir to Python
      {TiannaraRuntime.NATS.Publisher, []},
      
      # NATS Subscriber - receives events from Python to Elixir
      {TiannaraRuntime.NATS.Subscriber, []}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
