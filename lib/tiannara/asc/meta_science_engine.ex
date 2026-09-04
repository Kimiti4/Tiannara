defmodule Tiannara.ASC.MetaScienceEngine do
  use GenServer
  require Logger

  alias Tiannara.Operations.CampaignIntegration

  @analysis_interval :timer.hours(6)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def analyze, do: GenServer.cast(__MODULE__, :analyze)
  def recommendations, do: GenServer.call(__MODULE__, :recommendations)
  def history, do: GenServer.call(__MODULE__, :history)
  def methodology_score, do: GenServer.call(__MODULE__, :methodology_score)

  @impl true
  def init(_opts) do
    subscribe_to_phase6()
    schedule_analysis()

    {:ok, %{
      phase6_results: [],
      analyses_completed: 0,
      recommendations: [],
      methodology_score: 0.5,
      strategy_performance: %{},
      bias_detections: [],
      bottleneck_history: [],
      history: [],
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast(:analyze, state) do
    {:noreply, run_analysis(state)}
  end

  @impl true
  def handle_call(:recommendations, _from, state) do
    {:reply, state.recommendations, state}
  end

  @impl true
  def handle_call(:history, _from, state) do
    {:reply, state.history, state}
  end

  @impl true
  def handle_call(:methodology_score, _from, state) do
    {:reply, state.methodology_score, state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "campaign.phase7.input", payload: payload}}, state) do
    Logger.info("MetaScience: Received Phase 6 output")
    {:noreply, %{state | phase6_results: [payload | state.phase6_results] |> Enum.take(100)}}
  end

  @impl true
  def handle_info(:scheduled_analysis, state) do
    new_state = run_analysis(state)
    schedule_analysis()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_analysis(state) do
    if state.phase6_results == [] do
      state
    else
      strategy_perf = evaluate_strategies(state.phase6_results, state.strategy_performance)
      bottlenecks = detect_methodology_bottlenecks(state.phase6_results)
      biases = detect_biases(state.phase6_results)
      recs = generate_recommendations(strategy_perf, bottlenecks, biases)
      score = compute_methodology_score(strategy_perf, bottlenecks, biases)
      apply_improvements(recs)

      CampaignIntegration.route_result(:phase7, %{
        status: :completed,
        methodology_score: score,
        recommendations: length(recs),
        bottlenecks: length(bottlenecks),
        biases: length(biases),
        analyzed_at: DateTime.utc_now()
      })

      analysis_entry = %{
        at: DateTime.utc_now(),
        inputs_analyzed: length(state.phase6_results),
        methodology_score: score,
        recommendations: length(recs),
        bottlenecks: bottlenecks,
        biases: biases
      }

      Logger.info("MetaScience: Analysis complete — score #{Float.round(score, 3)}, #{length(recs)} recommendations, #{length(bottlenecks)} bottlenecks")

      %{state |
        analyses_completed: state.analyses_completed + 1,
        recommendations: recs,
        methodology_score: score,
        strategy_performance: strategy_perf,
        bias_detections: biases,
        bottleneck_history: [bottlenecks | state.bottleneck_history] |> Enum.take(50),
        history: [analysis_entry | state.history] |> Enum.take(200),
        phase6_results: []
      }
    end
  end

  defp evaluate_strategies(results, previous_performance) do
    strategy_outcomes =
      Enum.reduce(results, %{}, fn result, acc ->
        strategy = get_in(result, [:result, :strategy]) || :default
        discoveries = get_in(result, [:result, :discoveries]) || 0
        validated = get_in(result, [:result, :validated]) || 0

        current = Map.get(acc, strategy, %{total: 0, discoveries: 0, validated: 0})

        Map.put(acc, strategy, %{
          total: current.total + 1,
          discoveries: current.discoveries + discoveries,
          validated: current.validated + validated
        })
      end)

    Map.merge(previous_performance, strategy_outcomes, fn _key, old, new ->
      %{
        total: old.total + new.total,
        discoveries: old.discoveries + new.discoveries,
        validated: old.validated + new.validated,
        success_rate: safe_div(new.validated, max(1, new.discoveries))
      }
    end)
  end

  defp detect_methodology_bottlenecks(results) do
    total_discoveries = Enum.reduce(results, 0, fn r, acc ->
      acc + (get_in(r, [:result, :discoveries]) || 0)
    end)

    total_validated = Enum.reduce(results, 0, fn r, acc ->
      acc + (get_in(r, [:result, :validated]) || 0)
    end)

    validation_rate = safe_div(total_validated, max(1, total_discoveries))

    bottlenecks = if validation_rate < 0.3 and total_discoveries > 5 do
      [%{
        type: :low_validation_rate,
        detail: "Only #{Float.round(validation_rate * 100, 0)}% of discoveries are validated",
        severity: :high,
        recommendation: "Increase experiment rigor or reduce hypothesis count"
      }]
    else
      []
    end

    cycle_times = Enum.map(results, fn r ->
      get_in(r, [:result, :cycle_time_ms]) || 0
    end)

    avg_cycle_time = if cycle_times != [], do: Enum.sum(cycle_times) / length(cycle_times), else: 0

    bottlenecks = if avg_cycle_time > 30_000 do
      [%{
        type: :slow_cycle_time,
        detail: "Average cycle time #{round(avg_cycle_time)}ms exceeds 30s threshold",
        severity: :medium,
        recommendation: "Optimize experiment execution or reduce scope per cycle"
      } | bottlenecks]
    else
      bottlenecks
    end

    hypothesis_diversity = compute_hypothesis_diversity(results)

    bottlenecks = if hypothesis_diversity < 0.4 do
      [%{
        type: :hypothesis_monoculture,
        detail: "Hypothesis diversity #{Float.round(hypothesis_diversity, 2)} below 0.4 threshold",
        severity: :medium,
        recommendation: "Increase hypothesis generation diversity (cross-domain, analogical)"
      } | bottlenecks]
    else
      bottlenecks
    end

    bottlenecks
  end

  defp detect_biases(results) do
    outcomes = Enum.flat_map(results, fn r ->
      get_in(r, [:result, :outcomes]) || []
    end)

    if outcomes == [] do
      []
    else
      confirmed = Enum.count(outcomes, &(&1 == :confirmed))
      total = length(outcomes)

      confirmation_rate = safe_div(confirmed, total)

      if confirmation_rate > 0.9 and total > 10 do
        [%{
          type: :confirmation_bias,
          detail: "#{Float.round(confirmation_rate * 100, 0)}% confirmation rate (#{confirmed}/#{total}) — suspiciously high",
          severity: :high,
          recommendation: "Actively seek disconfirming evidence; add adversarial hypotheses"
        }]
      else
        []
      end
    end
  end

  defp generate_recommendations(strategy_perf, bottlenecks, biases) do
    recs = Enum.map(bottlenecks, fn b ->
      %{source: :bottleneck, type: b.type, priority: b.severity, action: b.recommendation, evidence: b.detail}
    end)

    recs = recs ++ Enum.map(biases, fn b ->
      %{source: :bias_detection, type: b.type, priority: b.severity, action: b.recommendation, evidence: b.detail}
    end)

    recs = recs ++ strategy_recommendations(strategy_perf)

    priority_order = %{critical: 4, high: 3, medium: 2, low: 1}
    Enum.sort_by(recs, fn r -> Map.get(priority_order, r.priority, 0) end, :desc)
  end

  defp strategy_recommendations(strategy_perf) do
    if map_size(strategy_perf) < 2 do
      []
    else
      sorted = Enum.sort_by(strategy_perf, fn {_k, v} -> Map.get(v, :success_rate, 0) end, :desc)
      {best_name, best_perf} = hd(sorted)
      {worst_name, worst_perf} = List.last(sorted)

      best_rate = Map.get(best_perf, :success_rate, 0)
      worst_rate = Map.get(worst_perf, :success_rate, 0)

      if best_rate - worst_rate > 0.3 do
        [%{
          source: :strategy_evaluation,
          type: :strategy_optimization,
          priority: :medium,
          action: "Favor '#{best_name}' strategy (#{Float.round(best_rate, 2)} success) over '#{worst_name}' (#{Float.round(worst_rate, 2)})",
          evidence: "Performance gap: #{Float.round(best_rate - worst_rate, 2)}"
        }]
      else
        []
      end
    end
  end

  defp apply_improvements(recommendations) do
    high_priority = Enum.filter(recommendations, fn r -> r.priority in [:critical, :high] end)

    if high_priority != [] do
      try do
        Tiannara.CEL.Services.EventBus.Safe.publish(
          "meta_science.improvements",
          %{recommendations: high_priority, count: length(high_priority), at: DateTime.utc_now()}
        )
        Logger.info("MetaScience: Fed #{length(high_priority)} improvements back into discovery pipeline")
      rescue
        _ -> :ok
      end
    end
  end

  defp compute_methodology_score(strategy_perf, bottlenecks, biases) do
    total_discoveries = Enum.reduce(strategy_perf, 0, fn {_k, v}, acc -> acc + v.discoveries end)
    total_validated = Enum.reduce(strategy_perf, 0, fn {_k, v}, acc -> acc + v.validated end)
    validation_rate = safe_div(total_validated, max(1, total_discoveries))
    bottleneck_penalty = length(bottlenecks) * 0.1
    bias_penalty = length(biases) * 0.15
    max(0.0, min(1.0, validation_rate - bottleneck_penalty - bias_penalty))
  end

  defp compute_hypothesis_diversity(results) do
    types = Enum.flat_map(results, fn r ->
      get_in(r, [:result, :hypothesis_types]) || []
    end)

    if types == [] do
      0.5
    else
      unique = Enum.uniq(types)
      length(unique) / length(types)
    end
  end

  defp safe_div(_n, 0), do: 0.0
  defp safe_div(n, d), do: n / d

  defp subscribe_to_phase6 do
    try do
      Tiannara.CEL.Services.EventBus.Safe.subscribe("campaign.phase7.input")
    rescue
      _ -> :ok
    end
  end

  defp schedule_analysis do
    Process.send_after(self(), :scheduled_analysis, @analysis_interval)
  end
end
