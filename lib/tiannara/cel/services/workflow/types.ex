defmodule Tiannara.CEL.Services.Workflow.Types do
  @moduledoc """
  Types and structs for the scientific workflow engine.

  Represents the canonical scientific method as a structured workflow:
    Observation → Hypothesis → Experiment → Validation → Knowledge Integration

  Constitutional Alignment:
    - "Evidence Before Confidence": Every step generates evidence.
    - "Verification First": Validation gates knowledge integration.
    - "Support reproducibility": Full lineage of every workflow execution.
  """

  @type step_id :: String.t()
  @type workflow_id :: String.t()
  @type step_status :: :pending | :running | :succeeded | :failed | :compensated | :skipped
  @type workflow_status :: :pending | :running | :succeeded | :failed | :compensating | :compensated

  @type step_def :: %{
          id: step_id(),
          type: :observation | :hypothesis | :experiment | :validation | :knowledge_integration | :custom,
          execute: {module(), atom(), list()},
          compensate: {module(), atom(), list()} | nil,
          retry_count: non_neg_integer(),
          retry_delay_ms: pos_integer(),
          timeout_ms: pos_integer(),
          checkpoint: boolean(),
          metadata: map()
        }

  @type workflow_def :: %{
          id: workflow_id(),
          name: String.t(),
          steps: [step_def()],
          metadata: map()
        }

  @type step_result :: %{
          step_id: step_id(),
          status: step_status(),
          started_at: DateTime.t(),
          completed_at: DateTime.t() | nil,
          output: term(),
          error: term() | nil,
          retries: non_neg_integer()
        }

  @type workflow_result :: %{
          workflow_id: workflow_id(),
          status: workflow_status(),
          step_results: [step_result()],
          started_at: DateTime.t(),
          completed_at: DateTime.t() | nil,
          checkpoint: non_neg_integer(),
          error: term() | nil
        }
end
