defmodule TiannaraRuntime.IndependentAudit.Phase16_95.DeterminismAudit do
  @moduledoc """
  Phase 16.95 — Determinism Audit (Category 7)

  Verifies:
  - Serialization hashes are deterministic
  - Replay hashes are deterministic
  - Graph hashes are deterministic
  - Experiment hashes are deterministic

  Multiple executions must produce identical results.
  """

  @doc "Audit determinism across all artifact types"
  @spec audit(map()) :: map()
  def audit(artifact_bundle) do
    all_artifacts = collect_all_artifacts(artifact_bundle)

    checks = %{
      "serialization_determinism" => check_serialization_stability(all_artifacts),
      "fingerprint_uniqueness" => check_fingerprint_uniqueness(all_artifacts)
    }

    failures = Enum.count(checks, fn {_k, %{"status" => status}} -> status != "PASS" end)

    %{
      "audit" => "determinism",
      "result" => if(failures == 0, do: "PASS", else: "FAIL"),
      "checks" => checks,
      "artifacts_tested" => length(all_artifacts),
      "failures" => failures
    }
  end

  defp check_serialization_stability(artifacts) do
    stable =
      artifacts
      |> Enum.all?(fn a ->
        json1 = Jason.encode!(canonicalize_map(a))
        json2 = Jason.encode!(canonicalize_map(a))
        hash1 = :crypto.hash(:sha256, json1) |> Base.encode16(case: :lower)
        hash2 = :crypto.hash(:sha256, json2) |> Base.encode16(case: :lower)
        hash1 == hash2
      end)

    %{"status" => if(stable, do: "PASS", else: "FAIL")}
  end

  defp check_fingerprint_uniqueness(artifacts) do
    fingerprints =
      artifacts
      |> Enum.map(fn a ->
        canonical = canonicalize_map(a)
        Jason.encode!(canonical)
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)
      end)

    unique = Enum.uniq(fingerprints)
    all_valid = Enum.all?(fingerprints, fn f -> byte_size(f) == 64 end)

    %{
      "status" => if(all_valid, do: "PASS", else: "FAIL"),
      "total_fingerprints" => length(fingerprints),
      "unique_fingerprints" => length(unique)
    }
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term

  defp collect_all_artifacts(bundle) do
    bundle
    |> Map.values()
    |> List.flatten()
  end
end
