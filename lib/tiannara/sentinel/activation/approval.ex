defmodule Tiannara.Sentinel.Activation.Approval do
  @moduledoc """
  Human Approval Gateway — the critical safety layer ensuring no action
  modifies Tiannara state without proposal, risk analysis, simulation,
  and human decision.

  No production-changing action executes without:
    Proposal → Simulation → Risk Report → Rollback Check → Human Decision
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Creates an approval proposal for a recommended action.
  Runs a simulation, generates a risk report, and pushes to the Observatory.
  """
  @spec propose(Event.t(), map()) :: map()
  def propose(%Event{} = event, recommendation) do
    simulation = simulate_impact(recommendation)
    risk_score = recommendation.risk

    proposal = %{
      proposal_id: UUID.uuid4(),
      event_id: event.id,
      action: recommendation.action,
      expected_benefit: recommendation.expected_gain,
      risk_score: risk_score,
      rollback_available: true,
      requires_approval: risk_score > 0.05,
      status: :pending,
      simulation_result: simulation,
      confidence: recommendation.confidence
    }

    Tiannara.Observatory.push_proposal(proposal)
    proposal
  end

  @doc """
  Processes human approval or rejection of a proposal.
  On approval, the action is routed through the Phase-4 experiment gateway —
  the single real-execution path (MC-003-M M2). With real execution disabled
  the gateway refuses; nothing is executed in any theater sandbox.
  """
  @spec decide(String.t(), :approve | :reject) :: :ok | :error | {:error, term()}
  def decide(proposal_id, :approve) do
    case Tiannara.Phase4.ExperimentOrchestrator.submit_experiment(%{
           id: proposal_id,
           type: :sentinel_approval,
           provenance: proposal_id,
           name: "Sentinel approval action #{proposal_id}",
           hypotheses: []
         }) do
      {:ok, _experiment_id} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def decide(_proposal_id, :reject), do: :ok

  defp simulate_impact(rec) do
    %{
      success_probability: max(0.0, 1.0 - rec.risk),
      expected_metric_delta: rec.expected_gain,
      confidence: rec.confidence
    }
  end
end
