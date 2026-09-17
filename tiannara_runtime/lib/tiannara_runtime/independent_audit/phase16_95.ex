defmodule TiannaraRuntime.IndependentAudit.Phase16_95 do
  @moduledoc """
  Phase 16.95 — Independent Constitutional Auditor

  Constitutional role:
  - Consumes only exported immutable artifacts
  - Does NOT import or execute any runtime modules
  - Does NOT access ETS, databases, or network
  - Does NOT issue certification artifacts
  - Returns only: PASS | PASS WITH OBSERVATIONS | FAIL

  Audit categories (frozen per Phase 16.95 specification):
  1. Replay Verification
  2. Evidence Chain Verification
  3. Knowledge Graph Audit
  4. Scientific Capital Audit
  5. Archaeology Audit
  6. Boundary Audit
  7. Determinism Audit
  8. Runtime Independence
  """

  alias TiannaraRuntime.IndependentAudit.Phase16_95.{
    ReplayAudit,
    EvidenceChainAudit,
    KnowledgeGraphAudit,
    ScientificCapitalAudit,
    ArchaeologyAudit,
    BoundaryAudit,
    DeterminismAudit
  }

  @type audit_result :: :pass | :pass_with_observations | :fail
  @type audit_report :: %{
    String.t() => any()
  }

  @doc "Run the full constitutional audit on exported artifacts"
  @spec run(%{String.t() => [map()]}) :: {:ok, audit_report()} | {:error, audit_report()}
  def run(artifact_bundle) when is_map(artifact_bundle) do
    observations = []

    results = %{
      "replay_audit" => run_category(ReplayAudit, :audit, [artifact_bundle]),
      "evidence_chain_audit" => run_category(EvidenceChainAudit, :audit, [artifact_bundle]),
      "knowledge_graph_audit" => run_category(KnowledgeGraphAudit, :audit, [artifact_bundle]),
      "scientific_capital_audit" => run_category(ScientificCapitalAudit, :audit, [artifact_bundle]),
      "archaeology_audit" => run_category(ArchaeologyAudit, :audit, [artifact_bundle]),
      "boundary_audit" => run_category(BoundaryAudit, :audit, [artifact_bundle]),
      "determinism_audit" => run_category(DeterminismAudit, :audit, [artifact_bundle])
    }

    verdict = compute_verdict(results, observations)
    report = build_report(verdict, results, observations)

    case verdict do
      :fail -> {:error, report}
      _ -> {:ok, report}
    end
  end

  @doc "Verify runtime independence: confirm no Phase 16.1 modules were loaded"
  @spec verify_independence() :: {:ok, map()} | {:error, map()}
  def verify_independence do
    phase16_1_prefix = "Elixir.TiannaraRuntime.AutonomousResearch.Phase16_1"

    loaded = :code.all_loaded()
    violations = Enum.filter(loaded, fn {mod, _} ->
      mod_str = Atom.to_string(mod)
      String.starts_with?(mod_str, phase16_1_prefix)
    end)

    if violations == [] do
      {:ok, %{
        "audit" => "runtime_independence",
        "result" => "PASS",
        "modules_loaded" => length(loaded),
        "violations" => []
      }}
    else
      {:error, %{
        "audit" => "runtime_independence",
        "result" => "FAIL",
        "reason" => "Phase 16.1 runtime modules are loaded in auditor process",
        "violations" => Enum.map(violations, fn {mod, _} -> Atom.to_string(mod) end)
      }}
    end
  end

  # --- internal ---

  defp run_category(module, function, args) do
    apply(module, function, args)
  rescue
    e -> %{"result" => "ERROR", "error" => inspect(e)}
  end

  defp compute_verdict(results, observations) do
    failures = Enum.filter(results, fn {_k, v} ->
      Map.get(v, "result") == "FAIL" or Map.get(v, "result") == "ERROR"
    end)

    cond do
      length(failures) > 0 -> :fail
      length(observations) > 0 -> :pass_with_observations
      true -> :pass
    end
  end

  defp build_report(verdict, results, observations) do
    %{
      "audit_phase" => "16.95",
      "auditor" => "TiannaraRuntime.IndependentAudit.Phase16_95",
      "verdict" => Atom.to_string(verdict),
      "timestamp" => "2000-01-01T00:00:00Z",
      "categories" => results,
      "observations" => observations,
      "categories_audited" => map_size(results),
      "categories_passed" => count_results(results, "PASS"),
      "categories_failed" => count_results(results, "FAIL") + count_results(results, "ERROR")
    }
  end

  defp count_results(results, status) do
    Enum.count(results, fn {_k, v} -> Map.get(v, "result") == status end)
  end
end
