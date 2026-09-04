defmodule TiannaraOS.ResearchCoordinationResult do
  @moduledoc """
  ResearchCoordinationResult - Canonical constitutional transaction for institutional scientific coordination.
  
  This artifact captures the complete audit trail of one institutional research coordination event,
  including scheduling decisions for multiple concurrent Research Episodes, budget allocations,
  priority negotiations, conflict resolutions, governance approvals, and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing scheduler state, planner graphs, execution queues, priority heaps, worker allocations,
  or timelines, this result stores only the behavioral contract: what Episodes were coordinated, what
  scheduling decisions were made, and what resources were allocated. Internal coordination mechanisms
  remain hidden implementation details.
  
  ## Constitutional Properties
  
  - Immutable once finalized
  - Contains lightweight coordination references (not full scheduler state)
  - Complete audit trail via semantic events and lifecycle tracking
  - Economic ledger accounts for coordination costs and budget allocations
  - Governance validates conflicting priorities before execution
  - All twenty domains use identical implementation
  
  ## Fields
  
  - `:coordination_id` - Unique identifier for this coordination event
  - `:institution_id` - Owning institution (atom)
  - `:timestamp` - When coordination occurred (DateTime.t())
  - `:tick` - Institutional tick counter (integer)
  - `:participating_episodes` - List of Episodes being coordinated ([%{episode_id, priority, status}])
  - `:scheduling_decisions` - Scheduling outcomes ([%{episode_id, decision, reason}])
  - `:budget_allocations` - Resource allocations (%{episode_id => amount})
  - `:conflict_resolutions` - Resolved conflicts ([%{conflict_type, episodes_involved, resolution}])
  - `:deferred_episodes` - Episodes postponed due to constraints ([%{episode_id, reason}])
  - `:completed_episodes` - Episodes finished during coordination ([%{episode_id, outcome}])
  - `:governance_approvals` - Governance decisions ([%{decision, reason, decided_tick}])
  - `:ledger_delta` - Economic cost accounting (%{operation, cost, description, timestamp} | nil)
  - `:memory_delta` - Memory updates (%{operation, data, timestamp} | nil)
  - `:semantic_events` - Domain-specific events emitted ([map()])
  - `:lifecycle_events` - Lifecycle registry entries ([map()])
  - `:constitutional_validation` - Invariant verification results (map() | nil)
  - `:execution_metrics` - Coordination performance metrics (%{duration_ms, episodes_coordinated, conflicts_resolved})
  - `:status` - Current state (:coordinated | :conflicts_unresolved | :resource_exhausted | :coordination_failed)
  - `:failure_reason` - Explanation if failed (String.t() | nil)
  
  ## Example
  
      %ResearchCoordinationResult{
        coordination_id: "rc_abc123",
        institution_id: :medicine_inst,
        participating_episodes: [
          %{episode_id: "ep_a", priority: :high, status: :scheduled},
          %{episode_id: "ep_b", priority: :medium, status: :scheduled},
          %{episode_id: "ep_c", priority: :low, status: :deferred}
        ],
        scheduling_decisions: [
          %{episode_id: "ep_a", decision: :execute_immediately, reason: "High priority drug interaction study"},
          %{episode_id: "ep_b", decision: :execute_after_ep_a, reason: "Depends on ep_a results"},
          %{episode_id: "ep_c", decision: :defer, reason: "Insufficient budget"}
        ],
        budget_allocations: %{
          "ep_a" => 50.0,
          "ep_b" => 30.0,
          "ep_c" => 0.0
        },
        conflict_resolutions: [
          %{
            conflict_type: :budget_competition,
            episodes_involved: ["ep_a", "ep_b"],
            resolution: "Allocated based on priority and expected impact"
          }
        ],
        deferred_episodes: [%{episode_id: "ep_c", reason: "Budget exhaustion"}],
        completed_episodes: [],
        governance_approvals: [%{decision: :approve, reason: "Priority allocation validated", decided_tick: 42}],
        status: :coordinated
      }
  """
  
  @derive Jason.Encoder
  defstruct [
    :coordination_id,             # String.t() - unique identifier
    :institution_id,              # atom() - owning institution
    :timestamp,                   # DateTime.t() - when coordination occurred
    :tick,                        # integer() - institutional tick
    
    :participating_episodes,      # [%{episode_id, priority, status}]
    :scheduling_decisions,        # [%{episode_id, decision, reason}]
    :budget_allocations,          # %{episode_id => float()}
    :conflict_resolutions,        # [%{conflict_type, episodes_involved, resolution}]
    :deferred_episodes,           # [%{episode_id, reason}]
    :completed_episodes,          # [%{episode_id, outcome}]
    
    :governance_approvals,        # [%{decision, reason, decided_tick}]
    :ledger_delta,                # map() | nil - economic cost accounting
    :memory_delta,                # map() | nil - memory updates
    :semantic_events,             # [map()] - domain-specific events
    :lifecycle_events,            # [map()] - lifecycle registry entries
    :constitutional_validation,   # map() | nil - invariant verification
    :execution_metrics,           # %{duration_ms, episodes_coordinated, conflicts_resolved}
    
    :status,                      # atom() - current state
    :failure_reason               # String.t() | nil - explanation if failed
  ]
  
  @doc """
  Create a new ResearchCoordinationResult for an institution's coordination event.
  
  ## Parameters
  
  - `institution_id`: atom() - owning institution
  - `opts`: map() - optional parameters (:tick, :participating_episodes)
  
  ## Returns
  
  ResearchCoordinationResult.t() - initialized result with :coordinated status
  
  ## Example
  
      result = ResearchCoordinationResult.new(:medicine_inst, %{
        tick: 42,
        participating_episodes: [%{episode_id: "ep_a", priority: :high}]
      })
  """
  def new(institution_id, opts \\ %{}) do
    # Convert keyword list to map if needed
    opts_map = if is_list(opts), do: Map.new(opts), else: opts
    
    %__MODULE__{
      coordination_id: generate_coordination_id(institution_id),
      institution_id: institution_id,
      timestamp: DateTime.utc_now(),
      tick: Map.get(opts_map, :tick, 0),
      
      participating_episodes: Map.get(opts_map, :participating_episodes, []),
      scheduling_decisions: [],
      budget_allocations: %{},
      conflict_resolutions: [],
      deferred_episodes: [],
      completed_episodes: [],
      
      governance_approvals: [],
      ledger_delta: nil,
      memory_delta: nil,
      semantic_events: [],
      lifecycle_events: [],
      constitutional_validation: nil,
      execution_metrics: %{duration_ms: 0, episodes_coordinated: 0, conflicts_resolved: 0},
      
      status: :coordinated,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a scheduling decision for an Episode.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `episode_id`: String.t() - Episode identifier
  - `decision`: atom() - scheduling decision (:execute_immediately | :execute_later | :defer | :cancel)
  - `reason`: String.t() - rationale for decision
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with scheduling decision
  """
  def add_scheduling_decision(result, episode_id, decision, reason) do
    scheduling = %{
      episode_id: episode_id,
      decision: decision,
      reason: reason
    }
    
    %{result | scheduling_decisions: result.scheduling_decisions ++ [scheduling]}
  end
  
  @doc """
  Set budget allocation for an Episode.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `episode_id`: String.t() - Episode identifier
  - `amount`: float() - budget amount allocated
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with budget allocation
  """
  def set_budget_allocation(result, episode_id, amount) do
    %{result | budget_allocations: Map.put(result.budget_allocations, episode_id, amount)}
  end
  
  @doc """
  Add a conflict resolution.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `conflict_type`: atom() - type of conflict (:budget_competition | :resource_conflict | :priority_conflict)
  - `episodes_involved`: [String.t()] - Episodes involved in conflict
  - `resolution`: String.t() - how conflict was resolved
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with conflict resolution
  """
  def add_conflict_resolution(result, conflict_type, episodes_involved, resolution) do
    conflict = %{
      conflict_type: conflict_type,
      episodes_involved: episodes_involved,
      resolution: resolution
    }
    
    %{result | conflict_resolutions: result.conflict_resolutions ++ [conflict]}
  end
  
  @doc """
  Add a deferred Episode.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `episode_id`: String.t() - Episode identifier
  - `reason`: String.t() - reason for deferral
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with deferred Episode
  """
  def add_deferred_episode(result, episode_id, reason) do
    deferred = %{
      episode_id: episode_id,
      reason: reason
    }
    
    %{result | deferred_episodes: result.deferred_episodes ++ [deferred]}
  end
  
  @doc """
  Add a completed Episode.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `episode_id`: String.t() - Episode identifier
  - `outcome`: atom() - Episode outcome (:success | :failure | :inconclusive)
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with completed Episode
  """
  def add_completed_episode(result, episode_id, outcome) do
    completed = %{
      episode_id: episode_id,
      outcome: outcome
    }
    
    %{result | completed_episodes: result.completed_episodes ++ [completed]}
  end
  
  @doc """
  Add a governance approval.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `approval`: map() - governance approval (%{decision, reason, decided_tick})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with governance approval
  """
  def add_governance_approval(result, approval) do
    %{result | governance_approvals: result.governance_approvals ++ [approval]}
  end
  
  @doc """
  Set ledger delta for coordination costs.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `delta`: map() - ledger delta (%{operation, cost, description, timestamp})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with ledger delta
  """
  def set_ledger_delta(result, delta) do
    %{result | ledger_delta: delta}
  end
  
  @doc """
  Set memory delta for coordination.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `delta`: map() - memory delta (%{operation, data, timestamp})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with memory delta
  """
  def set_memory_delta(result, delta) do
    %{result | memory_delta: delta}
  end
  
  @doc """
  Add semantic event emitted during coordination.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `event`: map() - semantic event (%{type, data, timestamp})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with event added
  """
  def add_semantic_event(result, event) do
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Add lifecycle event for coordination.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `event`: map() - lifecycle event (%{event_type, tick, timestamp, metadata})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with lifecycle event
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Set constitutional validation results.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `validation`: map() - validation results (%{status, invariants_checked, validated_tick})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with validation
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Set execution metrics for coordination.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `metrics`: map() - execution metrics (%{duration_ms, episodes_coordinated, conflicts_resolved})
  
  ## Returns
  
  ResearchCoordinationResult.t() - updated result with execution metrics
  """
  def set_execution_metrics(result, metrics) do
    %{result | execution_metrics: metrics}
  end
  
  @doc """
  Mark coordination as having unresolved conflicts.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `reason`: String.t() - explanation of unresolved conflicts
  
  ## Returns
  
  ResearchCoordinationResult.t() - result marked with conflicts unresolved
  """
  def mark_conflicts_unresolved(result, reason) do
    %{result |
      status: :conflicts_unresolved,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark coordination as resource exhausted.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `reason`: String.t() - explanation of resource exhaustion
  
  ## Returns
  
  ResearchCoordinationResult.t() - result marked as resource exhausted
  """
  def mark_resource_exhausted(result, reason) do
    %{result |
      status: :resource_exhausted,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark coordination as failed.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  - `reason`: String.t() - failure explanation
  
  ## Returns
  
  ResearchCoordinationResult.t() - result marked as failed
  """
  def mark_failed(result, reason) do
    %{result |
      status: :coordination_failed,
      failure_reason: reason
    }
  end
  
  @doc """
  Get total number of Episodes coordinated.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  
  ## Returns
  
  integer() - count of participating Episodes
  """
  def get_episodes_count(result) do
    length(result.participating_episodes)
  end
  
  @doc """
  Check if any Episodes were deferred.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  
  ## Returns
  
  boolean() - true if any Episodes were deferred
  """
  def has_deferred_episodes?(result) do
    length(result.deferred_episodes) > 0
  end
  
  @doc """
  Get total budget allocated across all Episodes.
  
  ## Parameters
  
  - `result`: ResearchCoordinationResult.t() - target result
  
  ## Returns
  
  float() - sum of all budget allocations
  """
  def get_total_budget_allocated(result) do
    Map.values(result.budget_allocations) |> Enum.sum()
  end
  
  # Generate unique coordination ID
  defp generate_coordination_id(institution_id) do
    prefix = Atom.to_string(institution_id) |> String.slice(0, 3)
    timestamp = System.system_time(:millisecond) |> rem(1000000)
    random = :rand.uniform(9999)
    "rc_#{prefix}_#{timestamp}_#{random}"
  end
end
