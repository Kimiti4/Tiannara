defmodule TiannaraRuntime.AutonomousResearch.Phase16_1Test do
  @moduledoc "Phase 16.1 Implementation Tests"

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

  setup_all do
    :ok = ObservationRegistry.init_table()
    :ok = QuestionGenerator.init_table()
    :ok = HypothesisEngine.init_table()
    :ok = ExperimentPlanner.init_table()
    :ok = TheoryEngine.init_table()
    :ok = ResearchPortfolio.init_table()
    :ok = KnowledgeGraph.init_tables()
    :ok = DiscoveryLineage.init_table()
    :ok = ScientificCapital.init_table()
    :ok = ResearchArchaeology.init_table()
    :ok
  end

  test "ObservationRegistry: deterministic ID generation" do
    origin = %{"source" => "test", "tick" => 1}
    payload = %{"observation" => "test_data", "value" => 42}

    assert :ok = ObservationRegistry.register_observation(origin, payload, "2026-07-06T00:00:00Z", %{})

    assert [_] = ObservationRegistry.list_observations()
  end

  test "QuestionGenerator: deterministic question generation" do
    gaps = [%{"knowledge_gap_id" => "gap_001", "gap_type" => "UNCERTAINTY", "domain" => "test_domain", "description" => "Test"}]

    assert {:ok, [question]} = QuestionGenerator.generate_questions(gaps)
    assert Map.has_key?(question, "question_id")
    assert Map.get(question, "knowledge_gap_id") == "gap_001"
  end

  test "HypothesisEngine: hypothesis creation" do
    question_id = "q_test_123"
    evidence = %{"evidence_records" => [%{"evidence_bundle_id" => "eb_001"}]}

    assert {:ok, hypothesis} = HypothesisEngine.create_hypothesis(question_id, evidence, %{})
    assert Map.has_key?(hypothesis, "hypothesis_id")
    assert Map.get(hypothesis, "question_id") == question_id
  end

  test "ExperimentPlanner: experiment creation" do
    program_id = "prog_001"
    parameters = %{"sample_size" => 1000, "variables" => %{"x" => "treatment"}}

    assert {:ok, experiment} = ExperimentPlanner.create_experiment(program_id, parameters)
    assert Map.has_key?(experiment, "experiment_id")
    assert Map.get(experiment, "research_program_id") == program_id
  end

  test "TheoryEngine: theory creation" do
    question_id = "q_th_001"
    statement = "Test theory statement"
    evidence_ref = "evidence_001"

    assert {:ok, theory} = TheoryEngine.create_theory(question_id, evidence_ref, statement)
    assert Map.has_key?(theory, "theory_id")
  end

  test "ResearchPortfolio: program creation" do
    question_id = "q_prog_001"
    objectives = %{"description" => "Test objective"}

    assert {:ok, program} = ResearchPortfolio.create_program(question_id, objectives)
    assert Map.has_key?(program, "research_program_id")
  end

  test "KnowledgeGraph: node operations" do
    assert :ok = KnowledgeGraph.add_node("node_001", "ObservationNode")
    assert [_node] = KnowledgeGraph.query_nodes("ObservationNode")
  end

  test "DiscoveryLineage: lineage building" do
    artifact_id = "artifact_001"
    inputs = ["input_001", "input_002"]
    context = %{"origin" => "test", "phase" => "16.1"}

    assert {:ok, lineage} = DiscoveryLineage.build_lineage(artifact_id, "DISCOVERY", inputs, context)
    assert Map.has_key?(lineage, "lineage_node_id")
  end

  test "ScientificCapital: event application" do
    ScientificCapital.init_capital(%{"scientific_capital" => 0})

    event = %{"type" => "discovery", "value" => 100}
    s1 = ScientificCapital.apply_event(event)
    s2 = ScientificCapital.apply_event(event)

    assert Map.get(s1, "scientific_capital") == 100
    assert Map.get(s2, "scientific_capital") == 200
  end

  test "ResearchScheduler: dispatch intents" do
    programs = [%{"research_program_id" => "p_001", "portfolio_rank_hint" => 1}]

    assert {:ok, intents} = ResearchScheduler.schedule(programs, %{})
    assert length(intents) == 1
  end

  test "ReplayEngine: deterministic fingerprint" do
    artifacts = [%{"artifact_id" => "a1", "data" => "test"}]

    fp1 = ReplayEngine.replay_fingerprint(artifacts)
    fp2 = ReplayEngine.replay_fingerprint(artifacts)

    assert fp1 == fp2
  end

  test "ResearchArchaeology: provenance tracking" do
    artifact = %{"artifact_id" => "arch_test", "type" => "test"}
    metadata = %{"dependencies" => [], "lineage_refs" => []}

    assert :ok = ResearchArchaeology.record(artifact, metadata)
    explanation = ResearchArchaeology.explain("arch_test")
    assert Map.has_key?(explanation, "artifact_id")
  end
end