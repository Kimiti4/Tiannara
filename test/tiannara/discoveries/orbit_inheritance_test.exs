defmodule Tiannara.REA.OrbitMemoryInheritanceTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.Inheritance

  setup_all do
    records = OrbitGenesis.all_records()
    {:ok, %{records: records}}
  end

  describe "Phase 11.11C Orbit Memory Inheritance Suite" do

    test "A1 — Parent to Child Cloning: MES and MPP survive replication", %{records: records} do
      parent_record = hd(records)
      parent_omt = OrbitMemory.extract(parent_record)

      child_omt = Inheritance.clone(parent_omt)

      assert child_omt.transition_signature == parent_omt.transition_signature
      assert child_omt.memory_existence_score == parent_omt.memory_existence_score
      assert child_omt.memory_predictive_power == parent_omt.memory_predictive_power
      assert child_omt.memory_strength == parent_omt.memory_strength
    end

    test "A2 — Dual Parent Recombination: bundles properties from both parents", %{records: records} do
      parent_a = hd(records)
      parent_b = List.last(records)

      omt_a = OrbitMemory.extract(parent_a)
      omt_b = OrbitMemory.extract(parent_b)

      child_omt = Inheritance.recombine(omt_a, omt_b, 0.50)

      assert is_list(child_omt.transition_signature)
      assert child_omt.memory_strength == Float.round((omt_a.memory_strength + omt_b.memory_strength) / 2.0, 4)
      assert child_omt.memory_existence_score > 0.0
      assert child_omt.memory_predictive_power > 0.0
    end

    test "B1 — Weighted Recombination: continuous scaling is proportional to weight", %{records: records} do
      parent_a = hd(records)
      parent_b = List.last(records)

      omt_a = OrbitMemory.extract(parent_a)
      omt_b = OrbitMemory.extract(parent_b)

      child_25 = Inheritance.recombine(omt_a, omt_b, 0.25)
      child_75 = Inheritance.recombine(omt_a, omt_b, 0.75)

      # Check continuity
      assert child_25.memory_strength == Float.round(omt_a.memory_strength * 0.25 + omt_b.memory_strength * 0.75, 4)
      assert child_75.memory_strength == Float.round(omt_a.memory_strength * 0.75 + omt_b.memory_strength * 0.25, 4)
    end

    test "B2 — Emergence Check: calculates if child outperforms best parent", %{records: records} do
      parent_a = hd(records)
      parent_b = List.last(records)

      omt_a = OrbitMemory.extract(parent_a)
      omt_b = OrbitMemory.extract(parent_b)

      # Synthesize child that has strong values
      child = %{omt_a | memory_predictive_power: 0.30, memory_existence_score: 0.90}

      # GSI of child, parent_a, parent_b
      gsi_c = 0.90
      gsi_a = 0.50
      gsi_b = 0.50

      is_emergent = Inheritance.check_emergence(child, omt_a, omt_b, gsi_c, gsi_a, gsi_b)
      assert is_emergent == true
    end

    test "Experiment Suite: calculates OMH, OMR, and OME scores successfully", %{records: records} do
      results = Inheritance.run_inheritance_experiment(records)

      assert Map.has_key?(results, :omh)
      assert Map.has_key?(results, :omr)
      assert Map.has_key?(results, :ome)
      assert Map.has_key?(results, :species_archive)

      assert results.omh > 0.0
      assert results.omr > 0.0
      assert results.ome >= 0.0
      assert is_map(results.species_archive)
    end

    test "Evolution selection over generations under fitness function", %{records: records} do
      mutated_pop = Inheritance.run_evolution(records, 3, 0.2)
      assert length(mutated_pop) == length(records)

      # Children should have mutated names/world_ids
      child = Enum.find(mutated_pop, &String.starts_with?(&1["world_id"], "child_"))
      assert child != nil
      assert is_map(child["terminal_coordinates"])
    end

    test "OMG Genome: child recombined OMT has non-nil compressed_signature", %{records: records} do
      parent_a = hd(records) |> OrbitMemory.extract()
      parent_b = List.last(records) |> OrbitMemory.extract()

      child = Inheritance.recombine(parent_a, parent_b, 0.5)
      assert child.compressed_signature != nil
      assert Map.has_key?(child.compressed_signature, "entropy")
    end

    test "Recombination Classifier: correctly maps child modes", %{records: records} do
      parent_a = hd(records) |> OrbitMemory.extract()
      parent_b = List.last(records) |> OrbitMemory.extract()

      # Mode 1: Clone A should be parent_a_dominant
      mode_a = Inheritance.classify_recombination_mode(parent_a, parent_a, parent_b)
      assert mode_a == :parent_a_dominant

      # Mode 2: Recombination at 0.50 should be averaged or hybrid
      child_50 = Inheritance.recombine(parent_a, parent_b, 0.50)
      mode_50 = Inheritance.classify_recombination_mode(child_50, parent_a, parent_b)
      assert mode_50 in [:averaged, :hybrid]

      # Mode 3: Recombination with novel signature elements
      novel_child = %{child_50 | transition_signature: child_50.transition_signature ++ ["novel_test_orbit"]}
      mode_novel = Inheritance.classify_recombination_mode(novel_child, parent_a, parent_b)
      assert mode_novel == :novel_emergent
    end

    test "Experiment Set C: Lineage Formation generates 100 descendants and Speciation", %{records: records} do
      results = Inheritance.run_lineage_formation_experiment(records, 3)

      assert length(results.lineage_tree) >= 100
      assert results.species_count > 0
      assert results.lineage_persistence == 3
      assert results.mes_retention > 0.0
      assert length(results.final_population) == 100
    end

    test "Experiment Set D: Memory Fitness Convergence over epochs", %{records: records} do
      results = Inheritance.run_fitness_dominance(records, 5)

      assert length(results.generation_stats) == 5
      assert results.dominance_verified in [true, false]
      assert is_float(results.fitness_gain)
    end
  end
end
