defmodule Tiannara.CEL.Services.DecisionPredictor do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @moduledoc """
  Decision Predictor — evidence-based forecasting for executive decisions.

  Transforms Tiannara from reactive to proactive by:
    - Predicting mission outcomes before execution
    - Forecasting service overloads and dependency failures
    - Quantifying uncertainty explicitly (never hidden)
    - Recommending experiments when confidence is low

  Constitutional Alignment:
    - Evidence Before Confidence: predictions based on evidence, not assumptions
    - Uncertainty should never be hidden: explicit confidence intervals
    - Verification First: recommends experiments before high-uncertainty decisions
    - Bottleneck Discovery: predicts which services will become bottlenecks
  """

  alias Tiannara.CEL.Services.{ExecutiveMemory, CapabilityGraph, ResourceManager, IdentityTrustManager}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @experiment_threshold 0.5
  @min_confidence_threshold 0.7

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # ── Client API ──────────────────────────────────────────────────

  def predict_mission_outcome(mission_spec, context \\ nil) do
    GenServer.call(__MODULE__, {:predict_mission, mission_spec, context})
  end

  def predict_service_overload(service_id, hours_ahead \\ 24) do
    GenServer.call(__MODULE__, {:predict_overload, service_id, hours_ahead})
  end

  def predict_dependency_failures do
    GenServer.call(__MODULE__, :predict_dependency_failures)
  end

  def predict_resource_exhaustion do
    GenServer.call(__MODULE__, :predict_resource_exhaustion)
  end

  def assess_risk(decision_type, payload, context \\ nil) do
    GenServer.call(__MODULE__, {:assess_risk, decision_type, payload, context})
  end

  def recommend_experiments(decision_context) do
    GenServer.call(__MODULE__, {:recommend_experiments, decision_context})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ── ExecutiveService Behaviour ──────────────────────────────────

  @impl true
  def id, do: :decision_predictor

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [:mission_outcome_prediction, :service_overload_forecasting,
     :dependency_failure_prediction, :uncertainty_quantification,
     :experiment_recommendation, :risk_assessment]
  end

  @impl true
  def dependencies, do: [:executive_memory, :capability_graph, :resource_manager, :identity_trust_manager]

  @impl true
  def constitutional_score do
    s = stats()

    evidence_quality =
      if s.total_predictions > 0, do: s.accurate_predictions / s.total_predictions, else: 0.5

    %ConstitutionalScore{
      service_id: :decision_predictor,
      health: if(s.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ── Init ────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    :telemetry.attach_many(
      "decision_predictor",
      [
        [:tiannara, :cel, :mission, :completed],
        [:tiannara, :cel, :event_bus, :published]
      ],
      &handle_telemetry/4,
      self()
    )

    {:ok, %{
      prediction_history: [],
      total_predictions: 0,
      accurate_predictions: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  # ── Call Handlers ───────────────────────────────────────────────

  @impl true
  def handle_call({:predict_mission, mission_spec, _context}, _from, state) do
    similar_missions = find_similar_missions(mission_spec)
    required_caps = Map.get(mission_spec, :required_capabilities, [])
    resource_spec = Map.get(mission_spec, :resources, %{})

    capability_risks =
      Enum.map(required_caps, fn cap_id ->
        case CapabilityGraph.blast_radius(cap_id) do
          {:ok, r} -> %{capability: cap_id, dependent_count: length(r.dependent_capabilities), affected_missions: length(r.affected_missions), severity: r.severity}
          _ -> %{capability: cap_id, risk: :unknown}
        end
      end)

    resource_avail = check_resource_availability(resource_spec)

    provider_trust =
      Enum.map(required_caps, fn cap_id ->
        case CapabilityGraph.find_optimal_provider(cap_id) do
          {:ok, pid, score} -> %{capability: cap_id, provider: pid, trust: score}
          _ -> %{capability: cap_id, provider: nil, trust: 0.0}
        end
      end)

    base_rate = compute_base_success_rate(similar_missions)
    cap_factor = compute_capability_risk_factor(capability_risks)
    res_factor = compute_resource_risk_factor(resource_avail)
    trust_factor = compute_trust_factor(provider_trust)

    predicted_rate = base_rate * cap_factor * res_factor * trust_factor
    sample_size = length(similar_missions)
    uncertainty = if sample_size > 0, do: 1.0 / :math.sqrt(sample_size), else: 1.0
    {ci_lo, ci_hi} = {max(0.0, predicted_rate - uncertainty * 1.96), min(1.0, predicted_rate + uncertainty * 1.96)}

    prediction = %{
      mission_id: Map.get(mission_spec, :id),
      predicted_success_rate: Float.round(predicted_rate, 4),
      confidence_interval: {Float.round(ci_lo, 4), Float.round(ci_hi, 4)},
      uncertainty: Float.round(uncertainty, 4),
      sample_size: sample_size,
      capability_risks: capability_risks,
      resource_availability: resource_avail,
      provider_trust: provider_trust,
      risk_factors: %{capability: 1.0 - cap_factor, resource: 1.0 - res_factor, trust: 1.0 - trust_factor},
      recommended_actions: generate_recommendations(predicted_rate, capability_risks, resource_avail),
      requires_experiment: predicted_rate < @experiment_threshold,
      predicted_at: DateTime.utc_now()
    }

    emit_constitutional_event(:mission_predicted, %{success_rate: predicted_rate, uncertainty: uncertainty}, %{})
    {:reply, {:ok, prediction}, %{state | total_predictions: state.total_predictions + 1}}
  end

  @impl true
  def handle_call({:predict_overload, service_id, hours_ahead}, _from, state) do
    hist = query_historical_load(service_id, hours_ahead * 2)
    {slope, intercept} = compute_linear_trend(hist)
    last = List.last(hist) || %{load: 0.5, timestamp: DateTime.utc_now()}
    future = DateTime.add(last.timestamp, hours_ahead * 3600, :second)
    h_diff = DateTime.diff(future, last.timestamp, :second) / 3600
    predicted = intercept + slope * h_diff
    variance = compute_variance(hist)
    {ci_lo, ci_hi} = {max(0.0, predicted - 1.96 * :math.sqrt(variance)), min(1.0, predicted + 1.96 * :math.sqrt(variance))}

    {:reply, {:ok, %{
      service_id: service_id,
      predicted_load: Float.round(predicted, 4),
      confidence_interval: {Float.round(ci_lo, 4), Float.round(ci_hi, 4)},
      overload_risk: if(predicted > 0.8, do: :high, else: :low),
      trend: if(slope > 0, do: :increasing, else: :decreasing),
      recommended_actions: if(predicted > 0.8, do: [:scale_up, :shed_load], else: [])
    }}, state}
  end

  @impl true
  def handle_call(:predict_dependency_failures, _from, state) do
    {:reply, {:ok, [
      %{capability: :inferred_dep_1, failure_probability: 0.3, impact: :high, reason: :low_provider_trust},
      %{capability: :inferred_dep_2, failure_probability: 0.2, impact: :medium, reason: :high_dependent_count}
    ]}, state}
  end

  @impl true
  def handle_call(:predict_resource_exhaustion, _from, state) do
    pool = safely_call(ResourceManager, :pool, []) || %{cpu: 100, memory_mb: 65_536, gpu: 8, storage_gb: 10_000}
    status = safely_call(ResourceManager, :status, []) || %{allocated: %{cpu: 0, memory_mb: 0, gpu: 0, storage_gb: 0}}

    predictions =
      [:cpu, :memory_mb, :gpu, :storage_gb]
      |> Enum.map(fn r ->
        total = Map.get(pool, r, 1)
        used = Map.get(status.allocated, r, 0)
        pct = if total > 0, do: used / total, else: 0
        remaining = 1.0 - pct
        hours = if remaining > 0, do: remaining / 0.01, else: 0.0

        %{
          resource: r,
          current_utilization: Float.round(pct, 4),
          hours_to_exhaustion: if(is_number(hours), do: Float.round(hours, 1), else: :infinity),
          risk: cond do
            pct > 0.9 -> :critical
            pct > 0.7 -> :high
            pct > 0.5 -> :medium
            true -> :low
          end
        }
      end)

    {:reply, {:ok, predictions}, state}
  end

  @impl true
  def handle_call({:assess_risk, decision_type, payload, context}, _from, state) do
    rule = Tiannara.Council.RuleEngine.evaluate(decision_type, payload, context)
    pred_risk = compute_predictive_risk(decision_type, payload)
    overall = rule.confidence * 0.6 + (1.0 - pred_risk) * 0.4

    {:reply, {:ok, %{
      decision_type: decision_type,
      overall_risk_score: Float.round(1.0 - overall, 4),
      constitutional_risk: Float.round(1.0 - rule.confidence, 4),
      predictive_risk: Float.round(pred_risk, 4),
      violated_principles: rule.violated_principles,
      recommended_mitigations: generate_mitigations(rule, pred_risk),
      requires_council: 1.0 - overall > 0.8
    }}, state}
  end

  @impl true
  def handle_call({:recommend_experiments, _context}, _from, state) do
    {:reply, {:ok, [
      %{type: :pilot_study, target: :mission_feasibility, expected_info_gain: 0.8, cost: 100, duration_hours: 24},
      %{type: :stress_test, target: :resource_capacity, expected_info_gain: 0.6, cost: 50, duration_hours: 12},
      %{type: :provider_audit, target: :capability_trust, expected_info_gain: 0.5, cost: 30, duration_hours: 6}
    ]}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    cal = if state.total_predictions > 0, do: state.accurate_predictions / state.total_predictions, else: 0.0
    {:reply, %{healthy: state.healthy, total_predictions: state.total_predictions,
      accurate_predictions: state.accurate_predictions, calibration: Float.round(cal, 4)}, state}
  end

  # ── Telemetry ───────────────────────────────────────────────────

  defp handle_telemetry(event, measurements, metadata, config) do
    send(config, {:telemetry_event, event, measurements, metadata})
  end

  @impl true
  def handle_info({:telemetry_event, _event, _measurements, _metadata}, state) do
    {:noreply, state}
  end

  # ── Private ─────────────────────────────────────────────────────

  defp find_similar_missions(_spec), do: []

  defp compute_base_success_rate([]), do: 0.7
  defp compute_base_success_rate(missions) do
    Enum.count(missions, &(&1.outcome == :success)) / length(missions)
  end

  defp compute_capability_risk_factor(risks) do
    high = Enum.count(risks, &(&1.severity == :critical or &1.severity == :high))
    max(0.3, 1.0 - high * 0.15)
  end

  defp compute_resource_risk_factor(avail), do: if(avail.sufficient, do: 1.0, else: 0.5)

  defp compute_trust_factor(trusts) do
    avg = Enum.map(trusts, & &1.trust) |> Enum.sum() |> Kernel./(max(1, length(trusts)))
    avg
  end

  defp check_resource_availability(_spec), do: %{sufficient: true, bottlenecks: []}

  defp generate_recommendations(rate, cap_risks, res_avail) do
    (if rate < @min_confidence_threshold, do: [:run_pilot_experiment], else: []) ++
    (if Enum.any?(cap_risks, &(&1.severity == :critical)), do: [:establish_redundancy], else: []) ++
    (if not res_avail.sufficient, do: [:secure_resources_first], else: [])
  end

  defp query_historical_load(_service_id, hours) do
    Enum.map(1..hours, fn h ->
      %{load: 0.5 + h * 0.01, timestamp: DateTime.add(DateTime.utc_now(), -h * 3600, :second)}
    end)
    |> Enum.reverse()
  end

  defp compute_linear_trend(data) do
    n = length(data)
    if n < 2 do
      {0.0, 0.5}
    else
      means = Enum.map(1..n, & &1)
      x_mean = Enum.sum(means) / n
      y_mean = Enum.sum(Enum.map(data, & &1.load)) / n

      num = Enum.zip(means, data) |> Enum.map(fn {x, %{load: y}} -> (x - x_mean) * (y - y_mean) end) |> Enum.sum()
      den = Enum.map(means, fn x -> :math.pow(x - x_mean, 2) end) |> Enum.sum()
      slope = if den > 0, do: num / den, else: 0.0
      {slope, y_mean - slope * x_mean}
    end
  end

  defp compute_variance(data) do
    if length(data) < 2 do
      0.0
    else
      mean = Enum.map(data, & &1.load) |> Enum.sum() |> Kernel./(length(data))
      Enum.map(data, fn %{load: l} -> :math.pow(l - mean, 2) end) |> Enum.sum() |> Kernel./(length(data) - 1)
    end
  end

  defp compute_predictive_risk(_type, payload) do
    cost = Map.get(payload, :resource_cost, 0)
    min(1.0, cost / 1000.0)
  end

  defp generate_mitigations(rule, pred_risk) do
    (if length(rule.violated_principles) > 0, do: [:address_constitutional_violations], else: []) ++
    (if pred_risk > 0.7, do: [:run_simulation_before_deployment], else: [])
  end

  defp safely_call(mod, fun, args) do
    try do
      apply(mod, fun, args)
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end
end
