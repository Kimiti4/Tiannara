defmodule TiannaraOS.ResearchCycleResult do
  @moduledoc """
  Canonical Institutional Transaction Record for Research Cycles.
  
  This is NOT a subsystem. It is the complete audit trail of one institutional
  research investigation, from goal through belief revision to publication decision.
  
  Every field is traceable and reconstructable (Principle 11).
  
  ## Usage
  
  Returned by `InstitutionKernel.conduct_research_cycle/3` as the canonical output
  consumed by later capabilities:
  
  - JTMS++ → consumes `belief_change`
  - VSA Memory → consumes `memory_delta`
  - Do-Calculus → consumes `experiment`
  - Discovery Exchange → consumes `publication`
  - CIS → consumes `semantic_events`
  - Distributed Validation → consumes entire result
  - Topological Knowledge → consumes `knowledge_delta`
  
  No adapters required.
  
  ## Constitutional Properties
  
  Every ResearchCycleResult demonstrates:
  - Principle 1: Institution owns the process
  - Principle 2: Every mutation emits semantic events
  - Principle 3: Lifecycle history recorded
  - Principle 5: Kernel owns all mutation
  - Principle 6: Governance validates before mutation
  - Principle 8: Memory updated
  - Principle 11: Entire decision reconstructable
  """
  
  defstruct [
    # Research Inputs
    :goal,
    :budget_allocated,
    
    # Research Process
    :hypothesis,
    :experiment,
    :evidence,
    :evaluation,
    :belief_change,
    :publication,
    
    # Constitutional Deltas
    :knowledge_delta,
    :ledger_delta,
    :memory_delta,
    
    # Event Audit Trail
    :lifecycle_events,
    :semantic_events,
    :governance_decisions,
    
    # Execution Metadata
    :execution_time_ms,
    :tick_range,
    :constitutional_validation,
    
    # Status
    :status,
    :failure_reason
  ]
  
  # ==================== Constructors ====================
  
  @doc """
  Create a new ResearchCycleResult with default values.
  """
  @spec new(String.t(), keyword()) :: %__MODULE__{}
  def new(goal, opts \\ []) do
    %__MODULE__{
      goal: goal,
      budget_allocated: Keyword.get(opts, :budget_allocated, 0.0),
      tick_range: Keyword.get(opts, :tick_range, nil),
      evidence: [],
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      execution_time_ms: 0,
      constitutional_validation: %{},
      status: :success,
      failure_reason: nil
    }
  end
  
  @doc """
  Mark cycle as successful with final deltas.
  """
  @spec success(%__MODULE__{}, map()) :: %__MODULE__{}
  def success(result, deltas) do
    %{result |
      knowledge_delta: Map.get(deltas, :knowledge_delta),
      ledger_delta: Map.get(deltas, :ledger_delta),
      memory_delta: Map.get(deltas, :memory_delta),
      constitutional_validation: Map.get(deltas, :constitutional_validation, %{}),
      status: :success
    }
  end
  
  @doc """
  Mark cycle as failed with reason.
  """
  @spec failure(%__MODULE__{}, String.t()) :: %__MODULE__{}
  def failure(result, reason) do
    %{result |
      status: :failed,
      failure_reason: reason
    }
  end
  
  @doc """
  Add lifecycle event to audit trail.
  """
  @spec add_lifecycle_event(%__MODULE__{}, map()) :: %__MODULE__{}
  def add_lifecycle_event(result, event) do
    %{result |
      lifecycle_events: result.lifecycle_events ++ [event]
    }
  end
  
  @doc """
  Add semantic event to audit trail.
  """
  @spec add_semantic_event(%__MODULE__{}, map()) :: %__MODULE__{}
  def add_semantic_event(result, event) do
    %{result |
      semantic_events: result.semantic_events ++ [event]
    }
  end
  
  @doc """
  Add governance decision to audit trail.
  """
  @spec add_governance_decision(%__MODULE__{}, map()) :: %__MODULE__{}
  def add_governance_decision(result, decision) do
    %{result |
      governance_decisions: result.governance_decisions ++ [decision]
    }
  end
  
  @doc """
  Generate human-readable summary for Capability Report.
  """
  @spec summarize(%__MODULE__{}) :: String.t()
  def summarize(result) do
    """
    Research Cycle Summary
    =====================
    
    Goal: #{result.goal}
    Status: #{result.status}
    
    Hypothesis Generated: #{if result.hypothesis, do: "✓", else: "✗"}
    Experiment Executed: #{if result.experiment, do: "✓", else: "✗"}
    Evidence Collected: #{length(result.evidence)} items
    Belief Revised: #{if result.belief_change, do: "✓", else: "✗"}
    Publication Decision: #{if result.publication, do: "✓", else: "✗"}
    
    Constitutional Deltas:
      Knowledge Graph: #{if result.knowledge_delta, do: "Updated", else: "No change"}
      Economic Ledger: #{if result.ledger_delta, do: "Updated", else: "No change"}
      Memory: #{if result.memory_delta, do: "Compressed", else: "No change"}
    
    Audit Trail:
      Lifecycle Events: #{length(result.lifecycle_events)}
      Semantic Events: #{length(result.semantic_events)}
      Governance Decisions: #{length(result.governance_decisions)}
    
    Execution Time: #{result.execution_time_ms}ms
    Constitutional Validation: #{Map.get(result.constitutional_validation, :status, "N/A")}
    """
  end
end
