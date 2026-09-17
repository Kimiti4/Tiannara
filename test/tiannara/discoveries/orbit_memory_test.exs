defmodule Tiannara.REA.OrbitMemoryTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.Decay
  alias Tiannara.REA.OrbitMemory.Transfer
  alias Tiannara.REA.OrbitMemory.Merge
  alias Tiannara.REA.OrbitMemory.Synthesis
  alias Tiannara.REA.OrbitMemory.Compression

  setup_all do
    # Load genesis sweeps to pull active trajectory history records
    records = OrbitGenesis.all_records()
    record = hd(records)
    {:ok, %{record: record, records: records}}
  end

  describe "Phase 11.11 Orbit Memory Physics Suite" do

    test "Law M0 — Orbit Memory Sufficiency: state + memory is a superior predictor", %{record: record} do
      sufficiency = OrbitMemory.verify_sufficiency(record)
      
      assert sufficiency.is_fundamental == true
      assert sufficiency.sufficiency_delta >= 0.15
      assert sufficiency.accuracy_with_memory > sufficiency.accuracy_without_memory
    end

    test "MES & MPP: memory exists and is actionable", %{record: record} do
      omt = OrbitMemory.extract(record)
      
      assert omt.memory_existence_score > 0.0
      assert omt.memory_predictive_power > 0.0
      assert is_list(omt.transition_signature)
    end

    test "Memory Ablation: systematically removing components causes prediction loss", %{record: record} do
      ablation = OrbitMemory.run_ablation_tournament(record)
      assert length(ablation) == 5

      # Assert each ablation displays a valid loss and accuracy reduction
      Enum.each(ablation, fn item ->
        assert item.loss >= 0.0
        assert item.accuracy < 0.88
      end)
    end

    test "Counterfactual Memory Swap: swapping OMT profiles swaps future outcomes" do
      # Fetch twins or separate histories
      separation = Tiannara.REA.OrbitGenesis.Causal.run_separation_experiment()
      
      swap = OrbitMemory.run_counterfactual_swap(separation.world_a, separation.world_b)
      
      assert swap.original_a != swap.original_b
      assert swap.swapped_a_future == swap.original_b
      assert swap.swapped_b_future == swap.original_a
      assert swap.conclusion == :outcome_swapped
    end

    test "Memory Decay & Half-Life: strength decays exponentially", %{record: record} do
      omt = OrbitMemory.extract(record)
      decayed = Decay.decay(omt, 10, 0.05)

      assert decayed.memory_strength < omt.memory_strength
      assert decayed.memory_half_life == 13.86
    end

    test "Memory Transfer: donor-recipient coupling moves stability experience" do
      donor = Synthesis.synthesize(["stability_orbit", "stability_orbit"])
      recipient = Synthesis.synthesize(["other_orbit_1", "other_orbit_1"])
      recipient = %{recipient | memory_strength: 0.20}

      result = Transfer.transfer(donor, recipient, 0.50)
      
      assert result.recipient_omt.memory_strength > recipient.memory_strength
      assert result.transfer_efficiency > 0.0
    end

    test "Memory Fusion & Synthesis: merging OMTs blends curves" do
      omt_a = Synthesis.synthesize(["stability_orbit"])
      omt_b = Synthesis.synthesize(["collapse_recovery_orbit"])

      merged = Merge.merge(omt_a, omt_b)
      assert length(merged.transition_signature) == 2
      assert Map.has_key?(merged.visit_frequencies, "stability_orbit")
      assert Map.has_key?(merged.visit_frequencies, "collapse_recovery_orbit")
    end

    test "Memory Compression: latent codes achieve high compression ratio and retention", %{record: record} do
      omt = OrbitMemory.extract(record)
      compressed = Compression.compress(omt)

      assert Map.has_key?(compressed.compressed_signature, "entropy")
      assert compressed.compression_ratio >= 1.5
      assert compressed.retention >= 0.85
    end
  end
end
