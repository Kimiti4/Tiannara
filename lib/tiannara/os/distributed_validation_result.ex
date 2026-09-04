defmodule TiannaraOS.DistributedValidationResult do
  @moduledoc """
  DistributedValidationResult - Canonical constitutional transaction for distributed scientific validation.
  
  This artifact captures the complete audit trail of one distributed scientific validation event,
  including independent institutional assessments, supporting and contradicting evidence,
  agreement levels, disagreement maps, unresolved questions, and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing consensus algorithms, voting graphs, network managers, or cluster state,
  this result stores only the behavioral contract: what claim was validated, what institutions
  participated, what evidence was presented, and what collective assessment emerged. Internal
  distributed mechanisms remain hidden implementation details.
  
  ## Constitutional Properties
  
  - Immutable once finalized
  - Contains complete audit trail of distributed validation
  - Preserves both agreement and disagreement
  - Minority positions are never suppressed
  - Uncertainty is explicitly represented
  - No institution loses autonomy
  - Only canonical transactions exchanged between institutions
  - Governance mediates process, never determines scientific truth
  
  ## Fields
  
  - `validation_id`: String.t() - unique identifier
  - `claim`: String.t() - scientific claim being validated
  - `initiating_institution`: atom() - institution that initiated validation
  - `participating_institutions`: [atom()] - institutions that evaluated the claim
  - `supporting_evidence`: [%{institution, episode_ref, confidence}] - evidence supporting claim
  - `contradicting_evidence`: [%{institution, episode_ref, confidence}] - evidence contradicting claim
  - `independent_assessments`: %{atom() => %{assessment, confidence, reasoning}} - per-institution assessments
  - `agreement_level`: float() - degree of agreement (0.0-1.0)
  - `disagreement_map`: %{atom() => %{position, evidence_summary}} - map of disagreements
  - `unresolved_questions`: [String.t()] - questions requiring further investigation
  - `consensus_status`: atom() - :validated | :contested | :undecidable | :rejected
  - `recommended_actions`: [String.t()] - suggested next steps
  - `knowledge_delta`: map() | nil - knowledge graph updates
  - `ledger_delta`: map() | nil - economic cost accounting
  - `memory_delta`: map() | nil - memory pipeline updates
  - `lifecycle_events`: [map()] - lifecycle registry entries
  - `semantic_events`: [map()] - domain-specific semantic events
  - `governance_decisions`: [map()] - governance approvals/rejections
  - `constitutional_validation`: map() | nil - invariant verification
  - `status`: atom() - current state (:pending | :validated | :contested | :undecidable | :rejected | :failed)
  - `failure_reason`: String.t() | nil - explanation if failed
  """
  
  defstruct [
    :validation_id,                   # String.t() - unique identifier
    :claim,                           # String.t() - scientific claim being validated
    :initiating_institution,          # atom() - institution that initiated validation
    :participating_institutions,      # [atom()] - institutions that evaluated the claim
    :supporting_evidence,             # [%{institution, episode_ref, confidence}]
    :contradicting_evidence,          # [%{institution, episode_ref, confidence}]
    :independent_assessments,         # %{atom() => %{assessment, confidence, reasoning}}
    :agreement_level,                 # float() - degree of agreement (0.0-1.0)
    :disagreement_map,                # %{atom() => %{position, evidence_summary}}
    :unresolved_questions,            # [String.t()] - questions requiring further investigation
    :consensus_status,                # atom() - :validated | :contested | :undecidable | :rejected
    :recommended_actions,             # [String.t()] - suggested next steps
    :knowledge_delta,                 # map() | nil - knowledge graph updates
    :ledger_delta,                    # map() | nil - economic cost accounting
    :memory_delta,                    # map() | nil - memory pipeline updates
    :lifecycle_events,                # [map()] - lifecycle registry entries
    :semantic_events,                 # [map()] - domain-specific semantic events
    :governance_review_required,      # boolean() - whether governance review was requested
    :constitutional_validation,       # map() | nil - invariant verification
    :status,                          # atom() - current state
    :failure_reason                   # String.t() | nil - explanation if failed
  ]
  
  @type t :: %__MODULE__{
    validation_id: String.t(),
    claim: String.t(),
    initiating_institution: atom(),
    participating_institutions: [atom()],
    supporting_evidence: [%{institution: atom(), episode_ref: String.t(), confidence: float()}],
    contradicting_evidence: [%{institution: atom(), episode_ref: String.t(), confidence: float()}],
    independent_assessments: %{atom() => %{assessment: atom(), confidence: float(), reasoning: String.t()}},
    agreement_level: float(),
    disagreement_map: %{atom() => %{position: atom(), evidence_summary: String.t()}},
    unresolved_questions: [String.t()],
    consensus_status: atom(),
    recommended_actions: [String.t()],
    knowledge_delta: map() | nil,
    ledger_delta: map() | nil,
    memory_delta: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    governance_review_required: boolean(),
    constitutional_validation: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }
  
  @doc """
  Initialize a new DistributedValidationResult.
  
  ## Parameters
  
  - `claim`: String.t() - scientific claim being validated
  - `initiating_institution`: atom() - institution that initiated validation
  - `opts`: keyword list or map with optional parameters:
    - `:validation_id`: String.t() - custom validation ID (auto-generated if omitted)
    - `:participating_institutions`: [atom()] - institutions participating in validation
    - `:tick`: integer() - current tick
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def new(claim, initiating_institution, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts
    
    validation_id = Keyword.get(opts, :validation_id, generate_validation_id())
    participating_institutions = Keyword.get(opts, :participating_institutions, [])
    
    %__MODULE__{
      validation_id: validation_id,
      claim: claim,
      initiating_institution: initiating_institution,
      participating_institutions: participating_institutions,
      supporting_evidence: [],
      contradicting_evidence: [],
      independent_assessments: %{},
      agreement_level: 0.0,
      disagreement_map: %{},
      unresolved_questions: [],
      consensus_status: :pending,
      recommended_actions: [],
      knowledge_delta: nil,
      ledger_delta: nil,
      memory_delta: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_review_required: false,
      constitutional_validation: nil,
      status: :pending,
      failure_reason: nil
    }
  end
  
  @doc """
  Add supporting evidence from an institution.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `institution`: atom() - institution providing evidence
  - `episode_ref`: String.t() - reference to supporting episode
  - `confidence`: float() - confidence level (0.0-1.0)
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_supporting_evidence(result, institution, episode_ref, confidence) do
    evidence = %{
      institution: institution,
      episode_ref: episode_ref,
      confidence: confidence
    }
    
    %{result | supporting_evidence: result.supporting_evidence ++ [evidence]}
  end
  
  @doc """
  Add contradicting evidence from an institution.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `institution`: atom() - institution providing evidence
  - `episode_ref`: String.t() - reference to contradicting episode
  - `confidence`: float() - confidence level (0.0-1.0)
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_contradicting_evidence(result, institution, episode_ref, confidence) do
    evidence = %{
      institution: institution,
      episode_ref: episode_ref,
      confidence: confidence
    }
    
    %{result | contradicting_evidence: result.contradicting_evidence ++ [evidence]}
  end
  
  @doc """
  Set independent assessment from an institution.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `institution`: atom() - institution providing assessment
  - `assessment`: atom() - :supports | :rejects | :uncertain
  - `confidence`: float() - confidence level (0.0-1.0)
  - `reasoning`: String.t() - explanation of assessment
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def set_independent_assessment(result, institution, assessment, confidence, reasoning) do
    assessments = Map.put(result.independent_assessments, institution, %{
      assessment: assessment,
      confidence: confidence,
      reasoning: reasoning
    })
    
    %{result | independent_assessments: assessments}
  end
  
  @doc """
  Calculate and set agreement level based on independent assessments.
  
  Agreement level is calculated as the proportion of institutions supporting the claim
  weighted by their confidence levels.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def calculate_agreement_level(result) do
    assessments = result.independent_assessments
    
    if Enum.empty?(assessments) do
      %{result | agreement_level: 0.0}
    else
      total_weighted_support = Enum.reduce(assessments, 0.0, fn {_inst, assessment}, acc ->
        weight = case assessment.assessment do
          :supports -> assessment.confidence
          :rejects -> 0.0
          :uncertain -> assessment.confidence * 0.5
        end
        acc + weight
      end)
          
      max_possible = map_size(assessments)
      agreement_level = if max_possible > 0, do: total_weighted_support / max_possible, else: 0.0
      
      %{result | agreement_level: Float.round(agreement_level, 4)}
    end
  end
  
  @doc """
  Add a disagreement entry to the disagreement map.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `institution`: atom() - institution with disagreement
  - `position`: atom() - :supports | :rejects | :uncertain
  - `evidence_summary`: String.t() - summary of disagreeing evidence
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_disagreement(result, institution, position, evidence_summary) do
    disagreement_map = Map.put(result.disagreement_map, institution, %{
      position: position,
      evidence_summary: evidence_summary
    })
    
    %{result | disagreement_map: disagreement_map}
  end
  
  @doc """
  Add an unresolved question requiring further investigation.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `question`: String.t() - unresolved question
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_unresolved_question(result, question) do
    %{result | unresolved_questions: result.unresolved_questions ++ [question]}
  end
  
  @doc """
  Set consensus status based on agreement level and evidence.
  
  ## Status Determination
  
  - `:validated` - agreement_level >= 0.95 with strong supporting evidence
  - `:contested` - significant disagreement exists (0.3 <= agreement_level < 0.95)
  - `:undecidable` - insufficient evidence to distinguish hypotheses (agreement_level ~0.5)
  - `:rejected` - agreement_level < 0.3 with strong contradicting evidence
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def determine_consensus_status(result) do
    supporting_count = get_supporting_count(result)
    rejecting_count = get_rejecting_count(result)
    uncertain_count = get_uncertain_count(result)
    total = supporting_count + rejecting_count + uncertain_count
    
    status = cond do
      result.agreement_level >= 0.95 and length(result.supporting_evidence) > 0 ->
        :validated
      
      # Preserve minority positions: if there are both supporters and rejecters, it's contested
      supporting_count > 0 and rejecting_count > 0 ->
        :contested
      
      result.agreement_level < 0.3 and length(result.contradicting_evidence) > 0 ->
        :rejected
      
      # Undecidable: mostly uncertain assessments with no clear majority
      uncertain_count > 0 and uncertain_count >= total * 0.5 ->
        :undecidable
      
      true ->
        :contested
    end
    
    %{result | consensus_status: status}
  end
  
  @doc """
  Mark validation as validated (high agreement).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def mark_validated(result) do
    %{result | consensus_status: :validated, status: :validated}
  end
  
  @doc """
  Mark validation as contested (significant disagreement).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def mark_contested(result) do
    %{result | consensus_status: :contested, status: :contested}
  end
  
  @doc """
  Mark validation as undecidable (insufficient evidence).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def mark_undecidable(result) do
    %{result | consensus_status: :undecidable, status: :undecidable}
  end
  
  @doc """
  Mark validation as rejected (strong contradiction).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def mark_rejected(result) do
    %{result | consensus_status: :rejected, status: :rejected}
  end
  
  @doc """
  Add a recommended action for follow-up investigation.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `action`: String.t() - recommended action
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_recommended_action(result, action) do
    %{result | recommended_actions: result.recommended_actions ++ [action]}
  end
  
  @doc """
  Set knowledge delta (knowledge graph updates).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `delta`: map() - knowledge graph changes
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def set_knowledge_delta(result, delta) do
    %{result | knowledge_delta: delta}
  end
  
  @doc """
  Set ledger delta (economic cost accounting).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `delta`: map() - ledger changes
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def set_ledger_delta(result, delta) do
    %{result | ledger_delta: delta}
  end
  
  @doc """
  Set memory delta (memory pipeline updates).
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `delta`: map() - memory changes
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def set_memory_delta(result, delta) do
    %{result | memory_delta: delta}
  end
  
  @doc """
  Add a lifecycle event.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `event`: map() - lifecycle event data
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a semantic event.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `event_type`: atom() - type of semantic event
  - `data`: map() - event data
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def add_semantic_event(result, event_type, data) do
    event = %{
      event_type: event_type,
      data: data,
      timestamp: DateTime.utc_now()
    }
    
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Mark that governance review was requested for this validation.
  
  This does NOT add governance decisions to the scientific result.
  Governance operates separately, reviewing process integrity without
  participating in scientific reasoning.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def mark_governance_review_required(result) do
    %{result | governance_review_required: true}
  end
  
  @doc """
  Set constitutional validation results.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  - `validation`: map() - validation results
  
  ## Returns
  
  DistributedValidationResult.t()
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Get the number of supporting institutions.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  integer()
  """
  def get_supporting_count(result) do
    Enum.count(result.independent_assessments, fn {_inst, assessment} ->
      assessment.assessment == :supports
    end)
  end
  
  @doc """
  Get the number of rejecting institutions.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  integer()
  """
  def get_rejecting_count(result) do
    Enum.count(result.independent_assessments, fn {_inst, assessment} ->
      assessment.assessment == :rejects
    end)
  end
  
  @doc """
  Get the number of uncertain institutions.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  integer()
  """
  def get_uncertain_count(result) do
    Enum.count(result.independent_assessments, fn {_inst, assessment} ->
      assessment.assessment == :uncertain
    end)
  end
  
  @doc """
  Check if minority position exists.
  
  A minority position exists when at least one institution disagrees with the majority.
  
  ## Parameters
  
  - `result`: DistributedValidationResult.t() - target result
  
  ## Returns
  
  boolean()
  """
  def has_minority_position?(result) do
    assessments = Map.values(result.independent_assessments)
    
    if Enum.empty?(assessments) do
      false
    else
      positions = Enum.map(assessments, & &1.assessment)
      unique_positions = Enum.uniq(positions)
      length(unique_positions) > 1
    end
  end
  
  # Generate unique validation ID
  defp generate_validation_id do
    "dval_#{:erlang.unique_integer([:positive])}_#{System.system_time(:millisecond)}"
  end
end
