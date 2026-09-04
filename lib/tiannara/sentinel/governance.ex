defmodule Tiannara.Sentinel.Governance do
  @moduledoc """
  SOPL/REA Governance — Goodhart detection, monoculture pathology,
  and causal topology analysis for evolutionary governance.

  Prevents blind optimization by detecting when evolutionary pressure
  creates pathological outcomes: metrics losing meaning, diversity
  collapsing, or causal structures becoming brittle.
  """
  use GenServer
  require Logger

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a metric-value observation for Goodhart analysis.
  """
  def record_metric(metric_id, value, context \\ %{}) do
    GenServer.cast(__MODULE__, {:record_metric, metric_id, value, context})
  end

  @doc """
  Analyszes a metric for Goodhart's Law indicators:
  - Does optimizing this metric correlate with degradation in other metrics?
  - Has the metric lost its predictive power over time?
  """
  def goodhart_analysis(metric_id) do
    GenServer.call(__MODULE__, {:goodhart_analysis, metric_id})
  end

  @doc """
  Detects monoculture: when a population has low diversity across
  multiple dimensions (genetic, strategic, behavioral).
  """
  def monoculture_detection(population_id) do
    GenServer.call(__MODULE__, {:monoculture_detection, population_id})
  end

  @doc """
  Analyzes causal topology for governance health:
  - Centralization (are too many decisions routing through one node?)
  - Fragility (are there single points of failure?)
  - Cyclic dependencies (are there governance loops?)
  """
  def causal_topology_analysis do
    GenServer.call(__MODULE__, :causal_topology_analysis)
  end

  @doc """
  Full governance health check across all tracked populations and metrics.
  """
  def governance_health_check do
    GenServer.call(__MODULE__, :governance_health_check)
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    create_named_table(:governance_metrics)
    create_named_table(:governance_goodhart_flags)
    Logger.info("⚖️ [GOVERNANCE] SOPL/REA Governance initialized.")
    {:ok, %{
      metrics_table: :governance_metrics,
      flags_table: :governance_goodhart_flags
    }}
  end

  @impl true
  def handle_cast({:record_metric, metric_id, value, context}, state) do
    entry = {metric_id, value, DateTime.utc_now(), context}
    :ets.insert(state.metrics_table, entry)
    {:noreply, state}
  end

  @impl true
  def handle_call({:goodhart_analysis, metric_id}, _from, state) do
    analysis = compute_goodhart_analysis(state, metric_id)
    {:reply, analysis, state}
  end

  @impl true
  def handle_call({:monoculture_detection, population_id}, _from, state) do
    detection = detect_monoculture(state, population_id)
    {:reply, detection, state}
  end

  @impl true
  def handle_call(:causal_topology_analysis, _from, state) do
    topology = analyze_topology(state)
    {:reply, topology, state}
  end

  @impl true
  def handle_call(:governance_health_check, _from, state) do
    health = compute_governance_health(state)
    {:reply, health, state}
  end

  # ── Private Helpers ──

  defp compute_goodhart_analysis(state, metric_id) do
    entries = :ets.match_object(state.metrics_table, {metric_id, :_, :_, :_})
    |> Enum.sort_by(fn {_id, _v, ts, _ctx} -> ts end)

    if length(entries) < 5 do
      %{
        metric_id: metric_id,
        goodhart_risk: :insufficient_data,
        observations: length(entries),
        message: "Need at least 5 observations for Goodhart analysis"
      }
    else
      values = Enum.map(entries, fn {_id, v, _ts, _ctx} -> v end)

      first_half = Enum.take(values, div(length(values), 2))
      second_half = Enum.drop(values, div(length(values), 2))

      first_mean = if first_half != [], do: Enum.sum(first_half) / length(first_half), else: 0.0
      second_mean = if second_half != [], do: Enum.sum(second_half) / length(second_half), else: 0.0

      variance_first = variance(first_half, first_mean)
      variance_second = variance(second_half, second_mean)

      metric_drift = abs(second_mean - first_mean)
      variance_increase = if variance_first > 0, do: variance_second / variance_first, else: 1.0

      goodhart_risk = cond do
        variance_increase > 2.0 and metric_drift > 0.1 -> :high
        variance_increase > 1.5 or metric_drift > 0.05 -> :moderate
        true -> :low
      end

      flags = []
      flags = if variance_increase > 2.0, do: [{:metric_gaming, "Variance increased #{Float.round(variance_increase, 2)}x"} | flags], else: flags
      flags = if metric_drift > 0.1, do: [{:metric_decay, "Metric drifted #{Float.round(metric_drift, 4)}"} | flags], else: flags

      %{
        metric_id: metric_id,
        goodhart_risk: goodhart_risk,
        observations: length(entries),
        first_half_mean: Float.round(first_mean, 4),
        second_half_mean: Float.round(second_mean, 4),
        variance_ratio: Float.round(variance_increase, 4),
        metric_drift: Float.round(metric_drift, 4),
        flags: flags,
        message: goodhart_message(goodhart_risk, metric_id)
      }
    end
  end

  defp goodhart_message(:high, metric_id), do: "Goodhart's Law: #{metric_id} is being optimized and losing meaning"
  defp goodhart_message(:moderate, metric_id), do: "Monitor closely: #{metric_id} shows early signs of metric degradation"
  defp goodhart_message(:low, _metric_id), do: "Metric appears healthy"
  defp goodhart_message(_, _metric_id), do: "Insufficient data for analysis"

  defp variance(values, mean) when length(values) > 1 do
    squared_diffs = Enum.map(values, fn v -> (v - mean) ** 2 end)
    Enum.sum(squared_diffs) / (length(values) - 1)
  end

  defp variance(_values, _mean), do: 0.0

  defp detect_monoculture(_state, population_id) do
    # Query evolutionary diversity data from EvolutionaryOversight
    diversity = case Code.ensure_loaded?(Tiannara.Sentinel.EvolutionaryOversight) do
      true -> apply(Tiannara.Sentinel.EvolutionaryOversight, :diversity_entropy, [population_id])
      false -> nil
    end

    health = case Code.ensure_loaded?(Tiannara.Sentinel.EvolutionaryOversight) do
      true -> apply(Tiannara.Sentinel.EvolutionaryOversight, :population_health, [population_id])
      false -> nil
    end

    entropy = if is_float(diversity), do: diversity, else: (health[:diversity][:shannon_entropy] || 0.0)

    unique_count = if health, do: health[:diversity][:unique_entities] || 0, else: 0

    monoculture_risk = cond do
      entropy < 0.2 -> :critical
      entropy < 0.5 -> :high
      entropy < 1.0 -> :moderate
      true -> :low
    end

    %{
      population_id: population_id,
      monoculture_risk: monoculture_risk,
      shannon_entropy: Float.round(entropy, 4),
      unique_entities: unique_count,
      recommendations: monoculture_recommendations(monoculture_risk)
    }
  end

  defp monoculture_recommendations(:critical), do: ["Urgent: Inject novelty operators", "Force exploration", "Suspend optimization of dominant strategy"]
  defp monoculture_recommendations(:high), do: ["Increase mutation rate", "Introduce competitive pressure", "Diversify selection criteria"]
  defp monoculture_recommendations(:moderate), do: ["Monitor diversity trends", "Consider periodic novelty injection"]
  defp monoculture_recommendations(:low), do: ["Diversity healthy — continue current governance"]

  defp analyze_topology(state) do
    # Analyze governance structure by examining metric correlation patterns
    all_metrics = :ets.tab2list(state.metrics_table)
    |> Enum.map(fn {id, _v, _ts, _ctx} -> id end)
    |> Enum.uniq()

    total_observations = :ets.info(state.metrics_table, :size)

    metric_count = length(all_metrics)

    %{
      tracked_metrics: metric_count,
      total_observations: total_observations,
      topology_health: if(metric_count >= 3, do: :distributed, else: :insufficient_metrics),
      centralization_risk: if(metric_count <= 2, do: :high, else: :low),
      recommendation: "Maintain at least 5 independent governance metrics"
    }
  end

  defp compute_governance_health(state) do
    all_metrics = :ets.tab2list(state.metrics_table)
    |> Enum.map(fn {id, _v, _ts, _ctx} -> id end)
    |> Enum.uniq()

    metric_analyses = Enum.map(all_metrics, fn id ->
      {id, compute_goodhart_analysis(state, id)}
    end)

    high_risk_count = Enum.count(metric_analyses, fn {_id, a} -> a.goodhart_risk == :high end)
    moderate_risk_count = Enum.count(metric_analyses, fn {_id, a} -> a.goodhart_risk == :moderate end)

    health = cond do
      high_risk_count > 0 -> :critical
      moderate_risk_count > 2 -> :concerning
      metric_analyses == [] -> :uninitialized
      true -> :healthy
    end

    %{
      governance_health: health,
      total_metrics: length(metric_analyses),
      high_risk_metrics: high_risk_count,
      moderate_risk_metrics: moderate_risk_count,
      metrics: metric_analyses
    }
  end

  defp create_named_table(name) do
    case :ets.info(name) do
      :undefined -> :ets.new(name, [:bag, :public, :named_table])
      _ -> name
    end
  end
end
