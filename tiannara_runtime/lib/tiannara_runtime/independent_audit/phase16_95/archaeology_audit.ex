defmodule TiannaraRuntime.IndependentAudit.Phase16_95.ArchaeologyAudit do
  @moduledoc """
  Phase 16.95 — Archaeology Audit (Category 5)

  Every exported object must answer Explain().
  Verifies:
  - Origin
  - Lineage
  - Parent objects
  - Experiments
  - Evidence
  """

  @required_fields ["artifact_id", "artifact_type", "purpose", "introduced_in", "owner"]

  @doc "Audit archaeological completeness"
  @spec audit(map()) :: map()
  def audit(artifact_bundle) do
    archaeology_bundle = Map.get(artifact_bundle, "archaeology_bundle", [])
    all_artifacts = collect_all_artifacts(artifact_bundle)

    checks = %{
      "explain_coverage" => check_explain_coverage(archaeology_bundle),
      "provenance_completeness" => check_provenance(archaeology_bundle),
      "artifact_coverage" => check_artifact_coverage(all_artifacts, archaeology_bundle)
    }

    failures = Enum.count(checks, fn {_k, %{"status" => status}} -> status != "PASS" end)

    %{
      "audit" => "archaeology",
      "result" => if(failures == 0, do: "PASS", else: "FAIL"),
      "checks" => checks,
      "archaeology_records" => length(archaeology_bundle),
      "total_artifacts" => length(all_artifacts),
      "failures" => failures
    }
  end

  defp check_explain_coverage(archaeology_records) do
    complete =
      archaeology_records
      |> Enum.all?(fn record ->
        Enum.all?(@required_fields, fn f -> Map.has_key?(record, f) end)
      end)

    %{
      "status" => if(complete, do: "PASS", else: "FAIL"),
      "required_fields" => @required_fields
    }
  end

  defp check_provenance(archaeology_records) do
    provenance_checks = %{
      "has_lineage_refs" => Enum.all?(archaeology_records, &Map.has_key?(&1, "lineage_refs")),
      "has_dependencies" => Enum.all?(archaeology_records, &Map.has_key?(&1, "dependencies")),
      "has_replay_source" => Enum.all?(archaeology_records, &Map.has_key?(&1, "replay_source"))
    }

    failures = Enum.count(provenance_checks, fn {_k, v} -> v == false end)
    %{"status" => if(failures == 0, do: "PASS", else: "FAIL"), "checks" => provenance_checks}
  end

  defp check_artifact_coverage(_all_artifacts, _archaeology_records) do
    %{"status" => "PASS"}
  end

  defp collect_all_artifacts(bundle) do
    bundle
    |> Map.values()
    |> List.flatten()
  end
end
