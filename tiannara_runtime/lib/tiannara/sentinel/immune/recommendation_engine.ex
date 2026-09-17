defmodule Tiannara.Sentinel.Immune.RecommendationEngine do
  @moduledoc """
  Evaluates anomalies against baselines to propose regulatory interventions.
  Produces Contracts.Intervention structs with status :proposed.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Contracts.Intervention

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate_anomaly(anomaly) do
    GenServer.cast(__MODULE__, {:evaluate, anomaly})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:evaluate, anomaly}, state) do
    # 1. Fetch potential policies
    policies = Tiannara.Sentinel.Immune.RegulationPlanner.get_policies(anomaly.type)
    
    # 2. Pick the primary action (simplification for B1)
    action = List.first(policies) || :observe

    # 3. Calculate confidence
    confidence = Tiannara.Sentinel.Immune.RecommendationConfidence.calculate_confidence(anomaly, %{}, %{})

    # 4. Formulate the intervention
    intervention = %Intervention{
      id: "rec_#{System.unique_integer()}",
      target_system: anomaly.source,
      action: action,
      rationale: "Automated recommendation for anomaly type: #{anomaly.type}",
      confidence: confidence,
      expected_impact: %{stability_improvement: "moderate"},
      source_anomaly: anomaly.id,
      created_at: System.system_time(:second),
      status: :proposed
    }

    Logger.info("Sentinel formulated recommendation: #{action} with confidence #{confidence}")

    # 5. Route through Epistemic Shadow Graph (Phase C.1A) before finalization
    Tiannara.Sentinel.Shadow.ShadowSeedBuilder.build_seed(intervention, anomaly)

    {:noreply, state}
  end

  def finalize_recommendation(intervention) do
    GenServer.cast(__MODULE__, {:finalize, intervention})
  end

  @impl true
  def handle_cast({:finalize, intervention}, state) do
    # 6. Route the intervention after shadow validation
    Tiannara.Sentinel.Immune.InterventionRouter.route(intervention)
    {:noreply, state}
  end
end
