defmodule TiannaraOS.ResearchStrategyResult do
  @moduledoc """
  ResearchStrategyResult - Canonical constitutional transaction for research strategy selection.

  This artifact captures the civilization's strategic research objective before allocating
  resources to specific programs and experiments. It represents the transition from
  tactical experiment scheduling to strategic civilization-level planning.

  ## Constitutional Role

  The Research Strategy sits between the Research Director and Programs:

  ```
  Civilization Goals
      ↓
  Research Strategy (this transaction)
      ↓
  Portfolio Allocation
      ↓
  Programs
      ↓
  Experiments
  ```

  ## Strategic Objectives

  Example strategies include:
  - :reduce_uncertainty - Focus on resolving critical unknowns
  - :validate_discoveries - Prioritize operational validation of discoveries
  - :expand_frontier - Explore new knowledge areas with high potential
  - :replicate_results - Strengthen confidence through replication
  - :improve_theory_quality - Increase theory confidence levels
  - :increase_applications - Translate discoveries into applications
  - :explore_neglected_domains - Address domains with high research debt
  - :improve_prediction_accuracy - Enhance predictive capabilities

  ## Constitutional Discipline

  - One institutional behavior: selecting civilization-wide research strategy
  - One public API: InstitutionKernel.select_research_strategy/2
  - One canonical transaction: ResearchStrategyResult
  - Composes frozen primitives only (ResearchDirector, DomainRegistry, UnknownRegistry, etc.)
  - No self-modification: strategy selection does not alter methods or institutions
  - Complete traceability: strategy rationale documented with supporting evidence

  ## Usage

      result = ResearchStrategyResult.new(civilization_id, opts)
      result = ResearchStrategyResult.set_civilization_state(result, state_data)
      result = ResearchStrategyResult.evaluate_strategies(result, strategies)
      result = ResearchStrategyResult.select_strategy(result, strategy_id, rationale)
      result = ResearchStrategyResult.allocate_portfolio(result, allocation)
      result = ResearchStrategyResult.finalize(result)
  """

  defstruct [
    # Core identification
    :id,
    :civilization_id,
    :strategy_timestamp,

    # Civilization state assessment
    :civilization_state,
    :research_debt_summary,
    :domain_health_metrics,
    :resource_availability,

    # Strategic options evaluated
    :candidate_strategies,
    :strategy_evaluations,

    # Selected strategy
    :selected_strategy,
    :strategy_rationale,
    :expected_outcomes,
    :risk_assessment,

    # Portfolio allocation based on strategy
    :portfolio_allocation,
    :priority_domains,
    :neglected_domains,

    # Constitutional compliance
    :constitutional_compliance,
    :traceability_graph,
    :lifecycle_events,
    :semantic_events,

    # Status
    :status,
    :failure_reason
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    civilization_id: atom(),
    strategy_timestamp: DateTime.t(),
    civilization_state: map() | nil,
    research_debt_summary: map() | nil,
    domain_health_metrics: map() | nil,
    resource_availability: map() | nil,
    candidate_strategies: [map()],
    strategy_evaluations: map(),
    selected_strategy: map() | nil,
    strategy_rationale: String.t(),
    expected_outcomes: [map()],
    risk_assessment: map() | nil,
    portfolio_allocation: map() | nil,
    priority_domains: [atom()],
    neglected_domains: [atom()],
    constitutional_compliance: map() | nil,
    traceability_graph: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    status: atom(),
    failure_reason: String.t() | nil
  }

  @doc """
  Create a new ResearchStrategyResult.

  ## Parameters
  - `civilization_id`: atom() - civilization identifier
  - `opts`: keyword list or map with optional fields

  ## Returns
  ResearchStrategyResult.t()
  """
  def new(civilization_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts

    %__MODULE__{
      id: Keyword.get(opts, :id, "strategy_#{civilization_id}_#{System.monotonic_time(:millisecond)}"),
      civilization_id: civilization_id,
      strategy_timestamp: DateTime.utc_now(),
      civilization_state: nil,
      research_debt_summary: nil,
      domain_health_metrics: nil,
      resource_availability: nil,
      candidate_strategies: [],
      strategy_evaluations: %{},
      selected_strategy: nil,
      strategy_rationale: "",
      expected_outcomes: [],
      risk_assessment: nil,
      portfolio_allocation: nil,
      priority_domains: [],
      neglected_domains: [],
      constitutional_compliance: nil,
      traceability_graph: nil,
      lifecycle_events: [],
      semantic_events: [],
      status: :initiated,
      failure_reason: nil
    }
  end

  @doc """
  Add lifecycle event to the strategy result.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `event_data`: map() with event details

  ## Returns
  ResearchStrategyResult.t()
  """
  def add_lifecycle_event(result, event_data) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event_data]}
  end

  @doc """
  Add semantic event to the strategy result.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `event_type`: atom()
  - `data`: map()

  ## Returns
  ResearchStrategyResult.t()
  """
  def add_semantic_event(result, event_type, data) do
    %{result | semantic_events: result.semantic_events ++ [%{type: event_type, data: data}]}
  end

  @doc """
  Set civilization state assessment.

  Captures current state of research civilization including:
  - Total discoveries, theories, laws
  - Open unknowns count
  - Active programs
  - Validation backlog
  - Domain maturity distribution

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `state_data`: map()

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_civilization_state(result, state_data) do
    result = %{result | civilization_state: state_data}
    add_lifecycle_event(result, %{
      event: :civilization_state_assessed,
      timestamp: DateTime.utc_now(),
      summary: %{
        total_discoveries: get_in(state_data, [:summary, :total_discoveries]),
        total_unknowns: get_in(state_data, [:summary, :total_unknowns]),
        active_programs: get_in(state_data, [:summary, :active_programs])
      }
    })
  end

  @doc """
  Set research debt summary by domain.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `debt_summary`: %{domain_id => unknown_count}

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_research_debt_summary(result, debt_summary) do
    %{result | research_debt_summary: debt_summary}
  end

  @doc """
  Set domain health metrics.

  Includes per-domain statistics on knowledge capital, maturity, innovation velocity, etc.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `health_metrics`: %{domain_id => health_data}

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_domain_health_metrics(result, health_metrics) do
    %{result | domain_health_metrics: health_metrics}
  end

  @doc """
  Set available resources for allocation.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `resources`: map() with resource types and quantities

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_resource_availability(result, resources) do
    %{result | resource_availability: resources}
  end

  @doc """
  Add candidate strategy for evaluation.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `strategy`: map() with :id, :name, :description, :objective

  ## Returns
  ResearchStrategyResult.t()
  """
  def add_candidate_strategy(result, strategy) do
    %{result | candidate_strategies: result.candidate_strategies ++ [strategy]}
  end

  @doc """
  Evaluate a candidate strategy.

  Assesses strategy against civilization state and objectives.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `strategy_id`: atom()
  - `evaluation`: map() with :score, :benefits, :risks, :resource_requirements

  ## Returns
  ResearchStrategyResult.t()
  """
  def evaluate_strategy(result, strategy_id, evaluation) do
    evaluations = Map.put(result.strategy_evaluations || %{}, strategy_id, evaluation)
    %{result | strategy_evaluations: evaluations}
  end

  @doc """
  Select the optimal strategy with rationale.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `strategy_id`: atom()
  - `rationale`: String.t() explaining why this strategy was chosen
  - `expected_outcomes`: [map()] of anticipated results

  ## Returns
  ResearchStrategyResult.t()
  """
  def select_strategy(result, strategy_id, rationale, expected_outcomes) do
    selected = Enum.find(result.candidate_strategies, fn s -> s.id == strategy_id end)

    if selected do
      result = %{result |
        selected_strategy: selected,
        strategy_rationale: rationale,
        expected_outcomes: expected_outcomes
      }

      result = add_lifecycle_event(result, %{
        event: :strategy_selected,
        strategy_id: strategy_id,
        strategy_name: selected.name,
        timestamp: DateTime.utc_now()
      })

      add_semantic_event(result, :strategy_selected, %{
        strategy: strategy_id,
        rationale_length: String.length(rationale),
        expected_outcome_count: length(expected_outcomes)
      })
    else
      result
    end
  end

  @doc """
  Set risk assessment for selected strategy.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `risk_data`: map() with :level, :mitigations, :contingencies

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_risk_assessment(result, risk_data) do
    %{result | risk_assessment: risk_data}
  end

  @doc """
  Set portfolio allocation based on strategy.

  Distributes resources across domains according to strategic priorities.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `allocation`: %{domain_id => %{percentage: float(), rationale: String.t()}}

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_portfolio_allocation(result, allocation) do
    result = %{result | portfolio_allocation: allocation}

    priority_domains = allocation
    |> Enum.sort_by(fn {_domain, data} -> data.percentage end, :desc)
    |> Enum.map(fn {domain, _data} -> domain end)

    %{result | priority_domains: priority_domains}
  end

  @doc """
  Set neglected domains requiring attention.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `domains`: [atom()]

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_neglected_domains(result, domains) do
    %{result | neglected_domains: domains}
  end

  @doc """
  Set constitutional compliance verification.

  ## Parameters
  - `result`: ResearchStrategyResult.t()
  - `compliance`: map() with verification results

  ## Returns
  ResearchStrategyResult.t()
  """
  def set_constitutional_compliance(result, compliance) do
    %{result | constitutional_compliance: compliance}
  end

  @doc """
  Finalize the strategy result.

  Marks the strategy as complete and ready for execution.

  ## Parameters
  - `result`: ResearchStrategyResult.t()

  ## Returns
  ResearchStrategyResult.t()
  """
  def finalize(result) do
    if result.selected_strategy == nil do
      %{result |
        status: :failed,
        failure_reason: "No strategy selected"
      }
    else
      result = add_lifecycle_event(result, %{
        event: :strategy_finalized,
        timestamp: DateTime.utc_now(),
        strategy: result.selected_strategy.id
      })

      %{result | status: :completed}
    end
  end

  @doc """
  Verify strategy result completeness.

  Checks that all required fields are populated and strategy is valid.

  ## Parameters
  - `result`: ResearchStrategyResult.t()

  ## Returns
  boolean()
  """
  def verify_completeness(result) do
    result.status == :completed &&
    result.selected_strategy != nil &&
    result.strategy_rationale != "" &&
    result.portfolio_allocation != nil &&
    length(result.expected_outcomes) > 0
  end

  @doc """
  Get summary of the strategy result.

  ## Parameters
  - `result`: ResearchStrategyResult.t()

  ## Returns
  map() with summary information
  """
  def get_summary(result) do
    %{
      id: result.id,
      civilization_id: result.civilization_id,
      strategy_timestamp: result.strategy_timestamp,
      selected_strategy: if(result.selected_strategy, do: result.selected_strategy.name, else: nil),
      strategy_rationale: result.strategy_rationale,
      priority_domains: result.priority_domains,
      neglected_domains: result.neglected_domains,
      expected_outcomes_count: length(result.expected_outcomes),
      status: result.status
    }
  end
end
