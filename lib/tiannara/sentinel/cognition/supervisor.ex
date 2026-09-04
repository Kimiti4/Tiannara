defmodule Tiannara.Sentinel.Cognition.Supervisor do
  use Supervisor

  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.Sentinel.Cognition.ContextEngine, name: :context_engine},
      {Tiannara.Sentinel.Cognition.WorldModel, name: :world_model},
      {Tiannara.Sentinel.Cognition.CausalReasoner, name: :causal_reasoner},
      {Tiannara.Sentinel.Cognition.HypothesisEngine, name: :hypothesis_engine},
      {Tiannara.Sentinel.Cognition.PredictiveEngine, name: :predictive_engine},
      {Tiannara.Sentinel.Cognition.PriorityEngine, name: :priority_engine},
      {Tiannara.Sentinel.Cognition.ExperimentPlanner, name: :experiment_planner},
      {Tiannara.Sentinel.Cognition.ConfidenceEngine, name: :confidence_engine},
      {Tiannara.Sentinel.Cognition.KnowledgeIntegrator, name: :knowledge_integrator}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
