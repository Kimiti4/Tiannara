defmodule Tiannara.Meta.Mesh.Supervisor do
  @moduledoc """
  Phase 5F.x — NATS Distributed Reality Mesh Supervisor

  Supervises all components of the distributed ontological event fabric:
  - RealityBus: Core NATS messaging layer
  - ObserverRouter: Entropy-based event routing
  - MeshBalancer: OLEF pressure diffusion
  - ChronogramSync: Distributed memory synchronization
  - RealityFirewall: Cross-manifold security

  ## Architecture

  ```
  ┌─────────────────────────────────────┐
  │     Reality Mesh Supervisor         │
  ├─────────────────────────────────────┤
  │  RealityBus (Core NATS Layer)       │
  │  ObserverRouter (Entropy Routing)   │
  │  MeshBalancer (Load Distribution)   │
  │  ChronogramSync (Memory Sync)       │
  │  RealityFirewall (Security Gate)    │
  └─────────────────────────────────────┘
  ```

  ## Subject Topology

  The mesh manages these NATS subject hierarchies:
  - `tiannara.observer.*` — Observer lifecycle events
  - `tiannara.opc.*` — Physics compilation pipeline
  - `tiannara.chronogram.*` — Memory mutations
  - `tiannara.mscl.*` — Stability signals
  - `tiannara.olef.*` — Load equilibrium
  - `tiannara.mesh.*` — Mesh synchronization
  - `tiannara.gck.*` — Grammar constraint gates
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Core Reality Bus - NATS messaging backbone
      {Tiannara.Meta.Mesh.RealityBus, []},

      # Observer Entropy Router - partitions by divergence
      {Tiannara.Meta.Mesh.ObserverRouter, []},

      # OLEF Mesh Balancer - pressure diffusion
      {Tiannara.Meta.OLEF.MeshBalancer, []},

      # Chronogram Synchronization - distributed memory
      {Tiannara.Meta.Mesh.ChronogramSync, []},

      # Reality Firewall - cross-manifold security
      # Note: Firewall is stateless, no GenServer needed
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
