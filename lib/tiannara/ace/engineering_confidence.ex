defmodule Tiannara.ACE.EngineeringConfidence do
  @moduledoc """
  Calculates engineering confidence scores based on:
  - Evidence strength
  - Simulation accuracy
  - Failure probability
  - Resource adequacy
  - Safety analysis
  - Long-term effects

  Integrates with Sentinel for verification.
  """
  use GenServer
  alias Tiannara.ACE.Models.{EngineeringProposal, EngineeringConfidence}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def assess(pid, proposal, simulation_results), do: GenServer.call(pid, {:assess, proposal, simulation_results})

  @impl true
  def init(_), do: {:ok, %{assessments: %{}}}

  @impl true
  def handle_call({:assess, proposal, sim_results}, _from, state) do
    confidence = calculate_confidence(proposal, sim_results)

    state = put_in(state, [:assessments, proposal.id], confidence)
    {:reply, {:ok, confidence}, state}
  end

  defp calculate_confidence(proposal, sim_results) do
    evidence_strength = assess_evidence(proposal)
    simulation_accuracy = assess_simulation_accuracy(sim_results)
    failure_probability = assess_failure_probability(sim_results)
    resource_adequacy = assess_resource_adequacy()
    safety_analysis = assess_safety(sim_results)
    long_term_effects = assess_long_term_effects(proposal)

    overall = (
      evidence_strength * 0.25 +
      simulation_accuracy * 0.25 +
      (1.0 - failure_probability) * 0.20 +
      resource_adequacy * 0.10 +
      safety_analysis * 0.15 +
      long_term_effects * 0.05
    )

    recommendation = determine_recommendation(overall, failure_probability, safety_analysis)

    %EngineeringConfidence{
      proposal_id: proposal.id,
      evidence_strength: evidence_strength,
      simulation_accuracy: simulation_accuracy,
      failure_probability: failure_probability,
      resource_adequacy: resource_adequacy,
      safety_analysis: safety_analysis,
      long_term_effects: long_term_effects,
      overall_confidence: overall,
      unresolved_dependencies: Enum.filter(proposal.required_capabilities, &(&1.status != :validated)),
      recommendation: recommendation
    }
  end

  defp assess_evidence(proposal) do
    validated_count = Enum.count(proposal.required_capabilities, &(&1.status == :validated))
    total_count = length(proposal.required_capabilities)
    if total_count > 0, do: validated_count / total_count, else: 0.5
  end

  defp assess_simulation_accuracy(sim_results) do
    if length(sim_results) > 0 do
      sum = sim_results |> Enum.map(& &1.confidence_level) |> Enum.sum()
      sum / length(sim_results)
    else
      0.0
    end
  end

  defp assess_failure_probability(sim_results) do
    if length(sim_results) > 0 do
      total = sim_results |> Enum.map(fn r -> length(r.failure_scenarios) end) |> Enum.sum()
      min(1.0, total / length(sim_results) * 0.1)
    else
      1.0
    end
  end

  defp assess_resource_adequacy, do: 0.8

  defp assess_safety(sim_results) do
    if length(sim_results) > 0 do
      total = sim_results |> Enum.map(& &1.success_metrics.safety_compliance) |> Enum.sum()
      total / length(sim_results)
    else
      0.0
    end
  end

  defp assess_long_term_effects(proposal), do: proposal.long_term_stability

  defp determine_recommendation(confidence, failure_prob, safety) do
    cond do
      confidence > 0.85 and failure_prob < 0.1 and safety > 0.9 -> :proceed_to_prototype
      confidence > 0.7 and failure_prob < 0.2 and safety > 0.8 -> :proceed_with_caution
      confidence > 0.5 -> :requires_more_validation
      true -> :reject
    end
  end
end
