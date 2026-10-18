defmodule Tiannara.CCI.Orchestrator do
  @moduledoc """
  Orchestrates the full CCI pipeline:
  Observation → Understanding → Governance Evaluation → Forecasting →
  Risk Assessment → Priority Recommendation → Experiment Proposal → Human Collaboration.

  Integrates with Sentinel (observation), ASC (civilization state), Reality Graph (causality),
  and MetaGovernor (constitutional oversight).
  """
  alias Tiannara.CCI.{
    CivilizationSelfModel, ConstitutionalGovernanceEngine,
    CivilizationForecastingEngine, InstitutionalEvolutionSystem,
    CivilizationalMemoryEngine, CivilizationExperimentRuntime,
    PriorityResearchEngine, CivilizationRiskIntelligence
  }

  @doc """
  Performs a comprehensive civilizational intelligence cycle.
  Returns a civilizational report for human review.

  Fail-closed (production-readiness scan A6): until the ASC and Sentinel
  reads below are implemented, the cycle reports unavailability instead of
  pushing hardcoded subsystem counts and invented observation confidences
  through the risk, forecast, and priority engines as if they were
  measurements.
  """
  def civilizational_cycle do
    with {:ok, asc_state} <- fetch_asc_state(),
         {:ok, sentinel_observations} <- fetch_sentinel_observations() do
      CivilizationSelfModel.update_state(:cci_csm, asc_state)
      civ_state = CivilizationSelfModel.get_state(:cci_csm)

      {:ok, risk_assessment} = CivilizationRiskIntelligence.assess_risks(:cci_cri, civ_state)

      {:ok, forecast} = CivilizationForecastingEngine.forecast(:cci_cfe, civ_state, 100)

      institutional_health = InstitutionalEvolutionSystem.list_health(:cci_ies)

      {:ok, priorities} =
        PriorityResearchEngine.recommend_priorities(:cci_pre, sentinel_observations, civ_state)

      CivilizationalMemoryEngine.preserve(:cci_cme, %{
        type: :decision,
        domain: :civilizational,
        content: "Civilizational cycle completed",
        context: %{risk_level: risk_assessment.overall_risk_level, forecast_confidence: forecast.confidence},
        outcome: :completed
      })

      %{
        civilization_state: civ_state,
        risk_assessment: risk_assessment,
        forecast: forecast,
        institutional_health: institutional_health,
        priorities: priorities,
        timestamp: DateTime.utc_now(),
        requires_human_review: true
      }
    end
  end

  @doc """
  Evaluates a governance proposal through the full constitutional pipeline.
  """
  def evaluate_governance_proposal(proposal) do
    {:ok, decision} = ConstitutionalGovernanceEngine.evaluate_proposal(:cci_cge, proposal)

    if decision.decision == :pending_human_approval and decision.constitutional_alignment > 0.7 do
      {:ok, experiment} = CivilizationExperimentRuntime.propose_experiment(
        :cci_cxr,
        "Test governance proposal: #{proposal.description}",
        :governance_model
      )
      {:ok, simulated} = CivilizationExperimentRuntime.run_simulation(:cci_cxr, experiment.id)

      %{
        decision: decision,
        experiment: simulated,
        recommendation: :proceed_to_human_approval
      }
    else
      %{decision: decision, recommendation: :requires_revision}
    end
  end

  # Fail-closed seams (scan A6). The previous implementations returned
  # hardcoded ASC counts (validated_assets: 450, ...) and two invented
  # sentinel observations (confidences 0.78/0.72) regardless of reality.
  # Real reads plug in here; until then the cycle reports unavailability.
  defp fetch_asc_state do
    {:error, :subsystem_state_unavailable}
  end

  defp fetch_sentinel_observations do
    {:error, :observations_unavailable}
  end
end
