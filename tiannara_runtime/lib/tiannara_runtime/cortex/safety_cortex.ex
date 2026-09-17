defmodule TiannaraRuntime.Cortex.SafetyCortex do
  @moduledoc """
  PHASE 5 SAFETY CORTEX: Global Stability & Self-Regulation Layer
  
  Transforms KillSwitch from reactive termination into homeostatic regulation.
  
  ## Core Philosophy
  
  > "Nothing is 'unsafe'—only 'misaligned'. Instability is misdirected evolution pressure."
  
  ## Architecture (4-Layer Brain Structure)
  
      Layer 1: Predictive Instability Engine (nervous system - predicts failure)
      Layer 2: Regulation Engine (applies controls - dampen/smooth/reinforce)
      Layer 3: Recovery Engine (restores stable attractor states)
      Layer 4: Kill Arbitration (last-resort after all stabilization fails)
  
  ## Key Principles
  
  1. **Killing is forbidden** unless simulation-space integrity fails
  2. **Stability is a global budget**, not a rule (entropy/causal/evolutionary credits)
  3. **Everything passes through**: freeze → reroute → dampen → re-stabilize
  
  ## NATS Topics
  
      tiannara.cortex.world_metrics       # Incoming world state updates
      tiannara.cortex.regulation          # Applied interventions
      tiannara.cortex.freeze              # Freeze notifications
      tiannara.cortex.recovery            # Recovery actions
      tiannara.cortex.kill.arbitration    # Kill approval requests
  """

  use GenServer
  use TiannaraRuntime.Layer, authority: :constraint, can_call: [:ecology, :execution], can_receive: [:meta, :ecology, :execution]
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager
  alias TiannaraRuntime.Contracts.ConstraintSignal
  alias TiannaraRuntime.Contracts.MetaAdjustment

  # Risk thresholds for intervention routing
  @risk_stabilize_max 0.6
  @risk_regulate_max 0.85
  @risk_escalate_threshold 0.85

  # Prediction weights
  @weight_entropy_growth 0.4
  @weight_causal_breakage 0.3
  @weight_evolution_spike 0.3

  defstruct [
    world_states: %{},        # %{world_id => WorldSafetyState}
    risk_cache: %{},          # %{world_id => current_risk_score}
    intervention_log: [],     # [{timestamp, world_id, action}]
    stability_budget: %{      # Global credit pool
      entropy_credit: 1000.0,
      causal_credit: 1000.0,
      evolutionary_credit: 1000.0
    }
  ]

  @type world_safety_state :: %{
    world_id: String.t(),
    entropy_pressure: float(),
    causal_stability: float(),
    evolutionary_velocity: float(),
    kill_risk: float(),
    freeze_risk: float(),
    stability_credit: float(),
    paradox_load: float(),
    prediction_horizon_ms: integer()
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Submit world metrics for continuous safety monitoring.
  
  Triggers predictive analysis and automatic intervention routing.
  
  ## Example
  
      SafetyCortex.submit_metrics("W1", %{
        entropy_pressure: 0.72,
        causal_stability: 0.85,
        evolutionary_velocity: 1.3
      })
  """
  def submit_metrics(world_id, metrics) do
    GenServer.cast(__MODULE__, {:world_metrics, world_id, metrics})
  end

  @doc """
  Handle risk assessment from ImmuneCortex (Phase 5E integration point).
  
  This is the bridge between predictive risk scoring and regulatory action.
  
  ## Actions
  
      :normal   → No intervention needed
      :regulate → Apply entropy dampening / field smoothing
      :escalate → Freeze world + consensus review
  """
  def handle_world_risk(world_id, risk_score, action) do
    GenServer.cast(__MODULE__, {:immune_assessment, world_id, risk_score, action})
  end

  @doc """
  Request emergency escalation for critically unstable world.
  
  Bypasses normal regulation and triggers immediate freeze.
  """
  def request_escalation(world_id, reason) do
    GenServer.cast(__MODULE__, {:emergency_escalation, world_id, reason})
  end

  @doc """
  Get current risk assessment for a world.
  
  ## Returns
    
      {:ok, risk_score} where 0.0 = safe, 1.0 = critical
  """
  def get_risk(world_id) do
    GenServer.call(__MODULE__, {:get_risk, world_id})
  end

  @doc """
  Retrieve intervention history for forensic analysis.
  
  ## Returns
    
      [{timestamp, world_id, action_type, details}]
  """
  def get_intervention_log(limit \\ 50) do
    GenServer.call(__MODULE__, {:get_intervention_log, limit})
  end

  @impl true
  def init(_opts) do
    Logger.info("🧠 TiannaraRuntime.SafetyCortex initialized (4-layer regulatory system)")
    Logger.info("   Stabilization threshold: ≤ #{@risk_stabilize_max}")
    Logger.info("   Regulation range: #{@risk_stabilize_max} - #{@risk_regulate_max}")
    Logger.info("   Escalation threshold: > #{@risk_escalate_threshold}")

    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:world_metrics, world_id, metrics}, state) do
    # Layer 1: Predict instability
    risk = predict_instability(metrics)

    # Update state
    new_state =
      state
      |> put_in([:risk_cache, world_id], risk)
      |> update_world_state(world_id, metrics, risk)

    # Layer 2-4: Route to appropriate intervention
    routed_state = route_intervention(new_state, world_id, metrics, risk)

    {:noreply, routed_state}
  end

  @impl true
  def handle_cast({:immune_assessment, world_id, risk_score, action}, state) do
    # Handle risk assessment from ImmuneCortex
    Logger.debug("🛡️  ImmuneCortex assessment: #{world_id} risk=#{risk_score} action=#{action}")

    # Update risk cache
    new_state = put_in(state.risk_cache[world_id], risk_score)

    # Take action based on ImmuneCortex recommendation
    case action do
      :regulate ->
        # Layer 2: Apply regulation
        regulate_world(world_id, risk_score)
        log_intervention(new_state, world_id, :immune_regulation, %{risk: risk_score})

      :escalate ->
        # Layer 4: Escalate to freeze
        freeze_world(world_id, :immune_escalation)
        log_intervention(new_state, world_id, :immune_freeze, %{risk: risk_score})

      :normal ->
        # No action needed
        new_state
    end
  end

  @impl true
  def handle_cast({:emergency_escalation, world_id, reason}, state) do
    Logger.error("🚨 Emergency escalation for #{world_id}: #{reason}")

    # Immediate freeze without prediction
    freeze_world(world_id, :emergency_escalation)

    # Log intervention
    new_log = [{DateTime.utc_now(), world_id, :emergency_freeze, reason} | state.intervention_log]

    {:noreply, %{state | intervention_log: Enum.take(new_log, 100)}}
  end

  @impl true
  def handle_cast({:meta_adjustment, %MetaAdjustment{} = adjustment}, state) do
    # Meta input is treated as advisory parameter envelope, not direct world mutation.
    new_log = [{DateTime.utc_now(), "global", :meta_adjustment, Map.from_struct(adjustment)} | state.intervention_log]
    {:noreply, %{state | intervention_log: Enum.take(new_log, 100)}}
  end

  @impl true
  def handle_call({:get_risk, world_id}, _from, state) do
    risk = Map.get(state.risk_cache, world_id, 0.0)
    {:reply, {:ok, risk}, state}
  end

  @impl true
  def handle_call({:get_intervention_log, limit}, _from, state) do
    log = Enum.take(state.intervention_log, limit)
    {:reply, {:ok, log}, state}
  end

  # ============================================================================
  # Layer 1: Predictive Instability Engine
  # ============================================================================

  defp predict_instability(metrics) do
    # Calculate entropy growth rate (derivative approximation)
    entropy_growth = Map.get(metrics, :entropy_growth_rate, 0.0)

    # Check for causal breakage
    causal_stability = Map.get(metrics, :causal_stability, 1.0)
    causal_breakage = if causal_stability < 0.4, do: 1.0, else: 0.0

    # Detect evolution velocity spikes
    evolution_velocity = Map.get(metrics, :evolutionary_velocity, 0.0)
    evolution_spike = min(evolution_velocity / 3.0, 1.0)

    # Weighted risk calculation
    risk =
      @weight_entropy_growth * entropy_growth +
      @weight_causal_breakage * causal_breakage +
      @weight_evolution_spike * evolution_spike

    # Clamp to [0.0, 1.0]
    max(0.0, min(1.0, risk))
  end

  # ============================================================================
  # Intervention Router (Layers 2-4)
  # ============================================================================

  defp route_intervention(state, world_id, metrics, risk) do
    cond do
      risk > @risk_escalate_threshold ->
        escalate(state, world_id, risk)

      risk > @risk_stabilize_max ->
        regulate(state, world_id, risk)

      true ->
        stabilize(state, world_id)
    end
  end

  # ============================================================================
  # Layer 4: Escalation (Freeze + Kill Arbitration)
  # ============================================================================

  defp escalate(state, world_id, risk) do
    Logger.warning("⚠️  Safety Cortex escalation: #{world_id} (risk: #{Float.round(risk, 3)})")

    # Freeze world execution
    freeze_world(world_id, :cortex_escalation)
    emit_constraint_signal(%ConstraintSignal{
      source: :safety_cortex,
      target_layer: :ecology,
      quarantine: true,
      branch_limit: 0
    })

    # Publish escalation event
    MetaEvolutionStreamManager.publish_cortex_event(%{
      world_id: world_id,
      event: :escalation,
      risk: risk,
      action: :freeze,
      timestamp: DateTime.utc_now()
    })

    # Log intervention
    new_log = [{DateTime.utc_now(), world_id, :escalation_freeze, "risk=#{risk}"} | state.intervention_log]

    %{state | intervention_log: Enum.take(new_log, 100)}
  end

  # ============================================================================
  # Layer 2: Regulation Engine (Entropy Damping, Field Smoothing)
  # ============================================================================

  defp regulate(state, world_id, risk) do
    Logger.info("🔧 Safety Cortex regulation: #{world_id} (risk: #{Float.round(risk, 3)})")

    # Determine regulation strength based on risk level
    regulation_strength = calculate_regulation_strength(risk)

    # Apply entropy damping
    apply_entropy_dampening(world_id, regulation_strength)
    emit_constraint_signal(%ConstraintSignal{
      source: :safety_cortex,
      target_layer: :execution,
      execution_throttle: max(0.1, 1.0 - regulation_strength)
    })

    # Publish regulation event
    MetaEvolutionStreamManager.publish_cortex_event(%{
      world_id: world_id,
      event: :regulation,
      risk: risk,
      action: :entropy_dampening,
      strength: regulation_strength,
      timestamp: DateTime.utc_now()
    })

    # Log intervention
    new_log = [{DateTime.utc_now(), world_id, :regulation, "strength=#{regulation_strength}"} | state.intervention_log]

    %{state | intervention_log: Enum.take(new_log, 100)}
  end

  defp calculate_regulation_strength(risk) do
    # Linear mapping: risk 0.6 → strength 0.3, risk 0.85 → strength 0.8
    normalized = (risk - @risk_stabilize_max) / (@risk_escalate_threshold - @risk_stabilize_max)
    0.3 + (normalized * 0.5)
  end

  defp apply_entropy_dampening(world_id, strength) do
    # Send regulation command via NATS to world runtime
    MetaEvolutionStreamManager.publish_regulation_command(%{
      world_id: world_id,
      action: :entropy_dampening,
      strength: strength
    })

    Logger.debug("   Applied entropy dampening (strength: #{Float.round(strength, 2)})")
  end

  defp emit_constraint_signal(%ConstraintSignal{} = signal) do
    target =
      case signal.target_layer do
        :execution -> :execution
        :ecology -> :ecology
      end

    TiannaraRuntime.Layer.assert_call!(:constraint, target)

    MetaEvolutionStreamManager.publish_cortex_event(%{
      event: :constraint_signal,
      source: signal.source,
      target_layer: signal.target_layer,
      entropy_floor: signal.entropy_floor,
      mutation_ceiling: signal.mutation_ceiling,
      branch_limit: signal.branch_limit,
      execution_throttle: signal.execution_throttle,
      quarantine: signal.quarantine,
      timestamp: DateTime.utc_now()
    })
  end

  # ============================================================================
  # Layer 3: Stabilization (Passive Monitoring)
  # ============================================================================

  defp stabilize(state, world_id) do
    # No intervention needed - world is within safe parameters
    # Optionally publish heartbeat for monitoring
    Logger.debug("✅ World #{world_id} stabilized (no intervention required)")

    state
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp freeze_world(world_id, reason) do
    Logger.info("❄️  Freezing world #{world_id} (reason: #{reason})")

    # Send freeze message to HardenedKillSwitch
    send(TiannaraRuntime.MultiWorld.HardenedKillSwitch, {:freeze_request, world_id, reason})

    # Also notify WorldSupervisor if available
    try do
      send(TiannaraRuntime.MultiWorld.WorldSupervisor, {:freeze_world, world_id})
    rescue
      _ -> Logger.warning("WorldSupervisor not available for freeze notification")
    end
  end

  defp update_world_state(state, world_id, metrics, risk) do
    # Create or update world safety state
    safety_state = %{
      world_id: world_id,
      entropy_pressure: Map.get(metrics, :entropy_pressure, 0.0),
      causal_stability: Map.get(metrics, :causal_stability, 1.0),
      evolutionary_velocity: Map.get(metrics, :evolutionary_velocity, 0.0),
      kill_risk: if(risk > 0.9, do: 1.0, else: 0.0),
      freeze_risk: if(risk > 0.7, do: risk, else: 0.0),
      stability_credit: Map.get(metrics, :stability_credit, 100.0),
      paradox_load: Map.get(metrics, :paradox_load, 0.0),
      prediction_horizon_ms: Map.get(metrics, :prediction_horizon_ms, 5000)
    }

    put_in(state.world_states[world_id], safety_state)
  end

  defp regulate_world(world_id, risk) do
    # Layer 2: Apply regulation (simplified for Phase 5E)
    Logger.info("🔧 Regulating world #{world_id} (risk: #{Float.round(risk, 3)})")

    regulation_strength = calculate_regulation_strength(risk)

    # Apply entropy dampening
    apply_entropy_dampening(world_id, regulation_strength)
  end

  defp log_intervention(state, world_id, action_type, details) do
    # Log intervention to state
    new_log = [{DateTime.utc_now(), world_id, action_type, details} | state.intervention_log]
    %{state | intervention_log: Enum.take(new_log, 100)}
  end
end
