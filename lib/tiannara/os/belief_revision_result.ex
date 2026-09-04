defmodule TiannaraOS.BeliefRevisionResult do
  @moduledoc """
  BeliefRevisionResult - Canonical constitutional transaction for belief revision.
  
  This artifact captures the complete audit trail of one institutional belief revision
  event, including triggering evidence, affected beliefs, justification graph changes,
  and all constitutional deltas.
  
  ## Constitutional Properties
  
  - Single canonical transaction object (no partial results)
  - Complete traceability from evidence to revised beliefs
  - Historical preservation (previous beliefs never deleted, only superseded)
  - Justification graph delta for explainability
  - Composes existing constitutional services (no parallel systems)
  - Consumed by future capabilities (JTMS++, VSA, Do-Calculus, etc.)
  
  ## Usage
  
  ```elixir
  result = InstitutionKernel.revise_beliefs(kernel_pid, new_evidence, opts)
  
  # Access revision details
  result.revised_beliefs
  result.retracted_beliefs
  result.justification_delta
  result.constitutional_validation
  ```
  
  ## Architecture
  
  BeliefRevisionResult is to belief revision what ResearchCycleResult is to research:
  the immutable, auditable, constitutionally complete transaction record.
  """
  
  @derive Jason.Encoder
  defstruct [
    # ==================== Revision Identity ====================
    :revision_id,                 # String.t() - unique revision identifier
    :institution_id,              # atom() - institution performing revision
    :timestamp,                   # DateTime.t() - when revision occurred
    :tick,                        # integer() - simulation tick
    
    # ==================== Triggering Evidence ====================
    :triggering_evidence,         # Evidence.t() - new evidence that triggered revision
    :evidence_source,             # atom() - :internal_research | :external_adoption | :contradiction_detection
    
    # ==================== Affected Beliefs ====================
    :affected_beliefs,            # [String.t()] - IDs of beliefs examined during revision
    :preserved_beliefs,           # [String.t()] - beliefs unchanged by this revision
    :revised_beliefs,             # [BeliefChange.t()] - beliefs with updated confidence
    :retracted_beliefs,           # [RetractedBelief.t()] - beliefs withdrawn due to contradiction
    :suspended_beliefs,           # [SuspendedBelief.t()] - beliefs temporarily held pending further evidence
    :newly_derived_beliefs,       # [DerivedBelief.t()] - new beliefs inferred from revision
    
    # ==================== Confidence Changes ====================
    :confidence_changes,          # [%{belief_id: String.t(), prior: float(), posterior: float(), delta: float()}]
    
    # ==================== Justification Graph ====================
    :justification_delta,         # JustificationDelta.t() - changes to belief dependency graph
    
    # ==================== Constitutional Deltas ====================
    :knowledge_delta,             # KnowledgeDelta.t() - knowledge graph mutations
    :ledger_delta,                # LedgerDelta.t() - economic costs of revision
    :memory_delta,                # MemoryDelta.t() - memory pipeline updates
    
    # ==================== Event Audit Trail ====================
    :lifecycle_events,            # [LifecycleEvent.t()] - immutable lifecycle history
    :semantic_events,             # [SemanticEvent.t()] - domain-specific events emitted
    :governance_decisions,        # [GovernanceDecision.t()] - governance review outcomes
    
    # ==================== Execution Metadata ====================
    :execution_time_ms,           # integer() - wall clock time for revision
    :revision_reason,             # atom() - :strengthening | :weakening | :contradiction | :minimal_revision | :governance_rejected | :budget_exhausted
    :constitutional_validation,   # Validation.t() - invariant compliance check
    
    # ==================== Status ====================
    :status,                      # atom() - :completed | :rejected | :deferred | :partial
    :failure_reason               # String.t() | nil - explanation if status != :completed
  ]
  
  @type t :: %__MODULE__{
    revision_id: String.t(),
    institution_id: atom(),
    timestamp: DateTime.t(),
    tick: integer(),
    triggering_evidence: map() | nil,
    evidence_source: atom(),
    affected_beliefs: [String.t()],
    preserved_beliefs: [String.t()],
    revised_beliefs: [map()],
    retracted_beliefs: [map()],
    suspended_beliefs: [map()],
    newly_derived_beliefs: [map()],
    confidence_changes: [map()],
    justification_delta: map() | nil,
    knowledge_delta: map() | nil,
    ledger_delta: map() | nil,
    memory_delta: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    governance_decisions: [map()],
    execution_time_ms: integer(),
    revision_reason: atom(),
    constitutional_validation: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }
  
  # ==================== Public API ====================
  
  @doc """
  Create a new BeliefRevisionResult for an upcoming revision.
  
  Initializes with metadata and empty revision containers.
  """
  def new(institution_id, triggering_evidence, opts \\ []) do
    %__MODULE__{
      revision_id: generate_revision_id(),
      institution_id: institution_id,
      timestamp: DateTime.utc_now(),
      tick: Map.get(opts, :tick, 0),
      triggering_evidence: triggering_evidence,
      evidence_source: Map.get(opts, :evidence_source, :internal_research),
      affected_beliefs: [],
      preserved_beliefs: [],
      revised_beliefs: [],
      retracted_beliefs: [],
      suspended_beliefs: [],
      newly_derived_beliefs: [],
      confidence_changes: [],
      justification_delta: nil,
      knowledge_delta: nil,
      ledger_delta: nil,
      memory_delta: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      execution_time_ms: 0,
      revision_reason: nil,
      constitutional_validation: nil,
      status: :pending,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a revised belief to the result.
  
  Records confidence change for a belief that was strengthened or weakened.
  """
  def add_revised_belief(result, belief_change) do
    %{result |
      revised_beliefs: result.revised_beliefs ++ [belief_change],
      confidence_changes: result.confidence_changes ++ [%{
        belief_id: belief_change.belief_id,
        prior: belief_change.prior_confidence,
        posterior: belief_change.posterior_confidence,
        delta: belief_change.delta
      }]
    }
  end
  
  @doc """
  Add a retracted belief to the result.
  
  Records a belief that was withdrawn due to contradiction.
  """
  def add_retracted_belief(result, retracted_belief) do
    %{result | retracted_beliefs: result.retracted_beliefs ++ [retracted_belief]}
  end
  
  @doc """
  Add a suspended belief to the result.
  
  Records a belief temporarily held pending further evidence.
  """
  def add_suspended_belief(result, suspended_belief) do
    %{result | suspended_beliefs: result.suspended_beliefs ++ [suspended_belief]}
  end
  
  @doc """
  Add a newly derived belief to the result.
  
  Records a belief inferred from the revision process.
  """
  def add_derived_belief(result, derived_belief) do
    %{result | newly_derived_beliefs: result.newly_derived_beliefs ++ [derived_belief]}
  end
  
  @doc """
  Set justification graph delta.
  
  Captures changes to belief dependency structure for explainability.
  """
  def set_justification_delta(result, justification_delta) do
    %{result | justification_delta: justification_delta}
  end
  
  @doc """
  Set knowledge graph delta.
  
  Records mutations to the institutional knowledge graph.
  """
  def set_knowledge_delta(result, knowledge_delta) do
    %{result | knowledge_delta: knowledge_delta}
  end
  
  @doc """
  Set ledger delta.
  
  Records economic costs of the revision operation.
  """
  def set_ledger_delta(result, ledger_delta) do
    %{result | ledger_delta: ledger_delta}
  end
  
  @doc """
  Set memory delta.
  
  Records memory pipeline updates from revision.
  """
  def set_memory_delta(result, memory_delta) do
    %{result | memory_delta: memory_delta}
  end
  
  @doc """
  Add a semantic event emitted during revision.
  """
  def add_semantic_event(result, event) do
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Add a lifecycle event recorded during revision.
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a governance decision made during revision.
  """
  def add_governance_decision(result, decision) do
    %{result | governance_decisions: result.governance_decisions ++ [decision]}
  end
  
  @doc """
  Set constitutional validation result.
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Mark revision as completed successfully.
  """
  def mark_completed(result, reason) do
    %{result |
      status: :completed,
      revision_reason: reason
    }
  end
  
  @doc """
  Mark revision as rejected by governance.
  """
  def mark_rejected(result, reason) do
    %{result |
      status: :rejected,
      revision_reason: :governance_rejected,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark revision as deferred due to budget exhaustion.
  """
  def mark_deferred(result, reason) do
    %{result |
      status: :deferred,
      revision_reason: :budget_exhausted,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark revision as partially completed.
  """
  def mark_partial(result, reason) do
    %{result |
      status: :partial,
      revision_reason: reason
    }
  end
  
  @doc """
  Set execution time metadata.
  """
  def set_execution_time(result, time_ms) do
    %{result | execution_time_ms: time_ms}
  end
  
  @doc """
  Set affected and preserved belief lists.
  """
  def set_affected_beliefs(result, affected_ids, preserved_ids) do
    %{result |
      affected_beliefs: affected_ids,
      preserved_beliefs: preserved_ids
    }
  end
  
  # ==================== Private Helpers ====================
  
  defp generate_revision_id do
    "rev_#{:crypto.hash(:sha256, "#{DateTime.utc_now() |> DateTime.to_iso8601()}_#{System.system_time(:nanosecond)}") |> Base.encode16(case: :lower) |> String.slice(0, 16)}"
  end
end
