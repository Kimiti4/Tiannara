defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ProgramReplayFingerprint do
  @moduledoc """
  Phase 17.8.1 — ProgramReplayFingerprint: replay certification artifact for
  a complete research program.

  Captures the Merkle root over all replayed artifacts, the replay levels
  achieved, and any divergence report reference. This is the artifact that
  the ConstitutionalCertificateAuthority checks before issuing an ARPECertificate.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.
  - A fingerprint without divergence_report_id implies zero divergence was detected.
  - If divergence was detected, divergence_report_id must be present and
    replay_levels_achieved must not include levels where divergence occurred.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "rf"
  @id_field :fingerprint_id

  @valid_replay_levels [:level1, :level2, :level3]

  defstruct [
    :fingerprint_id,
    :program_id,
    :replay_levels_achieved,
    :merkle_root,
    :artifact_ids_replayed,
    :divergence_report_id,
    :replay_algorithm_version,
    :replay_config_hash
  ]

  @type t :: %__MODULE__{
          fingerprint_id: String.t() | nil,
          program_id: String.t() | nil,
          replay_levels_achieved: [:level1 | :level2 | :level3] | nil,
          merkle_root: String.t() | nil,
          artifact_ids_replayed: [String.t()] | nil,
          divergence_report_id: String.t() | nil,
          replay_algorithm_version: String.t() | nil,
          replay_config_hash: String.t() | nil
        }

  @doc """
  Constructs and validates a ProgramReplayFingerprint. All domain values must be
  supplied by the caller.

  Required keys:
  - :program_id (String.t)
  - :replay_levels_achieved ([atom] — subset of [:level1, :level2, :level3])
  - :merkle_root (String.t — Merkle root over artifact_ids_replayed)
  - :artifact_ids_replayed ([String.t()])
  - :replay_algorithm_version (String.t)
  - :replay_config_hash (String.t)

  Optional:
  - :divergence_report_id (String.t | nil — nil iff no divergence was detected)

  The :fingerprint_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    fingerprint = %__MODULE__{
      program_id: Keyword.get(opts, :program_id),
      replay_levels_achieved: Keyword.get(opts, :replay_levels_achieved),
      merkle_root: Keyword.get(opts, :merkle_root),
      artifact_ids_replayed: Keyword.get(opts, :artifact_ids_replayed),
      divergence_report_id: Keyword.get(opts, :divergence_report_id),
      replay_algorithm_version: Keyword.get(opts, :replay_algorithm_version),
      replay_config_hash: Keyword.get(opts, :replay_config_hash)
    }

    with :ok <- validate(fingerprint) do
      id = Canonical.generate_id(fingerprint, @id_field, @id_prefix)
      {:ok, %{fingerprint | fingerprint_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = fingerprint) do
    Canonical.verify_id(fingerprint, @id_field, @id_prefix)
  end

  @doc """
  Returns true iff this fingerprint achieved at minimum level1 and level3 replay,
  which are required for constitutional certification.
  """
  @spec certifiable?(t()) :: boolean()
  def certifiable?(%__MODULE__{replay_levels_achieved: levels}) when is_list(levels) do
    :level1 in levels and :level3 in levels
  end

  def certifiable?(_), do: false

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{program_id: nil}),
    do: {:error, "ProgramReplayFingerprint: program_id is required"}

  defp validate(%__MODULE__{program_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ProgramReplayFingerprint: program_id must be a non-empty string"}

  defp validate(%__MODULE__{replay_levels_achieved: nil}),
    do: {:error, "ProgramReplayFingerprint: replay_levels_achieved is required"}

  defp validate(%__MODULE__{replay_levels_achieved: v}) when not is_list(v),
    do: {:error, "ProgramReplayFingerprint: replay_levels_achieved must be a list"}

  defp validate(%__MODULE__{replay_levels_achieved: levels} = fp) do
    invalid = Enum.reject(levels, &(&1 in @valid_replay_levels))

    if invalid == [] do
      validate_remaining(fp)
    else
      {:error,
       "ProgramReplayFingerprint: invalid replay levels #{inspect(invalid)}; " <>
         "valid levels are #{inspect(@valid_replay_levels)}"}
    end
  end

  defp validate_remaining(%__MODULE__{merkle_root: nil}),
    do: {:error, "ProgramReplayFingerprint: merkle_root is required"}

  defp validate_remaining(%__MODULE__{merkle_root: v}) when not is_binary(v) or v == "",
    do: {:error, "ProgramReplayFingerprint: merkle_root must be a non-empty string"}

  defp validate_remaining(%__MODULE__{artifact_ids_replayed: nil}),
    do: {:error, "ProgramReplayFingerprint: artifact_ids_replayed is required"}

  defp validate_remaining(%__MODULE__{artifact_ids_replayed: v}) when not is_list(v),
    do: {:error, "ProgramReplayFingerprint: artifact_ids_replayed must be a list"}

  defp validate_remaining(%__MODULE__{artifact_ids_replayed: []}),
    do: {:error,
         "ProgramReplayFingerprint: artifact_ids_replayed must not be empty — " <>
           "a fingerprint with no replayed artifacts proves nothing"}

  defp validate_remaining(%__MODULE__{replay_algorithm_version: nil}),
    do: {:error, "ProgramReplayFingerprint: replay_algorithm_version is required"}

  defp validate_remaining(%__MODULE__{replay_algorithm_version: v})
       when not is_binary(v) or v == "",
       do: {:error,
            "ProgramReplayFingerprint: replay_algorithm_version must be a non-empty string"}

  defp validate_remaining(%__MODULE__{replay_config_hash: nil}),
    do: {:error, "ProgramReplayFingerprint: replay_config_hash is required"}

  defp validate_remaining(%__MODULE__{replay_config_hash: v})
       when not is_binary(v) or v == "",
       do: {:error, "ProgramReplayFingerprint: replay_config_hash must be a non-empty string"}

  defp validate_remaining(%__MODULE__{}), do: :ok
end
