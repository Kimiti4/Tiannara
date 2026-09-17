defmodule TiannaraRuntime.WorldModel.Composition.Engines.CompositionArchaeology do
  @moduledoc """
  Phase 17.6.7 — CompositionArchaeology engine.
  Records and manages the evidence lineage of compositions.
  Ensures every composition is archaeologically explainable.
  """

  alias TiannaraRuntime.WorldModel.Composition.CompositionEvidence

  @doc """
  Records a composition's evidence lineage.
  Returns {:ok, CompositionEvidence.t()}.
  """
  def record(composition) do
    evidence = %CompositionEvidence{
      evidence_id: generate_evidence_id(composition),
      composition_id: composition.composition_id,
      model_roots: composition.parent_model_ids,
      interface_hashes: Enum.map(composition.interfaces || [], & &1.interface_id),
      sync_hashes: Enum.map(composition.sync_rules || [], & &1.rule_id),
      math_verification: nil,
      replay_attempts: [],
      metadata: %{
        recorded_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    }

    {:ok, evidence}
  end

  @doc """
  Records a replay attempt in the archaeology record.
  """
  def record_replay(evidence, original_fingerprint, computed_fingerprint, verified) do
    attempt = %{
      replayed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      original_fingerprint: original_fingerprint,
      computed_fingerprint: computed_fingerprint,
      verified: verified
    }

    %{evidence | replay_attempts: evidence.replay_attempts ++ [attempt]}
  end

  @doc """
  Verifies the replay of a composition against its archaeology record.
  """
  def verify_replay(evidence, graph) do
    case evidence.replay_attempts do
      [] -> {:error, :no_replay_attempts}
      attempts ->
        latest = List.last(attempts)
        if latest.verified do
          {:ok, :replay_verified}
        else
          {:error, :replay_mismatch}
        end
    end
  end

  defp generate_evidence_id(composition) do
    hash =
      :crypto.hash(:sha256, composition.composition_id <> "evidence")
      |> Base.encode16(case: :lower)
    "ce_" <> hash
  end
end
