defmodule Tiannara.Sentinel.Immune.RecommendationScorer do
  @moduledoc """
  Aggregates empirical outcomes to produce Sentinel's effectiveness metrics.
  """
  use GenServer

  alias Tiannara.Sentinel.Immune.ConfidenceCalibrator
  alias Tiannara.Sentinel.Immune.ReasoningArchive

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_outcome(intervention, success_score) do
    GenServer.cast(__MODULE__, {:record, intervention, success_score})
  end

  def get_effectiveness_report() do
    GenServer.call(__MODULE__, :get_report)
  end

  @impl true
  def init(_opts) do
    {:ok, %{
      total_evaluated: 0,
      total_successful: 0,
      scores: [],
      history_by_type: %{} # anomaly_type -> list of actions
    }}
  end

  @impl true
  def handle_cast({:record, intervention, success_score}, state) do
    new_evaluated = state.total_evaluated + 1
    new_successful = state.total_successful + (if success_score >= 0.70, do: 1, else: 0)
    new_scores = [success_score | state.scores]
    
    # Send feedback to Calibrator
    ConfidenceCalibrator.update_priors(intervention.action, success_score)
    
    # Store full context in Reasoning Archive
    ReasoningArchive.archive_case(intervention, success_score)

    # Track action history for drift calculation
    anomaly_type = extract_type(intervention.rationale)
    type_history = Map.get(state.history_by_type, anomaly_type, [])
    updated_history = Enum.take([intervention.action | type_history], 20) # keep last 20
    new_history_by_type = Map.put(state.history_by_type, anomaly_type, updated_history)

    {:noreply, %{state | total_evaluated: new_evaluated, total_successful: new_successful, scores: new_scores, history_by_type: new_history_by_type}}
  end

  @impl true
  def handle_call(:get_report, _from, state) do
    success_rate = if state.total_evaluated > 0, do: state.total_successful / state.total_evaluated, else: 0.0
    drift = calculate_drift(state.history_by_type)

    report = %{
      recommendations_generated: state.total_evaluated,
      recommendations_observed: state.total_evaluated,
      success_rate: success_rate,
      anomaly_type_accuracy: %{},
      confidence_calibration_error: 0.0,
      forecast_accuracy: 0.0,
      recommendation_precision: 0.0,
      recommendation_recall: 0.0,
      recommendation_drift: drift
    }
    
    {:reply, report, state}
  end

  defp extract_type(rationale) do
    case Regex.run(~r/anomaly type: (.+)$/, rationale || "") do
      [_, type] -> type
      _ -> "unknown"
    end
  end

  defp calculate_drift(history_by_type) when history_by_type == %{}, do: 0.0
  defp calculate_drift(history_by_type) do
    drifts = Enum.map(history_by_type, fn {_type, actions} ->
      len = length(actions)
      if len <= 1 do
        0.0
      else
        changes = 
          actions
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.count(fn [a, b] -> a != b end)
        
        changes / (len - 1)
      end
    end)
    
    if Enum.empty?(drifts), do: 0.0, else: Enum.sum(drifts) / length(drifts)
  end
end
