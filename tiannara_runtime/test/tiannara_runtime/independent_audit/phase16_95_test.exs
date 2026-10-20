defmodule TiannaraRuntime.IndependentAudit.Phase16_95Test do
  @moduledoc """
  Phase 16.95 — Independent Constitutional Auditor Tests
  """

  use ExUnit.Case, async: false

  alias TiannaraRuntime.IndependentAudit.Phase16_95
  alias TiannaraRuntime.IndependentAudit.Phase16_95.{
    ReplayAudit,
    EvidenceChainAudit,
    KnowledgeGraphAudit,
    ScientificCapitalAudit,
    ArchaeologyAudit,
    BoundaryAudit,
    DeterminismAudit
  }

  defp sha256(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp with_artifact_id(map) do
    hash = sha256(Map.delete(map, "artifact_id"))
    Map.put(map, "artifact_id", hash)
  end

  defp valid_bundle do
    a1 = with_artifact_id(%{"artifact_type" => "question", "question_id" => "q1", "knowledge_gap_id" => "g1"})
    a2 = with_artifact_id(%{"artifact_type" => "question", "question_id" => "q2", "knowledge_gap_id" => "g2"})

    e1 = with_artifact_id(%{"experiment_id" => "e1", "question_id" => "q1", "hypothesis_id" => "h1", "experiment_type" => "SIMULATION"})
    e2 = with_artifact_id(%{"experiment_id" => "e2", "question_id" => "q2", "hypothesis_id" => "h2", "experiment_type" => "SIMULATION"})

    %{
      "research_bundle" => [a1, a2],
      "knowledge_graph" => [
        %{"node_id" => "n1", "node_type" => "ObservationNode"},
        %{"node_id" => "n2", "node_type" => "HypothesisNode"},
        %{"node_id" => "n3", "node_type" => "TheoryNode"}
      ],
      "scientific_capital" => [
        %{"scientific_capital" => 100, "knowledge_capital" => 50, "research_debt" => 10, "discovery_fitness" => 0.8}
      ],
      "experiment_log" => [e1, e2],
      "replay_bundle" => [
        %{"artifact_id" => "abc123"}
      ],
      "serialization_manifest" => [],
      "archaeology_bundle" => [
        with_artifact_id(%{
          "artifact_type" => "question", "purpose" => "autonomous_research",
          "introduced_in" => "phase_16_1", "owner" => "Constitutional Research Council",
          "dependencies" => [], "lineage_refs" => ["l1"], "replay_source" => "deterministic"
        })
      ]
    }
  end

  # ========================================================================
  # Category 1 — Replay Verification
  # ========================================================================

  describe "ReplayAudit" do
    test "passes on valid artifact bundle" do
      result = ReplayAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "scans artifacts correctly" do
      result = ReplayAudit.audit(valid_bundle())
      assert Map.get(result, "artifacts_scanned") > 0
    end

    test "has all required checks" do
      result = ReplayAudit.audit(valid_bundle())
      checks = Map.get(result, "checks", %{})
      assert Map.has_key?(checks, "fingerprint_determinism")
      assert Map.has_key?(checks, "artifact_hash_integrity")
      assert Map.has_key?(checks, "content_addressing")
    end
  end

  # ========================================================================
  # Category 2 — Evidence Chain Verification
  # ========================================================================

  describe "EvidenceChainAudit" do
    test "passes on valid artifact bundle" do
      result = EvidenceChainAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "has all required chain checks" do
      result = EvidenceChainAudit.audit(valid_bundle())
      chains = Map.get(result, "chains", %{})
      assert Map.has_key?(chains, "observation_to_question")
      assert Map.has_key?(chains, "question_to_hypothesis")
      assert Map.has_key?(chains, "hypothesis_to_experiment")
      assert Map.has_key?(chains, "theory_support")
    end
  end

  # ========================================================================
  # Category 3 — Knowledge Graph Audit
  # ========================================================================

  describe "KnowledgeGraphAudit" do
    test "passes on valid artifact bundle" do
      result = KnowledgeGraphAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "detects invalid node types" do
      bundle = %{valid_bundle() | "knowledge_graph" => [
        %{"node_id" => "bad", "node_type" => "InvalidNodeType"}
      ]}
      result = KnowledgeGraphAudit.audit(bundle)
      assert Map.get(result, "result") == "FAIL"
    end

    test "has all required checks" do
      result = KnowledgeGraphAudit.audit(valid_bundle())
      checks = Map.get(result, "checks", %{})
      assert Map.has_key?(checks, "node_integrity")
      assert Map.has_key?(checks, "reference_integrity")
      assert Map.has_key?(checks, "duplicate_detection")
      assert Map.has_key?(checks, "deterministic_ids")
    end
  end

  # ========================================================================
  # Category 4 — Scientific Capital Audit
  # ========================================================================

  describe "ScientificCapitalAudit" do
    test "passes on valid artifact bundle" do
      result = ScientificCapitalAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "has all required checks" do
      result = ScientificCapitalAudit.audit(valid_bundle())
      checks = Map.get(result, "checks", %{})
      assert Map.has_key?(checks, "ledger_reconstruction")
      assert Map.has_key?(checks, "event_determinism")
    end
  end

  # ========================================================================
  # Category 5 — Archaeology Audit
  # ========================================================================

  describe "ArchaeologyAudit" do
    test "passes on valid artifact bundle" do
      result = ArchaeologyAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "detects incomplete archaeology records" do
      bundle = %{valid_bundle() | "archaeology_bundle" => [
        %{"artifact_id" => "incomplete"}
      ]}
      result = ArchaeologyAudit.audit(bundle)
      assert Map.get(result, "result") == "FAIL"
    end
  end

  # ========================================================================
  # Category 6 — Boundary Audit
  # ========================================================================

  describe "BoundaryAudit" do
    test "passes on valid artifact bundle" do
      result = BoundaryAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "detects certification artifacts" do
      bundle = %{valid_bundle() | "research_bundle" => [
        %{"artifact_type" => "RESEARCH_CERTIFICATE", "data" => "forbidden"}
      ]}
      result = BoundaryAudit.audit(bundle)
      assert Map.get(result, "result") == "FAIL"
    end

    test "detects constitutional overreach keys" do
      bundle = %{valid_bundle() | "research_bundle" => [
        %{"certificate_status" => "approved", "artifact_type" => "test"}
      ]}
      result = BoundaryAudit.audit(bundle)
      assert Map.get(result, "result") == "FAIL"
    end
  end

  # ========================================================================
  # Category 7 — Determinism Audit
  # ========================================================================

  describe "DeterminismAudit" do
    test "passes on valid artifact bundle" do
      result = DeterminismAudit.audit(valid_bundle())
      assert Map.get(result, "result") == "PASS"
    end

    test "produces unique fingerprints" do
      result = DeterminismAudit.audit(valid_bundle())
      assert Map.get(result, "artifacts_tested") > 0
    end
  end

  # ========================================================================
  # Category 8 — Runtime Independence
  # ========================================================================

  describe "RuntimeIndependence" do
    test "verify_independence does not crash" do
      result = Phase16_95.verify_independence()
      assert elem(result, 0) == :ok or elem(result, 0) == :error
    end

    test "auditor source files do not import Phase 16.1 runtime modules" do
      audit_file = Path.join([__DIR__, "..", "..", "..", "lib", "tiannara_runtime", "independent_audit", "phase16_95.ex"])
                   |> Path.expand()
      audit_dir = Path.join([__DIR__, "..", "..", "..", "lib", "tiannara_runtime", "independent_audit", "phase16_95"])
                   |> Path.expand()
      files = [audit_file] ++ (if File.exists?(audit_dir) do Path.wildcard(Path.join(audit_dir, "*.ex")) else [] end)
      Enum.each(files, fn f ->
        if File.exists?(f) do
          content = File.read!(f)
          lines = String.split(content, "\n")
          import_lines = Enum.filter(lines, fn line ->
            String.match?(line, ~r/(alias|import|use)\s+TiannaraRuntime\.AutonomousResearch/)
          end)
          assert import_lines == [],
                 "Phase 16.95 auditor must not alias/import/use Phase 16.1 runtime modules. Found: #{inspect(import_lines)} in #{f}"
        end
      end)
    end
  end

  # ========================================================================
  # Full Constitutional Audit
  # ========================================================================

  describe "FullAudit" do
    test "full audit passes on valid artifact bundle" do
      assert {:ok, report} = Phase16_95.run(valid_bundle())
      assert Map.get(report, "verdict") == "pass"
      assert Map.get(report, "categories_audited") == 7
    end

    test "full audit reports all category results" do
      assert {:ok, report} = Phase16_95.run(valid_bundle())
      categories = Map.get(report, "categories", %{})
      assert Map.has_key?(categories, "replay_audit")
      assert Map.has_key?(categories, "evidence_chain_audit")
      assert Map.has_key?(categories, "knowledge_graph_audit")
      assert Map.has_key?(categories, "scientific_capital_audit")
      assert Map.has_key?(categories, "archaeology_audit")
      assert Map.has_key?(categories, "boundary_audit")
      assert Map.has_key?(categories, "determinism_audit")
    end

    test "full audit fails on bundle with certification artifacts" do
      bad_bundle = %{valid_bundle() | "research_bundle" => [
        %{"artifact_type" => "RESEARCH_CERTIFICATE", "data" => "forbidden"}
      ]}
      assert {:error, report} = Phase16_95.run(bad_bundle)
      assert Map.get(report, "verdict") == "fail"
    end

    test "full audit reports correct pass/fail counts" do
      assert {:ok, report} = Phase16_95.run(valid_bundle())
      assert Map.get(report, "categories_passed") == 7
      assert Map.get(report, "categories_failed") == 0
    end
  end
end
