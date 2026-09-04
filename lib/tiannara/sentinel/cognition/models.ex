defmodule Tiannara.Sentinel.Cognition.State do
  @moduledoc "The complete cognitive state for a specific investigation."
  defstruct [
    :event, :context, :world_model, :causal, :hypothesis,
    :prediction, :priority, :experiment, :confidence, :uncertainty
  ]
end

defmodule Tiannara.Sentinel.Cognition.Hypothesis do
  @moduledoc "Represents a scientific hypothesis formed by Sentinel."
  defstruct [
    :id, :observation, :question, :hypothesis, :prediction,
    evidence: [], contradictions: [], unknown_variables: [],
    confidence: 0.0, experiments: [], status: :forming
  ]
end

defmodule Tiannara.Sentinel.Cognition.Experiment do
  @moduledoc "Structured experiment proposal requiring human validation."
  defstruct [
    :id, :hypothesis_id, :observation, :research_question,
    :hypothesis, :independent_variables, :dependent_variables,
    :controls, :expected_outcome, :failure_conditions,
    :validation_metrics, :rollback_plan
  ]
end

defmodule Tiannara.Sentinel.Cognition.WorldModelData do
  @moduledoc "Internal model of Tiannara's state, dependencies, and risks."
  defstruct [
    :subsystems, :dependencies, :agents, :processes,
    failure_probabilities: %{}, bottlenecks: [], last_updated: nil
  ]
end
