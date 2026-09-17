defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentBudget do
  @moduledoc """
  Phase 17.8.1 — ExperimentBudget: resource allocation for experiments.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults for domain values.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "bd"
  @id_field :budget_id

  defstruct [
    :budget_id,
    :portfolio_id,
    :total_compute_units,
    :total_evidence_units,
    :per_program_allocations,
    :allocation_algorithm_version,
    :allocation_proof_hash,
    :config_hash
  ]

  @type per_program_allocation :: %{
          program_id: String.t(),
          compute_units: non_neg_integer(),
          evidence_units: non_neg_integer(),
          max_experiments: non_neg_integer(),
          priority_rank: non_neg_integer()
        }

  @type t :: %__MODULE__{
          budget_id: String.t() | nil,
          portfolio_id: String.t() | nil,
          total_compute_units: non_neg_integer() | nil,
          total_evidence_units: non_neg_integer() | nil,
          per_program_allocations: [per_program_allocation()] | nil,
          allocation_algorithm_version: String.t() | nil,
          allocation_proof_hash: String.t() | nil,
          config_hash: String.t() | nil
        }

  @doc """
  Constructs and validates an ExperimentBudget. All domain values must be
  supplied by the caller — no defaults are applied.

  Required keys:
  - :portfolio_id (String.t)
  - :total_compute_units (non_neg_integer)
  - :total_evidence_units (non_neg_integer)
  - :per_program_allocations ([per_program_allocation()])
  - :allocation_algorithm_version (String.t)
  - :allocation_proof_hash (String.t)
  - :config_hash (String.t)

  The :budget_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    budget = %__MODULE__{
      portfolio_id: Keyword.get(opts, :portfolio_id),
      total_compute_units: Keyword.get(opts, :total_compute_units),
      total_evidence_units: Keyword.get(opts, :total_evidence_units),
      per_program_allocations: Keyword.get(opts, :per_program_allocations),
      allocation_algorithm_version: Keyword.get(opts, :allocation_algorithm_version),
      allocation_proof_hash: Keyword.get(opts, :allocation_proof_hash),
      config_hash: Keyword.get(opts, :config_hash)
    }

    with :ok <- validate(budget) do
      id = Canonical.generate_id(budget, @id_field, @id_prefix)
      {:ok, %{budget | budget_id: id}}
    end
  end

  @doc """
  Verifies the content-addressed ID on an existing struct.
  Returns :ok if the ID matches the current field values.
  """
  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = budget) do
    Canonical.verify_id(budget, @id_field, @id_prefix)
  end

  # Validation — no domain constraints carry hardcoded thresholds.
  # Shape and presence constraints only.

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{portfolio_id: nil}),
    do: {:error, "ExperimentBudget: portfolio_id is required"}

  defp validate(%__MODULE__{portfolio_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentBudget: portfolio_id must be a non-empty string"}

  defp validate(%__MODULE__{total_compute_units: nil}),
    do: {:error, "ExperimentBudget: total_compute_units is required"}

  defp validate(%__MODULE__{total_compute_units: v}) when not is_integer(v) or v < 0,
    do: {:error, "ExperimentBudget: total_compute_units must be a non-negative integer"}

  defp validate(%__MODULE__{total_evidence_units: nil}),
    do: {:error, "ExperimentBudget: total_evidence_units is required"}

  defp validate(%__MODULE__{total_evidence_units: v}) when not is_integer(v) or v < 0,
    do: {:error, "ExperimentBudget: total_evidence_units must be a non-negative integer"}

  defp validate(%__MODULE__{per_program_allocations: nil}),
    do: {:error, "ExperimentBudget: per_program_allocations is required"}

  defp validate(%__MODULE__{per_program_allocations: v}) when not is_list(v),
    do: {:error, "ExperimentBudget: per_program_allocations must be a list"}

  defp validate(%__MODULE__{allocation_algorithm_version: nil}),
    do: {:error, "ExperimentBudget: allocation_algorithm_version is required"}

  defp validate(%__MODULE__{allocation_algorithm_version: v})
       when not is_binary(v) or v == "",
       do: {:error, "ExperimentBudget: allocation_algorithm_version must be a non-empty string"}

  defp validate(%__MODULE__{allocation_proof_hash: nil}),
    do: {:error, "ExperimentBudget: allocation_proof_hash is required"}

  defp validate(%__MODULE__{allocation_proof_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentBudget: allocation_proof_hash must be a non-empty string"}

  defp validate(%__MODULE__{config_hash: nil}),
    do: {:error, "ExperimentBudget: config_hash is required"}

  defp validate(%__MODULE__{config_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentBudget: config_hash must be a non-empty string"}

  defp validate(%__MODULE__{}), do: :ok
end
