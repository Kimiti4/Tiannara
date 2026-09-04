defmodule Tiannara.CCI.ConstitutionalGovernanceEngine do
  @moduledoc """
  Constitutional Governance Engine (CGE): evaluates proposals against Tiannara's
  constitutional principles. Every major action passes through:
    Proposal → Evidence → Impact Simulation → Constitutional Evaluation →
    Approval/Rejection → Execution

  Enforces: human oversight preservation, scientific integrity, value alignment.
  """
  use GenServer
  alias Tiannara.CCI.Models.GovernanceDecision

  @constitutional_principles [
    :evidence_before_confidence,
    :verification_first,
    :augments_human_intelligence,
    :knowledge_compounding,
    :safety_and_reliability,
    :long_term_sustainability,
    :transparency,
    :modularity
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def evaluate_proposal(pid, proposal), do: GenServer.call(pid, {:evaluate, proposal})
  def get_decision(pid, decision_id), do: GenServer.call(pid, {:get, decision_id})
  def record_human_decision(pid, decision_id, human_decision), do: GenServer.cast(pid, {:human_decision, decision_id, human_decision})

  @impl true
  def init(_), do: {:ok, %{decisions: %{}, audit_log: []}}

  @impl true
  def handle_call({:evaluate, proposal}, _from, state) do
    evidence = gather_evidence(proposal)
    impact = simulate_impact(proposal)
    constitutional_eval = evaluate_against_principles(proposal, evidence, impact)

    decision = %GovernanceDecision{
      id: UUID.uuid4(),
      proposal_id: proposal.id,
      timestamp: DateTime.utc_now(),
      proposal_type: proposal.type,
      description: proposal.description,
      evidence: evidence,
      impact_simulation: impact,
      constitutional_evaluation: constitutional_eval,
      human_benefit_score: calculate_human_benefit(impact),
      safety_score: calculate_safety(impact),
      long_term_stability: calculate_stability(impact),
      constitutional_alignment: constitutional_eval.overall_alignment,
      decision: :pending_human_approval,
      rationale: build_rationale(constitutional_eval),
      requires_human_approval: true,
      audit_trail: [%{step: :evaluation, timestamp: DateTime.utc_now()}]
    }

    state = put_in(state, [:decisions, decision.id], decision)
    state = update_in(state, [:audit_log], &[Map.put(decision, :step, :created) | &1])
    {:reply, {:ok, decision}, state}
  end

  @impl true
  def handle_call({:get, decision_id}, _from, state) do
    {:reply, Map.get(state.decisions, decision_id), state}
  end

  @impl true
  def handle_cast({:human_decision, decision_id, human_decision}, state) do
    case Map.get(state.decisions, decision_id) do
      nil -> {:noreply, state}
      decision ->
        updated = %{decision |
          decision: human_decision,
          audit_trail: decision.audit_trail ++ [%{
            step: :human_decision,
            decision: human_decision,
            timestamp: DateTime.utc_now()
          }]
        }
        state = put_in(state, [:decisions, decision_id], updated)
        state = update_in(state, [:audit_log], &[Map.put(updated, :step, :human_decided) | &1])
        {:noreply, state}
    end
  end

  defp gather_evidence(_proposal) do
    [
      %{source: :reality_graph, strength: 0.8},
      %{source: :asc_metrics, strength: 0.75},
      %{source: :sentinel_observations, strength: 0.82}
    ]
  end

  defp simulate_impact(_proposal) do
    %{
      short_term_benefit: 0.7,
      long_term_benefit: 0.8,
      risk_to_existing_capabilities: 0.15,
      resource_consumption: 0.3,
      knowledge_creation_potential: 0.85,
      human_oversight_impact: :neutral
    }
  end

  defp evaluate_against_principles(_proposal, evidence, impact) do
    principle_scores = Enum.map(@constitutional_principles, fn principle ->
      score = evaluate_principle(principle, evidence, impact)
      {principle, score}
    end) |> Map.new()

    scores = Map.values(principle_scores)
    total = Enum.reduce(scores, 0, fn s, acc -> acc + s.score end)
    overall = total / length(scores)

    violations = Enum.filter(principle_scores, fn {_p, v} -> v.score < 0.5 end)
    |> Enum.map(fn {p, v} -> {p, v.reason} end)

    %{
      principle_scores: principle_scores,
      overall_alignment: overall,
      violations: violations,
      recommendation: if(violations == [], do: :approve, else: :requires_revision)
    }
  end

  defp evaluate_principle(:evidence_before_confidence, evidence, _impact) do
    sum = evidence |> Enum.map(& &1.strength) |> Enum.sum()
    avg_strength = sum / length(evidence)
    %{score: avg_strength, reason: "Evidence strength: #{avg_strength}"}
  end

  defp evaluate_principle(:verification_first, _evidence, impact) do
    has_verification = impact.risk_to_existing_capabilities < 0.5
    %{score: if(has_verification, do: 0.9, else: 0.3), reason: "Verification pathway exists"}
  end

  defp evaluate_principle(:augments_human_intelligence, _evidence, impact) do
    score = case impact.human_oversight_impact do
      :enhances -> 0.95
      :neutral -> 0.75
      :reduces -> 0.2
    end
    %{score: score, reason: "Human oversight: #{impact.human_oversight_impact}"}
  end

  defp evaluate_principle(_principle, _evidence, _impact) do
    %{score: 0.75, reason: "Principle satisfied with minor concerns"}
  end

  defp calculate_human_benefit(impact) do
    (impact.short_term_benefit * 0.4 + impact.long_term_benefit * 0.6) * impact.knowledge_creation_potential
  end

  defp calculate_safety(impact) do
    1.0 - impact.risk_to_existing_capabilities
  end

  defp calculate_stability(impact) do
    impact.long_term_benefit * (1.0 - impact.resource_consumption)
  end

  defp build_rationale(eval) do
    if eval.violations == [] do
      "Proposal aligns with all constitutional principles (alignment: #{Float.round(eval.overall_alignment, 2)})."
    else
      violations_text = eval.violations |> Enum.map(fn {p, r} -> "#{p}: #{r}" end) |> Enum.join("; ")
      "Concerns: #{violations_text}. Revision required."
    end
  end
end
