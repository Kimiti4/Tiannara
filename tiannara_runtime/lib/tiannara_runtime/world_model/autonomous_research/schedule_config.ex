defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ScheduleConfig do
  @moduledoc """
  Phase 17.8.5 — ScheduleConfig: the epoch-frozen configuration artifact
  that governs experiment scheduling in the ARPEScheduler.

  Constitutional rules:
  - All scheduling constraints come from this config — never hardcoded.
  - If absent, ARPEScheduler fails closed.
  - content-addressed ID via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "schcfg"
  @id_field :config_id

  defstruct [
    :config_id,
    :epoch_id,
    :schema_version,
    # Maximum number of campaigns dispatched concurrently
    :max_parallel_campaigns,
    # Maximum total compute units that may be in-flight simultaneously
    :max_inflight_compute_units,
    # Whether adaptive rescheduling is enabled
    :adaptive_scheduling_enabled,
    # Scheduling algorithm version label (frozen string)
    :scheduling_algorithm_version
  ]

  @type t :: %__MODULE__{
          config_id: String.t() | nil,
          epoch_id: String.t() | nil,
          schema_version: String.t() | nil,
          max_parallel_campaigns: pos_integer() | nil,
          max_inflight_compute_units: pos_integer() | nil,
          adaptive_scheduling_enabled: boolean() | nil,
          scheduling_algorithm_version: String.t() | nil
        }

  @doc """
  Constructs and validates a ScheduleConfig. All values must be supplied.

  Required keys:
  - :epoch_id (String.t)
  - :schema_version (String.t)
  - :max_parallel_campaigns (pos_integer)
  - :max_inflight_compute_units (pos_integer)
  - :adaptive_scheduling_enabled (boolean)
  - :scheduling_algorithm_version (String.t)

  The :config_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    config = %__MODULE__{
      epoch_id: Keyword.get(opts, :epoch_id),
      schema_version: Keyword.get(opts, :schema_version),
      max_parallel_campaigns: Keyword.get(opts, :max_parallel_campaigns),
      max_inflight_compute_units: Keyword.get(opts, :max_inflight_compute_units),
      adaptive_scheduling_enabled: Keyword.get(opts, :adaptive_scheduling_enabled),
      scheduling_algorithm_version: Keyword.get(opts, :scheduling_algorithm_version)
    }

    with :ok <- validate(config) do
      id = Canonical.generate_id(config, @id_field, @id_prefix)
      {:ok, %{config | config_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = config) do
    Canonical.verify_id(config, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "ScheduleConfig: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ScheduleConfig: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "ScheduleConfig: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "ScheduleConfig: schema_version must be a non-empty string"}

  defp validate(%__MODULE__{max_parallel_campaigns: nil}),
    do: {:error, "ScheduleConfig: max_parallel_campaigns is required"}

  defp validate(%__MODULE__{max_parallel_campaigns: v}) when not is_integer(v) or v < 1,
    do: {:error, "ScheduleConfig: max_parallel_campaigns must be a positive integer"}

  defp validate(%__MODULE__{max_inflight_compute_units: nil}),
    do: {:error, "ScheduleConfig: max_inflight_compute_units is required"}

  defp validate(%__MODULE__{max_inflight_compute_units: v}) when not is_integer(v) or v < 1,
    do: {:error, "ScheduleConfig: max_inflight_compute_units must be a positive integer"}

  defp validate(%__MODULE__{adaptive_scheduling_enabled: nil}),
    do: {:error, "ScheduleConfig: adaptive_scheduling_enabled is required"}

  defp validate(%__MODULE__{adaptive_scheduling_enabled: v}) when not is_boolean(v),
    do: {:error, "ScheduleConfig: adaptive_scheduling_enabled must be a boolean"}

  defp validate(%__MODULE__{scheduling_algorithm_version: nil}),
    do: {:error, "ScheduleConfig: scheduling_algorithm_version is required"}

  defp validate(%__MODULE__{scheduling_algorithm_version: v})
       when not is_binary(v) or v == "",
       do: {:error, "ScheduleConfig: scheduling_algorithm_version must be a non-empty string"}

  defp validate(%__MODULE__{}), do: :ok
end
