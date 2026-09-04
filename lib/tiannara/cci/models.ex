defmodule Tiannara.CCI.Models do
  @moduledoc """
  Core data structures for Constitutional Civilization Intelligence.
  Transforms ASC's scientific civilization into a self-understanding,
  self-regulating, constitutionally governed intelligence system.
  """

  defmodule CivilizationState do
    @moduledoc "Comprehensive model of Tiannara's current civilizational state."
    defstruct [
      :id, :timestamp,
      knowledge_state: %{},
      capability_state: %{},
      research_state: %{},
      technological_state: %{},
      institutional_state: %{},
      resource_state: %{},
      risk_state: %{},
      uncertainty_state: %{},
      causal_state: %{},
      future_state: %{},
      confidence: 0.0,
      health_score: 0.0
    ]
  end

  defmodule GovernanceDecision do
    @moduledoc "A governance decision evaluated against constitutional principles."
    defstruct [
      :id, :proposal_id, :timestamp,
      :proposal_type, :description,
      evidence: [],
      impact_simulation: %{},
      constitutional_evaluation: %{},
      human_benefit_score: 0.0,
      safety_score: 0.0,
      long_term_stability: 0.0,
      constitutional_alignment: 0.0,
      decision: :pending,
      rationale: "",
      requires_human_approval: true,
      audit_trail: []
    ]
  end

  defmodule CivilizationForecast do
    @moduledoc "A forecasted civilizational trajectory with multiple possible futures."
    defstruct [
      :id, :timestamp, :horizon_cycles,
      :baseline_trajectory,
      possible_futures: [],
      risks: [],
      opportunities: [],
      bottlenecks: [],
      confidence: 0.0,
      uncertainty_factors: []
    ]
  end

  defmodule PossibleFuture do
    @moduledoc "One possible civilizational future trajectory."
    defstruct [
      :id, :name, :probability,
      :description,
      characteristics: %{},
      leading_indicators: [],
      intervention_points: []
    ]
  end

  defmodule InstitutionalHealth do
    @moduledoc "Health assessment of a civilizational institution."
    defstruct [
      :institution_id, :timestamp,
      effectiveness: 0.0,
      adaptability: 0.0,
      redundancy: 0.0,
      corruption_risk: 0.0,
      stagnation_risk: 0.0,
      knowledge_preservation: 0.0,
      human_alignment: 0.0,
      overall_health: 0.0,
      recommendations: []
    ]
  end

  defmodule CivilizationalMemoryRecord do
    @moduledoc "A preserved civilizational memory record (discovery, failure, decision, pathway)."
    defstruct [
      :id, :type, :timestamp,
      :domain, :content,
      :context, :outcome,
      :lessons_learned,
      :related_records,
      :preservation_reason,
      confidence: 0.0,
      reuse_count: 0
    ]
  end

  defmodule CivilizationExperiment do
    @moduledoc "A safe experiment on civilizational structures or processes."
    defstruct [
      :id, :hypothesis, :timestamp,
      :experiment_type, :scope,
      :simulation_phase, :trial_phase,
      :evaluation_metrics,
      :success_criteria,
      :failure_conditions,
      :rollback_plan,
      :status, :results,
      :human_approval,
      :constitutional_check
    ]
  end

  defmodule ResearchPriority do
    @moduledoc "A civilization-scale research priority recommendation."
    defstruct [
      :id, :timestamp,
      :domain, :rationale,
      :evidence, :causal_chain,
      :expected_impact,
      :confidence, :unknowns,
      :alternatives,
      :resource_requirements,
      :human_benefit,
      :recommendation_level
    ]
  end

  defmodule CivilizationalRisk do
    @moduledoc "A detected civilizational-scale risk."
    defstruct [
      :id, :category, :timestamp,
      :description, :severity,
      :probability, :impact,
      :early_indicators,
      :mitigation_options,
      :confidence, :evidence,
      :requires_immediate_action
    ]
  end
end
