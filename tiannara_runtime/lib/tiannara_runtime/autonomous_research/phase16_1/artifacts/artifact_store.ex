defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.Artifacts.ArtifactStore do
  @moduledoc """
  Phase 16.1 Immutable Artifact Store

  Deterministic serialization + content-addressed storage for runtime artifacts.

  Phase 16.1 does NOT emit certification artifacts:
  - RESEARCH_CERTIFICATE.json
  - RESEARCH_PROOF.json
  - RESEARCH_FINAL_REPORT.md
  - RESEARCH_ARCHAEOLOGY.md

  Only contract-defined immutable runtime artifacts are produced:
  - research ledgers
  - observation/question/hypothesis/experiment/theory records
  - knowledge graph snapshots
  - scientific capital ledgers
  - replay manifests / hashes
  - lineage proofs
  - archaeology metadata
  - validation evidence bundles
  - audit input packages
  """

  @doc "Write an artifact deterministically with content-addressed ID"
  @spec write(map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def write(artifact, opts \\ []) do
    canonical = canonicalize_map(artifact)
    json = Jason.encode!(canonical)
    hash = :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)

    artifact_record = %{
      "artifact_id" => hash,
      "schema_version" => "16.1.0",
      "artifact_type" => Keyword.get(opts, :artifact_type, "unknown"),
      "canonical_json" => json,
      "sha256" => hash
    }

    {:ok, artifact_record}
  end

  @doc "Verify an artifact against an expected content-addressed hash"
  @spec verify(map(), String.t()) :: {:ok, map()} | {:error, map()}
  def verify(artifact, expected_hash) when is_binary(expected_hash) do
    canonical = canonicalize_map(artifact)
    json = Jason.encode!(canonical)
    computed = :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)

    if computed == expected_hash do
      {:ok, %{"verified" => true, "hash" => computed}}
    else
      {:error, %{"verified" => false, "expected" => expected_hash, "computed" => computed}}
    end
  end

  @doc "Compute content-addressed ID for an artifact"
  @spec content_id(map()) :: String.t()
  def content_id(artifact) do
    canonical = canonicalize_map(artifact)
    Jason.encode!(canonical)
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
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
