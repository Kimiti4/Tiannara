defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ResearchOutcome do
  @moduledoc """
  Phase 17.8.1 — ResearchOutcome: final disposition of a completed research program.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults for domain values.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  - disposition and termination_reason must be explicit — no inferred states.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "rout"
  @id_field :outcome_id

  @valid_dispositions [
    :completed,
    :terminated,
    :superseded,
    :archived,
    :provisional_archive
  ]

  @valid_termination_reasons [
    :success,
    :budget_exhausted,
    :stopping_criterion_met,
    :contradiction_detected,
    :constitutional_violation,
    :mathematical_unverified
  ]

  defstruct [
    :outcome_id,
    :program_id,
    :disposition,
    :termination_reason,
    :completed_experiment_ids,
    :evidence_bundle_ids,
    :validation_ids,
    :theory_proposal_ids,
    :replay_fingerprint_id,
    :certificate_id,
    :archaeology_record_id,
    :total_compute_units_consumed,
    :total_evidence_units_consumed
  ]

  @type t :: %__MODULE__{
          outcome_id: String.t() | nil,
          program_id: String.t() | nil,
          disposition: atom() | nil,
          termination_reason: atom() | nil,
          completed_experiment_ids: [String.t()] | nil,
          evidence_bundle_ids: [String.t()] | nil,
          validation_ids: [String.t()] | nil,
          theory_proposal_ids: [String.t()] | nil,
          replay_fingerprint_id: String.t() | nil,
          certificate_id: String.t() | nil,
          archaeology_record_id: String.t() | nil,
          total_compute_units_consumed: non_neg_integer() | nil,
          total_evidence_units_consumed: non_neg_integer() | nil
        }

  @doc """
  Constructs and validates a ResearchOutcome. All domain values must be supplied.

  Required keys:
  - :program_id (String.t)
  - :disposition (atom — one of #{inspect(@valid_dispositions)})
  - :termination_reason (atom — one of #{inspect(@valid_termination_reasons)})
  - :completed_experiment_ids ([String.t()])
  - :evidence_bundle_ids ([String.t()])
  - :validation_ids ([String.t()])
  - :theory_proposal_ids ([String.t()])
  - :replay_fingerprint_id (String.t)
  - :archaeology_record_id (String.t)
  - :total_compute_units_consumed (non_neg_integer)
  - :total_evidence_units_consumed (non_neg_integer)

  Optional:
  - :certificate_id (String.t | nil — nil when not yet certified)

  The :outcome_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    outcome = %__MODULE__{
      program_id: Keyword.get(opts, :program_id),
      disposition: Keyword.get(opts, :disposition),
      termination_reason: Keyword.get(opts, :termination_reason),
      completed_experiment_ids: Keyword.get(opts, :completed_experiment_ids),
      evidence_bundle_ids: Keyword.get(opts, :evidence_bundle_ids),
      validation_ids: Keyword.get(opts, :validation_ids),
      theory_proposal_ids: Keyword.get(opts, :theory_proposal_ids),
      replay_fingerprint_id: Keyword.get(opts, :replay_fingerprint_id),
      certificate_id: Keyword.get(opts, :certificate_id),
      archaeology_record_id: Keyword.get(opts, :archaeology_record_id),
      total_compute_units_consumed: Keyword.get(opts, :total_compute_units_consumed),
      total_evidence_units_consumed: Keyword.get(opts, :total_evidence_units_consumed)
    }

    with :ok <- validate(outcome) do
      id = Canonical.generate_id(outcome, @id_field, @id_prefix)
      {:ok, %{outcome | outcome_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = outcome) do
    Canonical.verify_id(outcome, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{program_id: nil}),
    do: {:error, "ResearchOutcome: program_id is required"}

  defp validate(%__MODULE__{program_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchOutcome: program_id must be a non-empty string"}

  defp validate(%__MODULE__{disposition: nil}),
    do: {:error, "ResearchOutcome: disposition is required"}

  defp validate(%__MODULE__{disposition: v}) when v not in @valid_dispositions,
    do: {:error,
         "ResearchOutcome: disposition must be one of #{inspect(@valid_dispositions)}"}

  defp validate(%__MODULE__{termination_reason: nil}),
    do: {:error, "ResearchOutcome: termination_reason is required"}

  defp validate(%__MODULE__{termination_reason: v})
       when v not in @valid_termination_reasons,
       do: {:error,
            "ResearchOutcome: termination_reason must be one of " <>
              "#{inspect(@valid_termination_reasons)}"}

  defp validate(%__MODULE__{completed_experiment_ids: nil}),
    do: {:error, "ResearchOutcome: completed_experiment_ids is required"}

  defp validate(%__MODULE__{completed_experiment_ids: v}) when not is_list(v),
    do: {:error, "ResearchOutcome: completed_experiment_ids must be a list"}

  defp validate(%__MODULE__{evidence_bundle_ids: nil}),
    do: {:error, "ResearchOutcome: evidence_bundle_ids is required"}

  defp validate(%__MODULE__{evidence_bundle_ids: v}) when not is_list(v),
    do: {:error, "ResearchOutcome: evidence_bundle_ids must be a list"}

  defp validate(%__MODULE__{validation_ids: nil}),
    do: {:error, "ResearchOutcome: validation_ids is required"}

  defp validate(%__MODULE__{validation_ids: v}) when not is_list(v),
    do: {:error, "ResearchOutcome: validation_ids must be a list"}

  defp validate(%__MODULE__{theory_proposal_ids: nil}),
    do: {:error, "ResearchOutcome: theory_proposal_ids is required"}

  defp validate(%__MODULE__{theory_proposal_ids: v}) when not is_list(v),
    do: {:error, "ResearchOutcome: theory_proposal_ids must be a list"}

  defp validate(%__MODULE__{replay_fingerprint_id: nil}),
    do: {:error, "ResearchOutcome: replay_fingerprint_id is required"}

  defp validate(%__MODULE__{replay_fingerprint_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchOutcome: replay_fingerprint_id must be a non-empty string"}

  defp validate(%__MODULE__{archaeology_record_id: nil}),
    do: {:error, "ResearchOutcome: archaeology_record_id is required"}

  defp validate(%__MODULE__{archaeology_record_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchOutcome: archaeology_record_id must be a non-empty string"}

  defp validate(%__MODULE__{total_compute_units_consumed: nil}),
    do: {:error, "ResearchOutcome: total_compute_units_consumed is required"}

  defp validate(%__MODULE__{total_compute_units_consumed: v})
       when not is_integer(v) or v < 0,
       do: {:error, "ResearchOutcome: total_compute_units_consumed must be a non-negative integer"}

  defp validate(%__MODULE__{total_evidence_units_consumed: nil}),
    do: {:error, "ResearchOutcome: total_evidence_units_consumed is required"}

  defp validate(%__MODULE__{total_evidence_units_consumed: v})
       when not is_integer(v) or v < 0,
       do: {:error, "ResearchOutcome: total_evidence_units_consumed must be a non-negative integer"}

  defp validate(%__MODULE__{}), do: :ok
end
