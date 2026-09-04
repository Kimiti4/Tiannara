defmodule Tiannara.CEL.Workflow.StepResult do
  @moduledoc """
  Step Result — the canonical output of a workflow step execution.

  Contains not just the output but the full reasoning chain:
    - Evidence gathered
    - Resource usage
    - Confidence level
    - Quality metrics (for scientific steps)
    - Duration

  This rich output becomes the training data for the Adaptive PriorityEngine
  and the evidence base for the Executive Digital Twin.

  Constitutional Alignment (rules.md):
    - "Uncertainty should never be hidden": confidence is mandatory.
    - "Evidence Before Confidence": evidence list is mandatory.
    - "Memory Philosophy": results evolve into knowledge, patterns, principles.
  """

  defstruct [
    :step_id,
    :step_type,
    :output,
    :evidence,
    :duration_ms,
    :resource_usage,
    :confidence,
    :quality_metrics,
    :status,
    :error,
    :retries,
    :executed_at,
    :started_at,
    :completed_at
  ]

  @type t :: %__MODULE__{
          step_id: String.t(),
          step_type: atom(),
          output: map(),
          evidence: [map()],
          duration_ms: non_neg_integer(),
          resource_usage: map(),
          confidence: float(),
          quality_metrics: map(),
          status: :pending | :running | :succeeded | :failed | :skipped,
          error: term() | nil,
          retries: non_neg_integer(),
          executed_at: DateTime.t() | nil,
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil
        }

  def new(step_id, step_type, output, opts \\ []) do
    now = DateTime.utc_now()
    %__MODULE__{
      step_id: step_id,
      step_type: step_type,
      output: output,
      evidence: Keyword.get(opts, :evidence, []),
      duration_ms: Keyword.get(opts, :duration_ms, 0),
      resource_usage: Keyword.get(opts, :resource_usage, %{}),
      confidence: Keyword.get(opts, :confidence, 0.5),
      quality_metrics: Keyword.get(opts, :quality_metrics, %{}),
      status: Keyword.get(opts, :status, :succeeded),
      error: Keyword.get(opts, :error),
      retries: Keyword.get(opts, :retries, 0),
      executed_at: now,
      started_at: Keyword.get(opts, :started_at, now),
      completed_at: now
    }
  end

  def succeeded(step_id, step_type, output, opts \\ []) do
    new(step_id, step_type, output, Keyword.merge(opts, status: :succeeded))
  end

  def failed(step_id, step_type, error, opts \\ []) do
    now = DateTime.utc_now()
    %__MODULE__{
      step_id: step_id,
      step_type: step_type,
      output: nil,
      evidence: [],
      duration_ms: Keyword.get(opts, :duration_ms, 0),
      resource_usage: Keyword.get(opts, :resource_usage, %{}),
      confidence: 0.0,
      quality_metrics: %{},
      status: :failed,
      error: error,
      retries: Keyword.get(opts, :retries, 0),
      executed_at: now,
      started_at: Keyword.get(opts, :started_at, now),
      completed_at: now
    }
  end
end
