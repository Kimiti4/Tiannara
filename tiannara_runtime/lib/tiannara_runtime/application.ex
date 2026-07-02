defmodule TiannaraRuntime.Application do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: Phase 1 Hybrid Architecture
  
  Main OTP Application supervisor that defines the cognitive runtime topology.
  
  This implements the foundational structure from elixir.md where:
  - GRCC identity lineages run as GenServer processes
  - CIS immune supervision monitors ecological health
  - NATS bridges Python simulation layer with Elixir runtime
  - AEO orchestration manages distributed execution
  
  The system is organized around:
    agents, ecologies, immune regulation, signal propagation
  NOT:
    routes, controllers, requests, CRUD
  """
  
  use Application
  
  def start(_type, _args) do
    IO.puts("🧠 Tiannara Runtime - Cognitive Ecology Starting...")
    
    children = [
      {TiannaraRuntime.RootSupervisor, []}
    ]
    
    opts = [strategy: :one_for_one, name: TiannaraRuntime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
