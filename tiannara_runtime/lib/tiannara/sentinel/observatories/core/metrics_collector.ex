defmodule Tiannara.Sentinel.Observatories.Core.MetricsCollector do
  @moduledoc """
  Tracks consensus_advantage_live and related metrics for Phase D.1 validation.
  """
  use GenServer
  require Logger

  @evaluation_window_hours 24
  @alert_threshold -0.05  # Alert if consensus is >5% worse than best single

  # Public API
  @spec get_recent_consensus_metrics(keyword()) :: {float(), float(), float()}
  def get_recent_consensus_metrics(opts \\ []) do
    GenServer.call(__MODULE__, {:get_metrics, opts})
  end

  @spec get_disagreement_win_rates() :: map()
  def get_disagreement_win_rates do
    GenServer.call(__MODULE__, :get_win_rates)
  end

  @spec record_evaluation_case(map()) :: :ok
  def record_evaluation_case(case_data) do
    GenServer.cast(__MODULE__, {:record_case, case_data})
  end

  @spec get_recent_evaluation_cases() :: [map()]
  def get_recent_evaluation_cases do
    GenServer.call(__MODULE__, :get_cases)
  end

  # GenServer callbacks
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{
      evaluation_cases: :queue.new(),
      max_cases: 10000
    }}
  end

  @impl true
  def handle_cast({:record_case, case}, state) do
    # Add to evaluation queue with timestamp
    timed_case = Map.put(case, :recorded_at, System.system_time(:millisecond))
    new_queue = :queue.in(timed_case, state.evaluation_cases)
    
    # Trim old cases outside window
    cutoff = System.system_time(:millisecond) - (@evaluation_window_hours * 3600 * 1000)
    trimmed = trim_old_cases(new_queue, cutoff)
    
    {:noreply, %{state | evaluation_cases: trimmed}}
  end

  @impl true
  def handle_call({:get_metrics, _opts}, _from, state) do
    cases = :queue.to_list(state.evaluation_cases)
    
    # Compute consensus strength (how concentrated are action scores?)
    consensus_strength = compute_consensus_strength(cases)
    
    # Compute disagreement rate (% of cases with high-confidence conflicts)
    disagreement_rate = compute_disagreement_rate(cases)

    # Compute epistemic tension (high-confidence conflicts among :trusted observatories)
    epistemic_tension = compute_epistemic_tension(cases)
    
    {:reply, {consensus_strength, disagreement_rate, epistemic_tension}, state}
  end

  @impl true
  def handle_call(:get_win_rates, _from, state) do
    cases = :queue.to_list(state.evaluation_cases)
    
    # Filter for cases where we know the observed outcome and there was a disagreement
    disagreement_cases = Enum.filter(cases, fn c -> 
      c.observed != :pending and length(Enum.uniq(Map.values(c.observatory_predictions))) > 1
    end)

    total_disagreements = max(length(disagreement_cases), 1)

    win_rates = Enum.reduce(disagreement_cases, %{
      consensus: 0,
      runtime: 0,
      ecological: 0,
      semantic: 0
    }, fn case, acc ->
      acc
      |> Map.update(:consensus, 0, & if(case.consensus_prediction == case.observed, do: &1 + 1, else: &1))
      |> Map.update(:runtime, 0, & if(case.observatory_predictions[:runtime] == case.observed, do: &1 + 1, else: &1))
      |> Map.update(:ecological, 0, & if(case.observatory_predictions[:ecological] == case.observed, do: &1 + 1, else: &1))
      |> Map.update(:semantic, 0, & if(case.observatory_predictions[:semantic] == case.observed, do: &1 + 1, else: &1))
    end)
    
    final_win_rates = Map.new(win_rates, fn {k, wins} -> 
      {k, Float.round(wins / total_disagreements, 3)}
    end)

    {:reply, final_win_rates, state}
  end

  @impl true
  def handle_call(:get_cases, _from, state) do
    {:reply, :queue.to_list(state.evaluation_cases), state}
  end

  # Alerting: Monitor consensus_advantage_live drift
  def check_advantage_alert(advantage) do
    if advantage < @alert_threshold do
      Logger.warning("⚠️ [CONSENSUS ALERT] consensus_advantage_live = #{advantage} < #{@alert_threshold}")
      :alert_triggered
    else
      :ok
    end
  end

  # Helpers
  defp trim_old_cases(queue, cutoff) do
    # Remove cases older than cutoff timestamp
    :queue.to_list(queue)
    |> Enum.filter(&(&1.recorded_at >= cutoff))
    |> :queue.from_list()
  end

  defp compute_consensus_strength(cases) do
    cases
    |> Enum.map(& Map.get(&1, :consensus_action_scores, %{}))
    |> Enum.map(fn scores -> 
      values = Map.values(scores)
      if length(values) <= 1, do: 1.0, else:
        (Enum.max(values) - Enum.min(values)) / (Enum.sum(values) / length(values) + 0.001)
    end)
    |> case do
      [] -> 0.0
      vals -> Enum.sum(vals) / length(vals)
    end
  end

  defp compute_disagreement_rate(cases) do
    Enum.count(cases, fn case ->
      high_conf = Enum.filter(Map.get(case, :observatory_signals, []), &(&1.confidence >= 0.85))
      actions = Enum.map(high_conf, & &1.recommended_action) |> Enum.uniq()
      length(high_conf) >= 2 and length(actions) >= 2
    end) / max(length(cases), 1)
  end

  defp compute_epistemic_tension(cases) do
    Enum.count(cases, fn case ->
      trusted_high_conf = Enum.filter(Map.get(case, :observatory_signals, []), fn sig -> 
        sig.confidence >= 0.85 and sig.reliability == :trusted 
      end)
      actions = Enum.map(trusted_high_conf, & &1.recommended_action) |> Enum.uniq()
      length(trusted_high_conf) >= 2 and length(actions) >= 2
    end) / max(length(cases), 1)
  end
end
