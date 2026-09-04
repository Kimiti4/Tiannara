defmodule TiannaraOS.InstitutionSelfModel do
  @moduledoc """
  InstitutionSelfModel - Canonical constitutional transaction for institution self-model formation.
  
  This artifact captures an explicit, evidence-grounded model of an institution's own scientific
  reasoning capabilities, limitations, methodological tendencies, and epistemic confidence using
  only constitutionally traceable evidence.
  
  ## Key Principle: Self-Knowledge Over Performance Analytics
  
  Instead of producing performance reports or evaluation scores, this result stores an explicit
  representation of how the institution reasons, where it succeeds, where it fails, what
  methodologies it favors, and what uncertainties remain about its own reasoning.
  
  The result is **self-knowledge**, not performance analytics.
  
  ## Constitutional Discipline
  
  - One institutional behavior: constructing explicit model of itself
  - One public API: InstitutionKernel.construct_self_model/2
  - One canonical transaction: InstitutionSelfModel
  - No new persistent state: composes existing frozen primitives
  - Complete traceability: every finding references supporting episodes/theories/plans
  - Self-model uncertainty explicitly represented
  
  ## Phase 13 Significance
  
  This capability represents the beginning of **recursive cognition**.
  
  The institution is no longer merely producing science.
  
  It is producing an explicit model of itself.
  
  Before: Institution conducts research → External observer evaluates
  After: Institution constructs self-model → Civilization composes many self-models
  
  ## Usage
  
      model = InstitutionSelfModel.new(institution_id, opts)
      model = InstitutionSelfModel.add_reasoning_strength(model, strength_data)
      model = InstitutionSelfModel.add_reasoning_limitation(model, limitation_data)
      model = InstitutionSelfModel.add_methodological_tendency(model, tendency_data)
      model = InstitutionSelfModel.estimate_model_confidence(model)
      model = InstitutionSelfModel.mark_constructed(model)
  """
  
  defstruct [
    # Core identification
    :id,
    :institution_id,
    :construction_timestamp,
    
    # Model scope and metadata
    :model_scope,  # :recent, :full, :custom
    :episodes_observed,
    :theories_observed,
    :research_programs_observed,
    :time_range_start,
    :time_range_end,
    
    # Self-model quality metrics (replaces health_score)
    :model_confidence,  # How certain is the institution about its own self-model?
    :self_understanding_quality,  # How well does the institution understand itself?
    
    # Reasoning strengths (what the institution does well)
    :reasoning_strengths,
    
    # Reasoning limitations (where the institution struggles)
    :reasoning_limitations,
    
    # Methodological tendencies (preferred approaches, biases)
    :methodological_tendencies,
    
    # Epistemic uncertainties (what the institution doesn't know about itself)
    :epistemic_uncertainties,
    
    # Comparative history (optional comparison to previous self-models)
    :comparative_history,
    
    # Constitutional compliance verification
    :constitutional_compliance,
    
    # Supporting data references
    :episode_ids_observed,
    :theory_ids_observed,
    :plan_ids_observed,
    :topology_ids_observed,
    
    # Constitutional deltas
    :knowledge_delta,
    :ledger_delta,
    :traceability_graph,
    :lifecycle_events,
    :semantic_events,
    :governance_decisions,
    :constitutional_validation,
    
    # Status
    :status,
    :failure_reason
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    institution_id: atom(),
    construction_timestamp: DateTime.t(),
    model_scope: atom(),
    episodes_observed: non_neg_integer(),
    theories_observed: non_neg_integer(),
    research_programs_observed: non_neg_integer(),
    time_range_start: DateTime.t() | nil,
    time_range_end: DateTime.t() | nil,
    model_confidence: float() | nil,
    self_understanding_quality: float() | nil,
    reasoning_strengths: [map()],
    reasoning_limitations: [map()],
    methodological_tendencies: [map()],
    epistemic_uncertainties: [map()],
    comparative_history: map() | nil,
    constitutional_compliance: map() | nil,
    episode_ids_observed: [String.t()],
    theory_ids_observed: [String.t()],
    plan_ids_observed: [String.t()],
    topology_ids_observed: [String.t()],
    knowledge_delta: map() | nil,
    ledger_delta: map() | nil,
    traceability_graph: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    governance_decisions: [map()],
    constitutional_validation: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }
  
  @doc """
  Create a new InstitutionSelfModel.
  
  ## Parameters
  
  - `institution_id`: atom() - institution constructing self-model
  - `opts`: keyword list or map with optional fields
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def new(institution_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts
    
    %__MODULE__{
      id: Keyword.get(opts, :id, "self_model_#{institution_id}_#{System.monotonic_time(:millisecond)}"),
      institution_id: institution_id,
      construction_timestamp: DateTime.utc_now(),
      model_scope: Keyword.get(opts, :model_scope, :recent),
      episodes_observed: 0,
      theories_observed: 0,
      research_programs_observed: 0,
      time_range_start: nil,
      time_range_end: nil,
      model_confidence: nil,
      self_understanding_quality: nil,
      reasoning_strengths: [],
      reasoning_limitations: [],
      methodological_tendencies: [],
      epistemic_uncertainties: [],
      comparative_history: nil,
      constitutional_compliance: nil,
      episode_ids_observed: [],
      theory_ids_observed: [],
      plan_ids_observed: [],
      topology_ids_observed: [],
      knowledge_delta: nil,
      ledger_delta: nil,
      traceability_graph: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      constitutional_validation: nil,
      status: :initiated,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a lifecycle event to the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `event_data`: map() - event data with fields:
    - `:event` - event type atom
    - `:tick` - current tick number
    - `:details` - additional context
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def add_lifecycle_event(model, event_data) do
    event = %{
      event: Map.get(event_data, :event),
      timestamp: DateTime.utc_now(),
      tick: Map.get(event_data, :tick),
      details: Map.get(event_data, :details, %{})
    }
    
    %{model | lifecycle_events: model.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a semantic event to the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `event_type`: atom() - type of semantic event
  - `data`: map() - event data
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def add_semantic_event(model, event_type, data) do
    %{model | semantic_events: model.semantic_events ++ [%{type: event_type, data: data}]}
  end
  
  @doc """
  Add a reasoning strength to the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `strength_data`: map() - strength data with fields:
    - `:category` - area of strength (:theory_formation, :experiment_design, etc.)
    - `:description` - human-readable description
    - `:evidence` - supporting data (episode IDs, theory IDs, metrics)
    - `:confidence` - confidence level (0.0-1.0)
    - `:reuse_potential` - how applicable this strength is to future work
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def add_reasoning_strength(model, strength_data) do
    strength = %{
      strength_id: "strength_#{length(model.reasoning_strengths) + 1}",
      category: Map.get(strength_data, :category, :unknown),
      description: Map.get(strength_data, :description, ""),
      evidence: Map.get(strength_data, :evidence, []),
      confidence: Map.get(strength_data, :confidence, 0.5),
      reuse_potential: Map.get(strength_data, :reuse_potential, :medium),
      identified_at: DateTime.utc_now()
    }
    
    %{model | reasoning_strengths: model.reasoning_strengths ++ [strength]}
  end
  
  @doc """
  Add a reasoning limitation to the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `limitation_data`: map() - limitation data with fields:
    - `:category` - area of limitation (:theory_formation, :experiment_design, etc.)
    - `:description` - human-readable description
    - `:evidence` - supporting data (episode IDs, theory IDs, metrics)
    - `:severity` - :low, :medium, :high, :critical
    - `:potential_improvement` - observation about possible improvement (NOT implementation)
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def add_reasoning_limitation(model, limitation_data) do
    limitation = %{
      limitation_id: "limitation_#{length(model.reasoning_limitations) + 1}",
      category: Map.get(limitation_data, :category, :unknown),
      description: Map.get(limitation_data, :description, ""),
      evidence: Map.get(limitation_data, :evidence, []),
      severity: Map.get(limitation_data, :severity, :medium),
      potential_improvement: Map.get(limitation_data, :potential_improvement, ""),
      identified_at: DateTime.utc_now()
    }
    
    %{model | reasoning_limitations: model.reasoning_limitations ++ [limitation]}
  end
  
  @doc """
  Add a methodological tendency to the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `tendency_data`: map() - tendency data with fields:
    - `:area` - which area shows tendency
    - `:description` - description of the tendency/bias
    - `:evidence` - supporting observations
    - `:frequency` - how often this tendency appears
    - `:impact` - effect on research outcomes
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def add_methodological_tendency(model, tendency_data) do
    tendency = %{
      tendency_id: "tendency_#{length(model.methodological_tendencies) + 1}",
      area: Map.get(tendency_data, :area, :unknown),
      description: Map.get(tendency_data, :description, ""),
      evidence: Map.get(tendency_data, :evidence, []),
      frequency: Map.get(tendency_data, :frequency, :occasional),
      impact: Map.get(tendency_data, :impact, :neutral),
      identified_at: DateTime.utc_now()
    }
    
    %{model | methodological_tendencies: model.methodological_tendencies ++ [tendency]}
  end
  
  @doc """
  Add an epistemic uncertainty to the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `uncertainty_data`: map() - uncertainty data with fields:
    - `:area` - area of uncertainty
    - `:description` - what the institution doesn't know about itself
    - `:evidence_gap` - what evidence is missing
    - `:impact_on_confidence` - how this affects model_confidence
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def add_epistemic_uncertainty(model, uncertainty_data) do
    uncertainty = %{
      uncertainty_id: "uncertainty_#{length(model.epistemic_uncertainties) + 1}",
      area: Map.get(uncertainty_data, :area, :unknown),
      description: Map.get(uncertainty_data, :description, ""),
      evidence_gap: Map.get(uncertainty_data, :evidence_gap, ""),
      impact_on_confidence: Map.get(uncertainty_data, :impact_on_confidence, :low),
      identified_at: DateTime.utc_now()
    }
    
    %{model | epistemic_uncertainties: model.epistemic_uncertainties ++ [uncertainty]}
  end
  
  @doc """
  Set comparative history (comparison to previous self-models).
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `history_data`: map() - history data with fields:
    - `:previous_model_id` - ID of previous self-model
    - `:changes_in_strengths` - what strengths changed
    - `:changes_in_limitations` - what limitations changed
    - `:evolution_pattern` - observed evolution pattern
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def set_comparative_history(model, history_data) do
    history = %{
      previous_model_id: Map.get(history_data, :previous_model_id),
      changes_in_strengths: Map.get(history_data, :changes_in_strengths, []),
      changes_in_limitations: Map.get(history_data, :changes_in_limitations, []),
      evolution_pattern: Map.get(history_data, :evolution_pattern, :stable),
      compared_at: DateTime.utc_now()
    }
    
    %{model | comparative_history: history}
  end
  
  @doc """
  Estimate model confidence based on coverage, consistency, and evidence quality.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  
  ## Returns
  
  InstitutionSelfModel.t() with model_confidence and self_understanding_quality set
  """
  def estimate_model_confidence(model) do
    # Calculate confidence based on multiple factors
    coverage_score = calculate_coverage_score(model)
    consistency_score = calculate_consistency_score(model)
    evidence_quality = calculate_evidence_quality(model)
    
    # Weighted combination
    confidence = (
      coverage_score * 0.4 +
      consistency_score * 0.35 +
      evidence_quality * 0.25
    )
    
    # Self-understanding quality is similar but focuses on depth vs breadth
    understanding_quality = (
      coverage_score * 0.3 +
      consistency_score * 0.4 +
      evidence_quality * 0.3
    )
    
    %{model | 
      model_confidence: Float.round(confidence, 3),
      self_understanding_quality: Float.round(understanding_quality, 3)
    }
  end
  
  @doc """
  Set constitutional compliance verification.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `compliance_data`: map() - compliance data with fields:
    - `:used_only_frozen_primitives` - boolean
    - `:primitives_used` - list of primitive types composed
    - `:no_architectural_drift` - boolean
  
  ## Returns
  
  InstitutionSelfModel.t()
  """
  def set_constitutional_compliance(model, compliance_data) do
    compliance = %{
      used_only_frozen_primitives: Map.get(compliance_data, :used_only_frozen_primitives, false),
      primitives_used: Map.get(compliance_data, :primitives_used, []),
      no_architectural_drift: Map.get(compliance_data, :no_architectural_drift, false),
      verified_at: DateTime.utc_now()
    }
    
    %{model | constitutional_compliance: compliance}
  end
  
  @doc """
  Mark self-model as constructed.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  
  ## Returns
  
  InstitutionSelfModel.t() with status set to :constructed
  """
  def mark_constructed(model) do
    %{model | status: :constructed}
  end
  
  @doc """
  Mark self-model as failed.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - target self-model
  - `reason`: String.t() - failure reason
  
  ## Returns
  
  InstitutionSelfModel.t() with status set to :failed
  """
  def mark_failed(model, reason) do
    %{model | status: :failed, failure_reason: reason}
  end
  
  @doc """
  Verify traceability of self-model to supporting data.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - self-model to verify
  
  ## Returns
  
  boolean() - true if all findings reference valid supporting data
  """
  def verify_traceability(model) do
    # Check that limitations have evidence
    limitations_valid = Enum.all?(model.reasoning_limitations || [], fn l ->
      length(l.evidence || []) > 0
    end)
    
    # Check that strengths have evidence
    strengths_valid = Enum.all?(model.reasoning_strengths || [], fn s ->
      length(s.evidence || []) > 0
    end)
    
    # Check that tendencies have evidence
    tendencies_valid = Enum.all?(model.methodological_tendencies || [], fn t ->
      length(t.evidence || []) > 0
    end)
    
    # Check constitutional compliance
    compliance_valid = model.constitutional_compliance != nil &&
      model.constitutional_compliance.used_only_frozen_primitives == true &&
      model.constitutional_compliance.no_architectural_drift == true
    
    limitations_valid && strengths_valid && tendencies_valid && compliance_valid
  end
  
  @doc """
  Get summary statistics for the self-model.
  
  ## Parameters
  
  - `model`: InstitutionSelfModel.t() - self-model to summarize
  
  ## Returns
  
  map() with summary statistics
  """
  def get_summary(model) do
    %{
      id: model.id,
      institution_id: model.institution_id,
      model_scope: model.model_scope,
      episodes_observed: model.episodes_observed,
      theories_observed: model.theories_observed,
      research_programs_observed: model.research_programs_observed,
      strengths_count: length(model.reasoning_strengths || []),
      limitations_count: length(model.reasoning_limitations || []),
      tendencies_count: length(model.methodological_tendencies || []),
      uncertainties_count: length(model.epistemic_uncertainties || []),
      model_confidence: model.model_confidence,
      self_understanding_quality: model.self_understanding_quality,
      status: model.status
    }
  end
  
  @doc """
  Enrich self-model with Scientific Discovery Stack registry data.
  
  Queries PrincipleRegistry, DomainRegistry, TheoryRegistry, DiscoveryRegistry,
  LawRegistry, UnknownRegistry, and ProgramRegistry to provide deeper context
  for the institution's self-understanding.
  
  This integration enables the institution to understand not just HOW it reasons,
  but WHAT it knows, WHERE gaps exist, and HOW its knowledge compares to the
  broader civilization.
  
  ## Parameters
  - `model`: InstitutionSelfModel.t()
  - `domain_id`: atom() - institution's primary research domain
  
  ## Returns
  InstitutionSelfModel.t() with enriched fields
  
  ## Enrichment Adds
  - Domain knowledge capital summary
  - Theory competition landscape
  - Discovery validation status
  - Unknown priority distribution
  - Program portfolio health
  - Comparative maturity assessment
  """
  def enrich_with_registry_data(model, domain_id) do
    alias TiannaraOS.{
      TheoryRegistry,
      DiscoveryRegistry,
      LawRegistry,
      UnknownRegistry,
      ProgramRegistry,
      PrincipleRegistry
    }

    alias Tiannara.Domains.{CanonicalRegistry, KnowledgeCapitalBoundary}
    
    # Get domain knowledge capital
    domain_knowledge = KnowledgeCapitalBoundary.get(domain_id) || %{}
    
    # Get theories in domain
    theories = case TheoryRegistry.list_by_domain(domain_id) do
      {:ok, list} -> list
      _ -> []
    end
    
    # Get discoveries in domain
    discoveries = case DiscoveryRegistry.list_by_domain(domain_id) do
      {:ok, list} -> list
      _ -> []
    end
    
    # Get laws in domain
    laws = case LawRegistry.list_by_domain(domain_id) do
      {:ok, list} -> list
      _ -> []
    end
    
    # Get open unknowns
    unknowns = case UnknownRegistry.list_open_by_domain(domain_id) do
      {:ok, list} -> list
      _ -> []
    end
    
    # Get programs
    programs = case ProgramRegistry.list_by_domain(domain_id) do
      {:ok, list} -> list
      _ -> []
    end
    
    # Get principles
    principles = case PrincipleRegistry.for_domain(domain_id) do
      {:ok, list} -> list
      _ -> []
    end
    
    # Calculate theory confidence distribution
    theory_confidence_stats = if length(theories) > 0 do
      confidences = Enum.map(theories, & &1.confidence)
      avg_confidence = Float.round(Enum.sum(confidences) / length(confidences), 2)
      high_confidence_count = Enum.count(confidences, & &1 >= 0.9)
      low_confidence_count = Enum.count(confidences, & &1 < 0.5)
      
      %{
        total_theories: length(theories),
        average_confidence: avg_confidence,
        high_confidence_count: high_confidence_count,
        low_confidence_count: low_confidence_count
      }
    else
      %{total_theories: 0, average_confidence: 0, note: "No theories in domain"}
    end
    
    # Calculate discovery validation distribution
    discovery_validation_stats = if length(discoveries) > 0 do
      simulated = Enum.count(discoveries, & &1.validation_status == :simulated)
      reproduced = Enum.count(discoveries, & &1.validation_status == :reproduced)
      validated = Enum.count(discoveries, & &1.validation_status == :operationally_validated)
      
      %{
        total_discoveries: length(discoveries),
        simulated: simulated,
        reproduced: reproduced,
        operationally_validated: validated,
        validation_rate: Float.round((validated / length(discoveries)) * 100, 2)
      }
    else
      %{total_discoveries: 0, note: "No discoveries in domain"}
    end
    
    # Calculate unknown priority distribution
    unknown_priority_stats = if length(unknowns) > 0 do
      critical = Enum.count(unknowns, & &1.priority == :critical)
      high = Enum.count(unknowns, & &1.priority == :high)
      medium = Enum.count(unknowns, & &1.priority == :medium)
      low = Enum.count(unknowns, & &1.priority == :low)
      
      %{
        total_unknowns: length(unknowns),
        critical: critical,
        high: high,
        medium: medium,
        low: low,
        research_debt_severity: if(critical > 0, do: :high, else: :moderate)
      }
    else
      %{total_unknowns: 0, note: "No open unknowns"}
    end
    
    # Build enrichment data
    enrichment_data = %{
      domain_id: domain_id,
      domain_knowledge_capital: domain_knowledge,
      theory_landscape: theory_confidence_stats,
      discovery_landscape: discovery_validation_stats,
      unknown_landscape: unknown_priority_stats,
      program_portfolio: %{total_programs: length(programs)},
      principle_foundation: %{total_principles: length(principles)},
      law_foundation: %{total_laws: length(laws)},
      comparative_maturity: assess_comparative_maturity(theories, discoveries, unknowns)
    }
    
    # Add semantic event for enrichment
    model = add_semantic_event(model, :registry_data_enriched, %{
      domain: domain_id,
      theories_analyzed: length(theories),
      discoveries_analyzed: length(discoveries),
      unknowns_analyzed: length(unknowns)
    })
    
    # Store enrichment in comparative_history field (repurposed for registry context)
    %{model | comparative_history: enrichment_data}
  end
  
  defp assess_comparative_maturity(theories, discoveries, unknowns) do
    theory_maturity = if length(theories) > 0 do
      validated_ratio = Enum.count(theories, fn t -> t.confidence >= 0.9 end) / length(theories)
      if validated_ratio > 0.7, do: :mature, else: :developing
    else
      :emerging
    end
    
    discovery_maturity = if length(discoveries) > 0 do
      validated_count = Enum.count(discoveries, fn d ->
        d.validation_status == :operationally_validated
      end)
      if validated_count > 5, do: :mature, else: :developing
    else
      :emerging
    end
    
    unknown_severity = if length(unknowns) > 20 do
      :high_debt
    else
      :manageable
    end
    
    %{
      theory_maturity: theory_maturity,
      discovery_maturity: discovery_maturity,
      unknown_severity: unknown_severity
    }
  end
  
  # Private helper functions
  
  defp calculate_coverage_score(model) do
    # Coverage based on how much history was observed
    total_episodes = model.episodes_observed || 0
    # Normalize: assume 50+ episodes = full coverage
    min(total_episodes / 50.0, 1.0)
  end
  
  defp calculate_consistency_score(model) do
    # Consistency based on contradictions between strengths and limitations
    strengths = model.reasoning_strengths || []
    limitations = model.reasoning_limitations || []
    
    # Simple heuristic: more balanced profile = higher consistency
    total = length(strengths) + length(limitations)
    if total == 0 do
      0.5  # No data = medium uncertainty
    else
      ratio = min(length(strengths), length(limitations)) / max(total, 1)
      0.5 + (ratio * 0.5)  # Range: 0.5-1.0
    end
  end
  
  defp calculate_evidence_quality(model) do
    # Evidence quality based on average evidence count per finding
    all_findings = (
      (model.reasoning_strengths || []) ++
      (model.reasoning_limitations || []) ++
      (model.methodological_tendencies || [])
    )
    
    if length(all_findings) == 0 do
      0.0
    else
      total_evidence = Enum.sum(Enum.map(all_findings, fn f -> length(f.evidence || []) end))
      avg_evidence = total_evidence / length(all_findings)
      min(avg_evidence / 3.0, 1.0)  # Assume 3+ evidence items = high quality
    end
  end
end
