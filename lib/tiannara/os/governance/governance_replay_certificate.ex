defmodule TiannaraOS.Governance.GovernanceReplayCertificate do
  @moduledoc """
  GovernanceReplayCertificate - Immutable proof of governance state reconstruction.

  Every governance replay produces a certificate that serves as cryptographic proof
  that the state was reconstructed deterministically from the ledger. This enables
  future archaeology to verify that historical governance states were valid.

  ## Certificate Contents

  - `ledger_hash` - SHA-256 hash of complete ledger at replay time
  - `manifest_id` - Constitution manifest version used for replay
  - `replay_duration_ms` - Time taken to complete replay
  - `replay_success` - Whether replay matched captured state
  - `replay_version` - Replay engine version
  - `verification_status` - :verified, :mismatch, or :failed
  - `timestamp` - When certificate was issued
  - `state_fingerprint` - Fingerprint of reconstructed state
  - `field_verification` - Per-field verification results

  ## API

      @spec issue_certificate(map(), map(), non_neg_integer(), String.t()) :: t()
      @spec verify_certificate(t()) :: :valid | {:invalid, String.t()}
      @spec export_for_archaeology(t()) :: map()
  """

  defstruct [
    :certificate_id,
    :ledger_hash,
    :manifest_id,
    :replay_duration_ms,
    :replay_success,
    :replay_version,
    :verification_status,
    :timestamp,
    :state_fingerprint,
    :field_verification,
    :signature
  ]

  @type t :: %__MODULE__{
          certificate_id: String.t(),
          ledger_hash: String.t(),
          manifest_id: String.t(),
          replay_duration_ms: non_neg_integer(),
          replay_success: boolean(),
          replay_version: String.t(),
          verification_status: atom(),
          timestamp: DateTime.t(),
          state_fingerprint: String.t(),
          field_verification: map(),
          signature: String.t()
        }

  @doc """
  Issue replay certificate after successful verification.

  Compares replayed state against captured state field-by-field.
  """
  @spec issue_certificate(map(), map(), non_neg_integer(), String.t()) :: t()
  def issue_certificate(captured_state, replayed_state, duration_ms, ledger_hash) do
    now = DateTime.utc_now()
    certificate_id = generate_certificate_id()
    replay_version = "14.0.9"

    # Compute state fingerprint
    state_fingerprint = compute_state_fingerprint(replayed_state)

    # Verify each field
    field_verification = verify_all_fields(captured_state, replayed_state)

    # Determine overall status
    verification_status =
      if all_fields_match?(field_verification) do
        :verified
      else
        {:mismatch, get_mismatched_fields(field_verification)}
      end

    replay_success = verification_status == :verified

    # Sign certificate
    signature = sign_certificate(certificate_id, ledger_hash, state_fingerprint, now)

    %__MODULE__{
      certificate_id: certificate_id,
      ledger_hash: ledger_hash,
      manifest_id: "constitution-v13",
      replay_duration_ms: duration_ms,
      replay_success: replay_success,
      replay_version: replay_version,
      verification_status: verification_status,
      timestamp: now,
      state_fingerprint: state_fingerprint,
      field_verification: field_verification,
      signature: signature
    }
  end

  @doc """
  Verify certificate integrity.

  Checks signature and field consistency.
  """
  @spec verify_certificate(t()) :: :valid | {:invalid, String.t()}
  def verify_certificate(%__MODULE__{} = cert) do
    expected_signature = sign_certificate(
      cert.certificate_id,
      cert.ledger_hash,
      cert.state_fingerprint,
      cert.timestamp
    )

    if cert.signature != expected_signature do
      {:invalid, "Certificate signature invalid"}
    else
      if not cert.replay_success do
        {:invalid, "Replay did not match captured state"}
      else
        :valid
      end
    end
  end

  @doc """
  Export certificate for archaeological verification.
  """
  @spec export_for_archaeology(t()) :: map()
  def export_for_archaeology(%__MODULE__{} = cert) do
    %{
      certificate_id: cert.certificate_id,
      ledger_hash: cert.ledger_hash,
      manifest_id: cert.manifest_id,
      replay_duration_ms: cert.replay_duration_ms,
      replay_success: cert.replay_success,
      replay_version: cert.replay_version,
      verification_status: cert.verification_status,
      timestamp: DateTime.to_iso8601(cert.timestamp),
      state_fingerprint: cert.state_fingerprint,
      signature: cert.signature,
      field_summary: summarize_field_verification(cert.field_verification)
    }
  end

  @doc """
  Get certificate summary for dashboard display.
  """
  @spec get_summary(t()) :: map()
  def get_summary(%__MODULE__{} = cert) do
    %{
      certificate_id: cert.certificate_id,
      verification_status: cert.verification_status,
      replay_success: cert.replay_success,
      replay_duration_ms: cert.replay_duration_ms,
      timestamp: DateTime.to_iso8601(cert.timestamp),
      fields_verified: map_size(cert.field_verification),
      fields_matched: count_matched_fields(cert.field_verification)
    }
  end

  defp generate_certificate_id() do
    "gov-replay-cert-#{System.system_time(:millisecond)}-#{:erlang.unique_integer([:positive])}"
  end

  defp compute_state_fingerprint(state) do
    hash_input = inspect(%{
      institutions: Map.keys(state.institutions || %{}),
      appointments: Map.keys(state.appointments || %{}),
      roles: Map.keys(state.roles || %{}),
      fitness: state.fitness,
      entropy: state.entropy,
      health: state.health
    })

    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end

  defp verify_all_fields(captured, replayed) do
    %{
      institutions: verify_field(captured.institutions, replayed.institutions),
      appointments: verify_field(captured.appointments, replayed.appointments),
      roles: verify_field(captured.roles, replayed.roles),
      capabilities: verify_field(captured.capabilities, replayed.capabilities),
      fitness: verify_numeric_field(captured.fitness, replayed.fitness, 0.001),
      entropy: verify_numeric_field(captured.entropy, replayed.entropy, 0.001),
      health: verify_numeric_field(captured.health, replayed.health, 0.001),
      active_proposals: verify_field(captured.active_proposals, replayed.active_proposals),
      pending_reviews: verify_field(captured.pending_reviews, replayed.pending_reviews),
      pending_deployments: verify_field(captured.pending_deployments, replayed.pending_deployments),
      pending_rollbacks: verify_field(captured.pending_rollbacks, replayed.pending_rollbacks),
      budget: verify_field(captured.budget, replayed.budget)
    }
  end

  defp verify_field(expected, actual) do
    if expected == actual do
      :match
    else
      {:mismatch, %{expected: expected, actual: actual}}
    end
  end

  defp verify_numeric_field(expected, actual, tolerance) do
    if abs(expected - actual) <= tolerance do
      :match
    else
      {:mismatch, %{expected: expected, actual: actual, tolerance: tolerance}}
    end
  end

  defp all_fields_match?(field_verification) do
    Enum.all?(field_verification, fn {_field, result} -> result == :match end)
  end

  defp get_mismatched_fields(field_verification) do
    field_verification
    |> Enum.filter(fn {_field, result} -> result != :match end)
    |> Enum.map(fn {field, _result} -> field end)
  end

  defp count_matched_fields(field_verification) do
    field_verification
    |> Enum.count(fn {_field, result} -> result == :match end)
  end

  defp summarize_field_verification(field_verification) do
    total = map_size(field_verification)
    matched = count_matched_fields(field_verification)

    if total == 0 do
      %{
        total_fields: 0,
        matched_fields: 0,
        mismatched_fields: 0,
        match_rate: 0.0
      }
    else
      %{
        total_fields: total,
        matched_fields: matched,
        mismatched_fields: total - matched,
        match_rate: Float.round(matched / total * 100, 2)
      }
    end
  end

  defp sign_certificate(cert_id, ledger_hash, state_fingerprint, timestamp) do
    hash_input = "#{cert_id}:#{ledger_hash}:#{state_fingerprint}:#{timestamp}"
    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end
end
