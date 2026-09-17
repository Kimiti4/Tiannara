defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ResearchEvidence do
  @moduledoc """
  Phase 17.8.1 — ResearchEvidence: normalized evidence bundle produced from
  a Digital Twin SimulationOutcome.

  Extends Phase 16.1 ResearchEvidence schema with phase_17_8_ext provenance fields.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults for domain values.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  - Evidence mapping ambiguity must produce an explicit EvidenceMappingFailure,
    not a partial bundle.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "re"
  @id_field :evidence_bundle_id

  @valid_evidence_types [:raw, :normalized]

  defstruct [
    # Phase 16.1 fields
    :evidence_bundle_id,
    :schema_version,
    :experiment_id,
    :evidence_type,
    :evidence_schema_id,
    :provenance,
    :evidence_records,
    :normalization_proof,
    # Phase 17.8 extension
    :phase_17_8_ext
  ]

  @type evidence_record :: %{
          record_id: String.t(),
          record_type: String.t(),
          content_hash: String.t(),
          content_pointer: String.t()
        }

  @type normalization_proof :: %{
          normalizer_id: String.t(),
          normalization_rules_hash: String.t()
        }

  @type phase_17_8_ext :: %{
          twin_outcome_id: String.t(),
          simulation_fingerprint: String.t(),
          normalization_proof_hash: String.t()
        }

  @type t :: %__MODULE__{
          evidence_bundle_id: String.t() | nil,
          schema_version: String.t() | nil,
          experiment_id: String.t() | nil,
          evidence_type: :raw | :normalized | nil,
          evidence_schema_id: String.t() | nil,
          provenance: map() | nil,
          evidence_records: [evidence_record()] | nil,
          normalization_proof: normalization_proof() | nil,
          phase_17_8_ext: phase_17_8_ext() | nil
        }

  @doc """
  Constructs and validates a ResearchEvidence bundle. All domain values must be
  supplied by the caller.

  Required keys:
  - :schema_version (String.t, e.g. "17.8.0")
  - :experiment_id (String.t)
  - :evidence_type (:raw | :normalized)
  - :evidence_schema_id (String.t)
  - :provenance (map with :source_artifact_ids and :capture_context)
  - :evidence_records ([evidence_record()])
  - :normalization_proof (normalization_proof())
  - :phase_17_8_ext (phase_17_8_ext() — required for Phase 17.8 origin evidence)

  The :evidence_bundle_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    evidence = %__MODULE__{
      schema_version: Keyword.get(opts, :schema_version),
      experiment_id: Keyword.get(opts, :experiment_id),
      evidence_type: Keyword.get(opts, :evidence_type),
      evidence_schema_id: Keyword.get(opts, :evidence_schema_id),
      provenance: Keyword.get(opts, :provenance),
      evidence_records: Keyword.get(opts, :evidence_records),
      normalization_proof: Keyword.get(opts, :normalization_proof),
      phase_17_8_ext: Keyword.get(opts, :phase_17_8_ext)
    }

    with :ok <- validate(evidence) do
      id = Canonical.generate_id(evidence, @id_field, @id_prefix)
      {:ok, %{evidence | evidence_bundle_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = evidence) do
    Canonical.verify_id(evidence, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "ResearchEvidence: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchEvidence: schema_version must be a non-empty string"}

  defp validate(%__MODULE__{experiment_id: nil}),
    do: {:error, "ResearchEvidence: experiment_id is required"}

  defp validate(%__MODULE__{experiment_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchEvidence: experiment_id must be a non-empty string"}

  defp validate(%__MODULE__{evidence_type: nil}),
    do: {:error, "ResearchEvidence: evidence_type is required"}

  defp validate(%__MODULE__{evidence_type: v}) when v not in @valid_evidence_types,
    do: {:error, "ResearchEvidence: evidence_type must be one of #{inspect(@valid_evidence_types)}"}

  defp validate(%__MODULE__{evidence_schema_id: nil}),
    do: {:error, "ResearchEvidence: evidence_schema_id is required"}

  defp validate(%__MODULE__{evidence_schema_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchEvidence: evidence_schema_id must be a non-empty string"}

  defp validate(%__MODULE__{provenance: nil}),
    do: {:error, "ResearchEvidence: provenance is required"}

  defp validate(%__MODULE__{provenance: v}) when not is_map(v),
    do: {:error, "ResearchEvidence: provenance must be a map"}

  defp validate(%__MODULE__{evidence_records: nil}),
    do: {:error, "ResearchEvidence: evidence_records is required"}

  defp validate(%__MODULE__{evidence_records: v}) when not is_list(v),
    do: {:error, "ResearchEvidence: evidence_records must be a list"}

  defp validate(%__MODULE__{normalization_proof: nil}),
    do: {:error, "ResearchEvidence: normalization_proof is required"}

  defp validate(%__MODULE__{normalization_proof: v}) when not is_map(v),
    do: {:error, "ResearchEvidence: normalization_proof must be a map"}

  defp validate(%__MODULE__{phase_17_8_ext: nil}),
    do: {:error, "ResearchEvidence: phase_17_8_ext is required for Phase 17.8 origin evidence"}

  defp validate(%__MODULE__{phase_17_8_ext: v}) when not is_map(v),
    do: {:error, "ResearchEvidence: phase_17_8_ext must be a map"}

  defp validate(%__MODULE__{}), do: :ok
end
