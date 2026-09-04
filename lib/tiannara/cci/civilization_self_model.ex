defmodule Tiannara.CCI.CivilizationSelfModel do
  @moduledoc """
  Civilization Self-Model (CSM): continuously updated model of Tiannara civilization.
  Answers:
    - Current state: "What exists?"
    - Causal state: "Why does it exist?"
    - Future state: "What happens next?"
  """
  use GenServer
  alias Tiannara.CCI.Models.CivilizationState

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def update_state(pid, new_data), do: GenServer.cast(pid, {:update, new_data})
  def explain_cause(pid, aspect), do: GenServer.call(pid, {:explain, aspect})
  def predict_aspect(pid, aspect, horizon), do: GenServer.call(pid, {:predict, aspect, horizon})

  @impl true
  def init(_) do
    {:ok, %{
      current_state: build_initial_state(),
      causal_model: %{},
      history: [],
      last_updated: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.current_state, state}
  end

  @impl true
  def handle_cast({:update, new_data}, state) do
    updated_state = merge_state(state.current_state, new_data)
    causal = infer_causal_links(updated_state, state.causal_model)
    history_entry = %{timestamp: DateTime.utc_now(), state_snapshot: updated_state}

    new_state = %{state |
      current_state: updated_state,
      causal_model: causal,
      history: [history_entry | state.history] |> Enum.take(1000),
      last_updated: DateTime.utc_now()
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:explain, aspect}, _from, state) do
    explanation = generate_explanation(aspect, state.current_state, state.causal_model)
    {:reply, explanation, state}
  end

  @impl true
  def handle_call({:predict, aspect, horizon}, _from, state) do
    prediction = project_forward(aspect, horizon, state.current_state, state.causal_model, state.history)
    {:reply, prediction, state}
  end

  defp build_initial_state do
    %CivilizationState{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      knowledge_state: %{validated_assets: 0, pending_validation: 0, principles: 0},
      capability_state: %{emerging: 0, promoted: 0, obsolete: 0},
      research_state: %{active_programs: 0, completed: 0, failed: 0},
      technological_state: %{mature: 0, experimental: 0},
      institutional_state: %{active: 0, forming: 0, declining: 0},
      resource_state: %{available: 1000, allocated: 0, reserved: 0},
      risk_state: %{critical: 0, elevated: 0, nominal: 0},
      uncertainty_state: %{known_unknowns: 0, unknown_unknowns: 0},
      confidence: 0.5,
      health_score: 0.7
    }
  end

  defp merge_state(current, new_data) do
    current
    |> Map.merge(new_data, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: Map.merge(v1, v2), else: v2
    end)
    |> Map.put(:timestamp, DateTime.utc_now())
    |> recalculate_health()
  end

  defp recalculate_health(%CivilizationState{} = state) do
    knowledge_health = min(1.0, state.knowledge_state.validated_assets / 100)
    capability_health = min(1.0, state.capability_state.promoted / 50)
    institutional_health = min(1.0, state.institutional_state.active / 10)
    risk_penalty = state.risk_state.critical * 0.1 + state.risk_state.elevated * 0.05

    health = (knowledge_health * 0.3 + capability_health * 0.3 + institutional_health * 0.4) - risk_penalty
    %{state | health_score: max(0.0, min(1.0, health))}
  end

  defp infer_causal_links(_state, existing_causal) do
    Map.put(existing_causal, :last_inference, DateTime.utc_now())
  end

  defp generate_explanation(aspect, state, _causal) do
    %{
      aspect: aspect,
      current_value: Map.get(state, aspect),
      causal_factors: identify_causal_factors(aspect, state),
      confidence: 0.75,
      evidence_sources: [:reality_graph, :asc_metrics, :sentinel_observations]
    }
  end

  defp identify_causal_factors(_aspect, _state), do: [:historical_patterns, :resource_constraints, :selection_pressures]

  defp project_forward(aspect, horizon, state, _causal, history) do
    trend = calculate_trend(aspect, history)
    %{
      aspect: aspect,
      horizon_cycles: horizon,
      projected_value: apply_trend(Map.get(state, aspect), trend, horizon),
      confidence: 0.6,
      uncertainty_range: calculate_uncertainty(trend, horizon),
      assumptions: [:stable_resources, :no_external_shocks, :continuing_selection_pressures]
    }
  end

  defp calculate_trend(_aspect, history) when length(history) < 2, do: 0.0
  defp calculate_trend(aspect, [recent, previous | _]) do
    recent_val = get_in(recent.state_snapshot, [aspect]) || 0
    previous_val = get_in(previous.state_snapshot, [aspect]) || 0
    recent_val - previous_val
  end

  defp apply_trend(current, trend, horizon), do: current + trend * horizon
  defp calculate_uncertainty(trend, horizon), do: abs(trend) * horizon * 0.2
end
