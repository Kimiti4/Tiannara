defmodule TiannaraRuntime.IndependentAudit.Phase16_95.BoundaryAudit do
  @moduledoc """
  Phase 16.95 — Boundary Audit (Category 6)

  Verifies the runtime cannot:
  - Certify discoveries
  - Promote theories
  - Approve laws
  - Modify constitutional contracts

  Any reachable path is an automatic audit failure.
  """

  @forbidden_functions [
    "issue_certificate", "certify_discovery", "certify_research",
    "promote_theory", "approve_law", "modify_constitution",
    "emit_certificate", "generate_certificate", "self_certify"
  ]

  @forbidden_artifact_types [
    "RESEARCH_CERTIFICATE", "RESEARCH_PROOF", "CERTIFICATION",
    "CONSTITUTIONAL_APPROVAL", "LAW_PROMULGATION"
  ]

  @doc "Audit constitutional boundary enforcement"
  @spec audit(map()) :: map()
  def audit(artifact_bundle) do
    all_artifacts = collect_all_artifacts(artifact_bundle)

    checks = %{
      "no_certification_artifacts" => check_forbidden_artifacts(all_artifacts),
      "no_certification_references" => check_forbidden_references(all_artifacts),
      "no_constitutional_overreach" => check_constitutional_boundary(all_artifacts)
    }

    failures = Enum.count(checks, fn {_k, %{"status" => status}} -> status != "PASS" end)

    %{
      "audit" => "boundary_enforcement",
      "result" => if(failures == 0, do: "PASS", else: "FAIL"),
      "checks" => checks,
      "artifacts_scanned" => length(all_artifacts),
      "failures" => failures
    }
  end

  defp check_forbidden_artifacts(artifacts) do
    violations =
      artifacts
      |> Enum.filter(fn a ->
        artifact_type = Map.get(a, "artifact_type", "") || Map.get(a, "type", "")
        String.upcase(artifact_type) in @forbidden_artifact_types
      end)

    %{
      "status" => if(violations == [], do: "PASS", else: "FAIL"),
      "forbidden_types" => @forbidden_artifact_types,
      "violations_found" => length(violations)
    }
  end

  defp check_forbidden_references(artifacts) do
    violations =
      artifacts
      |> Enum.flat_map(fn a ->
        @forbidden_functions
        |> Enum.filter(fn func ->
          artifact_str = inspect(a)
          String.contains?(artifact_str, func)
        end)
      end)
      |> Enum.uniq()

    %{
      "status" => if(violations == [], do: "PASS", else: "FAIL"),
      "forbidden_functions" => @forbidden_functions,
      "violations_found" => violations
    }
  end

  defp check_constitutional_boundary(artifacts) do
    boundary_keys = ["certificate_status", "certification_verdict", "research_ready", "constitutional_approval"]

    violations =
      artifacts
      |> Enum.filter(fn a ->
        Enum.any?(boundary_keys, fn k -> Map.has_key?(a, k) end)
      end)

    %{
      "status" => if(violations == [], do: "PASS", else: "FAIL"),
      "boundary_keys" => boundary_keys,
      "violations_found" => length(violations)
    }
  end

  defp collect_all_artifacts(bundle) do
    bundle
    |> Map.values()
    |> List.flatten()
  end
end
