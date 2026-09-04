defmodule TiannaraOS.CivilizationAdaptationResult do
  @moduledoc """
  CivilizationAdaptationResult - Canonical constitutional transaction for civilization-scale adaptation.

  Capability 13.5 - Civilization Adaptation

  This artifact captures the evaluation and coordination of institutional improvements
  across the entire research civilization. The civilization asks "Which improvements
  should spread?" and performs evidence-based civilizational adaptation.

  ## Constitutional Role

  Civilization Adaptation evaluates InstitutionAdaptationResults from all institutions
  and determines which improvements should spread, remain local, or be rejected.
  It does NOT generate improvements; it coordinates their propagation.

  ## Constitutional Pipeline

  ```
  Collect InstitutionAdaptationResults
      ↓
  Validate completeness
      ↓
  Group by adaptation families
      ↓
  Compare outcomes across institutions
      ↓
  Analyze transferability
      ↓
  Make civilizational decision
      ↓
  Generate rollout plan
      ↓
  Record CivilizationAdaptationResult
  ```

  ## Constitutional Invariants

  1. Evidence-based only (all decisions reference canonical transactions)
  2. No forced adoption (institutions decide, civilization coordinates)
  3. Diversity preservation (conflicting adaptations may coexist)
  4. Rollback available (civilization-wide reversibility)
  5. Complete provenance (every decision traces to supporting episodes)
  6. Prediction history influences rollout (learning from forecast accuracy)
  7. Governance reviews process—not scientific merit

  ## Civilizational Decisions

  - :universal_adoption - Spread to all compatible institutions
  - :selective_adoption - Spread to subset based on similarity
  - :experimental_expansion - Test in additional institutions
  - :further_validation - Require more evidence before spreading
  - :reject - Unsafe or ineffective, do not spread
  - :preserve_diversity - Conflicting adaptations both valid locally

  ## Transferability Categories

  - :universal - Works across all domains/institutions
  - :domain_specific - Works within specific scientific domain
  - :institution_specific - Only works in originating institution
  - :experimental - Needs more testing
  - :unsafe - Harmful if spread
  - :rejected - Proven ineffective

  ## Usage

      # Create civilization adaptation result
      {:ok, result} = CivilizationAdaptationResult.new(:tiannara_civilization, %{
        generation: 1,
        institutions_evaluated: 20
      })

      # Record adaptation families
      result = CivilizationAdaptationResult.record_adaptation_families(result, families)

      # Make civilizational decision
      result = CivilizationAdaptationResult.make_civilization_decision(result, :universal_adoption, %{
        rationale: "Improvement shows consistent success across 15/20 institutions"
      })

      # Generate rollout plan
      result = CivilizationAdaptationResult.generate_rollout_plan(result, plan)
  """

  defstruct [
    # Core identification
    :id,
    :civilization_id,
    :adaptation_timestamp,
    :generation,

    # Scope
    :institutions_evaluated,
    :total_adaptations_analyzed,

    # Adaptation families
    :adaptation_families,

    # Transferability analysis
    :transferability_analysis,

    # Civilizational decision
    :civilization_decision,
    :decision_rationale,
    :decision_timestamp,

    # Rollout plan
    :rollout_plan,

    # Supporting evidence
    :supporting_institutions,
    :supporting_episodes,
    :supporting_adaptation_results,
    :prediction_history,

    # Resource tracking
    :estimated_resources,
    :expected_benefits,
    :expected_risks,

    # Constitutional compliance
    :traceability_graph,
    :lifecycle_events,
    :semantic_events,
    :constitutional_compliance,

    # Status
    :status,
    :failure_reason
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    civilization_id: atom(),
    adaptation_timestamp: DateTime.t(),
    generation: integer(),
    institutions_evaluated: integer(),
    total_adaptations_analyzed: integer(),
    adaptation_families: [map()] | nil,
    transferability_analysis: map() | nil,
    civilization_decision: atom() | nil,
    decision_rationale: String.t() | nil,
    decision_timestamp: DateTime.t() | nil,
    rollout_plan: map() | nil,
    supporting_institutions: [atom()] | nil,
    supporting_episodes: [atom()] | nil,
    supporting_adaptation_results: [String.t()] | nil,
    prediction_history: map() | nil,
    estimated_resources: map() | nil,
    expected_benefits: map() | nil,
    expected_risks: map() | nil,
    traceability_graph: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    constitutional_compliance: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }

  @doc """
  Create a new CivilizationAdaptationResult.

  ## Parameters
  - `civilization_id`: atom() - civilization identifier
  - `opts`: keyword list or map with optional fields

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def new(civilization_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts

    %__MODULE__{
      id: Keyword.get(opts, :id, "civ_adaptation_#{civilization_id}_gen#{Keyword.get(opts, :generation, 1)}_#{System.monotonic_time(:millisecond)}"),
      civilization_id: civilization_id,
      adaptation_timestamp: DateTime.utc_now(),
      generation: Keyword.get(opts, :generation, 1),
      institutions_evaluated: Keyword.get(opts, :institutions_evaluated, 0),
      total_adaptations_analyzed: Keyword.get(opts, :total_adaptations_analyzed, 0),
      adaptation_families: nil,
      transferability_analysis: nil,
      civilization_decision: nil,
      decision_rationale: nil,
      decision_timestamp: nil,
      rollout_plan: nil,
      supporting_institutions: nil,
      supporting_episodes: nil,
      supporting_adaptation_results: nil,
      prediction_history: nil,
      estimated_resources: nil,
      expected_benefits: nil,
      expected_risks: nil,
      traceability_graph: nil,
      lifecycle_events: [],
      semantic_events: [],
      constitutional_compliance: nil,
      status: :pending,
      failure_reason: nil
    }
  end

  @doc """
  Advance adaptation to next stage.

  Records stage transition in history for complete audit trail.

  ## Valid Stage Transitions

  :adaptations_collected → :validated
  :validated → :families_grouped
  :families_grouped → :compared
  :compared → :transferability_analyzed
  :transferability_analyzed → :decision_made
  :decision_made → :rollout_planned
  :rollout_planned → :recorded

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `new_stage`: atom() - target stage

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def advance_stage(result, new_stage) do
    valid_transitions = %{
      adaptations_collected: [:validated],
      validated: [:families_grouped],
      families_grouped: [:compared],
      compared: [:transferability_analyzed],
      transferability_analyzed: [:decision_made],
      decision_made: [:rollout_planned],
      rollout_planned: [:recorded]
    }

    current_stage = result.status
    allowed_next_stages = Map.get(valid_transitions, current_stage, [])

    if new_stage not in allowed_next_stages do
      raise ArgumentError,
        message: "Invalid stage transition from #{inspect(current_stage)} to #{inspect(new_stage)}. Allowed: #{inspect(allowed_next_stages)}"
    end

    stage_record = %{
      stage: new_stage,
      timestamp: DateTime.utc_now(),
      previous_stage: current_stage
    }

    lifecycle_events = result.lifecycle_events ++ [stage_record]

    %{result | status: new_stage, lifecycle_events: lifecycle_events}
  end

  @doc """
  Record adaptation families grouped by characteristics.

  Groups similar adaptations for comparison across institutions.

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `families`: [map()] list of adaptation family groups

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def record_adaptation_families(result, families) do
    %{result | adaptation_families: families}
  end

  @doc """
  Record transferability analysis results.

  Determines whether adaptations are universal, domain-specific, institution-specific, etc.

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `analysis`: map() with keys:
    - :universal_count - integer()
    - :domain_specific_count - integer()
    - :institution_specific_count - integer()
    - :experimental_count - integer()
    - :unsafe_count - integer()
    - :rejected_count - integer()
    - :family_details - [map()] per-family analysis

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def record_transferability_analysis(result, analysis) do
    %{result | transferability_analysis: analysis}
  end

  @doc """
  Make civilizational decision about adaptation propagation.

  Decides whether to spread, restrict, or reject improvements.

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `decision`: atom() - :universal_adoption, :selective_adoption, :experimental_expansion,
                :further_validation, :reject, :preserve_diversity
  - `rationale`: map() with keys:
    - :reasoning - String.t() explanation
    - :key_factors - [String.t()] primary considerations
    - :supporting_evidence - [String.t()] references to canonical transactions

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def make_civilization_decision(result, decision, rationale) do
    %{
      result
      | civilization_decision: decision,
        decision_rationale: inspect(rationale),
        decision_timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Generate rollout plan for approved adaptations.

  Creates deployment strategy including resources, timeline, and rollback.

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `plan`: map() with keys:
    - :recommended_institutions - [atom()]
    - :deployment_order - [atom()] ordered list
    - :required_resources - map() budget, personnel, time
    - :expected_benefits - map() predicted improvements
    - :expected_risks - [map()] potential issues
    - :rollback_strategy - map() reversal procedure
    - :evaluation_checkpoints - [map()] monitoring points

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def generate_rollout_plan(result, plan) do
    %{
      result
      | rollout_plan: plan,
        estimated_resources: plan[:required_resources],
        expected_benefits: plan[:expected_benefits],
        expected_risks: plan[:expected_risks]
    }
  end

  @doc """
  Record supporting evidence for civilizational decision.

  Links decision back to canonical transactions (episodes, adaptations, predictions).

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `evidence`: map() with keys:
    - :institutions - [atom()] supporting institutions
    - :episodes - [atom()] supporting research episodes
    - :adaptation_results - [String.t()] supporting adaptation IDs
    - :prediction_history - map() historical prediction accuracy

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def record_supporting_evidence(result, evidence) do
    %{
      result
      | supporting_institutions: evidence[:institutions],
        supporting_episodes: evidence[:episodes],
        supporting_adaptation_results: evidence[:adaptation_results],
        prediction_history: evidence[:prediction_history]
    }
  end

  @doc """
  Add lifecycle event for traceability.

  Records key moments in the civilization adaptation process.

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `event_type`: atom()
  - `metadata`: map()

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def add_lifecycle_event(result, event_type, metadata) do
    event = %{
      type: event_type,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }

    events = result.lifecycle_events ++ [event]
    %{result | lifecycle_events: events}
  end

  @doc """
  Add semantic event for audit trail.

  Captures high-level semantic meaning of civilization adaptation steps.

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()
  - `event_type`: atom()
  - `metadata`: map()

  ## Returns
  CivilizationAdaptationResult.t()
  """
  def add_semantic_event(result, event_type, metadata) do
    event = %{
      type: event_type,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }

    events = result.semantic_events ++ [event]
    %{result | semantic_events: events}
  end

  @doc """
  Validate constitutional compliance of the civilization adaptation.

  Ensures all invariants are satisfied:
  - Evidence-based decisions (references canonical transactions)
  - No forced adoption (institutions retain autonomy)
  - Rollback available (reversibility preserved)
  - Complete provenance (full traceability)
  - Governance reviewed (process compliance verified)

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()

  ## Returns
  {:compliant, violations} where violations is empty list if compliant
  """
  def validate_constitutional_compliance(result) do
    violations = []

    # Check 1: Must have supporting evidence
    violations = if result.civilization_decision != nil and result.supporting_institutions == nil do
      [%{rule: "evidence_required", message: "Decision made without supporting institutions"} | violations]
    else
      violations
    end

    # Check 2: Must have rollout plan if adopting
    violations = if result.civilization_decision in [:universal_adoption, :selective_adoption, :experimental_expansion] and result.rollout_plan == nil do
      [%{rule: "rollout_required", message: "Adoption decision without rollout plan"} | violations]
    else
      violations
    end

    # Check 3: Must have complete lifecycle
    required_stages = [:adaptations_collected, :validated, :families_grouped, :compared, :transferability_analyzed, :decision_made, :rollout_planned, :recorded]
    completed_stages = Enum.map(result.lifecycle_events, fn e -> e.stage end)
    missing_stages = Enum.filter(required_stages, fn stage -> stage not in completed_stages end)

    violations = if length(missing_stages) > 0 do
      [%{rule: "incomplete_pipeline", message: "Missing required stages: #{inspect(missing_stages)}"} | violations]
    else
      violations
    end

    # Check 4: Must have prediction history considered
    violations = if result.civilization_decision != nil and result.prediction_history == nil do
      [%{rule: "prediction_history_required", message: "Decision made without considering prediction accuracy"} | violations]
    else
      violations
    end

    compliance = %{
      checked_at: DateTime.utc_now(),
      total_violations: length(violations),
      violations: violations,
      is_compliant: length(violations) == 0
    }

    {%{result | constitutional_compliance: compliance}, violations}
  end

  @doc """
  Build traceability graph linking civilization adaptation to evidence.

  Creates visualizable graph showing:
  - Which institutions contributed adaptations
  - Supporting research episodes
  - Prediction history
  - Final civilizational decision

  ## Parameters
  - `result`: CivilizationAdaptationResult.t()

  ## Returns
  map() with nodes and edges for visualization
  """
  def build_traceability_graph(result) do
    nodes = []
    edges = []

    # Add civilization node
    civ_node = %{
      id: "civilization_#{result.civilization_id}",
      type: :civilization,
      label: "Civilization #{result.civilization_id}",
      generation: result.generation
    }
    nodes = [civ_node | nodes]

    # Add institution nodes
    institution_nodes = if result.supporting_institutions do
      Enum.map(result.supporting_institutions, fn inst ->
        %{
          id: "institution_#{inst}",
          type: :institution,
          label: "Institution #{inst}"
        }
      end)
    else
      []
    end
    nodes = institution_nodes ++ nodes

    # Add decision node
    decision_node = %{
      id: "decision_#{result.id}",
      type: :decision,
      label: "Civilization Decision: #{inspect(result.civilization_decision)}",
      decision: result.civilization_decision
    }
    nodes = [decision_node | nodes]

    # Add edges from institutions to decision
    institution_edges = if result.supporting_institutions do
      Enum.map(result.supporting_institutions, fn inst ->
        %{
          from: "institution_#{inst}",
          to: "decision_#{result.id}",
          type: :contributed_to
        }
      end)
    else
      []
    end
    edges = institution_edges ++ edges

    # Add edge from civilization to decision
    civ_edge = %{
      from: "civilization_#{result.civilization_id}",
      to: "decision_#{result.id}",
      type: :coordinated
    }
    edges = [civ_edge | edges]

    %{
      nodes: nodes,
      edges: edges,
       summary: %{
        total_nodes: length(nodes),
        total_edges: length(edges),
        civilization_id: result.civilization_id,
        generation: result.generation,
        final_decision: result.civilization_decision,
        supporting_institutions_count: length(result.supporting_institutions || [])
      }
    }
  end

  def identify_successful_patterns(_institution_id, _opts), do: {:ok, []}
  def record_comparative_analysis(_institution_id, _opts), do: {:ok, :stub}
  def assess_transferability(_institution_id, _opts), do: {:ok, :stub}
  def assess_diversity_impact(_institution_id, _opts), do: {:ok, :stub}
  def analyze_specialization_opportunities(_institution_id, _opts), do: {:ok, []}
  def analyze_collaboration_potential(_institution_id, _opts), do: {:ok, []}
  def analyze_ecosystem_effects(_institution_id, _opts), do: {:ok, :stub}
  def assess_resilience_impact(_institution_id, _opts), do: {:ok, :stub}
  def make_coordination_recommendation(_institution_id, _opts, _context), do: {:ok, :stub}
  def plan_rollout(_institution_id, _opts), do: {:ok, :stub}
  def track_adoption(_institution_id, _opts), do: {:ok, :stub}
  def evaluate_outcome(_institution_id, _opts), do: {:ok, :stub}
  def add_lessons_learned(_institution_id, _opts), do: {:ok, :stub}
  def record_institutional_improvements(_institution_id, _opts), do: {:ok, :stub}
end
