defmodule Tiannara.Sentinel.Shadow.ReplayValidator do
  @moduledoc """
  Compares the counterfactual prediction against the actual historical outcome.
  Logs failures to the archive if the ESG prediction was wrong.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Shadow.ReplayFailureArchive
  alias Tiannara.Sentinel.Shadow.ReplayMetrics

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def validate(replay_case, counterfactual_prediction) do
    GenServer.cast(__MODULE__, {:validate, replay_case, counterfactual_prediction})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:validate, replay_case, counterfactual_prediction}, state) do
    outcome_accuracy = calculate_outcome_accuracy(replay_case.actual_outcome, counterfactual_prediction.predicted_success_score)
    confidence_accuracy = calculate_confidence_accuracy(replay_case.recommendation.confidence, counterfactual_prediction.confidence)
    drift_score = 0.88 # Mock drift consistency score

    ReplayMetrics.record_result(replay_case.anomaly, outcome_accuracy, confidence_accuracy, drift_score)

    if outcome_accuracy < 0.70 do
      Logger.warning("ESG Replay Failure: Historical outcome diverged from counterfactual prediction.")
      ReplayFailureArchive.archive_failure(replay_case, counterfactual_prediction, outcome_accuracy)
    end

    {:noreply, state}
  end

  defp calculate_outcome_accuracy(actual, predicted) do
    1.0 - abs(actual - predicted)
  end

  defp calculate_confidence_accuracy(historical_conf, current_conf) do
    1.0 - abs(historical_conf - current_conf)
  end
end
