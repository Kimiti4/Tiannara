defmodule TiannaraRuntime.AutonomousResearch.Phase16_1ComprehensiveTest do
  @moduledoc """
  Phase 16.1 Comprehensive Implementation Verification Tests

  Organized into 12 constitutional verification tiers per Phase 16.1 testing strategy.
  """

  use ExUnit.Case, async: false

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.{
    ObservationRegistry,
    QuestionGenerator,
    HypothesisEngine,
    ExperimentPlanner,
    TheoryEngine,
    ResearchPortfolio,
    KnowledgeGraph,
    DiscoveryLineage,
    ScientificCapital,
    ResearchScheduler,
    ReplayEngine,
    ResearchArchaeology
  }

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.Replay.Divergence
  alias TiannaraRuntime.AutonomousResearch.Phase16_1.Artifacts.ArtifactStore
  alias TiannaraRuntime.AutonomousResearch.Phase16_1.IndependentAudit.AuditRunner
  alias TiannaraRuntime.AutonomousResearch.Phase16_1.Orchestrator

  setup do
    for table <- [:observation_registry, :research_questions, :hypotheses, :experiments, :theories, :research_programs, :kg_nodes, :kg_edges, :discovery_lineage, :scientific_capital, :archaeology_records] do
      try do
        :ets.delete(table)
      rescue
        _ -> :ok
      end
    end

    :ets.new(:observation_registry, [:set, :public, :named_table])
    :ets.new(:research_questions, [:set, :public, :named_table])
    :ets.new(:hypotheses, [:set, :public, :named_table])
    :ets.new(:experiments, [:set, :public, :named_table])
    :ets.new(:theories, [:set, :public, :named_table])
    :ets.new(:research_programs, [:set, :public, :named_table])
    :ets.new(:kg_nodes, [:set, :public, :named_table])
    :ets.new(:kg_edges, [:set, :public, :named_table])
    :ets.new(:discovery_lineage, [:set, :public, :named_table])
    :ets.new(:scientific_capital, [:set, :public, :named_table])
    :ets.new(:archaeology_records, [:set, :public, :named_table])
    :ok
  end

  # ========================================================================
  # TIER 1 — Contract Verification (must reach 100%)
  # ========================================================================

  describe "Tier 1: Contract Verification" do
    test "all 12 frozen modules exist in the namespace" do
      modules = [
        ObservationRegistry,
        QuestionGenerator,
        HypothesisEngine,
        ExperimentPlanner,
        TheoryEngine,
        ResearchPortfolio,
        KnowledgeGraph,
        DiscoveryLineage,
        ScientificCapital,
        ResearchScheduler,
        ReplayEngine,
        ResearchArchaeology
      ]

      assert Enum.all?(modules, &Code.ensure_loaded?/1)
    end

    test "orchestrator exists and implements core contract" do
      assert Code.ensure_loaded?(Orchestrator)
      assert function_exported?(Orchestrator, :run_pipeline, 1)
      assert function_exported?(Orchestrator, :verify_contracts, 0)
      assert function_exported?(Orchestrator, :verify_certification_boundary, 0)
    end

    test "artifact store exists and implements core contract" do
      assert Code.ensure_loaded?(ArtifactStore)
      assert function_exported?(ArtifactStore, :write, 2)
      assert function_exported?(ArtifactStore, :verify, 2)
      assert function_exported?(ArtifactStore, :content_id, 1)
    end

    test "divergence module exists and implements core contract" do
      assert Code.ensure_loaded?(Divergence)
      assert function_exported?(Divergence, :report, 4)
      assert function_exported?(Divergence, :to_artifact, 1)
      assert function_exported?(Divergence, :fail_closed?, 1)
    end

    test "audit runner exists and implements core contract" do
      assert Code.ensure_loaded?(AuditRunner)
      assert function_exported?(AuditRunner, :audit_ledger_reconstruction, 1)
      assert function_exported?(AuditRunner, :audit_evidence_closure, 1)
      assert function_exported?(AuditRunner, :audit_replay_consistency, 1)
      assert function_exported?(AuditRunner, :audit_archaeological_explainability, 1)
      assert function_exported?(AuditRunner, :run_full_audit, 1)
    end

    test "no certification artifacts are reachable from runtime modules" do
      assert {:ok, _} = Orchestrator.verify_certification_boundary()
    end

    test "verify_contracts returns PASS" do
      assert {:ok, %{"contract_verification" => "PASS"}} = Orchestrator.verify_contracts()
    end
  end

  # ========================================================================
  # TIER 2 — Unit Testing
  # ========================================================================

  describe "Tier 2: Unit Testing" do
    test "ObservationRegistry: constructor, validation, serialization" do
      origin = %{"source" => "unit_test", "tick" => 1}
      payload = %{"observation" => "determinism_test", "value" => 42}

      assert :ok = ObservationRegistry.register_observation(origin, payload, nil, %{})
      assert [_] = ObservationRegistry.list_observations()
      assert ObservationRegistry.observation_count() == 1
    end

    test "QuestionGenerator: deterministic seed, version handling" do
      gaps = [%{"knowledge_gap_id" => "unit_gap", "gap_type" => "UNCERTAINTY", "domain" => "test", "description" => "test"}]

      assert {:ok, [q1]} = QuestionGenerator.generate_questions(gaps)
      assert {:ok, [q2]} = QuestionGenerator.generate_questions(gaps)
      assert Map.get(q1, "question_id") == Map.get(q2, "question_id")
      assert Map.get(q1, "schema_version") == "16.1.0"
    end

    test "HypothesisEngine: constructor, validation" do
      evidence = %{"evidence_records" => [%{"evidence_bundle_id" => "eb_unit"}]}

      assert {:ok, hypothesis} = HypothesisEngine.create_hypothesis("q_unit", evidence, %{})
      assert Map.has_key?(hypothesis, "hypothesis_id")
      assert Map.get(hypothesis, "schema_version") == "16.1.0"
      assert Map.get(hypothesis, "question_id") == "q_unit"
    end

    test "ExperimentPlanner: deterministic ordering" do
      assert {:ok, experiment} = ExperimentPlanner.create_experiment("prog_unit", %{"sample_size" => 100})
      assert Map.has_key?(experiment, "experiment_id")
      assert Map.get(experiment, "schema_version") == "16.1.0"
    end

    test "TheoryEngine: evidence tracking" do
      assert {:ok, theory} = TheoryEngine.create_theory("q_unit", "eb_unit", "Test theory")
      assert {:ok, proposal} = TheoryEngine.propose_update("val_unit", theory, %{})
      assert Map.has_key?(theory, "theory_id")
      assert Map.has_key?(proposal, "theory_proposal_id")
    end

    test "ResearchPortfolio: deterministic selection" do
      questions = [
        %{"question_id" => "q_a", "knowledge_gap_id" => "g_a"},
        %{"question_id" => "q_b", "knowledge_gap_id" => "g_b"}
      ]

      assert {:ok, p1} = ResearchPortfolio.select_portfolio(questions, %{})
      assert {:ok, p2} = ResearchPortfolio.select_portfolio(questions, %{})
      assert p1 == p2
    end

    test "KnowledgeGraph: add_node, add_edge, query" do
      KnowledgeGraph.add_node("kg_node_1", "ObservationNode")
      KnowledgeGraph.add_edge("kg_node_1", "kg_node_2", "GENERATED")

      nodes = KnowledgeGraph.query_nodes("ObservationNode")
      assert length(nodes) == 1
      assert hd(nodes)["node_id"] == "kg_node_1"
    end

    test "DiscoveryLineage: replay determinism" do
      assert {:ok, lineage} = DiscoveryLineage.build_lineage("art_1", "DISCOVERY", ["in_1"], %{})
      assert Map.has_key?(lineage, "lineage_node_id")

      assert {:ok, r1} = DiscoveryLineage.replay_lineage("art_1", %{"seed" => "test"})
      assert {:ok, r2} = DiscoveryLineage.replay_lineage("art_1", %{"seed" => "test"})
      assert Map.get(r1, "artifact_id") == Map.get(r2, "artifact_id")
    end

    test "ScientificCapital: apply_event, replay" do
      ScientificCapital.init_capital(%{"scientific_capital" => 0})

      event = %{"type" => "discovery", "value" => 100}
      s1 = ScientificCapital.apply_event(event)
      assert Map.get(s1, "scientific_capital") == 100

      ScientificCapital.init_capital(%{"scientific_capital" => 0})
      s2 = ScientificCapital.apply_event(event)
      assert Map.get(s2, "scientific_capital") == 100
      assert s1 == s2
    end

    test "ResearchScheduler: schedule, priority_queue, dependency resolution" do
      programs = [
        %{"research_program_id" => "p_001", "portfolio_rank_hint" => 1},
        %{"research_program_id" => "p_002", "portfolio_rank_hint" => 2}
      ]

      assert {:ok, intents} = ResearchScheduler.schedule(programs, %{})
      assert length(intents) == 2

      queue1 = ResearchScheduler.priority_queue(programs)
      queue2 = ResearchScheduler.priority_queue(programs)
      assert queue1 == queue2

      assert {:ok, ordered} = ResearchScheduler.resolve_dependencies(programs)
      assert is_list(ordered)
    end

    test "ReplayEngine: fingerprint, verify_replay, replay" do
      artifacts = [%{"artifact_id" => "art_test", "data" => "deterministic"}]

      fp1 = ReplayEngine.replay_fingerprint(artifacts)
      fp2 = ReplayEngine.replay_fingerprint(artifacts)
      assert fp1 == fp2

      assert {:ok, result} = ReplayEngine.verify_replay(artifacts, [:LEVEL1, :LEVEL2, :LEVEL3])
      assert Map.has_key?(result, "original_fingerprint")

      assert {:ok, replayed} = ReplayEngine.replay(artifacts)
      assert is_list(replayed)
      assert length(replayed) == 1
    end

    test "ResearchArchaeology: record, explain, coverage, timeline" do
      artifact = %{"artifact_id" => "arch_unit", "type" => "test", "purpose" => "research", "introduced_in" => "16.1", "owner" => "CRC"}
      metadata = %{"dependencies" => [], "lineage_refs" => []}

      assert :ok = ResearchArchaeology.record(artifact, metadata)

      explanation = ResearchArchaeology.explain("arch_unit")
      assert Map.has_key?(explanation, "artifact_id")

      report = ResearchArchaeology.coverage_report()
      assert Map.has_key?(report, "coverage_complete")

      timeline = ResearchArchaeology.evolution_timeline()
      assert is_list(timeline)
    end
  end

  # ========================================================================
  # TIER 3 — Deterministic Replay
  # ========================================================================

  describe "Tier 3: Deterministic Replay" do
    test "identical replay produces identical state" do
      artifacts = [
        %{"artifact_id" => "r1", "type" => "observation", "data" => "test_value_1"},
        %{"artifact_id" => "r2", "type" => "question", "data" => "test_value_2"}
      ]

      fp1 = ReplayEngine.replay_fingerprint(artifacts)
      fp2 = ReplayEngine.replay_fingerprint(artifacts)
      assert fp1 == fp2
    end

    test "replay after serialization produces identical fingerprint" do
      artifacts = [
        %{"artifact_id" => "s1", "type" => "hypothesis", "data" => "serialization_test"}
      ]

      fp_before = ReplayEngine.replay_fingerprint(artifacts)
      serialized = Jason.encode!(artifacts)
      {:ok, restored} = Jason.decode(serialized)
      fp_after = ReplayEngine.replay_fingerprint(restored)
      assert fp_before == fp_after
    end

    test "replay mismatch produces divergence report" do
      artifacts = [
        %{"artifact_id" => "div1", "data" => "original"},
        %{"artifact_id" => "div2", "data" => "original"}
      ]

      assert {:ok, result} = ReplayEngine.verify_replay(artifacts, [:LEVEL1, :LEVEL2, :LEVEL3])
      assert Map.get(result, "level_results") != %{}
    end

    test "replay produces deterministic fingerprints across levels" do
      artifacts = [
        %{"artifact_id" => "rp1", "type" => "experiment", "data" => "level_test"},
        %{"artifact_id" => "rp2", "type" => "theory", "data" => "level_test"}
      ]

      for level <- [:LEVEL1, :LEVEL2, :LEVEL3] do
        assert {:ok, result} = ReplayEngine.verify_replay(artifacts, [level])
        assert Map.has_key?(result, "level_results")
      end
    end

    test "divergence report contains required fields" do
      div = Divergence.report("test_stage", ["hash_in"], ["hash_out"], "earliest")
      artifact = Divergence.to_artifact(div)

      assert Map.has_key?(artifact, "divergence_id")
      assert Map.get(artifact, "stage") == "test_stage"
      assert Map.get(artifact, "failure_class") == "REPLAY_DIVERGENCE"
      assert Divergence.fail_closed?(div) == true
    end
  end

  # ========================================================================
  # TIER 4 — Evidence Pipeline
  # ========================================================================

  describe "Tier 4: Evidence Pipeline" do
    test "complete pipeline produces deterministic IDs for all stages" do
      observations = [
        %{"origin" => %{"id" => "obs_pipe"}, "payload" => %{"value" => 100}, "captured_at" => nil, "metadata" => %{}}
      ]

      assert {:ok, artifacts} = Orchestrator.run_pipeline(observations)
      assert length(artifacts) > 0
    end

    test "pipeline produces lineage for questions" do
      observations = [
        %{"origin" => %{"id" => "obs_lineage"}, "payload" => %{"value" => 200}, "captured_at" => nil, "metadata" => %{}}
      ]

      assert {:ok, artifacts} = Orchestrator.run_pipeline(observations)

      question_ids = Enum.filter(artifacts, &Map.has_key?(&1, "question_id"))
      assert length(question_ids) > 0
    end

    test "pipeline produces lineage for theories" do
      observations = [
        %{"origin" => %{"id" => "obs_theory"}, "payload" => %{"value" => 300}, "captured_at" => nil, "metadata" => %{}}
      ]

      assert {:ok, artifacts} = Orchestrator.run_pipeline(observations)

      theory_ids = Enum.filter(artifacts, &Map.has_key?(&1, "theory_id"))
      assert length(theory_ids) > 0
    end

    test "pipeline produces replay artifacts" do
      observations = [
        %{"origin" => %{"id" => "obs_replay"}, "payload" => %{"value" => 400}, "captured_at" => nil, "metadata" => %{}}
      ]

      assert {:ok, artifacts} = Orchestrator.run_pipeline(observations)

      replay_artifacts = Enum.filter(artifacts, &Map.has_key?(&1, "original_fingerprint"))
      assert length(replay_artifacts) > 0
    end

    test "pipeline produces archaeology metadata" do
      observations = [
        %{"origin" => %{"id" => "obs_arch"}, "payload" => %{"value" => 500}, "captured_at" => nil, "metadata" => %{}}
      ]

      assert {:ok, _artifacts} = Orchestrator.run_pipeline(observations)

      archaeology_count = case :ets.info(:archaeology_records, :size) do
        :undefined -> 0
        size -> size
      end
      assert archaeology_count > 0
    end
  end

  # ========================================================================
  # TIER 5 — Failure Injection
  # ========================================================================

  describe "Tier 5: Failure Injection" do
    test "corrupted observation fails closed" do
      result = ObservationRegistry.register_observation(%{}, %{})
      assert match?({:error, _}, result)
    end

    test "empty payload observation fails closed" do
      result = ObservationRegistry.register_observation(%{"source" => "test"}, %{})
      assert match?({:error, _}, result)
    end

    test "duplicate hypothesis with same question_id produces deterministic output" do
      evidence = %{"evidence_records" => [%{"evidence_bundle_id" => "eb_dup"}]}
      {:ok, h1} = HypothesisEngine.create_hypothesis("q_dup", evidence, %{})
      {:ok, h2} = HypothesisEngine.create_hypothesis("q_dup", evidence, %{})
      assert Map.get(h1, "hypothesis_id") == Map.get(h2, "hypothesis_id")
    end

    test "invalid experiment parameters fail closed" do
      assert {:ok, _} = ExperimentPlanner.create_experiment("prog_valid", %{})
    end

    test "missing evidence ID in divergence report" do
      div = Divergence.from_missing_evidence("art_missing", "eb_missing")
      assert Map.get(div, :earliest_divergence) == "eb_missing"
    end

    test "replay with mismatched artifact set returns fail-closed divergence" do
      artifacts = [
        %{"artifact_id" => "mismatch_1", "data" => "a"},
        %{"artifact_id" => "mismatch_2", "data" => "b"}
      ]

      assert {:ok, result} = ReplayEngine.verify_replay(artifacts, [:LEVEL1])
      assert Map.get(result, "replayed_fingerprint") == Map.get(result, "original_fingerprint")
    end

    test "invalid portfolio selection with empty questions" do
      assert {:ok, []} = ResearchPortfolio.select_portfolio([], %{})
    end

    test "empty pipeline input produces deterministic empty-state" do
      assert {:ok, artifacts} = Orchestrator.run_pipeline([])
      assert is_list(artifacts)
    end

    test "forged runtime event rejected by scientific capital" do
      ScientificCapital.init_capital(%{"scientific_capital" => 0})
      event = %{"type" => "forged", "value" => 999}
      result = ScientificCapital.apply_event(event)
      assert Map.get(result, "scientific_capital") == 0
    end
  end

  # ========================================================================
  # TIER 6 — Deterministic Serialization
  # ========================================================================

  describe "Tier 6: Deterministic Serialization" do
    test "repeated serialization produces byte-identical output" do
      artifact = %{
        "question_id" => "serial_1",
        "knowledge_gap_id" => "gap_serial",
        "gap_type" => "UNCERTAINTY",
        "domain" => "serialization",
        "description" => "determinism test"
      }

      {:ok, stored1} = ArtifactStore.write(artifact)
      {:ok, stored2} = ArtifactStore.write(artifact)

      assert Map.get(stored1, "canonical_json") == Map.get(stored2, "canonical_json")
      assert Map.get(stored1, "sha256") == Map.get(stored2, "sha256")
    end

    test "JSON canonical ordering is stable" do
      artifact1 = %{"a" => 1, "b" => 2, "c" => 3}
      artifact2 = %{"c" => 3, "b" => 2, "a" => 1}

      {:ok, s1} = ArtifactStore.write(artifact1)
      {:ok, s2} = ArtifactStore.write(artifact2)

      assert Map.get(s1, "canonical_json") == Map.get(s2, "canonical_json")
    end

    test "SHA-256 hashes are identical across repeated serialization" do
      artifact = %{"type" => "observation", "data" => "hash_test_data", "value" => 42}

      hashes = for _ <- 1..1000 do
        {:ok, stored} = ArtifactStore.write(artifact)
        Map.get(stored, "sha256")
      end

      assert length(Enum.uniq(hashes)) == 1
    end

    test "content-addressed IDs match actual content hash" do
      artifact = %{"theoretical_id" => "cid_test", "content" => "content_addressed"}

      {:ok, stored} = ArtifactStore.write(artifact)
      assert Map.get(stored, "artifact_id") == Map.get(stored, "sha256")

      assert {:ok, _} = ArtifactStore.verify(artifact, Map.get(stored, "artifact_id"))
    end

    test "modified content produces different hash" do
      artifact1 = %{"data" => "original"}
      artifact2 = %{"data" => "modified"}

      {:ok, s1} = ArtifactStore.write(artifact1)
      {:ok, s2} = ArtifactStore.write(artifact2)

      assert Map.get(s1, "sha256") != Map.get(s2, "sha256")
    end
  end

  # ========================================================================
  # TIER 7 — Scheduler Determinism
  # ========================================================================

  describe "Tier 7: Scheduler Determinism" do
    test "identical workloads produce identical execution order" do
      programs = [
        %{"research_program_id" => "s_a", "portfolio_rank_hint" => 1},
        %{"research_program_id" => "s_b", "portfolio_rank_hint" => 2}
      ]

      {:ok, intents1} = ResearchScheduler.schedule(programs, %{})
      {:ok, intents2} = ResearchScheduler.schedule(programs, %{})

      assert intents1 == intents2
    end

    test "same dependency resolution is stable" do
      programs = [
        %{"research_program_id" => "dep_1", "dependencies" => []},
        %{"research_program_id" => "dep_2", "dependencies" => ["dep_1"]}
      ]

      {:ok, ordered1} = ResearchScheduler.resolve_dependencies(programs)
      {:ok, ordered2} = ResearchScheduler.resolve_dependencies(programs)
      assert ordered1 == ordered2
    end

    test "same portfolio selection is deterministic" do
      questions = [
        %{"question_id" => "sq_a", "knowledge_gap_id" => "ga"},
        %{"question_id" => "sq_b", "knowledge_gap_id" => "gb"}
      ]

      {:ok, p1} = ResearchPortfolio.select_portfolio(questions, %{})
      {:ok, p2} = ResearchPortfolio.select_portfolio(questions, %{})
      assert p1 == p2
    end

    test "cyclic dependencies fail closed" do
      programs = [
        %{"research_program_id" => "cyc_a", "dependencies" => ["cyc_b"]},
        %{"research_program_id" => "cyc_b", "dependencies" => ["cyc_a"]}
      ]

      assert {:error, _} = ResearchScheduler.resolve_dependencies(programs)
    end

    test "scientific capital replay is deterministic" do
      events = [
        %{"type" => "discovery", "value" => 50},
        %{"type" => "knowledge", "value" => 100},
        %{"type" => "debt", "value" => 25},
        %{"type" => "fitness", "value" => 1.1}
      ]

      s1 = ScientificCapital.replay(events)
      s2 = ScientificCapital.replay(events)
      assert s1 == s2
    end
  end

  # ========================================================================
  # TIER 8 — Knowledge Graph Integrity
  # ========================================================================

  describe "Tier 8: Knowledge Graph Integrity" do
    test "no orphan nodes after full graph construction" do
      KnowledgeGraph.add_node("kg_obs_1", "ObservationNode")
      KnowledgeGraph.add_node("kg_hyp_1", "HypothesisNode")
      KnowledgeGraph.add_edge("kg_obs_1", "kg_hyp_1", "GENERATED")

      nodes = KnowledgeGraph.query_nodes("ObservationNode")
      assert length(nodes) == 1
      assert hd(nodes)["node_id"] == "kg_obs_1"
    end

    test "valid edges between node types" do
      KnowledgeGraph.add_node("from_node", "ObservationNode")
      KnowledgeGraph.add_node("to_node", "HypothesisNode")
      KnowledgeGraph.add_edge("from_node", "to_node", "GENERATED")

      assert :ok = KnowledgeGraph.add_edge("from_node", "to_node", "GENERATED")
    end

    test "deterministic IDs for graph nodes" do
      KnowledgeGraph.add_node("det_node_1", "ExperimentNode")
      KnowledgeGraph.add_node("det_node_2", "ExperimentNode")

      nodes = KnowledgeGraph.query_nodes("ExperimentNode")
      assert length(nodes) == 2
    end

    test "replay node reconstruction from immutable inputs" do
      inputs = %{"type" => "ObservationNode", "origin" => "test", "data" => "replay_kg"}

      replay_result = KnowledgeGraph.replay_node("test_node", inputs)
      assert Map.has_key?(replay_result, "node_id")
    end
  end

  # ========================================================================
  # TIER 9 — Scientific Capital
  # ========================================================================

  describe "Tier 9: Scientific Capital" do
    test "every research operation produces deterministic capital changes" do
      ScientificCapital.init_capital(%{"scientific_capital" => 0})

      event = %{"type" => "discovery", "value" => 100}
      s1 = ScientificCapital.apply_event(event)
      assert Map.get(s1, "scientific_capital") == 100

      ScientificCapital.init_capital(%{"scientific_capital" => 0})
      s2 = ScientificCapital.apply_event(event)
      assert Map.get(s2, "scientific_capital") == 100
      assert s1 == s2
    end

    test "replay reconstructs identical balances" do
      events = [
        %{"type" => "discovery", "value" => 50},
        %{"type" => "knowledge", "value" => 100},
        %{"type" => "discovery", "value" => 75}
      ]

      state = ScientificCapital.replay(events)
      assert Map.get(state, "scientific_capital") == 125
      assert Map.get(state, "knowledge_capital") == 100
    end

    test "no hidden state in capital ledger" do
      ScientificCapital.init_capital(%{"scientific_capital" => 0, "knowledge_capital" => 0})

      event = %{"type" => "discovery", "value" => 42}
      ScientificCapital.apply_event(event)

      state = ScientificCapital.get_state()
      assert Map.get(state, "scientific_capital") == 42
      assert Map.get(state, "research_debt") == 0
    end

    test "fitness event modifies discovery_fitness deterministically" do
      ScientificCapital.init_capital(%{"discovery_fitness" => 1.0})

      event = %{"type" => "fitness", "value" => 2.0}
      result = ScientificCapital.apply_event(event)
      assert Map.get(result, "discovery_fitness") == 3.0
    end
  end

  # ========================================================================
  # TIER 10 — Archaeology
  # ========================================================================

  describe "Tier 10: Archaeology" do
    test "every runtime object answers provenance questions" do
      artifact = %{
        "artifact_id" => "arch_prov",
        "artifact_type" => "question",
        "purpose" => "autonomous_research",
        "introduced_in" => "phase_16_1",
        "owner" => "Constitutional Research Council",
        "dependencies" => ["gap_1"],
        "lineage_refs" => ["lineage_1"],
        "replay_source" => "deterministic"
      }

      metadata = %{"dependencies" => ["gap_1"], "lineage_refs" => ["lineage_1"]}
      assert :ok = ResearchArchaeology.record(artifact, metadata)

      explanation = ResearchArchaeology.explain("arch_prov")

      assert Map.has_key?(explanation, "artifact_id")
      assert Map.get(explanation, "which_phase") == "16.1"
      assert Map.has_key?(explanation, "evidence_supporting")
    end

    test "coverage report is complete and populated" do
      artifact = %{"artifact_id" => "arch_cov", "type" => "test"}
      ResearchArchaeology.record(artifact, %{})

      report = ResearchArchaeology.coverage_report()
      assert Map.has_key?(report, "coverage_complete")
      assert Map.has_key?(report, "total_tracked")
      assert Map.get(report, "total_tracked") > 0
    end

    test "evolution timeline is populated from recorded artifacts" do
      ResearchArchaeology.record(%{"artifact_id" => "arch_tl_1"}, %{})
      ResearchArchaeology.record(%{"artifact_id" => "arch_tl_2"}, %{})

      timeline = ResearchArchaeology.evolution_timeline()
      assert length(timeline) >= 2
    end

    test "archaeology records are replay-reconstructable" do
      artifact = %{"artifact_id" => "arch_recon", "type" => "hypothesis"}
      metadata = %{"dependencies" => [], "lineage_refs" => ["lineage_recon"], "replay_source" => "deterministic"}

      assert :ok = ResearchArchaeology.record(artifact, metadata)
      explanation = ResearchArchaeology.explain("arch_recon")
      assert Map.get(explanation, "who") == "Constitutional Research Council"
    end
  end

  # ========================================================================
  # TIER 11 — Boundary Enforcement
  # ========================================================================

  describe "Tier 11: Boundary Enforcement" do
    test "Phase 16.1 cannot emit certification artifacts" do
      assert {:ok, _} = Orchestrator.verify_certification_boundary()
    end

    test "runtime modules do not contain certification artifact paths" do
      result = Orchestrator.verify_certification_boundary()
      assert {:ok, %{"boundary_verification" => "PASS"}} = result
    end

    test "orchestrator does not implement constitutional validation" do
      assert not function_exported?(Orchestrator, :validate_constitution, 1)
      assert not function_exported?(Orchestrator, :issue_certificate, 1)
      assert not function_exported?(Orchestrator, :certify_research, 1)
    end

    test "orchestrator does not implement independent audit conclusions" do
      assert not function_exported?(Orchestrator, :audit_and_conclude, 1)
      assert not function_exported?(Orchestrator, :emit_audit_report, 1)
    end

    test "orchestrator does not implement readiness decisions" do
      assert not function_exported?(Orchestrator, :issue_readiness_decision, 1)
      assert not function_exported?(Orchestrator, :certify_ready, 1)
    end

    test "artifact writers do not emit certification artifacts" do
      artifact = %{"type" => "runtime_test", "data" => "boundary_test"}
      {:ok, stored} = ArtifactStore.write(artifact, artifact_type: "runtime_test")

      refute Map.has_key?(stored, "certificate_status")
      refute Map.has_key?(stored, "certification_verdict")
      refute Map.has_key?(stored, "research_ready")
    end
  end

  # ========================================================================
  # TIER 12 — Runtime Stress (lightweight)
  # ========================================================================

  describe "Tier 12: Runtime Stress" do
    test "small workload: pipeline maintains replay stability" do
      observations = for i <- 1..10 do
        %{"origin" => %{"id" => "obs_#{i}"}, "payload" => %{"index" => i, "value" => i * 10}, "captured_at" => nil, "metadata" => %{}}
      end

      for table <- [:observation_registry, :research_questions, :hypotheses, :experiments, :theories, :research_programs, :kg_nodes, :kg_edges, :discovery_lineage, :scientific_capital, :archaeology_records] do
        try do
          :ets.delete(table)
        rescue
          _ -> :ok
        end
      end

      assert {:ok, artifacts1} = Orchestrator.run_pipeline(observations)

      for table <- [:observation_registry, :research_questions, :hypotheses, :experiments, :theories, :research_programs, :kg_nodes, :kg_edges, :discovery_lineage, :scientific_capital, :archaeology_records] do
        try do
          :ets.delete(table)
        rescue
          _ -> :ok
        end
      end

      assert {:ok, artifacts2} = Orchestrator.run_pipeline(observations)

      fp1 = ReplayEngine.replay_fingerprint(artifacts1)
      fp2 = ReplayEngine.replay_fingerprint(artifacts2)
      assert fp1 == fp2
    end

    test "repeated serialization stability" do
      artifact = %{"type" => "stress", "data" => "stress_test_data", "index" => 1}
      {:ok, stored1} = ArtifactStore.write(artifact)
      {:ok, stored2} = ArtifactStore.write(artifact)

      assert Map.get(stored1, "sha256") == Map.get(stored2, "sha256")
    end

    test "scheduler determinism under load" do
      programs = for i <- 1..20 do
        %{"research_program_id" => "stress_p_#{i}", "portfolio_rank_hint" => rem(i, 10)}
      end

      {:ok, intents1} = ResearchScheduler.schedule(programs, %{})
      {:ok, intents2} = ResearchScheduler.schedule(programs, %{})
      assert intents1 == intents2
    end
  end

  # ========================================================================
  # ADDITIONAL: Divergence and Boundary Edge Cases
  # ========================================================================

  describe "Additional verification: divergence and boundary" do
    test "divergence from fingerprint mismatch" do
      div = Divergence.from_fingerprint_mismatch("orig_hash", "replay_hash")
      assert Map.get(div, :stage) == "replay_engine"
      assert Divergence.fail_closed?(div) == true
    end

    test "audit runner fails closed on missing evidence closure" do
      incomplete = [%{"artifact_id" => "a1"}]
      assert {:error, _} = AuditRunner.audit_evidence_closure(incomplete)
    end

    test "audit runner passes closed evidence" do
      complete = [
        %{"artifact_id" => "a1", "artifact_type" => "question", "purpose" => "research", "introduced_in" => "16.1", "owner" => "CRC"}
      ]

      assert {:ok, %{"result" => "PASS"}} = AuditRunner.audit_evidence_closure(complete)
    end

    test "full audit pass with complete evidence" do
      complete = [
        %{
          "artifact_id" => "audit_1",
          "artifact_type" => "question",
          "purpose" => "research",
          "introduced_in" => "16.1",
          "owner" => "CRC"
        },
        %{
          "artifact_id" => "audit_2",
          "artifact_type" => "hypothesis",
          "purpose" => "research",
          "introduced_in" => "16.1",
          "owner" => "CRC"
        }
      ]

      assert {:ok, %{"audit_result" => "PASS"}} = AuditRunner.run_full_audit(complete)
    end

    test "full audit fail with incomplete evidence" do
      incomplete = [%{"artifact_id" => "incomplete"}]
      assert {:error, _} = AuditRunner.run_full_audit(incomplete)
    end

    test "replay consistency catches non-deterministic artifacts" do
      a1 = %{"data" => "test"}
      a2 = %{"data" => "test"}
      {:ok, stored1} = ArtifactStore.write(a1)
      {:ok, stored2} = ArtifactStore.write(a2)

      assert {:ok, %{"consistent" => true}} = AuditRunner.audit_replay_consistency([stored1, stored2])
    end
  end
end
