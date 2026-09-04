defmodule Tiannara.Discovery.Domain do
  defmodule KnowledgeGap do
    defstruct [:id, :domain, :description, :severity, :uncertainty, :affected_domains,
      :estimated_impact, :recommended_investigation, :source, :detected_at, :evidence,
      :unified_world_model_event_id]
    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{id: "gap_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        detected_at: DateTime.utc_now(), evidence: [], affected_domains: [],
        uncertainty: 0.5, estimated_impact: 0.5} |> struct(attrs)
    end
  end

  defmodule HypothesisSpec do
    defstruct [:id, :gap_id, :description, :statement, :domain, :prior, :confidence,
      :evidence, :predictions, :falsifiable, :status, :expected_information_gain,
      :risk, :metadata]
    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{id: "hyp_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        prior: 0.5, confidence: 0.0, evidence: [], predictions: [],
        falsifiable: true, status: :proposed, expected_information_gain: 0.5, risk: 0.0, metadata: %{}}
      |> struct(attrs)
    end
  end

  defmodule PredictionSpec do
    defstruct [:id, :hypothesis_id, :description, :statement, :measurable_outcome,
      :expected_outcome, :threshold, :failure_conditions, :falsification_criteria,
      :status, :falsifiable, :confidence, :uncertainty, :created_at]
    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{id: "pred_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        measurable_outcome: true, threshold: 0.05, failure_conditions: [],
        status: :proposed, falsifiable: true, confidence: 0.5, uncertainty: 0.5,
        created_at: DateTime.utc_now()}
      |> struct(attrs)
    end
  end

  defmodule ExperimentPlan do
    defstruct [:id, :hypothesis_id, :prediction_ids, :type, :inputs, :outputs,
      :variables, :controls, :stopping_criteria, :success_criteria, :failure_criteria,
      :estimated_cost, :expected_information_gain, :created_at]
    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{id: "exp_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        prediction_ids: [], inputs: %{}, outputs: [], variables: [], controls: [],
        estimated_cost: %{}, expected_information_gain: 0.5, created_at: DateTime.utc_now()}
      |> struct(attrs)
    end
  end

  defmodule DiscoveryResult do
    defstruct [:id, :experiment_id, :hypothesis_id, :outcome, :evidence,
      :confidence_delta, :posterior, :completed_at]
    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{id: "result_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        evidence: [], confidence_delta: 0.0, completed_at: DateTime.utc_now()} |> struct(attrs)
    end
  end
end
