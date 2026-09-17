defmodule TiannaraRuntime.Observability.CalibrationRunner do
  @moduledoc """
  PHASE 6: Observability Calibration Runner.

  Simulates and tracks bounded-scale calibration experiments across 8–16 worlds
  and 4–12 civilizations. Tracks and exposes key runtime metrics:
  - Semantic Diversity (H_s, embedding dispersion)
  - Attractor Convergence (concept recurrence loops)
  - Stabilizer Overreach (MSG pressure limits, RRG damping)
  """

  use GenServer
  require Logger

  @default_world_count 12
  @tick_interval_ms 2000

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Retrieve calibration metrics for all worlds"
  def get_world_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @doc "Retrieve a specific world's metrics"
  def get_world_metrics(world_id) do
    GenServer.call(__MODULE__, {:get_metrics, world_id})
  end

  @doc "Trigger an intervention for a specific world"
  def trigger_intervention(world_id, intervention_type) do
    GenServer.cast(__MODULE__, {:trigger_intervention, world_id, intervention_type})
  end

  @doc "Reset the entire calibration runner state"
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(opts) do
    world_count = Keyword.get(opts, :world_count, @default_world_count)
    Logger.info("🧪 [Calibration Runner] Initializing simulation for #{world_count} worlds")

    state = %{
      worlds: initialize_worlds(world_count),
      tick_count: 0
    }

    schedule_tick()
    {:ok, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state.worlds, state}
  end

  @impl true
  def handle_call({:get_metrics, world_id}, _from, state) do
    reply =
      case Map.get(state.worlds, world_id) do
        nil -> {:error, :not_found}
        world -> {:ok, world}
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    world_count = map_size(state.worlds)
    {:reply, :ok, %{state | worlds: initialize_worlds(world_count), tick_count: 0}}
  end

  @impl true
  def handle_cast({:trigger_intervention, world_id, intervention_type}, state) do
    case Map.get(state.worlds, world_id) do
      nil ->
        Logger.warning("⚠️ [Calibration Runner] Attempted intervention on invalid world: #{world_id}")
        {:noreply, state}

      world ->
        Logger.info("🛡️ [Calibration Runner] Applying #{intervention_type} on #{world_id}")
        updated_world = apply_intervention_effects(world, intervention_type)
        updated_worlds = Map.put(state.worlds, world_id, updated_world)

        # Broadcast update to PubSub
        broadcast_world_update(world_id, updated_world)

        {:noreply, %{state | worlds: updated_worlds}}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    updated_worlds =
      Enum.reduce(state.worlds, %{}, fn {world_id, world_data}, acc ->
        updated_data = simulate_world_tick(world_data)
        broadcast_world_update(world_id, updated_data)

        # Route a neural alert if world is not operational (stagnant, at_risk, collapsed)
        if updated_data.status != :operational do
          severity =
            case updated_data.status do
              :collapsed -> :critical
              :at_risk -> :high
              :stagnant -> :medium
              _ -> :low
            end

          alert = %{
            civilization_id: world_id,
            entropy: updated_data.entropy,
            collapse_probability: if(updated_data.status == :collapsed, do: 1.0, else: updated_data.stabilizer_overreach),
            state: updated_data.status,
            severity: severity,
            detected_issue: if(updated_data.status == :stagnant, do: :monoculture_risk, else: :extinction_risk),
            weight: 0.85,
            strength: 1.0
          }

          _ = Tiannara.AlertRouter.route(alert)
        end

        Map.put(acc, world_id, updated_data)
      end)

    # Trigger EGL Emergence Governance Loop evaluations in real-time
    _ = Tiannara.EGL.FeedbackLoop.run(updated_worlds)

    schedule_tick()
    {:noreply, %{state | worlds: updated_worlds, tick_count: state.tick_count + 1}}
  end

  # ==================== Helper & Simulation Logic ====================

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval_ms)
  end

  defp initialize_worlds(count) do
    # Introduce 12 distinct capability-complete worlds with asymmetrical optimization pressures
    biases = [
      "robotics_embodiment",
      "organic_biosynthesis",
      "thermodynamic_entropy",
      "algorithmic_governance",
      "cognitive_symbiosis",
      "swarm_coordination",
      "quantum_information",
      "ecological_regeneration",
      "astro_logistics",
      "epistemic_validation",
      "metabolic_efficiency",
      "temporal_coherence"
    ]

    Enum.reduce(1..count, %{}, fn idx, acc ->
      world_id = "world_#{idx}"
      active_civs = Enum.random(4..12)
      bias = Enum.at(biases, rem(idx - 1, 12))

      world_data = %{
        id: world_id,
        status: :operational,
        bias: bias,
        generation: 1,
        entropy: Float.round(Enum.random(500..800) / 1000, 3), # 0.50 - 0.80
        coherence: Float.round(Enum.random(600..900) / 1000, 3), # 0.60 - 0.90
        semantic_diversity: Float.round(Enum.random(650..850) / 1000, 3), # 0.65 - 0.85
        attractor_convergence: Float.round(Enum.random(200..450) / 1000, 3), # 0.20 - 0.45
        stabilizer_overreach: Float.round(Enum.random(150..350) / 1000, 3), # 0.15 - 0.35
        msg_pressure: 0.15,
        active_branches: Enum.random(8..24),
        active_civilizations: active_civs,
        agent_count: Enum.random(500..3500),
        history: []
      }

      Map.put(acc, world_id, world_data)
    end)
  end

  defp simulate_world_tick(world) do
    # Add random walk delta with safety clamping
    entropy = clamp(world.entropy + (Enum.random(-20..20) / 1000), 0.10, 0.95)
    coherence = clamp(world.coherence + (Enum.random(-15..15) / 1000), 0.20, 0.98)
    semantic_diversity = clamp(world.semantic_diversity + (Enum.random(-25..25) / 1000), 0.15, 0.95)
    attractor_convergence = clamp(world.attractor_convergence + (Enum.random(-20..20) / 1000), 0.10, 0.95)
    stabilizer_overreach = clamp(world.stabilizer_overreach + (Enum.random(-15..15) / 1000), 0.05, 0.90)

    # MSG Pressure calculation: M = stabilizer_overreach / (semantic_diversity + 0.001)
    msg_pressure = Float.round(stabilizer_overreach / (semantic_diversity + 0.001), 3)

    # Classify status based on metrics
    status =
      cond do
        msg_pressure > 0.85 -> :stagnant
        entropy < 0.35 or coherence < 0.40 -> :at_risk
        entropy < 0.15 -> :collapsed
        true -> :operational
      end

    # Append to history, keeping last 20 ticks
    history_entry = %{
      timestamp: System.system_time(:second),
      semantic_diversity: semantic_diversity,
      attractor_convergence: attractor_convergence,
      stabilizer_overreach: stabilizer_overreach,
      msg_pressure: msg_pressure
    }

    history = Enum.take([history_entry | world.history], 20)

    %{
      world
      | status: status,
        generation: world.generation + 1,
        entropy: Float.round(entropy, 3),
        coherence: Float.round(coherence, 3),
        semantic_diversity: Float.round(semantic_diversity, 3),
        attractor_convergence: Float.round(attractor_convergence, 3),
        stabilizer_overreach: Float.round(stabilizer_overreach, 3),
        msg_pressure: msg_pressure,
        history: history
    }
  end

  defp apply_intervention_effects(world, "mild_diversity_boost") do
    # Boost mutation rates, decreasing convergence and increasing diversity
    %{
      world
      | semantic_diversity: clamp(world.semantic_diversity + 0.18, 0.0, 0.98),
        attractor_convergence: clamp(world.attractor_convergence - 0.15, 0.0, 0.98),
        stabilizer_overreach: clamp(world.stabilizer_overreach - 0.08, 0.0, 0.98)
    }
  end

  defp apply_intervention_effects(world, "entropy_injection") do
    # Inject novelty and boost entropy, while decreasing overreach
    %{
      world
      | entropy: clamp(world.entropy + 0.20, 0.0, 0.98),
        semantic_diversity: clamp(world.semantic_diversity + 0.10, 0.0, 0.98),
        stabilizer_overreach: clamp(world.stabilizer_overreach - 0.12, 0.0, 0.98)
    }
  end

  defp apply_intervention_effects(world, "heavy_suppression") do
    # Aggressively clamp entropy by overregulating, increasing overreach
    %{
      world
      | entropy: clamp(world.entropy - 0.18, 0.0, 0.98),
        stabilizer_overreach: clamp(world.stabilizer_overreach + 0.22, 0.0, 0.98),
        coherence: clamp(world.coherence + 0.08, 0.0, 0.98)
    }
  end

  defp apply_intervention_effects(world, _), do: world

  defp clamp(val, min, max) do
    max(min, min(max, val))
  end

  defp broadcast_world_update(world_id, world_data) do
    # Simulate streaming broadcast via SignalBus PubSub
    Phoenix.PubSub.broadcast(
      TiannaraRuntime.PubSub,
      "visualization",
      {:viz_event,
       %{
         "timestamp" => System.system_time(:second),
         "layer" => "system",
         "entity_type" => "world_update",
         "entity_id" => world_id,
         "metrics" => %{
           "entropy" => world_data.entropy,
           "coherence" => world_data.coherence,
           "semantic_diversity" => world_data.semantic_diversity,
           "attractor_convergence" => world_data.attractor_convergence,
           "stabilizer_overreach" => world_data.stabilizer_overreach,
           "msg_pressure" => world_data.msg_pressure
         },
         "state" => to_string(world_data.status),
         "visual_type" => "heartbeat"
       }}
    )
  end
end
