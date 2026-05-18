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
      # Signal Bus for inter-process communication
      {TiannaraRuntime.SignalBus.Supervisor, name: :signal_bus_supervisor},
      
      # Core Ecology Layer - GRCC Identity Management
      {TiannaraRuntime.GRCC.EcologySupervisor, name: :ecology_supervisor},
      
      # Cognitive Immune System (CIS) - Ecological Stabilization
      {TiannaraRuntime.CIS.Supervisor, name: :cis_supervisor},
      
      # AEO Execution Layer - Distributed Orchestration
      {TiannaraRuntime.AEO.Supervisor, name: :aeo_supervisor},
      
      # NATS Bridge - Python/Elixir Integration
      {TiannaraRuntime.NATS.Supervisor, name: :nats_supervisor},
      
      # Event Gateway - Core NATS Router (Phase 2)
      {TiannaraRuntime.EventGateway, name: :event_gateway},
      
      # Interface Layer - API and Realtime Monitoring
      {TiannaraRuntime.Interface.Supervisor, name: :interface_supervisor}
    ]
    
    opts = [strategy: :one_for_one, name: TiannaraRuntime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
