defmodule TiannaraRuntime.Mathematics.ConjectureEngineTest do
  @moduledoc "Phase 16.X.5 — Conjecture Engine tests: generation, sources, priority, clustering, replay, archaeology."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.ConjectureEngine

  # ---------------------------------------------------------------------------
  # Conjecture Generation
  # ---------------------------------------------------------------------------

  describe "generate_conjecture/2" do
    test "generates a conjecture with default source" do
      assert {:ok, c} = ConjectureEngine.generate_conjecture("Every group of order p^2 is abelian")
      assert c["status"] == "candidate"
      assert c["origin"] == "knowledge_gap"
      assert String.starts_with?(c["conjecture_id"], "conjecture_")
      assert is_number(c["priority"])
    end

    test "generates with custom source" do
      assert {:ok, c} = ConjectureEngine.generate_conjecture("Test", %{"source" => "pattern"})
      assert c["origin"] == "pattern"
    end

    test "rejects invalid source" do
      assert {:error, _} = ConjectureEngine.generate_conjecture("Test", %{"source" => "invalid_source"})
    end
  end

  describe "from_knowledge_gap/2" do
    test "generates from knowledge gap" do
      assert {:ok, c} = ConjectureEngine.from_knowledge_gap("All primes are odd")
      assert c["origin"] == "knowledge_gap"
    end
  end

  describe "from_repeated_structure/2" do
    test "generates from repeated structure" do
      assert {:ok, c} = ConjectureEngine.from_repeated_structure("Pattern in Fibonacci")
      assert c["origin"] == "repeated_structure"
    end
  end

  describe "from_incomplete_proof/2" do
    test "generates from incomplete proof" do
      assert {:ok, c} = ConjectureEngine.from_incomplete_proof("Missing case")
      assert c["origin"] == "incomplete_proof"
    end
  end

  describe "from_pattern/2" do
    test "generates from pattern" do
      assert {:ok, c} = ConjectureEngine.from_pattern("Observed periodicity")
      assert c["origin"] == "pattern"
    end
  end

  describe "from_generalization/2" do
    test "generates from generalization" do
      assert {:ok, c} = ConjectureEngine.from_generalization("Generalize to n-dimensions")
      assert c["origin"] == "generalization"
    end
  end

  describe "from_specialization/2" do
    test "generates from specialization" do
      assert {:ok, c} = ConjectureEngine.from_specialization("Specialize to dimension 3")
      assert c["origin"] == "specialization"
    end
  end

  describe "from_symmetry/2" do
    test "generates from symmetry" do
      assert {:ok, c} = ConjectureEngine.from_symmetry("Rotational invariance")
      assert c["origin"] == "symmetry"
    end
  end

  describe "from_counterexample/2" do
    test "generates from counterexample" do
      assert {:ok, c} = ConjectureEngine.from_counterexample("Counterexample to converse")
      assert c["origin"] == "counterexample"
    end
  end

  describe "from_human_input/2" do
    test "generates from human input" do
      assert {:ok, c} = ConjectureEngine.from_human_input("Researcher's insight")
      assert c["origin"] == "human_input"
    end
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  describe "validate_conjecture/1" do
    test "passes for well-formed conjecture" do
      {:ok, c} = ConjectureEngine.generate_conjecture("Test statement")
      assert {:ok, _} = ConjectureEngine.validate_conjecture(c)
    end

    test "fails for missing fields" do
      assert {:error, _} = ConjectureEngine.validate_conjecture(%{})
    end
  end

  # ---------------------------------------------------------------------------
  # Lifecycle
  # ---------------------------------------------------------------------------

  describe "transition/2" do
    test "transitions from candidate to validated" do
      {:ok, c} = ConjectureEngine.generate_conjecture("Test")
      assert {:ok, updated} = ConjectureEngine.transition(c, "validated")
      assert updated["status"] == "validated"
    end

    test "rejects invalid transition" do
      {:ok, c} = ConjectureEngine.generate_conjecture("Test")
      assert {:error, _} = ConjectureEngine.transition(c, "registered")
    end
  end

  describe "register_conjecture/1" do
    test "promotes validated conjecture to registered" do
      {:ok, c} = ConjectureEngine.generate_conjecture("Test")
      {:ok, validated} = ConjectureEngine.transition(c, "validated")
      assert {:ok, registered} = ConjectureEngine.register_conjecture(validated)
      assert registered["status"] == "registered"
    end
  end

  # ---------------------------------------------------------------------------
  # Priority Engine
  # ---------------------------------------------------------------------------

  describe "compute_priority/2" do
    test "returns a float between 0 and 1" do
      score = ConjectureEngine.compute_priority("Test")
      assert is_float(score)
      assert score >= 0.0 and score <= 1.0
    end

    test "higher novelty produces higher priority" do
      low = ConjectureEngine.compute_priority("Test", %{"novelty" => 0.1})
      high = ConjectureEngine.compute_priority("Test", %{"novelty" => 0.9})
      assert high > low
    end

    test "deterministic: same inputs produce same score" do
      opts = %{"novelty" => 0.7, "potential_impact" => 0.8, "proof_difficulty" => 0.3}
      assert ConjectureEngine.compute_priority("Test", opts) == ConjectureEngine.compute_priority("Test", opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Clustering
  # ---------------------------------------------------------------------------

  describe "assign_cluster/2" do
    test "uses cluster hint when valid" do
      assert ConjectureEngine.assign_cluster("any statement", %{"cluster_hint" => "topology"}) == "topology"
    end

    test "detects cluster from statement" do
      assert ConjectureEngine.assign_cluster("Group theory and algebra") == "algebra"
      assert ConjectureEngine.assign_cluster("Manifold topology") == "topology"
      assert ConjectureEngine.assign_cluster("Graph network") == "graph_theory"
    end
  end

  describe "cluster_by_domain/1" do
    test "groups conjectures by cluster" do
      {:ok, c1} = ConjectureEngine.generate_conjecture("Algebra statement", %{"source" => "pattern", "cluster_hint" => "algebra"})
      {:ok, c2} = ConjectureEngine.generate_conjecture("Topology statement", %{"source" => "pattern", "cluster_hint" => "topology"})
      {:ok, c3} = ConjectureEngine.generate_conjecture("Another algebra", %{"source" => "pattern", "cluster_hint" => "algebra"})

      assert {:ok, grouped} = ConjectureEngine.cluster_by_domain([c1, c2, c3])
      assert Map.has_key?(grouped, "algebra")
      assert Map.has_key?(grouped, "topology")
      assert length(grouped["algebra"]) == 2
    end
  end

  describe "valid_clusters/0" do
    test "returns all clusters" do
      clusters = ConjectureEngine.valid_clusters()
      assert "algebra" in clusters
      assert "topology" in clusters
      assert "category_theory" in clusters
      assert length(clusters) == 8
    end
  end

  describe "valid_sources/0" do
    test "returns all sources" do
      sources = ConjectureEngine.valid_sources()
      assert "knowledge_gap" in sources
      assert "human_input" in sources
      assert length(sources) == 9
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  describe "replay_conjecture/1" do
    test "replays conjecture deterministically" do
      {:ok, original} = ConjectureEngine.generate_conjecture("Every group of order p^2 is abelian", %{"source" => "knowledge_gap"})
      assert {:ok, replayed} = ConjectureEngine.replay_conjecture(original)
      assert replayed["conjecture_id"] == original["conjecture_id"]
      assert replayed["statement"] == original["statement"]
    end

    test "preserves status after replay" do
      {:ok, c} = ConjectureEngine.generate_conjecture("Test")
      {:ok, validated} = ConjectureEngine.transition(c, "validated")
      assert {:ok, replayed} = ConjectureEngine.replay_conjecture(validated)
      assert replayed["status"] == "validated"
    end
  end

  describe "replay_research_queue/1" do
    test "sorts by priority descending" do
      {:ok, c1} = ConjectureEngine.generate_conjecture("Low priority", %{"source" => "pattern", "novelty" => 0.1})
      {:ok, c2} = ConjectureEngine.generate_conjecture("High priority", %{"source" => "pattern", "novelty" => 0.9})

      assert {:ok, sorted} = ConjectureEngine.replay_research_queue([c1, c2])
      assert hd(sorted)["conjecture_id"] == c2["conjecture_id"]
    end
  end

  describe "research_queue/1" do
    test "returns conjectures sorted by priority" do
      {:ok, c1} = ConjectureEngine.generate_conjecture("A", %{"source" => "pattern", "novelty" => 0.1})
      {:ok, c2} = ConjectureEngine.generate_conjecture("B", %{"source" => "pattern", "novelty" => 0.9})
      assert {:ok, queue} = ConjectureEngine.research_queue([c1, c2])
      assert hd(queue)["conjecture_id"] == c2["conjecture_id"]
    end
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  describe "archaeology/1" do
    test "returns provenance record for well-formed conjecture" do
      {:ok, c} = ConjectureEngine.generate_conjecture("Test statement", %{"source" => "pattern"})
      assert {:ok, record} = ConjectureEngine.archaeology(c)
      assert record["conjecture_id"] == c["conjecture_id"]
      assert record["generated_why"]["origin"] == "pattern"
    end

    test "returns error for incomplete conjecture" do
      assert {:error, _} = ConjectureEngine.archaeology(%{})
    end
  end

  # ---------------------------------------------------------------------------
  # Metrics
  # ---------------------------------------------------------------------------

  describe "metrics/1" do
    test "returns aggregate metrics for conjecture set" do
      {:ok, c1} = ConjectureEngine.generate_conjecture("S1")
      {:ok, c2} = ConjectureEngine.generate_conjecture("S2")
      {:ok, c3} = ConjectureEngine.generate_conjecture("S3")

      m = ConjectureEngine.metrics([c1, c2, c3])
      assert m["conjecture_count"] == 3
      assert is_number(m["average_priority"])
      assert is_number(m["cluster_diversity"])
    end

    test "returns zero metrics for empty list" do
      m = ConjectureEngine.metrics([])
      assert m["conjecture_count"] == 0
      assert m["average_priority"] == 0.0
    end
  end
end
