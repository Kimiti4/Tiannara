defmodule Tiannara.ACE.Models do
  @moduledoc """
  Core data structures for Autonomous Civilization Engineering.
  Transforms validated knowledge into engineered systems through
  design evolution, simulation, and constitutional governance.
  """

  defmodule EngineeringProposal do
    @moduledoc "A proposal to engineer a system based on validated capabilities."
    defstruct [
      :id, :problem_statement, :target_system,
      :required_capabilities, :constraints,
      design_candidates: [],
      simulation_results: [],
      confidence_score: 0.0,
      risk_assessment: %{},
      human_benefit: 0.0,
      sustainability_score: 0.0,
      long_term_stability: 0.0,
      approval_status: :pending,
      created_at: nil
    ]
  end

  defmodule DesignCandidate do
    @moduledoc "A candidate engineering solution evolved through simulation."
    defstruct [
      :id, :proposal_id, :design_spec,
      performance_metrics: %{},
      resource_requirements: %{},
      failure_modes: [],
      simulation_accuracy: 0.0,
      fitness: 0.0,
      lineage: [],
      generation: 0,
      status: :evaluating
    ]
  end

  defmodule CapabilityGenome do
    @moduledoc "Structured representation of an engineering capability."
    defstruct [
      :id, :name, :domain,
      :scientific_foundation,
      required_resources: %{},
      dependencies: [],
      performance_characteristics: %{},
      applications: [],
      risks: [],
      evolution_history: [],
      maturity_level: :emerging,
      reusability_score: 0.0
    ]
  end

  defmodule SimulationResult do
    @moduledoc "Result from testing a design in the Civilization Digital Twin."
    defstruct [
      :id, :design_id, :simulation_environment,
      success_metrics: %{},
      failure_scenarios: [],
      edge_cases_tested: 0,
      confidence_level: 0.0,
      unexpected_behaviors: [],
      timestamp: nil
    ]
  end

  defmodule EngineeringInstitution do
    @moduledoc "A specialized engineering organization that evolves capabilities."
    defstruct [
      :id, :name, :domain, :specialization,
      capabilities_stewarded: [],
      designs_produced: [],
      knowledge_base: [],
      collaboration_partners: [],
      performance_metrics: %{},
      status: :active
    ]
  end

  defmodule EngineeringConfidence do
    @moduledoc "Multi-dimensional confidence assessment for engineering proposals."
    defstruct [
      :proposal_id,
      evidence_strength: 0.0,
      simulation_accuracy: 0.0,
      failure_probability: 0.0,
      resource_adequacy: 0.0,
      safety_analysis: 0.0,
      long_term_effects: 0.0,
      overall_confidence: 0.0,
      unresolved_dependencies: [],
      recommendation: :unknown
    ]
  end
end
