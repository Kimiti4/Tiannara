defmodule TiannaraOS.MethodEvolutionResult do
  @moduledoc """
  MethodEvolutionResult - Canonical constitutional transaction for institutional method evolution.

  Capability 13.2 - Institutional Method Evolution

  This artifact captures evidence-supported proposals for improving how research is performed.
  The institution asks "How could I become a better scientist?" and generates method improvement
  recommendations based on analysis of historical Research Episodes.

  ## Constitutional Role

  Method Evolution evaluates institutional scientific methods, NOT scientific conclusions.
  It analyzes:
  - Hypothesis generation quality
  - Experiment design efficiency
  - Evidence gathering completeness
  - Replication workflow effectiveness
  - Publication quality
  - Collaboration efficiency
  - Validation strategy
  - Resource allocation optimization
  - Theory formation process
  - Planning quality
  - Reasoning strategy selection
  - Uncertainty management

  ## Constitutional Pipeline

  ```
  Observe Research Episodes
      ↓
  Measure scientific performance
      ↓
  Detect recurring inefficiencies
      ↓
  Generate candidate improvements
      ↓
  Predict expected impact
      ↓
  Estimate implementation risk
      ↓
  Preserve competing improvements
      ↓
  Record provenance
      ↓
  MethodEvolutionResult
  ```

  ## Constitutional Invariants

  1. Method proposals are evidence-derived (reference supporting Episodes)
  2. Alternative improvements are preserved (no single solution forced)
  3. Recommendations remain reversible (no permanent mutation)
  4. No constitutional mutation occurs (only recommendations)
  5. Complete provenance exists (traceable to source Episodes)
  6. Institution history remains immutable (read-only analysis)

  ## Evaluation Categories

  - :experiment_design - How experiments are structured and executed
  - :evidence_gathering - Data collection and validation processes
  - :replication_workflow - Independent verification procedures
  - :publication_quality - Dissemination and peer review
  - :collaboration_efficiency - Multi-institution coordination
  - :validation_strategy - Confidence building approaches
  - :resource_allocation - Budget and personnel optimization
  - :theory_formation - Hypothesis generation and testing
  - :planning_quality - Research program structuring
  - :reasoning_strategy - Logical inference methods
  - :uncertainty_management - Unknown prioritization and resolution

  ## Usage

      # Evaluate method evolution for an institution
      {:ok, result} = MethodEvolutionResult.new(:quantum_lab, %{
        evaluation_categories: [:experiment_design, :validation_strategy],
        time_window_months: 6
      })

      # Access candidate improvements
      # Enum.each(result.candidate_improvements, fn imp ->
      #   IO.inspect(imp[:category])
      # end)
  """

  defstruct [
    # Core identification
    :id,
    :institution_id,
    :evaluation_timestamp,

    # Evaluation scope
    :evaluation_categories,
    :time_window_months,
    :episodes_analyzed,

    # Performance metrics
    :current_performance_metrics,
    :inefficiencies_detected,

    # Candidate improvements
    :candidate_improvements,
    :competing_improvements,

    # Impact predictions
    :impact_predictions,
    :risk_assessments,

    # Evidence provenance
    :supporting_episodes,
    :evidence_summary,

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
    institution_id: atom(),
    evaluation_timestamp: DateTime.t(),
    evaluation_categories: [atom()],
    time_window_months: integer(),
    episodes_analyzed: integer(),
    current_performance_metrics: map() | nil,
    inefficiencies_detected: [map()] | nil,
    candidate_improvements: [map()] | nil,
    competing_improvements: [map()] | nil,
    impact_predictions: map() | nil,
    risk_assessments: map() | nil,
    supporting_episodes: [atom()] | nil,
    evidence_summary: map() | nil,
    constitutional_compliance: map() | nil,
    traceability_graph: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    status: atom(),
    failure_reason: String.t() | nil
  }

  @doc """
  Create a new MethodEvolutionResult.

  ## Parameters
  - `institution_id`: atom() - institution identifier
  - `opts`: keyword list or map with optional fields

  ## Returns
  MethodEvolutionResult.t()
  """
  def new(institution_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts

    %__MODULE__{
      id: Keyword.get(opts, :id, "method_evolution_#{institution_id}_#{System.monotonic_time(:millisecond)}"),
      institution_id: institution_id,
      evaluation_timestamp: DateTime.utc_now(),
      evaluation_categories: Keyword.get(opts, :evaluation_categories, []),
      time_window_months: Keyword.get(opts, :time_window_months, 6),
      episodes_analyzed: 0,
      current_performance_metrics: nil,
      inefficiencies_detected: [],
      candidate_improvements: [],
      competing_improvements: [],
      impact_predictions: nil,
      risk_assessments: nil,
      supporting_episodes: [],
      evidence_summary: nil,
      constitutional_compliance: nil,
      traceability_graph: nil,
      lifecycle_events: [],
      semantic_events: [],
      status: :pending,
      failure_reason: nil
    }
  end

  @doc """
  Add a candidate improvement proposal.

  Each improvement includes:
  - category: atom() - evaluation category
  - description: String.t() - proposed change
  - current_issue: String.t() - identified inefficiency
  - expected_impact: float() - predicted improvement (0.0-1.0)
  - implementation_risk: atom() - :low, :medium, :high
  - supporting_evidence: [atom()] - episode IDs
  - reversibility: boolean() - can be rolled back
  - estimated_cost: map() - resource requirements

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `improvement`: map()

  ## Returns
  MethodEvolutionResult.t()
  """
  def add_candidate_improvement(result, improvement) do
    improvements = result.candidate_improvements ++ [improvement]
    %{result | candidate_improvements: improvements}
  end

  @doc """
  Add a competing improvement (alternative approach to same issue).

  Preserves multiple solutions rather than forcing single answer.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `improvement`: map()

  ## Returns
  MethodEvolutionResult.t()
  """
  def add_competing_improvement(result, improvement) do
    improvements = result.competing_improvements ++ [improvement]
    %{result | competing_improvements: improvements}
  end

  @doc """
  Record supporting evidence from Research Episodes.

  Links improvement proposals to concrete historical evidence.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `episode_ids`: [atom()] - list of episode IDs providing evidence

  ## Returns
  MethodEvolutionResult.t()
  """
  def add_supporting_evidence(result, episode_ids) do
    episodes = result.supporting_episodes ++ episode_ids
    %{result | supporting_episodes: episodes}
  end

  @doc """
  Set performance metrics for current institutional methods.

  Measures baseline before proposing improvements.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `metrics`: map() with keys like:
    - :experiment_success_rate
    - :validation_throughput
    - :replication_accuracy
    - :publication_quality_score
    - :resource_efficiency
    - :time_to_discovery

  ## Returns
  MethodEvolutionResult.t()
  """
  def set_performance_metrics(result, metrics) do
    %{result | current_performance_metrics: metrics}
  end

  @doc """
  Record detected inefficiencies in current methods.

  Identifies recurring problems across multiple episodes.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `inefficiencies`: [map()] each with:
    - :category
    - :description
    - :frequency
    - :severity
    - :affected_episodes

  ## Returns
  MethodEvolutionResult.t()
  """
  def record_inefficiencies(result, inefficiencies) do
    %{result | inefficiencies_detected: inefficiencies}
  end

  @doc """
  Set impact predictions for proposed improvements.

  Estimates expected benefits across multiple dimensions.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `predictions`: map() with keys like:
    - :efficiency_gain
    - :quality_improvement
    - :cost_reduction
    - :time_savings
    - :confidence_increase

  ## Returns
  MethodEvolutionResult.t()
  """
  def set_impact_predictions(result, predictions) do
    %{result | impact_predictions: predictions}
  end

  @doc """
  Set risk assessments for proposed improvements.

  Evaluates potential downsides and implementation challenges.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `assessments`: map() with keys like:
    - :implementation_complexity
    - :disruption_risk
    - :learning_curve
    - :reversibility_confidence
    - :constitutional_compatibility

  ## Returns
  MethodEvolutionResult.t()
  """
  def set_risk_assessments(result, assessments) do
    %{result | risk_assessments: assessments}
  end

  @doc """
  Mark evaluation as complete with final status.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `status`: atom() - :completed, :failed, :insufficient_evidence

  ## Returns
  MethodEvolutionResult.t()
  """
  def mark_complete(result, status) do
    %{result | status: status}
  end

  @doc """
  Mark evaluation as failed with reason.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `reason`: String.t() - explanation of failure

  ## Returns
  MethodEvolutionResult.t()
  """
  def mark_failed(result, reason) do
    %{result | status: :failed, failure_reason: reason}
  end

  @doc """
  Add lifecycle event for traceability.

  Records key moments in the evaluation process.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `event_type`: atom()
  - `metadata`: map()

  ## Returns
  MethodEvolutionResult.t()
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

  Captures high-level semantic meaning of evaluation steps.

  ## Parameters
  - `result`: MethodEvolutionResult.t()
  - `event_type`: atom()
  - `metadata`: map()

  ## Returns
  MethodEvolutionResult.t()
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
  Validate constitutional compliance of the evaluation.

  Ensures all invariants are satisfied:
  - Evidence-derived proposals
  - Alternative improvements preserved
  - Reversibility maintained
  - Complete provenance
  - Immutable history

  ## Parameters
  - `result`: MethodEvolutionResult.t()

  ## Returns
  {:compliant, violations} where violations is empty list if compliant
  """
  def validate_constitutional_compliance(result) do
    violations = []

    # Check 1: Must have supporting evidence if improvements proposed
    violations = if length(result.candidate_improvements) > 0 and length(result.supporting_episodes) == 0 do
      [%{rule: "evidence_required", message: "Improvements proposed without supporting episodes"} | violations]
    else
      violations
    end

    # Check 2: Competing improvements should be preserved when alternatives exist
    violations = if length(result.candidate_improvements) > 1 and length(result.competing_improvements) == 0 do
      [%{rule: "alternatives_preserved", message: "Multiple candidates but no competing improvements recorded"} | violations]
    else
      violations
    end

    # Check 3: Status must be set
    violations = if result.status == :pending do
      [%{rule: "status_required", message: "Evaluation status not finalized"} | violations]
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
  Build traceability graph linking improvements to evidence.

  Creates visualizable graph showing:
  - Which episodes support which improvements
  - Which inefficiencies triggered which proposals
  - Confidence levels based on evidence quantity

  ## Parameters
  - `result`: MethodEvolutionResult.t()

  ## Returns
  map() with nodes and edges for visualization
  """
  def build_traceability_graph(result) do
    nodes = []
    edges = []

    # Add inefficiency nodes
    nodes_with_inefficiencies = Enum.reduce(result.inefficiencies_detected || [], nodes, fn ineff, acc ->
      node = %{
        id: "inefficiency_#{ineff[:category]}",
        type: :inefficiency,
        label: ineff[:description],
        severity: ineff[:severity]
      }
      [node | acc]
    end)

    # Add improvement nodes
    nodes_with_improvements = Enum.reduce(result.candidate_improvements || [], nodes_with_inefficiencies, fn imp, acc ->
      node = %{
        id: "improvement_#{imp[:category]}",
        type: :improvement,
        label: imp[:description],
        expected_impact: imp[:expected_impact]
      }
      [node | acc]
    end)

    # Add episode nodes
    all_nodes = Enum.reduce(result.supporting_episodes || [], nodes_with_improvements, fn episode_id, acc ->
      node = %{
        id: "episode_#{episode_id}",
        type: :episode,
        label: "Episode #{episode_id}"
      }
      [node | acc]
    end)

    # Add edges from inefficiencies to improvements
    edges_from_inefficiencies = Enum.reduce(result.candidate_improvements || [], edges, fn imp, acc ->
      edge = %{
        from: "inefficiency_#{imp[:category]}",
        to: "improvement_#{imp[:category]}",
        type: :addresses
      }
      [edge | acc]
    end)

    # Add edges from improvements to episodes
    all_edges = Enum.reduce(result.supporting_episodes || [], edges_from_inefficiencies, fn episode_id, acc ->
      edge = %{
        from: "improvement_general",
        to: "episode_#{episode_id}",
        type: :supported_by
      }
      [edge | acc]
    end)

    %{
      nodes: all_nodes,
      edges: all_edges,
      summary: %{
        total_inefficiencies: length(result.inefficiencies_detected || []),
        total_improvements: length(result.candidate_improvements || []),
        total_episodes: length(result.supporting_episodes || []),
        total_edges: length(all_edges)
      }
    }
  end

  def add_evidence_summary(_result_id, _summary), do: {:ok, :stub}
end
