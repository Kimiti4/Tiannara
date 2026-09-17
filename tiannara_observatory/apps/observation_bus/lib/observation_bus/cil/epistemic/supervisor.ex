defmodule ObservationBus.CIL.Epistemic.Supervisor do
  @moduledoc """
  Supervisor for the Constitutional Epistemic Observatory (CEO) — M12.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      ObservationBus.CIL.Epistemic.KnowledgeConfidenceEngine,
      ObservationBus.CIL.Epistemic.EvidenceGraph,
      ObservationBus.CIL.Epistemic.UnknownRegistry,
      ObservationBus.CIL.Epistemic.ContradictionDetector,
      ObservationBus.CIL.Epistemic.AssumptionRegistry,
      ObservationBus.CIL.Epistemic.BiasDetector,
      ObservationBus.CIL.Epistemic.TrustPropagator
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
