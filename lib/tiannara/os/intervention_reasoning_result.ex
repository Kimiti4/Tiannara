defmodule TiannaraOS.InterventionReasoningResult do
  @moduledoc """
  InterventionReasoningResult - Canonical constitutional transaction for institutional causal intervention reasoning.
  
  This artifact captures the complete audit trail of one institutional intervention reasoning event,
  including the intervention request, retrieved episode references, candidate interventions,
  recommended intervention with expected outcomes, counterfactuals, risk assessment,
  confidence levels, causal justification, and all constitutional deltas.
  
  ## Key Principle: Lightweight References
  
  Instead of embedding full episode objects or causal graphs, this result stores EPISODE REFERENCES
  and lightweight intervention metadata. Full episodes can always be reconstructed from immutable
  storage via Knowledge Graph. Internal causal models (Do-Calculus, SCMs, Bayesian Networks) remain
  hidden implementation details—only the behavioral contract is exposed.
  
  ## Constitutional Hierarchy
  
      Institution
          │
          ▼
      reason_about_intervention()  ← Public API
          │
          ▼
      InterventionReasoningResult  ← Canonical Transaction
          │
          ├─ retrieved_episode_refs  (lightweight references)
          ├─ candidate_interventions (evaluated options)
          ├─ recommended_intervention (final recommendation)
          ├─ expected_outcomes       (predicted effects)
          ├─ counterfactuals         (what-if scenarios)
          └─ constitutional deltas   (knowledge, ledger, memory)
  
  ## Usage
  
      result = InterventionReasoningResult.new(:medicine_inst, intervention_request, opts)
      result = InterventionReasoningResult.add_retrieved_episodes(result, episode_refs)
      result = InterventionReasoningResult.set_recommended_intervention(result, recommendation)
      result = InterventionReasoningResult.mark_completed(result, :intervention_approved)
  """
  
  @derive Jason.Encoder
  defstruct [
    # ==================== Reasoning Identity ====================
    :reasoning_id,                # String.t() - unique reasoning identifier
    :institution_id,              # atom() - institution performing reasoning
    :timestamp,                   # DateTime.t() - when reasoning occurred
    :tick,                        # integer() - simulation tick
    
    # ==================== Input ====================
    :intervention_request,        # map() - what intervention was requested (%{variable, change, context})
    
    # ==================== Episode Retrieval ====================
    :retrieved_episode_refs,      # [%{episode_id, similarity, topic, outcome}] - relevant historical episodes
    :total_episodes_searched,     # integer() - how many episodes were considered
    
    # ==================== Candidate Interventions ====================
    :candidate_interventions,     # [%{intervention: map(), expected_outcome: map(), confidence: float()}]
    
    # ==================== Recommendation ====================
    :recommended_intervention,    # map() | nil - final recommended intervention (or nil if rejected)
    :expected_outcomes,           # [%{outcome: String.t(), probability: float(), impact: String.t()}]
    :counterfactuals,             # [%{scenario: String.t(), predicted_result: String.t(), confidence: float()}]
    
    # ==================== Risk & Confidence ====================
    :risk_assessment,             # %{level: atom(), factors: [String.t()], mitigation: [String.t()]}
    :confidence,                  # float() - overall confidence in recommendation (0.0-1.0)
    :causal_justification,        # String.t() - explainable reasoning chain
    
    # ==================== Constitutional Deltas ====================
    :knowledge_delta,             # KnowledgeDelta.t() | nil - graph mutations (if any)
    :ledger_delta,                # LedgerDelta.t() - economic costs of reasoning
    :memory_delta,                # MemoryDelta.t() - access pattern updates
    
    # ==================== Event Audit Trail ====================
    :lifecycle_events,            # [LifecycleEvent.t()] - immutable lifecycle history
    :semantic_events,             # [SemanticEvent.t()] - domain-specific events emitted
    
    # ==================== Governance ====================
    :governance_decisions,        # [GovernanceDecision.t()] - approval/rejection decisions
    
    # ==================== Execution Metadata ====================
    :execution_time_ms,           # integer() - wall clock time for reasoning
    :constitutional_validation,   # Validation.t() - invariant compliance check
    
    # ==================== Status ====================
    :status,                      # atom() - :completed | :rejected | :deferred | :insufficient_evidence | :failed
    :failure_reason               # String.t() | nil - explanation if status != :completed
  ]
  
  @type t :: %__MODULE__{
    reasoning_id: String.t(),
    institution_id: atom(),
    timestamp: DateTime.t(),
    tick: integer(),
    intervention_request: map(),
    retrieved_episode_refs: [map()],
    total_episodes_searched: integer(),
    candidate_interventions: [map()],
    recommended_intervention: map() | nil,
    expected_outcomes: [map()],
    counterfactuals: [map()],
    risk_assessment: map(),
    confidence: float(),
    causal_justification: String.t(),
    knowledge_delta: map() | nil,
    ledger_delta: map(),
    memory_delta: map(),
    lifecycle_events: [map()],
    semantic_events: [map()],
    governance_decisions: [map()],
    execution_time_ms: integer(),
    constitutional_validation: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }
  
  # ==================== Public API ====================
  
  @doc """
  Create a new InterventionReasoningResult for an upcoming intervention reasoning session.
  
  ## Parameters
  
  - `institution_id`: atom() - institution performing reasoning
  - `intervention_request`: map() - what intervention is being evaluated
  - `opts`: Optional parameters (:tick, :metadata)
  
  ## Returns
  
  InterventionReasoningResult.t() - new pending reasoning result
  
  ## Example
  
      request = %{
        variable: :drug_dosage,
        change: :increase_by_20_percent,
        context: %{patient_group: :stage_2_cancer}
      }
      
      result = InterventionReasoningResult.new(:medicine_inst, request)
  """
  def new(institution_id, intervention_request, opts \\ []) do
    %__MODULE__{
      reasoning_id: generate_reasoning_id(),
      institution_id: institution_id,
      timestamp: DateTime.utc_now(),
      tick: Keyword.get(opts, :tick, 0),
      intervention_request: intervention_request,
      retrieved_episode_refs: [],
      total_episodes_searched: 0,
      candidate_interventions: [],
      recommended_intervention: nil,
      expected_outcomes: [],
      counterfactuals: [],
      risk_assessment: %{level: :unknown, factors: [], mitigation: []},
      confidence: 0.0,
      causal_justification: "",
      knowledge_delta: nil,
      ledger_delta: nil,
      memory_delta: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      execution_time_ms: 0,
      constitutional_validation: nil,
      status: :pending,
      failure_reason: nil
    }
  end
  
  @doc """
  Add retrieved episode references to the result.
  
  Stores lightweight episode references (not full objects) retrieved from EpisodeIndex.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `episode_refs`: [map()] - list of episode references with similarity scores
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  
  ## Example
  
      episode_refs = [
        %{episode_id: "ep_123", similarity: 0.85, topic: "Drug dosage study", outcome: :success}
      ]
      
      result = InterventionReasoningResult.add_retrieved_episodes(result, episode_refs)
  """
  def add_retrieved_episodes(result, episode_refs) do
    %{result |
      retrieved_episode_refs: result.retrieved_episode_refs ++ episode_refs,
      total_episodes_searched: result.total_episodes_searched + length(episode_refs)
    }
  end
  
  @doc """
  Set total episodes searched (from EpisodeIndex).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `count`: integer() - total episodes considered
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_total_episodes_searched(result, count) do
    %{result | total_episodes_searched: count}
  end
  
  @doc """
  Add a candidate intervention to evaluate.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `candidate`: map() - candidate intervention with expected outcome and confidence
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  
  ## Example
  
      candidate = %{
        intervention: %{variable: :dosage, change: :increase_20pct},
        expected_outcome: %{effect: :improved_efficacy, probability: 0.75},
        confidence: 0.68
      }
      
      result = InterventionReasoningResult.add_candidate_intervention(result, candidate)
  """
  def add_candidate_intervention(result, candidate) do
    %{result |
      candidate_interventions: result.candidate_interventions ++ [candidate]
    }
  end
  
  @doc """
  Set the recommended intervention (final decision).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `recommendation`: map() | nil - recommended intervention (nil if rejected)
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_recommended_intervention(result, recommendation) do
    %{result | recommended_intervention: recommendation}
  end
  
  @doc """
  Add expected outcomes for the recommended intervention.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `outcomes`: [map()] - list of predicted outcomes with probabilities
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def add_expected_outcomes(result, outcomes) do
    %{result | expected_outcomes: result.expected_outcomes ++ outcomes}
  end
  
  @doc """
  Add counterfactual scenarios (what-if analysis).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `counterfactuals`: [map()] - list of counterfactual scenarios
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  
  ## Example
  
      counterfactuals = [
        %{
          scenario: "What if dosage increased by 50% instead?",
          predicted_result: "Higher efficacy but increased side effects",
          confidence: 0.45
        }
      ]
      
      result = InterventionReasoningResult.add_counterfactuals(result, counterfactuals)
  """
  def add_counterfactuals(result, counterfactuals) do
    %{result | counterfactuals: result.counterfactuals ++ counterfactuals}
  end
  
  @doc """
  Set risk assessment for the intervention.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `assessment`: map() - risk level, factors, and mitigation strategies
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_risk_assessment(result, assessment) do
    %{result | risk_assessment: assessment}
  end
  
  @doc """
  Set overall confidence in the recommendation.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `confidence`: float() - confidence level (0.0-1.0)
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_confidence(result, confidence) do
    %{result | confidence: Float.round(confidence, 3)}
  end
  
  @doc """
  Set causal justification (explainable reasoning chain).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `justification`: String.t() - human-readable explanation
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_causal_justification(result, justification) do
    %{result | causal_justification: justification}
  end
  
  @doc """
  Set knowledge delta (if reasoning modifies knowledge graph).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `delta`: KnowledgeDelta.t() | nil - graph mutations
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_knowledge_delta(result, delta) do
    %{result | knowledge_delta: delta}
  end
  
  @doc """
  Set ledger delta (economic costs of reasoning).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `delta`: LedgerDelta.t() - cost accounting
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_ledger_delta(result, delta) do
    %{result | ledger_delta: delta}
  end
  
  @doc """
  Set memory delta (access pattern updates).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `delta`: MemoryDelta.t() - memory consolidation
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_memory_delta(result, delta) do
    %{result | memory_delta: delta}
  end
  
  @doc """
  Add a lifecycle event to the audit trail.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `event`: LifecycleEvent.t() - immutable lifecycle event
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a semantic event (domain-specific).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `event`: SemanticEvent.t() - semantic event
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def add_semantic_event(result, event) do
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Add a governance decision (approval/rejection).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `decision`: GovernanceDecision.t() - governance outcome
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def add_governance_decision(result, decision) do
    %{result | governance_decisions: result.governance_decisions ++ [decision]}
  end
  
  @doc """
  Set execution time in milliseconds.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `time_ms`: integer() - wall clock time
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_execution_time(result, time_ms) do
    %{result | execution_time_ms: time_ms}
  end
  
  @doc """
  Set constitutional validation result.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `validation`: Validation.t() - invariant compliance check
  
  ## Returns
  
  InterventionReasoningResult.t() - updated result
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Mark reasoning as completed successfully.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `reason`: atom() - completion reason (:intervention_approved | :intervention_rejected | :counterfactual_generated)
  
  ## Returns
  
  InterventionReasoningResult.t() - completed result
  """
  def mark_completed(result, reason) do
    %{result |
      status: :completed,
      causal_justification: "#{result.causal_justification} | Completion reason: #{reason}"
    }
  end
  
  @doc """
  Mark reasoning as rejected (by governance or risk assessment).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `reason`: String.t() - rejection explanation
  
  ## Returns
  
  InterventionReasoningResult.t() - rejected result
  """
  def mark_rejected(result, reason) do
    %{result |
      status: :rejected,
      failure_reason: reason,
      recommended_intervention: nil
    }
  end
  
  @doc """
  Mark reasoning as deferred (insufficient budget or evidence).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `reason`: String.t() - deferral explanation
  
  ## Returns
  
  InterventionReasoningResult.t() - deferred result
  """
  def mark_deferred(result, reason) do
    %{result |
      status: :deferred,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark reasoning as having insufficient evidence.
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `reason`: String.t() - explanation of evidence gap
  
  ## Returns
  
  InterventionReasoningResult.t() - insufficient evidence result
  """
  def mark_insufficient_evidence(result, reason) do
    %{result |
      status: :insufficient_evidence,
      confidence: 0.0,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark reasoning as failed (error during execution).
  
  ## Parameters
  
  - `result`: InterventionReasoningResult.t() - target result
  - `error_msg`: String.t() - error description
  
  ## Returns
  
  InterventionReasoningResult.t() - failed result
  """
  def mark_failed(result, error_msg) do
    %{result |
      status: :failed,
      failure_reason: error_msg
    }
  end
  
  # ==================== Private Helpers ====================
  
  defp generate_reasoning_id do
    hash = :crypto.hash(:sha256, "intervention_reasoning_#{System.system_time()}_#{:rand.uniform(1000000)}")
    "ir_#{Base.encode16(hash, case: :lower) |> String.slice(0..15)}"
  end
end
