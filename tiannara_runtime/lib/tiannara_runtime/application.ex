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
      # Phoenix PubSub for real-time event distribution
      {Phoenix.PubSub, name: TiannaraRuntime.PubSub},
      
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
      
      # Cognitive Observability Layer - Real-Time Visualization Stream
      {TiannaraRuntime.Observability.StreamProcessor, name: :observability_stream_processor},
      
      # Phase 4A: Predictive Memory Layer
      {TiannaraRuntime.Predictive.Supervisor, name: :predictive_supervisor},
      
      # Phase 4B: Identity Persistence Layer
      {TiannaraRuntime.Identity.CoalitionHistory, name: :coalition_history},
      {TiannaraRuntime.Identity.SpeciesRegistry, name: :species_registry},
      {TiannaraRuntime.Identity.Tracker, name: :identity_tracker},
      
      # Phase 4C: Causal Tracing System
      {TiannaraRuntime.Causality.CausalGraph, name: :causal_graph},
      
      # Phase 4D: Meta-Stability Engine
      {TiannaraRuntime.MetaStability.StabilityMetrics, name: :stability_metrics},
      {TiannaraRuntime.MetaStability.ParameterAdjustment, name: :parameter_adjustment},
      {TiannaraRuntime.MetaStability.StabilityOptimizer, name: :stability_optimizer},
      
      # Phase 4E: Cognitive Phase-Space Atlas
      {TiannaraRuntime.CognitivePhaseSpaceAtlas, name: :cognitive_phase_space_atlas},
      
      # Phase 5A: Multi-World Branching System
      {TiannaraRuntime.WorldRegistrySupervisor, []},
      {TiannaraRuntime.NATS.WorldStreamManager, []},
      {TiannaraRuntime.NATS.WorldSubscriptionHandler, []},
      
      # Phase 5B: Evolutionary Selection System
      {TiannaraRuntime.Evolution.Supervisor, []},
      
      # Phase 5C+: Symbiotic Entanglement Engine
      {Tiannara.Physics.EntanglementManager, []},
      {Tiannara.Physics.ChimericResolutionEngine, []},
      {Tiannara.Evolution.Memory, []},
      {Tiannara.Evolution.SpeciationEngine, []},
      {Tiannara.Speciation.TelemetryBuffer, []},
      {Tiannara.NATS.WorldEntanglementStreams, []},
      
      # Phase 5D: Meta-Evolution Engine
      {Tiannara.Meta.Memory.LawArchive, []},
      {Tiannara.Causality.Graph, []},
      {Tiannara.Debug.TimeReverse, []},
      {Tiannara.Meta.Supervisor, []},
      
      # Phase 5E: Causal Ontology Engine
      {Tiannara.Meta.CausalTensegrityEngine, []},
      {Tiannara.Meta.CausalOntologyEngine, []},
      {Tiannara.Meta.ChronoTensor, []},
      
      # Phase 5E Core Event Pipeline (minimal boot boundary)
      {TiannaraRuntime.MultiWorld.Events.EventStore, []},
      {TiannaraRuntime.Cortex.ImmuneCortex, []},
      
      # Phase 5 Safety Cortex (Hardened KillSwitch v2)
      {TiannaraRuntime.MultiWorld.HardenedKillSwitch, []},
      
      # Phase 5S: Safety Cortex (4-Layer Regulatory System)
      {TiannaraRuntime.Cortex.SafetyCortex, []},
      
      # Phase 5F.3.5: Control Plane Consolidation Layer
      {TiannaraRuntime.CIS.ExecutionController, []},
      {TiannaraRuntime.Resources.QuotaGovernor, []},
      {TiannaraRuntime.Memory.LineageCompression, []},
      {TiannaraRuntime.Causal.GCK, []},
      
      # Phoenix Endpoint for WebSocket streaming and HTTP API
      {TiannaraRuntimeWeb.Endpoint, []},
      
      # Interface Layer - API and Realtime Monitoring
      {TiannaraRuntime.Interface.Supervisor, name: :interface_supervisor}
    ]
    
    opts = [strategy: :one_for_one, name: TiannaraRuntime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
