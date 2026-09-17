defmodule TiannaraRuntime.Cortex.ImmuneCortex do
  @moduledoc """
  Minimal Phase 5E Immune Cortex
  
  Continuous risk scoring engine that monitors world health metrics
  and triggers regulatory responses before instability becomes critical.
  
  ## Purpose
  
  Replaces reactive kill logic with predictive risk assessment:
  - Computes weighted instability field per world
  - Triggers SafetyCortex regulation when risk exceeds thresholds
  - Records all assessments to EventStore for audit trail
  
  ## Risk Calculation
  
      risk = 0.4 * entropy + 0.3 * cascade_rate + 0.3 * divergence
  
  ## Thresholds
  
      risk < 0.6  → :normal (no action)
      0.6 ≤ risk < 0.85  → :regulated (apply dampening)
      risk ≥ 0.85  → :escalated (freeze + SafetyCortex review)
  
  ## Usage
  
      ImmuneCortex.assess_risk("world_123", %{
        entropy: 0.7,
        cascade_rate: 0.4,
        divergence: 0.5
      })
  """

  use GenServer

  @risk_threshold_regulate 0.6
  @risk_threshold_escalate 0.85

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Mix.shell().info("🛡️  ImmuneCortex initialized (risk assessment engine)")

    {:ok, %{assessments: 0, worlds_monitored: MapSet.new()}}
  end

  @doc """
  Assess risk for a world based on current metrics.
  
  Returns risk score (0.0-1.0) and recommended action.
  """
  def assess_risk(world_id, metrics) do
    GenServer.call(__MODULE__, {:assess_risk, world_id, metrics})
  end

  @doc """
  Get current risk score for a world.
  """
  def get_risk_score(world_id) do
    GenServer.call(__MODULE__, {:get_risk_score, world_id})
  end

  @doc """
  Get all monitored world IDs.
  """
  def get_monitored_worlds do
    GenServer.call(__MODULE__, :get_monitored_worlds)
  end

  # ----------------------------
  # GenServer callbacks
  # ----------------------------

  @impl true
  def handle_call({:assess_risk, world_id, metrics}, _from, state) do
    # Calculate weighted risk score
    risk = compute_risk(metrics)

    # Determine action based on thresholds
    action = determine_action(risk)

    # Record assessment to EventStore
    TiannaraRuntime.MultiWorld.Events.EventStore.record_event(
      :world_risk_assessed,
      %{
        world_id: world_id,
        risk_score: risk,
        action: action,
        metrics: metrics
      }
    )

    # Trigger SafetyCortex if needed
    if action in [:regulate, :escalate] do
      trigger_safety_cortex(world_id, risk, action)
    end

    # Update state
    new_state = %{
      state
      | assessments: state.assessments + 1,
        worlds_monitored: MapSet.put(state.worlds_monitored, world_id)
    }

    {:reply, %{risk_score: risk, action: action}, new_state}
  end

  @impl true
  def handle_call({:get_risk_score, world_id}, _from, state) do
    # For now, return cached risk or nil
    # In full implementation, this would query a risk cache
    {:reply, nil, state}
  end

  @impl true
  def handle_call(:get_monitored_worlds, _from, state) do
    {:reply, MapSet.to_list(state.worlds_monitored), state}
  end

  # ----------------------------
  # Private functions
  # ----------------------------

  defp compute_risk(%{entropy: entropy, cascade_rate: cascade, divergence: divergence}) do
    # Weighted instability field
    0.4 * normalize(entropy) +
    0.3 * normalize(cascade) +
    0.3 * normalize(divergence)
  end

  defp compute_risk(_metrics) do
    # Default risk if metrics incomplete
    0.5
  end

  defp normalize(value) when is_number(value) do
    # Clamp to [0.0, 1.0]
    max(0.0, min(1.0, value))
  end

  defp normalize(_), do: 0.5

  defp determine_action(risk) do
    cond do
      risk >= @risk_threshold_escalate ->
        :escalate

      risk >= @risk_threshold_regulate ->
        :regulate

      true ->
        :normal
    end
  end

  defp trigger_safety_cortex(world_id, risk, action) do
    # Notify SafetyCortex via cast (async, non-blocking)
    TiannaraRuntime.Cortex.SafetyCortex.handle_world_risk(world_id, risk, action)
  end
end
