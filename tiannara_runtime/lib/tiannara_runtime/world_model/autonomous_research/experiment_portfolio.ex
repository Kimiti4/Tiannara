defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentPortfolio do
  @moduledoc """
  Phase 17.8.1 — ExperimentPortfolio: selected set of programs and experiments
  for a scheduling epoch.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults for domain values.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "pf"
  @id_field :portfolio_id

  defstruct [
    :portfolio_id,
    :epoch_id,
    :config_hash,
    :selected_program_ids,
    :selected_experiment_ids,
    :diversity_score,
    :expected_total_information_gain,
    :optimization_proof_hash,
    :budget_allocation_id,
    :selection_rationale_hash
  ]

  @type t :: %__MODULE__{
          portfolio_id: String.t() | nil,
          epoch_id: String.t() | nil,
          config_hash: String.t() | nil,
          selected_program_ids: [String.t()] | nil,
          selected_experiment_ids: [String.t()] | nil,
          diversity_score: float() | nil,
          expected_total_information_gain: float() | nil,
          optimization_proof_hash: String.t() | nil,
          budget_allocation_id: String.t() | nil,
          selection_rationale_hash: String.t() | nil
        }

  @doc """
  Constructs and validates an ExperimentPortfolio. All domain values must be
  supplied by the caller.

  Required keys:
  - :epoch_id (String.t)
  - :config_hash (String.t)
  - :selected_program_ids ([String.t()])
  - :selected_experiment_ids ([String.t()])
  - :diversity_score (float, >= 0.0)
  - :expected_total_information_gain (float, >= 0.0)
  - :optimization_proof_hash (String.t)
  - :budget_allocation_id (String.t)
  - :selection_rationale_hash (String.t)

  The :portfolio_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    portfolio = %__MODULE__{
      epoch_id: Keyword.get(opts, :epoch_id),
      config_hash: Keyword.get(opts, :config_hash),
      selected_program_ids: Keyword.get(opts, :selected_program_ids),
      selected_experiment_ids: Keyword.get(opts, :selected_experiment_ids),
      diversity_score: Keyword.get(opts, :diversity_score),
      expected_total_information_gain: Keyword.get(opts, :expected_total_information_gain),
      optimization_proof_hash: Keyword.get(opts, :optimization_proof_hash),
      budget_allocation_id: Keyword.get(opts, :budget_allocation_id),
      selection_rationale_hash: Keyword.get(opts, :selection_rationale_hash)
    }

    with :ok <- validate(portfolio) do
      id = Canonical.generate_id(portfolio, @id_field, @id_prefix)
      {:ok, %{portfolio | portfolio_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = portfolio) do
    Canonical.verify_id(portfolio, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "ExperimentPortfolio: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentPortfolio: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{config_hash: nil}),
    do: {:error, "ExperimentPortfolio: config_hash is required"}

  defp validate(%__MODULE__{config_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentPortfolio: config_hash must be a non-empty string"}

  defp validate(%__MODULE__{selected_program_ids: nil}),
    do: {:error, "ExperimentPortfolio: selected_program_ids is required"}

  defp validate(%__MODULE__{selected_program_ids: v}) when not is_list(v),
    do: {:error, "ExperimentPortfolio: selected_program_ids must be a list"}

  defp validate(%__MODULE__{selected_experiment_ids: nil}),
    do: {:error, "ExperimentPortfolio: selected_experiment_ids is required"}

  defp validate(%__MODULE__{selected_experiment_ids: v}) when not is_list(v),
    do: {:error, "ExperimentPortfolio: selected_experiment_ids must be a list"}

  defp validate(%__MODULE__{diversity_score: nil}),
    do: {:error, "ExperimentPortfolio: diversity_score is required"}

  defp validate(%__MODULE__{diversity_score: v}) when not is_float(v) or v < 0.0,
    do: {:error, "ExperimentPortfolio: diversity_score must be a non-negative float"}

  defp validate(%__MODULE__{expected_total_information_gain: nil}),
    do: {:error, "ExperimentPortfolio: expected_total_information_gain is required"}

  defp validate(%__MODULE__{expected_total_information_gain: v})
       when not is_float(v) or v < 0.0,
       do: {:error,
            "ExperimentPortfolio: expected_total_information_gain must be a non-negative float"}

  defp validate(%__MODULE__{optimization_proof_hash: nil}),
    do: {:error, "ExperimentPortfolio: optimization_proof_hash is required"}

  defp validate(%__MODULE__{optimization_proof_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentPortfolio: optimization_proof_hash must be a non-empty string"}

  defp validate(%__MODULE__{budget_allocation_id: nil}),
    do: {:error, "ExperimentPortfolio: budget_allocation_id is required"}

  defp validate(%__MODULE__{budget_allocation_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentPortfolio: budget_allocation_id must be a non-empty string"}

  defp validate(%__MODULE__{selection_rationale_hash: nil}),
    do: {:error, "ExperimentPortfolio: selection_rationale_hash is required"}

  defp validate(%__MODULE__{selection_rationale_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentPortfolio: selection_rationale_hash must be a non-empty string"}

  defp validate(%__MODULE__{}), do: :ok
end
