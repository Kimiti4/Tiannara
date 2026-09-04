defmodule Tiannara.CEL.Workflow.Step do
  @moduledoc """
  Workflow Step — the saga participant contract.

  Every step must implement:
    - execute/2: perform the step, returning {:ok, result} or {:error, reason}
    - compensate/3: undo the step's effects (saga rollback)
    - validate_input/1: verify input before execution
    - required_capability/0: declare what capability this step needs

  Steps are declarative and serializable, enabling persistence and replay.

  Constitutional Alignment (rules.md):
    - "Recover gracefully": compensate/3 preserves stable state on failure.
    - "Support reproducibility": steps are deterministic given the same input.
    - "Maintain audit trails": every execution is recorded with full context.
  """

  @type step_id :: String.t()
  @type step_result :: %{
          output: map(),
          evidence: [map()],
          duration_ms: non_neg_integer(),
          resource_usage: map(),
          confidence: float(),
          quality_metrics: map()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          type: atom(),
          module: module(),
          input: map(),
          config: map(),
          retry_count: non_neg_integer(),
          retry_delay_ms: pos_integer(),
          timeout_ms: pos_integer()
        }

  defstruct [:id, :type, :module, input: %{}, config: %{}, retry_count: 3, retry_delay_ms: 1_000, timeout_ms: 30_000]

  @doc "Returns the unique identifier for this step type."
  @callback step_type() :: atom()

  @doc "Returns the capability required to execute this step."
  @callback required_capability() :: atom()

  @doc "Validates the step's input. Returns :ok or {:error, reason}."
  @callback validate_input(input :: map()) :: :ok | {:error, term()}

  @doc """
  Executes the step. Returns {:ok, step_result} or {:error, reason}.

  The step_result must include:
    - :output — the step's output data
    - :evidence — evidence gathered during execution
    - :duration_ms — how long execution took
    - :resource_usage — resources consumed
    - :confidence — confidence in the result (0.0 to 1.0)
    - :quality_metrics — domain-specific quality measures
  """
  @callback execute(input :: map(), context :: map()) ::
              {:ok, step_result()} | {:error, term()}

  @doc """
  Compensates for a previously executed step (saga rollback).
  Called when a later step fails and the workflow must recover.
  """
  @callback compensate(input :: map(), result :: step_result(), context :: map()) ::
              :ok | {:error, term()}

  @doc "Returns metadata about the step for observability."
  @callback metadata() :: map()
end
