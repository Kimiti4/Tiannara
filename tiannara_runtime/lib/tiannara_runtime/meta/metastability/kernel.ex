defmodule Tiannara.Meta.Metastability.Kernel do
  @moduledoc """
  Phase 5F.5 — Meta-Stability Constraint Layer (MSCL-Ω) Kernel

  The central governor preventing semantic decoherence across observer-relative realities.

  ## Core Problem Solved

  After Phase 5F.4, every observer has its own memory projection with no global timeline.
  Contradictions are normal, not errors. But this creates a new failure mode:

  > Local realities drift so far apart that causality stops aligning and execution
    branches become non-interpretable.

  MSCL-Ω enforces **coherence bounds between incompatible realities** without unifying them.

  ## Architecture Principle

  > You can have infinite perspectives, but not infinite incompatibility.

  ## Key Invariants Enforced

  1. **Causal Drift Pressure (CDP)**: Measures how far observer histories are diverging
  2. **Reconciliation Horizon Field (RHF)**: Maximum distance two realities can diverge while remaining convertible
  3. **Entropy Rebinding Kernel (ERK)**: Injects minimal shared causal anchors when divergence grows too large

  ## Mathematical Model

  For all observers i,j:
      D(M_i, M_j) ≤ Ω_threshold

  Where D is the divergence metric between memory states M_i and M_j.

  ## Usage

      # Check if two observers are within coherence bounds
      case MSCL.Kernel.validate_divergence("obs_A", "obs_B") do
        :stable -> IO.puts("Observers within safe divergence")
        :stabilized -> IO.puts("Excess divergence detected, anchors injected")
      end

      # Get global stability metrics
      metrics = MSCL.Kernel.get_stability_metrics()
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.ChronogramMatrix
  alias Tiannara.GCK.ChronogramGate

  # ── Configuration ─────────────────────────────────────────────────────────

  # Maximum allowed divergence between any two observers (0.0 = identical, 1.0 = incomprehensible)
  @divergence_threshold 0.78

  # Causal drift pressure threshold (triggers stabilization)
  @cdp_threshold 0.65

  # Entropy rebinding trigger point (injects weak invariants)
  @entropy_rebind_threshold 0.85

  # Monitoring interval (milliseconds)
  @monitoring_interval_ms 5_000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    observer_divergence_map: %{},  # %{ {obs_a, obs_b} => divergence_score }
    global_paradox_density: 0.0,
    causal_drift_pressure: 0.0,
    active_stabilizations: [],
    monitoring_timer: nil
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the MSCL-Ω Kernel GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Validates divergence between two observers and stabilizes if needed.

  ## Returns
  - `:stable` — Observers within safe divergence bounds
  - `:stabilized` — Excess divergence detected, causal anchors injected

  ## Example

      case MSCL.Kernel.validate_divergence("obs_A", "obs_B") do
        :stable -> IO.puts("Safe divergence")
        :stabilized -> IO.puts("Stabilization applied")
      end
  """
  def validate_divergence(observer_a_id, observer_b_id) do
    GenServer.call(__MODULE__, {:validate_divergence, observer_a_id, observer_b_id})
  end

  @doc """
  Gets global stability metrics for the entire observer manifold.

  ## Returns
  Map containing:
  - `global_paradox_density`: Overall paradox concentration (0.0-1.0)
  - `causal_drift_pressure`: System-wide divergence pressure (0.0-1.0)
  - `active_stabilizations`: Number of ongoing stabilization operations
  - `monitored_observers`: Count of observers under surveillance
  """
  def get_stability_metrics do
    GenServer.call(__MODULE__, :get_stability_metrics)
  end

  @doc """
  Requests observer split with divergence budget check.

  ## Parameters
  - `observer_id`: The observer requesting to branch
  - `split_cost`: Estimated entropy cost of the split

  ## Returns
  - `:approved` — Split approved within budget
  - `:denied` — Split denied, ontological evaporation triggered
  """
  def request_observer_split(observer_id, split_cost) do
    GenServer.cast(__MODULE__, {:request_observer_split, observer_id, split_cost})
  end

  @doc """
  Reports paradox density update from CTN containment field.
  """
  def report_paradox_density(density_value) do
    GenServer.cast(__MODULE__, {:report_paradox_density, density_value})
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("⚖️ MSCL-Ω Kernel initialized (Phase 5F.5 Meta-Stability Layer)")

    # Start periodic monitoring
    timer = Process.send_after(self(), :run_stability_check, @monitoring_interval_ms)

    state = %__MODULE__{
      monitoring_timer: timer
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:validate_divergence, obs_a_id, obs_b_id}, _from, state) do
    # Compute causal divergence between observers
    divergence = compute_causal_divergence(obs_a_id, obs_b_id)

    result =
      cond do
        divergence > @divergence_threshold ->
          Logger.warning("⚠️ MSCL-Ω: Excess divergence detected between #{obs_a_id} and #{obs_b_id} (#{divergence |> :erlang.float_to_binary(decimals: 3)} > #{@divergence_threshold})")

          # Inject reconciliation anchors
          inject_reconciliation_anchor(obs_a_id, obs_b_id, divergence)

          # Update state
          updated_state = record_divergence(state, obs_a_id, obs_b_id, divergence)
          updated_state = increment_stabilizations(updated_state)

          {:reply, :stabilized, updated_state}

        divergence > @cdp_threshold ->
          Logger.info("📊 MSCL-Ω: Elevated CDP detected (#{divergence |> :erlang.float_to_binary(decimals: 3)})")

          updated_state = record_divergence(state, obs_a_id, obs_b_id, divergence)
          {:reply, :stable, updated_state}

        true ->
          updated_state = record_divergence(state, obs_a_id, obs_b_id, divergence)
          {:reply, :stable, updated_state}
      end

    result
  end

  @impl true
  def handle_call(:get_stability_metrics, _from, state) do
    metrics = %{
      global_paradox_density: state.global_paradox_density,
      causal_drift_pressure: state.causal_drift_pressure,
      active_stabilizations: length(state.active_stabilizations),
      monitored_observers: count_monitored_observers(state.observer_divergence_map),
      divergence_threshold: @divergence_threshold,
      cdp_threshold: @cdp_threshold
    }

    {:reply, {:ok, metrics}, state}
  end

  @impl true
  def handle_cast({:request_observer_split, observer_id, split_cost}, state) do
    projected_load = state.causal_drift_pressure + split_cost

    if projected_load > @divergence_threshold do
      Logger.warning("⚖️ [MSCL-Ω] Divergence Denied. Observer #{observer_id} lacks energy budget. Triggering Ontological Evaporation.")

      # Publish radiation event to trigger WebGL evaporation shader
      publish_evaporation_event(observer_id, split_cost)

      {:noreply, state}
    else
      Logger.info("🌌 [MSCL-Ω] Divergence Approved. Observer #{observer_id} branched.")

      updated_state = %{state | causal_drift_pressure: projected_load}
      {:noreply, updated_state}
    end
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state |
      observer_divergence_map: %{},
      global_paradox_density: 0.0,
      causal_drift_pressure: 0.0,
      active_stabilizations: []
    }}
  end

  @impl true
  def handle_cast({:report_paradox_density, density_value}, state) do
    updated_state = %{state | global_paradox_density: density_value}

    # Check if paradox density exceeds safe limits
    if density_value > @entropy_rebind_threshold do
      Logger.warning("🔥 [MSCL-Ω] Critical paradox density: #{density_value}. Initiating entropy rebinding.")
      initiate_entropy_rebinding(density_value)
    end

    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:run_stability_check, state) do
    # Periodic stability assessment
    Logger.debug("📡 [MSCL-Ω] Running periodic stability check...")

    # Recalculate causal drift pressure from divergence map
    updated_cdp = recalculate_causal_drift_pressure(state.observer_divergence_map)

    # Schedule next check
    timer = Process.send_after(self(), :run_stability_check, @monitoring_interval_ms)

    updated_state = %{state | causal_drift_pressure: updated_cdp, monitoring_timer: timer}

    {:noreply, updated_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp compute_causal_divergence(obs_a_id, obs_b_id) do
    # Get MEI frequencies for both observers
    mei_a = get_observer_mei(obs_a_id) || 1.618
    mei_b = get_observer_mei(obs_b_id) || 1.618

    # Calculate frequency-based divergence
    frequency_divergence = abs(mei_a - mei_b) / max(mei_a, mei_b)

    # Get memory entropy for both observers (from ChronogramMatrix stats)
    entropy_a = get_observer_memory_entropy(obs_a_id)
    entropy_b = get_observer_memory_entropy(obs_b_id)

    # Calculate entropy-based divergence
    entropy_divergence = abs(entropy_a - entropy_b)

    # Combined divergence metric (weighted average)
    divergence = (frequency_divergence * 0.4) + (entropy_divergence * 0.6)

    # Normalize to 0.0-1.0 range
    min(divergence, 1.0)
  end

  defp get_observer_mei(observer_id) do
    case ChronogramMatrix.get_observer_mei(observer_id) do
      {:ok, mei} -> mei
      {:error, :not_found} -> nil
    end
  end

  defp get_observer_memory_entropy(_observer_id) do
    # Placeholder: In production, would query ChronogramMatrix for observer-specific entropy
    # For now, return simulated value based on observer ID hash
    :rand.uniform() * 0.5
  end

  defp inject_reconciliation_anchor(obs_a_id, obs_b_id, divergence) do
    Logger.info("🔗 [MSCL-Ω] Injecting causal anchor between #{obs_a_id} and #{obs_b_id}")

    # Publish anchor injection event via NATS
    # In production, this would coordinate with OLEF and RODL layers
    anchor_data = %{
      observers: [obs_a_id, obs_b_id],
      anchor_type: "minimal_shared_causality",
      divergence_level: divergence,
      timestamp: DateTime.utc_now()
    }

    # TODO: Integrate with NATS telemetry system
    # Gnat.pub(:tiannara_nats, "tiannara.mscl.omega.anchor.inject", Jason.encode!(anchor_data))

    Logger.debug("📤 Anchor injection event: #{inspect(anchor_data)}")
  end

  defp publish_evaporation_event(observer_id, overflow_mass) do
    Logger.info("☄️ [MSCL-Ω] Publishing ontological evaporation for #{observer_id}")

    evaporation_data = %{
      target: observer_id,
      overflow_mass: overflow_mass,
      timestamp: DateTime.utc_now()
    }

    # TODO: Integrate with NATS telemetry system
    # Gnat.pub(:tiannara_nats, "tiannara.meta.mscl.evaporate", Jason.encode!(evaporation_data))

    Logger.debug("📤 Evaporation event: #{inspect(evaporation_data)}")
  end

  defp initiate_entropy_rebinding(density_value) do
    Logger.warning("🔄 [MSCL-Ω] Initiating entropy rebinding at density #{density_value}")

    # Inject weak invariants across high-density regions
    # This prevents complete semantic decoherence
    rebinding_data = %{
      action: :entropy_rebinding,
      target_density: density_value,
      invariant_type: "conserved_structural_relations",
      timestamp: DateTime.utc_now()
    }

    # TODO: Coordinate with ChronogramMatrix to inject shared anchors
    Logger.debug("📤 Rebinding event: #{inspect(rebinding_data)}")
  end

  defp record_divergence(state, obs_a_id, obs_b_id, divergence) do
    key = {min(obs_a_id, obs_b_id), max(obs_a_id, obs_b_id)}
    updated_map = Map.put(state.observer_divergence_map, key, divergence)

    %{state | observer_divergence_map: updated_map}
  end

  defp increment_stabilizations(state) do
    stabilization_id = "stab_#{System.unique_integer([:positive])}_#{System.system_time(:millisecond)}"
    updated_stabilizations = [stabilization_id | state.active_stabilizations]

    # Keep only last 100 stabilizations to prevent memory bloat
    trimmed = Enum.take(updated_stabilizations, 100)

    %{state | active_stabilizations: trimmed}
  end

  defp count_monitored_observers(divergence_map) do
    divergence_map
    |> Map.keys()
    |> Enum.flat_map(fn {a, b} -> [a, b] end)
    |> Enum.uniq()
    |> length()
  end

  defp recalculate_causal_drift_pressure(divergence_map) do
    if map_size(divergence_map) == 0 do
      0.0
    else
      # Average divergence across all observer pairs
      total_divergence = Map.values(divergence_map) |> Enum.sum()
      total_divergence / map_size(divergence_map)
    end
  end
end
