defmodule Tiannara.Sentinel.Shadow.ReplayEngine do
  @moduledoc """
  Performs Counterfactual Evaluation (Phase C.0 scope).
  Asks: "If Sentinel saw this anomaly today, what action/confidence would it assign?"
  """
  use GenServer

  alias Tiannara.Sentinel.Shadow.ReplayValidator
  alias Tiannara.Sentinel.Immune.RecommendationEngine

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate_counterfactual(replay_case) do
    GenServer.cast(__MODULE__, {:evaluate, replay_case})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:evaluate, replay_case}, state) do
    # Counterfactual Evaluation: Ask the active Immune subsystem what it would do today 
    # given the historical anomaly.
    
    # Mocking the counterfactual output based on current system logic
    # In reality, this would query RecommendationEngine/RegulationPlanner without committing state.
    counterfactual_prediction = %{
      action: replay_case.recommendation.action,
      confidence: replay_case.recommendation.confidence, # Would be re-scored by current calibrator
      predicted_success_score: 0.85 
    }

    ReplayValidator.validate(replay_case, counterfactual_prediction)

    {:noreply, state}
  end
end
