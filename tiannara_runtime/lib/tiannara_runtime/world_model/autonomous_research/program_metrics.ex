defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ProgramMetrics do
  @moduledoc """
  Phase 17.8.1 — ProgramMetrics: observable metrics tracking program health.

  These are read-only diagnostic metrics produced by the ARPEProgramEngine.
  They are not used in certification decisions — they inform archaeology and
  long-horizon validation only.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; new metric snapshots produce new artifacts.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "pm"
  @id_field :metrics_id

  defstruct [
    :metrics_id,
    :program_id,
    :snapshot_at_tick,
    :experiments_completed,
    :experiments_pending,
    :experiments_failed,
    :evidence_bundles_collected,
    :validations_passed,
    :validations_failed,
    :theory_proposals_generated,
    :knowledge_gaps_resolved,
    :compute_units_consumed,
    :evidence_units_consumed
  ]

  @type t :: %__MODULE__{
          metrics_id: String.t() | nil,
          program_id: String.t() | nil,
          snapshot_at_tick: non_neg_integer() | nil,
          experiments_completed: non_neg_integer() | nil,
          experiments_pending: non_neg_integer() | nil,
          experiments_failed: non_neg_integer() | nil,
          evidence_bundles_collected: non_neg_integer() | nil,
          validations_passed: non_neg_integer() | nil,
          validations_failed: non_neg_integer() | nil,
          theory_proposals_generated: non_neg_integer() | nil,
          knowledge_gaps_resolved: non_neg_integer() | nil,
          compute_units_consumed: non_neg_integer() | nil,
          evidence_units_consumed: non_neg_integer() | nil
        }

  @doc """
  Constructs and validates a ProgramMetrics snapshot. All values must be supplied
  by the caller.

  Required keys:
  - :program_id (String.t)
  - :snapshot_at_tick (non_neg_integer)
  - All counter fields (non_neg_integer — must be supplied, not defaulted)

  The :metrics_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    metrics = %__MODULE__{
      program_id: Keyword.get(opts, :program_id),
      snapshot_at_tick: Keyword.get(opts, :snapshot_at_tick),
      experiments_completed: Keyword.get(opts, :experiments_completed),
      experiments_pending: Keyword.get(opts, :experiments_pending),
      experiments_failed: Keyword.get(opts, :experiments_failed),
      evidence_bundles_collected: Keyword.get(opts, :evidence_bundles_collected),
      validations_passed: Keyword.get(opts, :validations_passed),
      validations_failed: Keyword.get(opts, :validations_failed),
      theory_proposals_generated: Keyword.get(opts, :theory_proposals_generated),
      knowledge_gaps_resolved: Keyword.get(opts, :knowledge_gaps_resolved),
      compute_units_consumed: Keyword.get(opts, :compute_units_consumed),
      evidence_units_consumed: Keyword.get(opts, :evidence_units_consumed)
    }

    with :ok <- validate(metrics) do
      id = Canonical.generate_id(metrics, @id_field, @id_prefix)
      {:ok, %{metrics | metrics_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = metrics) do
    Canonical.verify_id(metrics, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{program_id: nil}),
    do: {:error, "ProgramMetrics: program_id is required"}

  defp validate(%__MODULE__{program_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ProgramMetrics: program_id must be a non-empty string"}

  defp validate(%__MODULE__{snapshot_at_tick: nil}),
    do: {:error, "ProgramMetrics: snapshot_at_tick is required"}

  defp validate(%__MODULE__{snapshot_at_tick: v}) when not is_integer(v) or v < 0,
    do: {:error, "ProgramMetrics: snapshot_at_tick must be a non-negative integer"}

  for field <- [
        :experiments_completed,
        :experiments_pending,
        :experiments_failed,
        :evidence_bundles_collected,
        :validations_passed,
        :validations_failed,
        :theory_proposals_generated,
        :knowledge_gaps_resolved,
        :compute_units_consumed,
        :evidence_units_consumed
      ] do
    defp validate(%__MODULE__{unquote(field) => nil}),
      do: {:error, "ProgramMetrics: #{unquote(field)} is required"}

    defp validate(%__MODULE__{unquote(field) => v}) when not is_integer(v) or v < 0,
      do: {:error,
           "ProgramMetrics: #{unquote(field)} must be a non-negative integer"}
  end

  defp validate(%__MODULE__{}), do: :ok
end
