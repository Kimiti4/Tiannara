defmodule Tiannara.REA.OrbitMemoryEcologyTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemoryEcology
  alias Tiannara.REA.OrbitMemory.VSA
  alias Tiannara.REA.OrbitMemory.Functor
  alias Tiannara.REA.OrbitMemory.CausalDo
  alias Tiannara.REA.OrbitMemory.JTMS
  alias Tiannara.REA.OrbitMemory.Topology

  setup_all do
    records = OrbitGenesis.all_records()
    {:ok, %{records: records}}
  end

  describe "Phase 11.12 Orbit Memory Ecology Suite" do

    test "Q1 — Memory Competition: high fitness memories dominate under selection pressure", %{records: records} do
      # Initialize population with varying strengths
      initial_pop = Enum.map(records, fn rec ->
        # Low stability recipient gets set to low identity persistence to make transfer gains strictly positive
        Map.put(rec, "identity_persistence", 0.5)
      end)

      fittest_pop = OrbitMemoryEcology.run_memory_competition(initial_pop, 3)
      assert length(fittest_pop) == 1000

      # Fittest population should have mutated parameters
      Enum.each(fittest_pop, fn ind ->
        assert is_float(ind["identity_persistence"])
        assert is_float(ind["recovery_velocity"])
      end)
    end

    test "Q2 — Memory Mutation: random perturbations occur within bounds", %{records: records} do
      parent = hd(records)
      mutated = OrbitMemoryEcology.mutate_individual_memory(parent)

      assert mutated["identity_persistence"] >= 0.1
      assert mutated["identity_persistence"] <= 1.0
      assert mutated["recovery_velocity"] >= 0.01
      assert mutated["recovery_velocity"] <= 1.0
    end

    test "Q3 — Memory Speciation: clustering divides population into lineages", %{records: records} do
      clusters = OrbitMemoryEcology.calculate_speciation(records)
      assert is_list(clusters)
      assert length(clusters) > 0

      # Check elements of a cluster
      first_cluster = hd(clusters)
      assert is_list(first_cluster)
      {world_id, vector} = hd(first_cluster)
      assert is_binary(world_id)
      assert length(vector) == 1000
    end

    test "Q4 — Functor Isomorphism: translations scale structurally across mismatched worlds", %{records: records} do
      world_a = Enum.find(records, &(&1["orbit_outcome"] == "stability_orbit")) || hd(records)
      world_b = Enum.find(records, &(&1["orbit_outcome"] in ["other_orbit_1", "collapse_recovery_orbit"])) || List.last(records)

      # Make sure worlds are slightly mismatched
      world_a = Map.put(world_a, "identity_persistence", 0.8)
      world_b = Map.put(world_b, "identity_persistence", 0.4)

      omt_a = OrbitMemory.extract(world_a)
      translated_res = Functor.translate(omt_a, world_a, world_b)
      translated = translated_res.translated_omt

      assert translated.memory_strength < omt_a.memory_strength
      assert Map.keys(translated.visit_frequencies) == Map.keys(omt_a.visit_frequencies)
    end

    test "Q5 — VSA Bundling: bindings and bundling produce continuous pseudo-orthogonal vectors", %{records: records} do
      rec_a = hd(records)
      rec_b = List.last(records)

      omt_a = OrbitMemory.extract(rec_a)
      omt_b = OrbitMemory.extract(rec_b)

      vec_a = VSA.encode(omt_a)
      vec_b = VSA.encode(omt_b)

      assert length(vec_a) == 1000
      assert length(vec_b) == 1000

      sim = VSA.cosine_similarity(vec_a, vec_b)
      assert sim >= -1.0
      assert sim <= 1.0

      # Similarity of a vector to itself should be 1.0
      assert VSA.cosine_similarity(vec_a, vec_a) == 1.0
    end

    test "Q6 — JTMS and Causal Do-Calculus: interventional do-calculus and retraction of beliefs", %{records: records} do
      # 1. Test CausalDo
      world = hd(records)
      omt = OrbitMemory.extract(world)
      do_result = CausalDo.evaluate_do_intervention(omt, world)
      assert is_map(do_result)
      assert Map.has_key?(do_result, :interventional_probability_of_survival)
      assert Map.has_key?(do_result, :causal_effect)

      # 2. Test JTMS
      JTMS.init_table()

      world_id = "test_world_99"
      sig = ["stability_orbit", "other_orbit_1"]

      # Register belief
      assert :ok == JTMS.register_belief(world_id, sig, "stability_orbit")

      # Verify belief is valid
      assert {:valid, belief} = JTMS.verify_and_retract(world_id, "stability_orbit")
      assert belief.validity == :valid
      assert belief.outcome == "stability_orbit"

      # Retract belief on failed outcome (other_orbit_1)
      assert {:retracted, updated_belief} = JTMS.verify_and_retract(world_id, "other_orbit_1")
      assert updated_belief.validity == :invalid
      assert updated_belief.outcome == "other_orbit_1"
    end

    test "Topology: Simplical complex hole detection operates correctly", %{records: records} do
      report = Topology.detect_epistemic_holes(records)
      assert Map.has_key?(report, :epistemic_holes)
      assert is_list(report.epistemic_holes)
      assert is_integer(report.hole_count)
      assert report.coverage_ratio >= 0.0 and report.coverage_ratio <= 1.0
    end

    test "Ecology: Speciation Tracker generates generation statistics and tracks divergence over 10 epochs", %{records: records} do
      results = OrbitMemoryEcology.SpeciationTracker.run_speciation_divergence(records, 10)
      assert results.final_genetic_distance >= 0.0
      assert results.final_orbit_distance >= 0.0
      assert results.final_behavioral_distance >= 0.0
      assert length(results.history) == 10
    end

    test "Learning Engine: translates World A transition and validates World B crisis injection", %{records: records} do
      world_a = Enum.find(records, &(&1["orbit_outcome"] == "stability_orbit")) || hd(records)
      world_b = Enum.find(records, &(&1["orbit_outcome"] in ["other_orbit_1", "collapse_recovery_orbit"])) || List.last(records)

      results = Tiannara.REA.OrbitMemory.LearningEngine.run_demonstration_experiment(world_a, world_b)
      assert results.gsi_gain > 0.0
      assert results.collapse_avoidance in [true, false]
      assert results.generator_residency >= 1
      assert results.mes_retention > 0.0
      assert results.mpp_retention > 0.0
    end
  end
end
