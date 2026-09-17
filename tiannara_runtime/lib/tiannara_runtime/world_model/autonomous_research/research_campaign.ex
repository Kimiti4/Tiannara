defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ResearchCampaign do
  @moduledoc """
  Phase 17.8.1 — ResearchCampaign: a set of related experiments dispatched together
  as part of a scheduling epoch.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "rc"
  @id_field :campaign_id

  @valid_statuses [:pending, :running, :completed, :failed, :interrupted]

  defstruct [
    :campaign_id,
    :program_id,
    :portfolio_id,
    :schedule_id,
    :experiment_ids,
    :execution_order,
    :status,
    :interruption_record_ids,
    :started_at,
    :completed_at
  ]

  @type t :: %__MODULE__{
          campaign_id: String.t() | nil,
          program_id: String.t() | nil,
          portfolio_id: String.t() | nil,
          schedule_id: String.t() | nil,
          experiment_ids: [String.t()] | nil,
          execution_order: [String.t()] | nil,
          status: atom() | nil,
          interruption_record_ids: [String.t()] | nil,
          started_at: String.t() | nil,
          completed_at: String.t() | nil
        }

  @doc """
  Constructs and validates a ResearchCampaign. All domain values must be supplied.

  Required keys:
  - :program_id (String.t)
  - :portfolio_id (String.t)
  - :schedule_id (String.t)
  - :experiment_ids ([String.t()])
  - :execution_order ([String.t()])
  - :status (atom — one of #{inspect(@valid_statuses)})

  Optional:
  - :interruption_record_ids ([String.t()] | nil)
  - :started_at (String.t | nil)
  - :completed_at (String.t | nil)

  The :campaign_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    campaign = %__MODULE__{
      program_id: Keyword.get(opts, :program_id),
      portfolio_id: Keyword.get(opts, :portfolio_id),
      schedule_id: Keyword.get(opts, :schedule_id),
      experiment_ids: Keyword.get(opts, :experiment_ids),
      execution_order: Keyword.get(opts, :execution_order),
      status: Keyword.get(opts, :status),
      interruption_record_ids: Keyword.get(opts, :interruption_record_ids),
      started_at: Keyword.get(opts, :started_at),
      completed_at: Keyword.get(opts, :completed_at)
    }

    with :ok <- validate(campaign) do
      id = Canonical.generate_id(campaign, @id_field, @id_prefix)
      {:ok, %{campaign | campaign_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = campaign) do
    Canonical.verify_id(campaign, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{program_id: nil}),
    do: {:error, "ResearchCampaign: program_id is required"}

  defp validate(%__MODULE__{program_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchCampaign: program_id must be a non-empty string"}

  defp validate(%__MODULE__{portfolio_id: nil}),
    do: {:error, "ResearchCampaign: portfolio_id is required"}

  defp validate(%__MODULE__{portfolio_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchCampaign: portfolio_id must be a non-empty string"}

  defp validate(%__MODULE__{schedule_id: nil}),
    do: {:error, "ResearchCampaign: schedule_id is required"}

  defp validate(%__MODULE__{schedule_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchCampaign: schedule_id must be a non-empty string"}

  defp validate(%__MODULE__{experiment_ids: nil}),
    do: {:error, "ResearchCampaign: experiment_ids is required"}

  defp validate(%__MODULE__{experiment_ids: v}) when not is_list(v),
    do: {:error, "ResearchCampaign: experiment_ids must be a list"}

  defp validate(%__MODULE__{execution_order: nil}),
    do: {:error, "ResearchCampaign: execution_order is required"}

  defp validate(%__MODULE__{execution_order: v}) when not is_list(v),
    do: {:error, "ResearchCampaign: execution_order must be a list"}

  defp validate(%__MODULE__{status: nil}),
    do: {:error, "ResearchCampaign: status is required"}

  defp validate(%__MODULE__{status: v}) when v not in @valid_statuses,
    do: {:error,
         "ResearchCampaign: status must be one of #{inspect(@valid_statuses)}"}

  defp validate(%__MODULE__{}), do: :ok
end
