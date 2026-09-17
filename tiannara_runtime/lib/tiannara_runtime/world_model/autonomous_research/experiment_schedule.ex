defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentSchedule do
  @moduledoc """
  Phase 17.8.1 — ExperimentSchedule: ordered dispatch plan for a portfolio's experiments.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults for domain values.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "sc"
  @id_field :schedule_id

  @valid_dispatch_modes [:sequential, :parallel, :dependent, :adaptive]

  defstruct [
    :schedule_id,
    :portfolio_id,
    :budget_id,
    :dispatch_intents,
    :schedule_algorithm_version,
    :schedule_fingerprint,
    :config_hash
  ]

  @type dispatch_intent :: %{
          intent_id: String.t(),
          experiment_id: String.t(),
          dispatch_mode: :sequential | :parallel | :dependent | :adaptive,
          depends_on_intent_ids: [String.t()],
          stopping_criteria: [map()],
          scenario_id: String.t()
        }

  @type t :: %__MODULE__{
          schedule_id: String.t() | nil,
          portfolio_id: String.t() | nil,
          budget_id: String.t() | nil,
          dispatch_intents: [dispatch_intent()] | nil,
          schedule_algorithm_version: String.t() | nil,
          schedule_fingerprint: String.t() | nil,
          config_hash: String.t() | nil
        }

  @doc """
  Constructs and validates an ExperimentSchedule. All domain values must be
  supplied by the caller.

  Required keys:
  - :portfolio_id (String.t)
  - :budget_id (String.t)
  - :dispatch_intents ([dispatch_intent()])
  - :schedule_algorithm_version (String.t)
  - :schedule_fingerprint (String.t)
  - :config_hash (String.t)

  The :schedule_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    schedule = %__MODULE__{
      portfolio_id: Keyword.get(opts, :portfolio_id),
      budget_id: Keyword.get(opts, :budget_id),
      dispatch_intents: Keyword.get(opts, :dispatch_intents),
      schedule_algorithm_version: Keyword.get(opts, :schedule_algorithm_version),
      schedule_fingerprint: Keyword.get(opts, :schedule_fingerprint),
      config_hash: Keyword.get(opts, :config_hash)
    }

    with :ok <- validate(schedule) do
      id = Canonical.generate_id(schedule, @id_field, @id_prefix)
      {:ok, %{schedule | schedule_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = schedule) do
    Canonical.verify_id(schedule, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{portfolio_id: nil}),
    do: {:error, "ExperimentSchedule: portfolio_id is required"}

  defp validate(%__MODULE__{portfolio_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentSchedule: portfolio_id must be a non-empty string"}

  defp validate(%__MODULE__{budget_id: nil}),
    do: {:error, "ExperimentSchedule: budget_id is required"}

  defp validate(%__MODULE__{budget_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentSchedule: budget_id must be a non-empty string"}

  defp validate(%__MODULE__{dispatch_intents: nil}),
    do: {:error, "ExperimentSchedule: dispatch_intents is required"}

  defp validate(%__MODULE__{dispatch_intents: v}) when not is_list(v),
    do: {:error, "ExperimentSchedule: dispatch_intents must be a list"}

  defp validate(%__MODULE__{dispatch_intents: intents} = s) do
    case validate_intents(intents) do
      :ok -> validate_remaining(s)
      error -> error
    end
  end

  defp validate_remaining(%__MODULE__{schedule_algorithm_version: nil}),
    do: {:error, "ExperimentSchedule: schedule_algorithm_version is required"}

  defp validate_remaining(%__MODULE__{schedule_algorithm_version: v})
       when not is_binary(v) or v == "",
       do: {:error, "ExperimentSchedule: schedule_algorithm_version must be a non-empty string"}

  defp validate_remaining(%__MODULE__{schedule_fingerprint: nil}),
    do: {:error, "ExperimentSchedule: schedule_fingerprint is required"}

  defp validate_remaining(%__MODULE__{schedule_fingerprint: v})
       when not is_binary(v) or v == "",
       do: {:error, "ExperimentSchedule: schedule_fingerprint must be a non-empty string"}

  defp validate_remaining(%__MODULE__{config_hash: nil}),
    do: {:error, "ExperimentSchedule: config_hash is required"}

  defp validate_remaining(%__MODULE__{config_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentSchedule: config_hash must be a non-empty string"}

  defp validate_remaining(%__MODULE__{}), do: :ok

  defp validate_intents([]), do: :ok

  defp validate_intents([intent | rest]) do
    case validate_intent(intent) do
      :ok -> validate_intents(rest)
      error -> error
    end
  end

  defp validate_intent(%{dispatch_mode: mode})
       when mode not in @valid_dispatch_modes,
       do: {:error,
            "ExperimentSchedule: dispatch_mode must be one of #{inspect(@valid_dispatch_modes)}"}

  defp validate_intent(%{experiment_id: id})
       when not is_binary(id) or id == "",
       do: {:error, "ExperimentSchedule: each intent requires a non-empty experiment_id"}

  defp validate_intent(%{scenario_id: sid})
       when not is_binary(sid) or sid == "",
       do: {:error, "ExperimentSchedule: each intent requires a non-empty scenario_id"}

  defp validate_intent(_), do: :ok
end
