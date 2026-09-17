defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.MetricsEngine do
  @moduledoc """
  Phase 17.7.6 — Civilization Metrics Engine.
  Computes reproducible civilization metrics from the twin state.
  Covers economic, scientific, infrastructure, governance, ecological, energy, logistics, medical, knowledge, readiness.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.TwinMetrics

  def compute(twin_state) do
    metrics = %TwinMetrics{
      metrics_id: nil,
      tick: twin_state.tick,
      economic_output: compute_economic(twin_state),
      scientific_productivity: compute_scientific(twin_state),
      infrastructure_health: compute_infrastructure(twin_state),
      governance_stability: compute_governance(twin_state),
      ecological_resilience: compute_ecological(twin_state),
      energy_efficiency: compute_energy(twin_state),
      logistics_performance: compute_logistics(twin_state),
      medical_outcomes: compute_medical(twin_state),
      knowledge_growth: compute_knowledge(twin_state),
      civilization_readiness: compute_readiness(twin_state)
    }

    compute_id(metrics)
  end

  def compute_readiness(twin_state) do
    metrics = [
      compute_economic(twin_state),
      compute_scientific(twin_state),
      compute_infrastructure(twin_state),
      compute_governance(twin_state),
      compute_ecological(twin_state)
    ]

    valid = Enum.filter(metrics, &(!is_nil(&1)))
    if valid == [], do: 0.5, else: Enum.sum(valid) / length(valid)
  end

  def compute_economic(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["gdp", "output", "production"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_scientific(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["research_output", "publications", "discoveries"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_infrastructure(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["infrastructure_health", "infra_health", "infrastructure"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_governance(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["governance_stability", "stability", "governance"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_ecological(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["ecological_resilience", "eco_health", "biodiversity"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_energy(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["energy_efficiency", "energy_output", "efficiency"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_logistics(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["logistics_performance", "logistics", "throughput"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_medical(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["medical_outcomes", "health", "mortality"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  def compute_knowledge(state) do
    model_states = state.model_states || %{}
    values = extract_metric_values(model_states, ["knowledge_growth", "knowledge", "research"])
    if values == [], do: 0.5, else: Enum.sum(values) / length(values)
  end

  defp extract_metric_values(model_states, keys) do
    Enum.flat_map(model_states, fn {_model_id, model_state} ->
      Enum.flat_map(keys, fn key ->
        case Map.get(model_state, key) do
          nil -> []
          v when is_number(v) -> [normalize(v)]
          _ -> []
        end
      end)
    end)
  end

  defp normalize(v) when v >= 0 and v <= 1, do: v
  defp normalize(v) when v > 1, do: min(v / 100.0, 1.0)
  defp normalize(v) when v < 0, do: 0.0

  defp compute_id(metrics) do
    canonical = %{
      tick: metrics.tick,
      economic_output: metrics.economic_output,
      scientific_productivity: metrics.scientific_productivity,
      infrastructure_health: metrics.infrastructure_health,
      governance_stability: metrics.governance_stability,
      ecological_resilience: metrics.ecological_resilience,
      energy_efficiency: metrics.energy_efficiency,
      logistics_performance: metrics.logistics_performance,
      medical_outcomes: metrics.medical_outcomes,
      knowledge_growth: metrics.knowledge_growth,
      civilization_readiness: metrics.civilization_readiness
    }

    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    %{metrics | metrics_id: "tm_" <> hash}
  end
end
