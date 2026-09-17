defmodule Tiannara.Meta.OLEF.MeshBalancer do
  @moduledoc """
  Phase 5F.x — Distributed OLEF Load Balancer

  Balances computational pressure across distributed mesh nodes
  using NATS-based pressure diffusion. Implements gradient-based
  load redistribution to maintain ontological equilibrium.

  ## Load Balancing Strategy

  When a node's pressure exceeds threshold (0.8):
  1. Calculate pressure gradient to neighbors
  2. Publish redistribution events via NATS
  3. Neighbors absorb excess pressure proportionally
  4. System converges to equilibrium through diffusion

  ## Pressure Thresholds

  - `@threshold`: 0.8 — Trigger redistribution above this level
  - `@max_pressure`: 1.0 — Absolute maximum before emergency evaporation
  - `@diffusion_rate`: 0.3 — Rate of pressure transfer per iteration

  ## Usage

      # Diffuse pressure from overloaded node
      MeshBalancer.diffuse("node_alpha", 0.9, ["node_beta", "node_gamma"])

      # Check if rebalancing needed
      if MeshBalancer.needs_rebalancing?(pressure) do
        MeshBalancer.initiate_rebalance(node_id, neighbors)
      end
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.Mesh.RealityBus

  # Pressure thresholds
  @threshold 0.8
  @max_pressure 1.0
  @diffusion_rate 0.3

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Diffuses pressure from an overloaded node to its neighbors.

  ## Parameters
  - `node_id`: Source node identifier
  - `pressure`: Current pressure level (0.0-1.0)
  - `neighbors`: List of neighbor node IDs

  ## Returns
  - `:ok` on successful diffusion initiation

  ## Example

      MeshBalancer.diffuse("node_001", 0.9, ["node_002", "node_003"])
  """
  def diffuse(node_id, pressure, neighbors) when is_list(neighbors) do
    GenServer.cast(__MODULE__, {:diffuse, node_id, pressure, neighbors})
  end

  @doc """
  Checks if pressure requires rebalancing.

  ## Parameters
  - `pressure`: Current pressure level

  ## Returns
  - `true` if pressure > threshold, `false` otherwise

  ## Example

      MeshBalancer.needs_rebalancing?(0.85)
      # Returns: true
  """
  def needs_rebalancing?(pressure) do
    pressure > @threshold
  end

  @doc """
  Initiates emergency pressure evacuation.

  Used when pressure approaches critical levels (> 0.95).
  Triggers MSCL evaporation protocols.

  ## Parameters
  - `node_id`: Node requiring evacuation
  - `pressure`: Critical pressure level

  ## Returns
  - `:ok`
  """
  def emergency_evacuate(node_id, pressure) do
    GenServer.cast(__MODULE__, {:emergency_evacuate, node_id, pressure})
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    state = %{
      node_pressures: %{},  # %{node_id => pressure}
      diffusion_events: 0,
      emergency_evacuations: 0
    }

    Logger.info("⚖️ [MeshBalancer] Initialized distributed load balancer")
    {:ok, state}
  end

  @impl true
  def handle_cast({:diffuse, node_id, pressure, neighbors}, state) do
    if pressure > @threshold do
      Logger.warning("⚖️ [MeshBalancer] High pressure on #{node_id}: #{pressure}")

      # Calculate pressure to distribute
      excess_pressure = pressure - @threshold
      pressure_per_neighbor = (excess_pressure * @diffusion_rate) / max(length(neighbors), 1)

      # Publish redistribution events to each neighbor
      Enum.each(neighbors, fn neighbor ->
        RealityBus.publish("tiannara.olef.redistribute", %{
          source: node_id,
          target: neighbor,
          pressure_transfer: pressure_per_neighbor,
          timestamp: System.system_time(:millisecond)
        })

        Logger.debug("⚖️ [MeshBalancer] Transferring #{pressure_per_neighbor} to #{neighbor}")
      end)

      new_state = %{state |
        diffusion_events: state.diffusion_events + length(neighbors)
      }

      {:noreply, new_state}
    else
      Logger.debug("⚖️ [MeshBalancer] Pressure #{pressure} within normal range")
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:emergency_evacuate, node_id, pressure}, state) do
    Logger.error("🚨 [MeshBalancer] EMERGENCY evacuation for #{node_id} (pressure: #{pressure})")

    # Publish emergency evacuation event
    RealityBus.publish("tiannara.mscl.evaporate", %{
      node_id: node_id,
      pressure: pressure,
      urgency: :critical,
      timestamp: System.system_time(:millisecond)
    })

    new_state = %{state |
      emergency_evacuations: state.emergency_evacuations + 1
    }

    {:noreply, new_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp calculate_gradient(source_pressure, neighbor_pressures) do
    # Calculate pressure gradients for optimal distribution
    Enum.map(neighbor_pressures, fn {neighbor_id, neighbor_pressure} ->
      gradient = source_pressure - neighbor_pressure
      {neighbor_id, gradient}
    end)
  end
end
