defmodule TiannaraOS.ReasoningStrategyResult do
  @moduledoc """
  ReasoningStrategyResult - Canonical constitutional transaction for institutional reasoning strategy selection.
  
  This artifact captures the complete audit trail of one institutional reasoning strategy selection event,
  including the problem description, candidate strategies evaluated, selected strategy with rationale,
  expected strengths/limitations, cost estimates, confidence levels, and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing routing algorithms, planner frameworks, or specific AI techniques (LLMs, SAT solvers,
  neural networks, etc.), this result stores only the behavioral contract: which reasoning strategy was
  selected for which problem, and why. Internal routing mechanisms remain hidden implementation details.
  
  ## Constitutional Properties
  
  - Immutable once finalized
  - Contains lightweight strategy references (not full algorithm implementations)
  - Complete audit trail via semantic events and lifecycle tracking
  - Economic ledger accounts for strategy selection costs
  - Governance validates strategy appropriateness before selection
  - All twenty domains use identical implementation
  
  ## Fields
  
  - `:reasoning_id` - Unique identifier for this strategy selection event
  - `:institution_id` - Owning institution (atom)
  - `:timestamp` - When selection occurred (DateTime.t())
  - `:tick` - Institutional tick counter (integer)
  - `:research_episode` - Associated ResearchEpisode reference (String.t() | nil)
  - `:problem_description` - What problem needs solving (String.t())
  - `:candidate_strategies` - List of strategies considered [%{strategy, rationale, cost, confidence}]
  - `:selected_strategy` - Chosen reasoning approach (atom | String.t())
  - `:selection_rationale` - Why this strategy was chosen (String.t())
  - `:expected_strengths` - What this strategy excels at ([String.t()])
  - `:expected_limitations` - Known weaknesses ([String.t()])
  - `:estimated_cost` - Predicted computational/resource cost (float)
  - `:estimated_confidence` - Confidence in strategy appropriateness (float 0.0-1.0)
  - `:governance_decision` - Governance approval/rejection (%{decision, reason, decided_tick} | nil)
  - `:ledger_delta` - Economic cost accounting (%{operation, cost, description, timestamp} | nil)
  - `:memory_delta` - Memory updates (%{operation, data, timestamp} | nil)
  - `:semantic_events` - Domain-specific events emitted ([map()])
  - `:lifecycle_events` - Lifecycle registry entries ([map()])
  - `:constitutional_validation` - Invariant verification results (map() | nil)
  - `:execution_time_ms` - How long selection took (integer)
  - `:status` - Current state (:pending | :completed | :rejected | :deferred | :insufficient_evidence)
  - `:failure_reason` - Explanation if failed/deferred (String.t() | nil)
  
  ## Example
  
      %ReasoningStrategyResult{
        reasoning_id: "rs_abc123",
        institution_id: :medicine_inst,
        problem_description: "Predict drug interaction effects",
        candidate_strategies: [
          %{strategy: :causal_reasoning, rationale: "Requires intervention analysis", cost: 10.0, confidence: 0.85},
          %{strategy: :probabilistic_inference, rationale: "Uncertainty quantification needed", cost: 5.0, confidence: 0.72}
        ],
        selected_strategy: :causal_reasoning,
        selection_rationale: "Problem requires understanding intervention effects on biological systems",
        expected_strengths: ["Intervention analysis", "Counterfactual reasoning", "Causal explanation"],
        expected_limitations: ["Computationally expensive", "Requires historical intervention data"],
        estimated_cost: 10.0,
        estimated_confidence: 0.85,
        status: :completed
      }
  """
  
  @derive Jason.Encoder
  defstruct [
    :reasoning_id,                # String.t() - unique identifier
    :institution_id,              # atom() - owning institution
    :timestamp,                   # DateTime.t() - when selection occurred
    :tick,                        # integer() - institutional tick
    
    :research_episode,            # String.t() | nil - associated episode
    :problem_description,         # String.t() - what problem needs solving
    
    :candidate_strategies,        # [%{strategy, rationale, cost, confidence}]
    :selected_strategy,           # atom() | String.t() - chosen approach
    :selection_rationale,         # String.t() - why this strategy
    :expected_strengths,          # [String.t()] - what it excels at
    :expected_limitations,        # [String.t()] - known weaknesses
    
    :estimated_cost,              # float() - predicted cost
    :estimated_confidence,        # float() - confidence in selection (0.0-1.0)
    
    :governance_decision,         # map() | nil - governance approval/rejection
    :ledger_delta,                # map() | nil - economic cost accounting
    :memory_delta,                # map() | nil - memory updates
    :semantic_events,             # [map()] - domain-specific events
    :lifecycle_events,            # [map()] - lifecycle registry entries
    :constitutional_validation,   # map() | nil - invariant verification
    
    :execution_time_ms,           # integer() - selection duration
    :status,                      # atom() - current state
    :failure_reason               # String.t() | nil - explanation if failed
  ]
  
  @doc """
  Create a new ReasoningStrategyResult for an institution's strategy selection.
  
  ## Parameters
  
  - `institution_id`: atom() - owning institution
  - `problem_description`: String.t() - what problem needs solving
  - `opts`: map() - optional parameters (:research_episode, :tick)
  
  ## Returns
  
  ReasoningStrategyResult.t() - initialized result with :pending status
  
  ## Example
  
      result = ReasoningStrategyResult.new(:medicine_inst, "Predict drug interactions", %{
        research_episode: "ep_xyz789",
        tick: 42
      })
  """
  def new(institution_id, problem_description, opts \\ %{}) do
    # Convert keyword list to map if needed
    opts_map = if is_list(opts), do: Map.new(opts), else: opts
    
    %__MODULE__{
      reasoning_id: generate_reasoning_id(institution_id),
      institution_id: institution_id,
      timestamp: DateTime.utc_now(),
      tick: Map.get(opts_map, :tick, 0),
      
      research_episode: Map.get(opts_map, :research_episode),
      problem_description: problem_description,
      
      candidate_strategies: [],
      selected_strategy: nil,
      selection_rationale: "",
      expected_strengths: [],
      expected_limitations: [],
      
      estimated_cost: 0.0,
      estimated_confidence: 0.0,
      
      governance_decision: nil,
      ledger_delta: nil,
      memory_delta: nil,
      semantic_events: [],
      lifecycle_events: [],
      constitutional_validation: nil,
      
      execution_time_ms: 0,
      status: :pending,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a candidate reasoning strategy for evaluation.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `strategy`: atom() | String.t() - strategy identifier (e.g., :causal_reasoning, :symbolic_deduction)
  - `rationale`: String.t() - why this strategy might be appropriate
  - `cost`: float() - estimated computational/resource cost
  - `confidence`: float() - confidence this strategy will solve the problem (0.0-1.0)
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with candidate added
  
  ## Example
  
      result = ReasoningStrategyResult.add_candidate_strategy(result, :causal_reasoning,
        "Requires intervention analysis", 10.0, 0.85)
  """
  def add_candidate_strategy(result, strategy, rationale, cost, confidence) do
    candidate = %{
      strategy: strategy,
      rationale: rationale,
      cost: cost,
      confidence: confidence
    }
    
    %{result | candidate_strategies: result.candidate_strategies ++ [candidate]}
  end
  
  @doc """
  Set the selected reasoning strategy and rationale.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `strategy`: atom() | String.t() - chosen strategy
  - `rationale`: String.t() - why this strategy was selected
  - `strengths`: [String.t()] - expected strengths
  - `limitations`: [String.t()] - known limitations
  - `confidence`: float() - confidence in selection (0.0-1.0)
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with strategy selected
  """
  def select_strategy(result, strategy, rationale, strengths, limitations, confidence) do
    %{result |
      selected_strategy: strategy,
      selection_rationale: rationale,
      expected_strengths: strengths,
      expected_limitations: limitations,
      estimated_confidence: confidence
    }
  end
  
  @doc """
  Set estimated cost for selected strategy.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `cost`: float() - estimated computational/resource cost
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with cost set
  """
  def set_estimated_cost(result, cost) do
    %{result | estimated_cost: cost}
  end
  
  @doc """
  Add governance decision (approve/reject strategy selection).
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `decision`: map() - governance decision (%{decision, reason, decided_tick})
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with governance decision
  """
  def add_governance_decision(result, decision) do
    %{result | governance_decision: decision}
  end
  
  @doc """
  Set ledger delta for strategy selection costs.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `delta`: map() - ledger delta (%{operation, cost, description, timestamp})
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with ledger delta
  """
  def set_ledger_delta(result, delta) do
    %{result | ledger_delta: delta}
  end
  
  @doc """
  Set memory delta for strategy selection.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `delta`: map() - memory delta (%{operation, data, timestamp})
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with memory delta
  """
  def set_memory_delta(result, delta) do
    %{result | memory_delta: delta}
  end
  
  @doc """
  Add semantic event emitted during strategy selection.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `event`: map() - semantic event (%{type, data, timestamp})
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with event added
  """
  def add_semantic_event(result, event) do
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Add lifecycle event for strategy selection.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `event`: map() - lifecycle event (%{event_type, tick, timestamp, metadata})
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with lifecycle event
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Set constitutional validation results.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `validation`: map() - validation results (%{status, invariants_checked, validated_tick})
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with validation
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Set execution time for strategy selection.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `time_ms`: integer() - execution time in milliseconds
  
  ## Returns
  
  ReasoningStrategyResult.t() - updated result with execution time
  """
  def set_execution_time(result, time_ms) do
    %{result | execution_time_ms: time_ms}
  end
  
  @doc """
  Mark strategy selection as completed.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `reason`: atom() - completion reason (:strategy_selected | :exploratory_reasoning)
  
  ## Returns
  
  ReasoningStrategyResult.t() - completed result
  """
  def mark_completed(result, reason) do
    %{result |
      status: :completed,
      selection_rationale: "#{result.selection_rationale} | Completion reason: #{reason}"
    }
  end
  
  @doc """
  Mark strategy selection as rejected (by governance or safety check).
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `reason`: String.t() - rejection explanation
  
  ## Returns
  
  ReasoningStrategyResult.t() - rejected result
  """
  def mark_rejected(result, reason) do
    %{result |
      status: :rejected,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark strategy selection as deferred (budget exhaustion or insufficient evidence).
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `reason`: String.t() - deferral explanation
  
  ## Returns
  
  ReasoningStrategyResult.t() - deferred result
  """
  def mark_deferred(result, reason) do
    %{result |
      status: :deferred,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark strategy selection as having insufficient evidence.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  - `reason`: String.t() - explanation of insufficient evidence
  
  ## Returns
  
  ReasoningStrategyResult.t() - result marked with insufficient evidence
  """
  def mark_insufficient_evidence(result, reason) do
    %{result |
      status: :insufficient_evidence,
      failure_reason: reason
    }
  end
  
  @doc """
  Get the best candidate strategy by confidence.
  
  ## Parameters
  
  - `result`: ReasoningStrategyResult.t() - target result
  
  ## Returns
  
  map() | nil - highest confidence candidate strategy, or nil if no candidates
  """
  def get_best_candidate(result) do
    if length(result.candidate_strategies) > 0 do
      Enum.max_by(result.candidate_strategies, & &1.confidence)
    else
      nil
    end
  end
  
  # Generate unique reasoning ID
  defp generate_reasoning_id(institution_id) do
    prefix = Atom.to_string(institution_id) |> String.slice(0, 3)
    timestamp = System.system_time(:millisecond) |> rem(1000000)
    random = :rand.uniform(9999)
    "rs_#{prefix}_#{timestamp}_#{random}"
  end
end
