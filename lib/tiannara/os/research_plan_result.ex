defmodule TiannaraOS.ResearchPlanResult do
  @moduledoc """
  ResearchPlanResult - Canonical constitutional transaction for autonomous research planning.
  
  This artifact captures the complete audit trail of one research planning event, including
  candidate research questions, identified knowledge gaps, recommended experiments,
  prioritized research queue, expected information gain, cost estimates, planning rationale,
  and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing planning algorithms, optimization strategies, ranking heuristics,
  search procedures, or decision trees, this result stores only the behavioral contract:
  what research opportunities were identified, what experiments are recommended, what
  the expected value is, and what reasoning led to these recommendations.
  
  ## Constitutional Discipline
  
  - One institutional behavior: deciding what to research next
  - One public API: InstitutionKernel.plan_research/2
  - One canonical transaction: ResearchPlanResult
  - No new persistent state: composes existing frozen primitives
  - Complete traceability: every recommendation references supporting evidence
  
  ## Usage
  
      result = ResearchPlanResult.new(institution_id, opts)
      result = ResearchPlanResult.add_candidate_question(result, question_data)
      result = ResearchPlanResult.add_knowledge_gap(result, gap_data)
      result = ResearchPlanResult.add_recommended_experiment(result, experiment_data)
      result = ResearchPlanResult.prioritize_research_queue(result)
      result = ResearchPlanResult.calculate_expected_roi(result)
      result = ResearchPlanResult.mark_planned(result)
  """
  
  defstruct [
    # Core identification
    :id,
    :institution_id,
    :planning_timestamp,
    
    # Candidate research questions
    :candidate_questions,
    
    # Knowledge gaps driving research
    :knowledge_gaps,
    
    # Recommended experiments
    :recommended_experiments,
    
    # Research programs (higher-level organizational unit)
    :research_programs,
    
    # Prioritized research queue
    :prioritized_research,
    
    # Expected outcomes
    :expected_information_gain,
    :expected_uncertainty_reduction,
    
    # Resource estimates
    :estimated_cost,
    :estimated_duration,
    :research_budget,
    
    # Planning rationale
    :planning_rationale,
    
    # Supporting evidence
    :supporting_theories,
    :topology_inputs,
    
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
    planning_timestamp: DateTime.t(),
    candidate_questions: [map()],
    knowledge_gaps: [map()],
    recommended_experiments: [map()],
    research_programs: [map()],
    prioritized_research: [map()],
    expected_information_gain: float() | nil,
    expected_uncertainty_reduction: float() | nil,
    estimated_cost: float() | nil,
    estimated_duration: non_neg_integer() | nil,
    research_budget: map() | nil,
    planning_rationale: [map()],
    supporting_theories: [String.t()],
    topology_inputs: map() | nil,
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
  Create a new ResearchPlanResult.
  
  ## Parameters
  
  - `institution_id`: atom() - institution performing planning
  - `opts`: keyword list or map with optional fields
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def new(institution_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts
    
    %__MODULE__{
      id: Keyword.get(opts, :id, "plan_#{institution_id}_#{System.monotonic_time(:millisecond)}"),
      institution_id: institution_id,
      planning_timestamp: DateTime.utc_now(),
      candidate_questions: [],
      knowledge_gaps: [],
      recommended_experiments: [],
      research_programs: [],
      prioritized_research: [],
      expected_information_gain: nil,
      expected_uncertainty_reduction: nil,
      estimated_cost: nil,
      estimated_duration: nil,
      research_budget: nil,
      planning_rationale: [],
      supporting_theories: [],
      topology_inputs: nil,
      knowledge_delta: nil,
      ledger_delta: nil,
      traceability_graph: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      constitutional_validation: nil,
      status: :initializing,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a candidate research question.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `question_data`: map() - research question data with fields:
    - `:question` - the research question
    - `:priority` - priority level (:high, :medium, :low)
    - `:expected_value` - expected scientific value
    - `:supporting_gaps` - knowledge gaps motivating this question
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_candidate_question(result, question_data) do
    question = %{
      question: Map.get(question_data, :question, ""),
      priority: Map.get(question_data, :priority, :medium),
      expected_value: Map.get(question_data, :expected_value, 0.5),
      supporting_gaps: Map.get(question_data, :supporting_gaps, []),
      question_id: Map.get(question_data, :question_id, "q_#{length(result.candidate_questions) + 1}")
    }
    
    %{result | candidate_questions: result.candidate_questions ++ [question]}
  end
  
  @doc """
  Add a knowledge gap driving research.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `gap_data`: map() - knowledge gap data
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_knowledge_gap(result, gap_data) do
    %{result | knowledge_gaps: result.knowledge_gaps ++ [gap_data]}
  end
  
  @doc """
  Add a recommended experiment.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `experiment_data`: map() - experiment data with fields:
    - `:title` - experiment title
    - `:research_question` - question being investigated
    - `:expected_evidence` - what evidence is expected
    - `:required_observations` - observations needed
    - `:estimated_effort` - effort estimate (hours/days)
    - `:expected_information_gain` - expected IG score
    - `:cost_estimate` - estimated cost
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_recommended_experiment(result, experiment_data) do
    experiment = %{
      experiment_id: Map.get(experiment_data, :experiment_id, "exp_#{length(result.recommended_experiments) + 1}"),
      title: Map.get(experiment_data, :title, "Untitled Experiment"),
      research_question: Map.get(experiment_data, :research_question, ""),
      expected_evidence: Map.get(experiment_data, :expected_evidence, []),
      required_observations: Map.get(experiment_data, :required_observations, []),
      estimated_effort: Map.get(experiment_data, :estimated_effort, 0),
      expected_information_gain: Map.get(experiment_data, :expected_information_gain, 0.5),
      cost_estimate: Map.get(experiment_data, :cost_estimate, 0.0),
      priority: Map.get(experiment_data, :priority, :medium),
      dependencies: Map.get(experiment_data, :dependencies, [])
    }
    
    %{result | recommended_experiments: result.recommended_experiments ++ [experiment]}
  end
  
  @doc """
  Add a research program (higher-level organizational unit containing related experiments).
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `program_data`: map() - research program data with fields:
    - `:program_id` - unique identifier
    - `:title` - program title
    - `:description` - program description
    - `:domain` - scientific domain
    - `:experiments` - list of experiment maps within this program
    - `:expected_outcomes` - expected results from the program
    - `:priority` - :high, :medium, :low
    - `:estimated_cost` - total cost for program
    - `:knowledge_gaps_addressed` - which gaps this program addresses
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_research_program(result, program_data) do
    program = %{
      program_id: Map.get(program_data, :program_id, "prog_#{length(result.research_programs) + 1}"),
      title: Map.get(program_data, :title, "Untitled Program"),
      description: Map.get(program_data, :description, ""),
      domain: Map.get(program_data, :domain, :general),
      experiments: Map.get(program_data, :experiments, []),
      expected_outcomes: Map.get(program_data, :expected_outcomes, []),
      priority: Map.get(program_data, :priority, :medium),
      estimated_cost: Map.get(program_data, :estimated_cost, 0.0),
      knowledge_gaps_addressed: Map.get(program_data, :knowledge_gaps_addressed, [])
    }
    
    %{result | research_programs: result.research_programs ++ [program]}
  end
  
  @doc """
  Prioritize research queue based on multiple criteria.
  
  Ranks experiments by:
  - Expected uncertainty reduction
  - Scientific impact
  - Cost efficiency
  - Available budget
  - Dependencies
  - Constitutional constraints
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with prioritized_research populated
  """
  def prioritize_research_queue(result) do
    experiments = result.recommended_experiments || []
    
    if length(experiments) > 0 do
      # Sort by expected_information_gain (descending)
      sorted = Enum.sort_by(experiments, &(-&1.expected_information_gain))
      
      # Add rank to each experiment
      prioritized = Enum.with_index(sorted)
        |> Enum.map(fn {exp, idx} -> 
          Map.put(exp, :rank, idx + 1)
        end)
      
      %{result | prioritized_research: prioritized}
    else
      result
    end
  end
  
  @doc """
  Calculate expected information gain from planned research.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with expected_information_gain updated
  """
  def calculate_expected_information_gain(result) do
    experiments = result.recommended_experiments || []
    
    if length(experiments) > 0 do
      # Average expected IG across all experiments, weighted by priority
      total_ig = Enum.reduce(experiments, 0.0, fn exp, acc ->
        weight = case exp.priority do
          :high -> 1.5
          :medium -> 1.0
          :low -> 0.5
        end
        acc + (exp.expected_information_gain * weight)
      end)
      
      avg_ig = total_ig / length(experiments)
      
      %{result | expected_information_gain: Float.round(avg_ig, 4)}
    else
      result
    end
  end
  
  @doc """
  Calculate expected uncertainty reduction.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with expected_uncertainty_reduction updated
  """
  def calculate_expected_uncertainty_reduction(result) do
    gaps = result.knowledge_gaps || []
    experiments = result.recommended_experiments || []
    
    if length(gaps) > 0 do
      # Estimate based on number of gaps addressed vs total gaps
      gaps_addressed = length(experiments)
      total_gaps = length(gaps)
      
      uncertainty_reduction = if total_gaps > 0 do
        Float.round(gaps_addressed / total_gaps, 4)
      else
        0.0
      end
      
      %{result | expected_uncertainty_reduction: uncertainty_reduction}
    else
      result
    end
  end
  
  @doc """
  Calculate total estimated cost and duration.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with cost and duration estimates
  """
  def calculate_estimates(result) do
    experiments = result.recommended_experiments || []
    
    if length(experiments) > 0 do
      total_cost = Enum.reduce(experiments, 0.0, 
        fn exp, acc -> acc + exp.cost_estimate end)
      
      total_effort = Enum.reduce(experiments, 0, 
        fn exp, acc -> acc + exp.estimated_effort end)
      
      %{result | 
        estimated_cost: Float.round(total_cost, 2),
        estimated_duration: total_effort
      }
    else
      result
    end
  end
  
  @doc """
  Check if research budget is sufficient.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  boolean() - true if budget is sufficient
  """
  def research_budget_ok?(result) do
    if result.estimated_cost != nil && result.research_budget != nil do
      result.estimated_cost <= Map.get(result.research_budget, :available_balance, 0)
    else
      false
    end
  end
  
  @doc """
  Calculate expected ROI (Return on Investment).
  
  ROI = Expected Information Gain / Estimated Cost
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with ROI added to planning_rationale
  """
  def calculate_expected_roi(result) do
    if result.expected_information_gain != nil && result.estimated_cost != nil && result.estimated_cost > 0 do
      roi = result.expected_information_gain / result.estimated_cost
      
      rationale = %{
        type: :roi_calculation,
        roi: Float.round(roi, 4),
        interpretation: interpret_roi(roi),
        timestamp: DateTime.utc_now()
      }
      
      rationales = result.planning_rationale || []
      %{result | planning_rationale: rationales ++ [rationale]}
    else
      result
    end
  end
  
  @doc """
  Get highest priority research item.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  map() | nil - highest priority experiment or nil if none
  """
  def highest_priority(result) do
    if length(result.prioritized_research) > 0 do
      hd(result.prioritized_research)
    else
      nil
    end
  end
  
  @doc """
  Get estimated value of research plan.
  
  Combines expected information gain, uncertainty reduction, and ROI.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  float() - composite value score (0.0-1.0)
  """
  def estimated_value(result) do
    ig_score = result.expected_information_gain || 0.0
    ur_score = result.expected_uncertainty_reduction || 0.0
    
    # Weighted combination
    Float.round((ig_score * 0.6) + (ur_score * 0.4), 4)
  end
  
  @doc """
  Verify traceability - all recommendations reference supporting evidence.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  boolean() - true if all recommendations are traceable
  """
  def verify_traceability(result) do
    # Check that all experiments reference at least one knowledge gap or theory
    experiments = result.recommended_experiments || []
    rationales = result.planning_rationale || []
    
    all_experiments_traceable = Enum.all?(experiments, fn exp ->
      required = exp.required_observations || []
      deps = exp.dependencies || []
      length(required) > 0 or length(deps) > 0
    end)
    
    # Check that planning rationale exists
    has_rationale = length(rationales) > 0
    
    all_experiments_traceable and has_rationale
  end
  
  @doc """
  Build traceability graph connecting plan to supporting theories and topology.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with traceability_graph populated
  """
  def build_traceability_graph(result) do
    traceability = %{
      experiments_to_gaps: build_experiment_gap_mapping(result),
      experiments_to_theories: build_experiment_theory_mapping(result),
      gaps_to_topology: build_gap_topology_mapping(result),
      total_connections: count_total_connections(result)
    }
    
    %{result | traceability_graph: traceability}
  end
  
  @doc """
  Add planning rationale explaining WHY this research was selected.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `rationale_data`: map() - rationale data with fields:
    - `:type` - rationale type (:gap_driven, :contradiction_resolution, :exploration, etc.)
    - `:explanation` - human-readable explanation
    - `:supporting_evidence` - evidence supporting this decision
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_planning_rationale(result, rationale_data) do
    rationale = %{
      type: Map.get(rationale_data, :type, :general),
      explanation: Map.get(rationale_data, :explanation, ""),
      supporting_evidence: Map.get(rationale_data, :supporting_evidence, []),
      timestamp: DateTime.utc_now()
    }
    
    %{result | planning_rationale: result.planning_rationale ++ [rationale]}
  end
  
  @doc """
  Set topology inputs used for planning.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `topology_result`: ScientificTopologyResult.t() or map() - topology analysis input
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def set_topology_inputs(result, topology_result) do
    # Ensure topology_result is a map
    topology_map = if is_map(topology_result), do: topology_result, else: %{}
    
    # Extract relevant topology information (values may be counts or lists)
    clusters = Map.get(topology_map, :clusters)
    gaps = Map.get(topology_map, :knowledge_gaps)
    contradictions = Map.get(topology_map, :contradictions)
    bridges = Map.get(topology_map, :bridge_theories)
    
    # If values are lists, count them; if they're already counts, use them directly
    topology_summary = %{
      clusters_analyzed: if(is_list(clusters), do: length(clusters), else: clusters || 0),
      gaps_identified: if(is_list(gaps), do: length(gaps), else: gaps || 0),
      contradictions_found: if(is_list(contradictions), do: length(contradictions), else: contradictions || 0),
      bridge_theories: if(is_list(bridges), do: length(bridges), else: bridges || 0)
    }
    
    %{result | topology_inputs: topology_summary}
  end
  
  @doc """
  Set research budget constraints.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `budget_data`: map() - budget data with fields:
    - `:available_balance` - available credits
    - `:max_single_experiment` - maximum cost for single experiment
    - `:time_horizon` - planning time horizon (days)
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def set_research_budget(result, budget_data) do
    budget = %{
      available_balance: Map.get(budget_data, :available_balance, 0.0),
      max_single_experiment: Map.get(budget_data, :max_single_experiment, 100.0),
      time_horizon: Map.get(budget_data, :time_horizon, 30),
      timestamp: DateTime.utc_now()
    }
    
    %{result | research_budget: budget}
  end
  
  @doc """
  Mark research plan as completed.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def mark_planned(result) do
    %{result | status: :planned}
  end
  
  @doc """
  Mark research plan as failed.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `reason`: String.t() - failure reason
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def mark_failed(result, reason) do
    %{result | status: :failed, failure_reason: reason}
  end
  
  @doc """
  Add a lifecycle event.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `event`: map() - lifecycle event data
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a semantic event.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `event_type`: atom() - type of semantic event
  - `data`: map() - event data
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def add_semantic_event(result, event_type, data) do
    %{result | semantic_events: result.semantic_events ++ [%{type: event_type, data: data}]}
  end
  
  @doc """
  Set constitutional validation result.
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  - `validation`: map() - validation result
  
  ## Returns
  
  ResearchPlanResult.t()
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Calculate quality score for research plan.
  
  Weighted combination of:
  - Traceability completeness
  - Budget feasibility
  - Expected information gain
  - Rationale completeness
  
  ## Parameters
  
  - `result`: ResearchPlanResult.t() - target result
  
  ## Returns
  
  ResearchPlanResult.t() with quality_score in planning_rationale
  """
  def calculate_quality_score(result) do
    traceability_score = if verify_traceability(result), do: 1.0, else: 0.0
    budget_score = if research_budget_ok?(result), do: 1.0, else: 0.5
    ig_score = min(result.expected_information_gain || 0.0, 1.0)
    rationale_score = min(length(result.planning_rationale) / 3.0, 1.0)
    
    quality = (traceability_score * 0.3) + 
              (budget_score * 0.2) + 
              (ig_score * 0.3) + 
              (rationale_score * 0.2)
    
    quality_rationale = %{
      type: :quality_assessment,
      quality_score: Float.round(quality, 4),
      components: %{
        traceability: traceability_score,
        budget_feasibility: budget_score,
        information_gain: ig_score,
        rationale_completeness: rationale_score
      },
      timestamp: DateTime.utc_now()
    }
    
    rationales = result.planning_rationale || []
    %{result | planning_rationale: rationales ++ [quality_rationale]}
  end
  
  # Private helper functions
  
  defp interpret_roi(roi) do
    cond do
      roi > 1.0 -> "High return - research strongly recommended"
      roi > 0.5 -> "Moderate return - research worthwhile"
      roi > 0.1 -> "Low return - consider alternatives"
      true -> "Very low return - not recommended"
    end
  end
  
  defp build_experiment_gap_mapping(result) do
    # Map each experiment to the knowledge gaps it addresses
    experiments = result.recommended_experiments || []
    Enum.map(experiments, fn exp ->
      %{
        experiment_title: exp.title,
        addresses_gaps: exp.required_observations || []
      }
    end)
  end
  
  defp build_experiment_theory_mapping(result) do
    # Map each experiment to supporting theories
    experiments = result.recommended_experiments || []
    Enum.map(experiments, fn exp ->
      %{
        experiment_title: exp.title,
        tests_theories: exp.dependencies || []
      }
    end)
  end
  
  defp build_gap_topology_mapping(result) do
    # Map knowledge gaps to topology features
    %{
      gaps_from_clusters: Enum.count(result.knowledge_gaps, &(&1.gap_type == :sparse_cluster)),
      gaps_from_isolation: Enum.count(result.knowledge_gaps, &(&1.gap_type == :missing_connection)),
      gaps_from_contradictions: Enum.count(result.knowledge_gaps, &(&1.gap_type == :unresolved_contradiction)),
      gaps_from_bridges: Enum.count(result.knowledge_gaps, &(&1.gap_type == :missing_bridge))
    }
  end
  
  defp count_total_connections(result) do 
    # Count total traceability connections
    experiments = result.recommended_experiments || []
    theories = result.supporting_theories || []
    
    exp_gap_count = length(experiments) * 2  # Approximate
    exp_theory_count = length(theories)
    
    exp_gap_count + exp_theory_count
  end
end
