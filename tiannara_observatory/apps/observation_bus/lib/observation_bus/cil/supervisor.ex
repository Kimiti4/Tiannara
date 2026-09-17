defmodule ObservationBus.CIL.Supervisor do
  @moduledoc """
  Top-level supervisor for the Constitutional Intelligence Layer (CIL).

  Starts all CIL subsystems as children of the COB supervision tree:
    1-11: Core CIL modules (M10)
    12. Prediction.Supervisor — Constitutional Predictive Observatory (M11)
    13. Epistemic.Supervisor — Constitutional Epistemic Observatory (M12)
    14. Mission.Supervisor — Constitutional Scientific Mission Control (M13)
    15. Strategy.Supervisor — Constitutional Strategic Intelligence Center (M14)
    16. Civilization.Supervisor — Constitutional Civilization Observatory (M15)
    17. Futures.Supervisor — Constitutional Futures Laboratory (M16)
    18. Meta.Supervisor — Constitutional Self-Governance & Observatory Evolution (M17)
    19. Ops.Supervisor — Constitutional Autonomous Operations Center (M18)
    20. Federation.Supervisor — Constitutional Distributed Scientific Civilization Network (M19)
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.PatternRegistry,
      ObservationBus.CIL.PatternEngine,
      ObservationBus.CIL.CausalEngine,
      ObservationBus.CIL.AnomalyDetector,
      ObservationBus.CIL.TrendEngine,
      ObservationBus.CIL.HealthEngine,
      ObservationBus.CIL.RecommendationEngine,
      ObservationBus.CIL.KnowledgeSynthesizer,
      ObservationBus.CIL.RiskAnalyzer,
      ObservationBus.CIL.ConfidenceEngine,
      ObservationBus.CIL.Diagnostics,
      ObservationBus.CIL.Prediction.Supervisor,
      ObservationBus.CIL.Epistemic.Supervisor,
      ObservationBus.CIL.Mission.Supervisor,
      ObservationBus.CIL.Strategy.Supervisor,
      ObservationBus.CIL.Civilization.Supervisor,
      ObservationBus.CIL.Futures.Supervisor,
      ObservationBus.CIL.Meta.Supervisor,
      ObservationBus.CIL.Ops.Supervisor,
      ObservationBus.CIL.Federation.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
