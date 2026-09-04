defmodule Tiannara.Sentinel.Cognition.Orchestrator do
  @moduledoc """
  Orchestrates the full cognitive pipeline:

    Event → Context → Causal → Hypothesis → Prediction → Priority → Experiment → Confidence → Report

  Each step calls into the corresponding named GenServer engine.
  The final CognitiveState is returned and the investigation report
  is pushed to the Observatory for human review.
  """
  alias Tiannara.Sentinel.Cognition.State

  def investigate(event) do
    context = Tiannara.Sentinel.Cognition.ContextEngine.reconstruct(:context_engine, event)
    world_model = Tiannara.Sentinel.Cognition.WorldModel.get_state(:world_model)
    causal = Tiannara.Sentinel.Cognition.CausalReasoner.analyze(:causal_reasoner, event, context)
    hypothesis = Tiannara.Sentinel.Cognition.HypothesisEngine.formulate(:hypothesis_engine, event, causal)
    prediction = Tiannara.Sentinel.Cognition.PredictiveEngine.forecast(:predictive_engine, event, context)
    priority = Tiannara.Sentinel.Cognition.PriorityEngine.calculate(:priority_engine, hypothesis, prediction)
    experiment = Tiannara.Sentinel.Cognition.ExperimentPlanner.design(:experiment_planner, hypothesis)
    confidence = Tiannara.Sentinel.Cognition.ConfidenceEngine.evaluate(:confidence_engine, hypothesis)

    state = %State{
      event: event, context: context, world_model: world_model, causal: causal,
      hypothesis: hypothesis, prediction: prediction, priority: priority,
      experiment: experiment, confidence: confidence, uncertainty: confidence.unknowns
    }

    report = Tiannara.Sentinel.Cognition.Interface.generate_report(state)
    Tiannara.Observatory.push_investigation(report)

    state
  end
end
