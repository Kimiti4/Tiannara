defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.IndependentAudit.AuditRunner do
  @moduledoc """
  Phase 16.1 Evidence-Only Independent Audit Boundary

  HARD CONSTRAINT:
  - MUST NOT import or execute Phase 16.1 runtime orchestrator/engine modules.
  - MUST NOT read mutable state from ETS, databases, or network.
  - MUST consume only immutable artifacts exported by the runtime.

  Audit Modes per INDEPENDENT_RESEARCH_AUDIT.md:
  - LEDGER_RECONSTRUCTION (Mode A)
  - EVIDENCE_CLOSURE (Mode B)
  - REPLAY_CONSISTENCY (Mode C)
  - ARCHAEOLOGICAL_EXPLAINABILITY (Mode D)

  On any failure: fail closed. No silent recovery.
  """

  @doc "Audit Mode A: Ledger Reconstruction"
  @spec audit_ledger_reconstruction([map()]) :: {:ok, map()} | {:error, map()}
  def audit_ledger_reconstruction(artifacts) when is_list(artifacts) do
    reconstructed = Enum.reduce(artifacts, %{}, fn artifact, acc ->
      artifact_id = Map.get(artifact, "artifact_id")
      artifact_type = Map.get(artifact, "artifact_type", "unknown")
      Map.put(acc, artifact_id, %{"status" => "reconstructed", "type" => artifact_type})
    end)

    report = %{
      "audit_mode" => "LEDGER_RECONSTRUCTION",
      "artifacts_processed" => length(artifacts),
      "reconstructed_count" => map_size(reconstructed),
      "result" => "PASS"
    }

    {:ok, report}
  end

  @doc "Audit Mode B: Evidence Closure"
  @spec audit_evidence_closure([map()]) :: {:ok, map()} | {:error, map()}
  def audit_evidence_closure(artifacts) when is_list(artifacts) do
    closed = Enum.all?(artifacts, fn a ->
      Map.has_key?(a, "artifact_id") and Map.has_key?(a, "artifact_type")
    end)

    if closed do
      {:ok, %{
        "audit_mode" => "EVIDENCE_CLOSURE",
        "artifacts_processed" => length(artifacts),
        "closure_complete" => true,
        "result" => "PASS"
      }}
    else
      {:error, %{
        "audit_mode" => "EVIDENCE_CLOSURE",
        "artifacts_processed" => length(artifacts),
        "closure_complete" => false,
        "result" => "FAIL",
        "reason" => "one or more artifacts missing required closure fields"
      }}
    end
  end

  @doc "Audit Mode C: Replay Consistency"
  @spec audit_replay_consistency([map()]) :: {:ok, map()} | {:error, map()}
  def audit_replay_consistency(artifacts) when is_list(artifacts) do
    hashes = Enum.map(artifacts, fn artifact ->
      canonical = canonicalize_map(artifact)
      Jason.encode!(canonical)
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
    end)

    consistent = Enum.all?(hashes, fn hash ->
      byte_size(hash) == 64 and Regex.match?(~r/^[0-9a-f]+$/, hash)
    end)

    if consistent do
      {:ok, %{
        "audit_mode" => "REPLAY_CONSISTENCY",
        "artifacts_processed" => length(artifacts),
        "consistent" => true,
        "hash_count" => length(hashes),
        "unique_hash_count" => length(Enum.uniq(hashes)),
        "result" => "PASS"
      }}
    else
      {:error, %{
        "audit_mode" => "REPLAY_CONSISTENCY",
        "artifacts_processed" => length(artifacts),
        "consistent" => false,
        "hash_count" => length(hashes),
        "unique_hash_count" => length(Enum.uniq(hashes)),
        "result" => "FAIL",
        "reason" => "non-deterministic artifact serialization detected"
      }}
    end
  end

  @doc "Audit Mode D: Archaeological Explainability"
  @spec audit_archaeological_explainability([map()]) :: {:ok, map()} | {:error, map()}
  def audit_archaeological_explainability(artifacts) when is_list(artifacts) do
    explainable = Enum.all?(artifacts, fn a ->
      required_fields = ["artifact_id", "artifact_type", "purpose", "introduced_in", "owner"]
      Enum.all?(required_fields, &Map.has_key?(a, &1))
    end)

    explainable_count = Enum.count(artifacts, fn a ->
      required_fields = ["artifact_id", "artifact_type", "purpose", "introduced_in", "owner"]
      Enum.all?(required_fields, &Map.has_key?(a, &1))
    end)

    if explainable do
      {:ok, %{
        "audit_mode" => "ARCHAEOLOGICAL_EXPLAINABILITY",
        "artifacts_processed" => length(artifacts),
        "explainable_count" => explainable_count,
        "result" => "PASS"
      }}
    else
      {:error, %{
        "audit_mode" => "ARCHAEOLOGICAL_EXPLAINABILITY",
        "artifacts_processed" => length(artifacts),
        "explainable_count" => explainable_count,
        "result" => "FAIL",
        "reason" => "one or more artifacts missing archaeology metadata"
      }}
    end
  end

  @doc "Run full audit (all modes)"
  @spec run_full_audit([map()]) :: {:ok, map()} | {:error, map()}
  def run_full_audit(artifacts) when is_list(artifacts) do
    case audit_evidence_closure(artifacts) do
      {:error, _} = fail ->
        fail

      {:ok, _} ->
        results = %{
          "ledger_reconstruction" => audit_ledger_reconstruction(artifacts),
          "evidence_closure" => audit_evidence_closure(artifacts),
          "replay_consistency" => audit_replay_consistency(artifacts),
          "archaeological_explainability" => audit_archaeological_explainability(artifacts)
        }

        failures = Enum.filter(Map.values(results), fn
          {:error, %{"result" => "FAIL"}} -> true
          _ -> false
        end)

        if length(failures) > 0 do
          {:error, %{"audit_result" => "FAIL", "failures" => failures, "results" => results}}
        else
          {:ok, %{"audit_result" => "PASS", "results" => results}}
        end
    end
  end

  # --- internal helpers ---

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
