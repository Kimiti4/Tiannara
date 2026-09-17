defmodule TiannaraRuntime.WorldModel.AutonomousResearch.MathematicalVerificationResult do
  @moduledoc """
  Phase 17.8.1 — MathematicalVerificationResult: output of the ARPEMathVerifier
  for a ResearchExperiment.

  The verification status is always returned as an artifact — even when the
  Phase 16.X Mathematics Substrate is not yet certified. In that case,
  verification_status is :mathematically_unverified, not an error tuple.

  This is intentional: callers always receive an artifact to archive.
  The status field drives downstream certification eligibility.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.
  - VERIFICATION_FAILED in any check does not block construction of this artifact;
    it is recorded faithfully so the program can be archived and archaeology can
    explain what failed.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "mvr"
  @id_field :verification_id

  @valid_statuses [:verified, :mathematically_unverified, :verification_failed]

  @valid_check_types [
    :statistical_power,
    :dimensional_consistency,
    :sampling_plan,
    :optimization_constraints,
    :symbolic_invariants
  ]

  @valid_check_results [:pass, :fail, :unverified]

  defstruct [
    :verification_id,
    :experiment_id,
    :verification_status,
    :checks_performed,
    :substrate_version,
    :substrate_certified,
    :verification_config_hash
  ]

  @type check :: %{
          check_type: atom(),
          result: :pass | :fail | :unverified,
          proof_hash: String.t() | nil,
          failure_reason: String.t() | nil
        }

  @type t :: %__MODULE__{
          verification_id: String.t() | nil,
          experiment_id: String.t() | nil,
          verification_status: :verified | :mathematically_unverified | :verification_failed | nil,
          checks_performed: [check()] | nil,
          substrate_version: String.t() | nil,
          substrate_certified: boolean() | nil,
          verification_config_hash: String.t() | nil
        }

  @doc """
  Constructs and validates a MathematicalVerificationResult. All domain values
  must be supplied by the caller.

  Required keys:
  - :experiment_id (String.t)
  - :verification_status (atom — one of #{inspect(@valid_statuses)})
  - :checks_performed ([check()])
  - :substrate_version (String.t)
  - :substrate_certified (boolean)
  - :verification_config_hash (String.t)

  The :verification_id is computed from the other fields; do not supply it.

  Note: verification_status must be computed by the caller from the check results.
  This struct does not infer status — it records what the verifier found.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    result = %__MODULE__{
      experiment_id: Keyword.get(opts, :experiment_id),
      verification_status: Keyword.get(opts, :verification_status),
      checks_performed: Keyword.get(opts, :checks_performed),
      substrate_version: Keyword.get(opts, :substrate_version),
      substrate_certified: Keyword.get(opts, :substrate_certified),
      verification_config_hash: Keyword.get(opts, :verification_config_hash)
    }

    with :ok <- validate(result) do
      id = Canonical.generate_id(result, @id_field, @id_prefix)
      {:ok, %{result | verification_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = result) do
    Canonical.verify_id(result, @id_field, @id_prefix)
  end

  @doc """
  Returns true iff this result allows the experiment to proceed to certification.
  Only :verified status is certifiable. :mathematically_unverified produces
  a PROVISIONAL_ARCHIVE disposition.
  """
  @spec certifiable?(t()) :: boolean()
  def certifiable?(%__MODULE__{verification_status: :verified}), do: true
  def certifiable?(_), do: false

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{experiment_id: nil}),
    do: {:error, "MathematicalVerificationResult: experiment_id is required"}

  defp validate(%__MODULE__{experiment_id: v}) when not is_binary(v) or v == "",
    do: {:error, "MathematicalVerificationResult: experiment_id must be a non-empty string"}

  defp validate(%__MODULE__{verification_status: nil}),
    do: {:error, "MathematicalVerificationResult: verification_status is required"}

  defp validate(%__MODULE__{verification_status: v}) when v not in @valid_statuses,
    do: {:error,
         "MathematicalVerificationResult: verification_status must be one of " <>
           "#{inspect(@valid_statuses)}"}

  defp validate(%__MODULE__{checks_performed: nil}),
    do: {:error, "MathematicalVerificationResult: checks_performed is required"}

  defp validate(%__MODULE__{checks_performed: v}) when not is_list(v),
    do: {:error, "MathematicalVerificationResult: checks_performed must be a list"}

  defp validate(%__MODULE__{checks_performed: checks} = r) do
    case validate_checks(checks) do
      :ok -> validate_remaining(r)
      error -> error
    end
  end

  defp validate_checks([]), do: :ok

  defp validate_checks([%{check_type: ct} | _]) when ct not in @valid_check_types,
    do: {:error,
         "MathematicalVerificationResult: check_type must be one of " <>
           "#{inspect(@valid_check_types)}"}

  defp validate_checks([%{result: r} | _]) when r not in @valid_check_results,
    do: {:error,
         "MathematicalVerificationResult: check result must be one of " <>
           "#{inspect(@valid_check_results)}"}

  defp validate_checks([_ | rest]), do: validate_checks(rest)

  defp validate_remaining(%__MODULE__{substrate_version: nil}),
    do: {:error, "MathematicalVerificationResult: substrate_version is required"}

  defp validate_remaining(%__MODULE__{substrate_version: v})
       when not is_binary(v) or v == "",
       do: {:error,
            "MathematicalVerificationResult: substrate_version must be a non-empty string"}

  defp validate_remaining(%__MODULE__{substrate_certified: nil}),
    do: {:error, "MathematicalVerificationResult: substrate_certified is required"}

  defp validate_remaining(%__MODULE__{substrate_certified: v}) when not is_boolean(v),
    do: {:error, "MathematicalVerificationResult: substrate_certified must be a boolean"}

  defp validate_remaining(%__MODULE__{verification_config_hash: nil}),
    do: {:error, "MathematicalVerificationResult: verification_config_hash is required"}

  defp validate_remaining(%__MODULE__{verification_config_hash: v})
       when not is_binary(v) or v == "",
       do: {:error,
            "MathematicalVerificationResult: verification_config_hash must be a non-empty string"}

  defp validate_remaining(%__MODULE__{}), do: :ok
end
