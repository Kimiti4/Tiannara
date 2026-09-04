defmodule Tiannara.Agency.ResearchDirector do
  @moduledoc """
  Research Director (Omega.2).
  Autonomous scientific investigation engine that answers:
  "What should Tiannara investigate next?"

  Pipeline:
    Agency Event -> Hypothesis Generation -> Ranking -> Experiment Selection ->
    Simulation Coordination -> Evidence Evaluation -> Knowledge Integration

  Does NOT modify runtime directly. Produces knowledge and recommendations.
  """
  use GenServer
  require Logger

  alias Tiannara.Agency.Models.{
    AgencyEvent, Hypothesis, Experiment, ExperimentResult, KnowledgeRecord
  }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: Keyword.get(opts, :name, __MODULE__))

  def investigate(pid, %AgencyEvent{} = event), do: GenServer.call(pid, {:investigate, event}, 60_000)
  def get_active_hypotheses(pid), do: GenServer.call(pid, :active_hypotheses)
  def get_knowledge_log(pid), do: GenServer.call(pid, :knowledge_log)

  @impl true
  def init(_) do
    {:ok, %{
      hypotheses: %{},
      experiments: %{},
      knowledge_log: [],
      investigation_count: 0
    }}
  end

  @impl true
  def handle_call({:investigate, event}, _from, state) do
    Logger.info("[ResearchDirector] Investigating event #{event.id} (#{event.category})")

    hypotheses = generate_hypotheses(event)
    ranked = rank_hypotheses(hypotheses)
    top_hypothesis = List.first(ranked)

    result = if top_hypothesis do
      experiment = select_and_design_experiment(top_hypothesis, event)
      experiment_result = execute_experiment(experiment)
      evaluation = evaluate_evidence(top_hypothesis, experiment_result)
      knowledge = integrate_knowledge(event, top_hypothesis, experiment_result, evaluation)

      updated_hypothesis = %{top_hypothesis |
        status: if(evaluation.recommendation == :accept, do: :validated, else: :refuted),
        confidence: evaluation.new_confidence,
        experiment_id: experiment.id
      }

      %{
        event: event,
        hypotheses: ranked,
        selected: updated_hypothesis,
        experiment: experiment,
        result: experiment_result,
        evaluation: evaluation,
        knowledge: knowledge
      }
    else
      %{event: event, hypotheses: ranked, selected: nil, note: "No testable hypothesis generated"}
    end

    new_state = update_state(state, result)

    Logger.info("[ResearchDirector] Investigation complete. " <>
                "Knowledge integrated: #{length(new_state.knowledge_log)} records total")

    {:reply, {:ok, result}, new_state}
  end

  @impl true
  def handle_call(:active_hypotheses, _from, state) do
    active = state.hypotheses
    |> Map.values()
    |> Enum.filter(& &1.status in [:generated, :ranked, :selected, :testing])
    {:reply, active, state}
  end

  @impl true
  def handle_call(:knowledge_log, _from, state) do
    {:reply, state.knowledge_log, state}
  end

  defp generate_hypotheses(%AgencyEvent{} = event) do
    event.causal_hypotheses
    |> Enum.with_index()
    |> Enum.map(fn {causal, _idx} ->
      %Hypothesis{
        id: UUID.uuid4(),
        timestamp: DateTime.utc_now(),
        event_id: event.id,
        statement: causal,
        prediction: generate_prediction(causal, event),
        required_evidence: ["controlled_comparison", "temporal_correlation", "mechanism_explanation"],
        falsification_criteria: "The hypothesis is falsified if controlled intervention produces no measurable change.",
        status: :generated,
        confidence: 0.5
      }
    end)
    |> case do
      [] ->
        [%Hypothesis{
          id: UUID.uuid4(),
          timestamp: DateTime.utc_now(),
          event_id: event.id,
          statement: "The observed #{event.category} in #{event.source} has a measurable cause",
          prediction: "Intervention on #{event.source} will alter the observed metric",
          required_evidence: ["baseline_comparison", "intervention_response"],
          falsification_criteria: "No measurable response to intervention",
          status: :generated,
          confidence: 0.4
        }]
      list -> list
    end
  end

  defp generate_prediction(causal, _event) do
    "If #{String.downcase(causal)}, then metrics will change measurably under controlled intervention."
  end

  defp rank_hypotheses(hypotheses) do
    hypotheses
    |> Enum.map(fn hyp ->
      breakdown = %{
        impact: 0.8,
        uncertainty_reduction: 1.0 - hyp.confidence,
        feasibility: 0.75,
        strategic_importance: 0.7,
        risk: 0.1
      }

      priority = (breakdown.impact * breakdown.uncertainty_reduction *
                  breakdown.feasibility * breakdown.strategic_importance) - breakdown.risk

      %{hyp |
        priority_score: max(0.0, min(1.0, priority)),
        priority_breakdown: breakdown,
        status: :ranked
      }
    end)
    |> Enum.sort_by(& &1.priority_score, :desc)
  end

  defp select_and_design_experiment(hypothesis, event) do
    experiment_type = cond do
      event.category == :risk and event.severity == :critical -> :simulation
      event.category == :discovery -> :simulation
      String.contains?(hypothesis.statement, "historical") -> :historical
      true -> :simulation
    end

    %Experiment{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      hypothesis_id: hypothesis.id,
      experiment_type: experiment_type,
      design: %{
        type: experiment_type,
        hypothesis: hypothesis.statement,
        methodology: "#{experiment_type} based comparison with controls",
        sample_size: if(experiment_type == :simulation, do: 100, else: 10)
      },
      variables: %{independent: [:intervention], dependent: [event.source]},
      controls: [:baseline_state, :environmental_conditions],
      success_criteria: hypothesis.prediction,
      failure_conditions: [
        "Metric degradation > 20%",
        "System instability detected",
        "Constitutional constraint violation"
      ],
      rollback_plan: "Restore pre-experiment state from snapshot; preserve all observations",
      expected_duration_cycles: 100,
      resource_cost: estimate_cost(experiment_type),
      risk_level: if(experiment_type == :runtime, do: :medium, else: :low),
      requires_human_approval: experiment_type == :runtime,
      status: :designed
    }
  end

  defp estimate_cost(:simulation), do: 10
  defp estimate_cost(:runtime), do: 50
  defp estimate_cost(:historical), do: 5
  defp estimate_cost(:external), do: 100

  defp execute_experiment(%Experiment{} = experiment) do
    raw_results = Tiannara.Agency.Sandbox.run_experiment(experiment)

    %ExperimentResult{
      id: UUID.uuid4(),
      experiment_id: experiment.id,
      timestamp: DateTime.utc_now(),
      success: raw_results.success,
      metrics: raw_results.metrics,
      evidence_items: raw_results.evidence,
      confidence_delta: raw_results.confidence_delta,
      unexpected_findings: raw_results.unexpected,
      recommendation: determine_recommendation(raw_results, experiment)
    }
  end

  defp determine_recommendation(results, _experiment) do
    cond do
      results.success and results.confidence_delta > 0.2 -> :accept
      not results.success -> :reject
      length(results.unexpected) > 0 -> :refine
      true -> :inconclusive
    end
  end

  defp evaluate_evidence(hypothesis, result) do
    evidence_strength = case result.evidence_items do
      [] -> 0.0
      items -> items |> Enum.map(& &1.quality) |> Enum.sum() |> Kernel./(length(items))
    end

    new_confidence = case result.recommendation do
      :accept -> min(1.0, hypothesis.confidence + result.confidence_delta)
      :reject -> max(0.0, hypothesis.confidence - result.confidence_delta)
      :refine -> hypothesis.confidence
      :inconclusive -> hypothesis.confidence * 0.95
    end

    %{
      hypothesis_id: hypothesis.id,
      evidence_strength: evidence_strength,
      new_confidence: Float.round(new_confidence, 3),
      recommendation: result.recommendation,
      contradictions: detect_contradictions(result),
      unknowns_remaining: max(0, 3 - length(result.evidence_items))
    }
  end

  defp detect_contradictions(result) do
    Enum.filter(result.evidence_items, & &1.contradicts_hypothesis)
    |> Enum.map(& &1.id)
  end

  defp integrate_knowledge(event, hypothesis, result, evaluation) do
    level = cond do
      evaluation.new_confidence > 0.9 and result.recommendation == :accept -> :principle
      evaluation.new_confidence > 0.7 -> :pattern
      result.recommendation == :accept -> :knowledge
      result.recommendation == :inconclusive -> :information
      true -> :data
    end

    record = %KnowledgeRecord{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      source_event_id: event.id,
      source_hypothesis_id: hypothesis.id,
      source_experiment_id: result.experiment_id,
      domain: event.source,
      content: "Investigation of #{event.category} in #{event.source}: " <>
               "Hypothesis '#{hypothesis.statement}' was #{result.recommendation} " <>
               "with confidence #{evaluation.new_confidence}. " <>
               "Evidence strength: #{Float.round(evaluation.evidence_strength, 2)}.",
      knowledge_level: level,
      confidence: evaluation.new_confidence,
      supporting_evidence: Enum.map(result.evidence_items, & &1.id),
      contradictions: evaluation.contradictions,
      reuse_count: 0
    }

    Tiannara.RealityGraph.add_node(:knowledge, record)
    Tiannara.Memory.store(:agency_knowledge, record)

    record
  end

  defp update_state(state, result) do
    new_state = %{state | investigation_count: state.investigation_count + 1}

    new_state = case result.selected do
      nil -> new_state
      hyp -> put_in(new_state, [:hypotheses, hyp.id], hyp)
    end

    new_state = case result[:experiment] do
      nil -> new_state
      exp -> put_in(new_state, [:experiments, exp.id], exp)
    end

    case result[:knowledge] do
      nil -> new_state
      k -> %{new_state | knowledge_log: [k | new_state.knowledge_log]}
    end
  end
end
