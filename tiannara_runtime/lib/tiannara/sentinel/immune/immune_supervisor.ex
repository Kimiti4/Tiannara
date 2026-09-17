defmodule Tiannara.Sentinel.ImmuneSupervisor do
  @moduledoc """
  Supervises the immune subsystem. In Phase B1.5, this includes empirical evaluation and scoring.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.Sentinel.Immune.StabilizationAuditor,
      Tiannara.Sentinel.Immune.ReasoningArchive,
      Tiannara.Sentinel.Immune.RecommendationJournal,
      Tiannara.Sentinel.Immune.OutcomeTracker,
      Tiannara.Sentinel.Immune.RecommendationScorer,
      Tiannara.Sentinel.Immune.ConfidenceCalibrator,
      Tiannara.Sentinel.Immune.RecommendationEvaluator,
      Tiannara.Sentinel.Immune.RegulationPlanner,
      Tiannara.Sentinel.Immune.RecommendationConfidence,
      Tiannara.Sentinel.Immune.RecommendationEngine,
      Tiannara.Sentinel.Immune.InterventionRouter
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
