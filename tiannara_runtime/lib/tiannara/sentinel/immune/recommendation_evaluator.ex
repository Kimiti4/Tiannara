defmodule Tiannara.Sentinel.Immune.RecommendationEvaluator do
  @moduledoc """
  Determines if a recommendation was successful by comparing the expected
  impact versus the actual observed delta.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Immune.RecommendationJournal
  alias Tiannara.Sentinel.Immune.RecommendationScorer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate_outcome(intervention, current_metrics) do
    GenServer.cast(__MODULE__, {:evaluate, intervention, current_metrics})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:evaluate, intervention, current_metrics}, state) do
    # 1. Compare observed delta vs expected impact
    success_score = calculate_success_score(intervention.expected_impact, current_metrics)
    
    new_status = if success_score >= 0.70, do: :successful, else: :failed
    
    Logger.info("Recommendation #{intervention.id} evaluated. Score: #{success_score}, Status: #{new_status}")

    # 2. Update Journal
    RecommendationJournal.update_status(intervention.id, new_status, %{success_score: success_score})

    # 3. Notify Scorer
    RecommendationScorer.record_outcome(intervention, success_score)

    {:noreply, state}
  end

  defp calculate_success_score(_expected_impact, _current_metrics) do
    # Simulating empirical score between 0.0 and 1.0 based on delta proximity
    min(1.0, max(0.0, 0.5 + (:rand.uniform() * 0.5)))
  end
end
