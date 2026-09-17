defmodule Tiannara.Sentinel.SEAIntegrationTest do
  use ExUnit.Case
  require Logger

  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.OMCS.Engine, as: OMCSEngine
  alias Tiannara.REL.EconomyEngine
  alias Tiannara.Sentinel.EpistemologyArchive
  alias Tiannara.Sentinel.EpistemologyAtlas
  alias Tiannara.Sentinel.DiscoveryGenealogy
  alias Tiannara.REL.DiscoveryLedger
  alias Tiannara.Core.WorldModel.EntityRegistry

  setup do
    # Clear GenServer state before tests if needed (or use fresh civ names)
    :ok
  end

  test "Collapse Signature Test: Verify REL emits facts and SEA interprets :infinite_novelty_spiral" do
    assert {:ok, :shard_sea1} = ShardManager.spawn_shard(:shard_sea1)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_sea1, "SpiralCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Consume all energy to force collapse on next tick
    EconomyEngine.consume(civ_id, %{energy: 1000})
    
    # Register 10 unstable discoveries and 1 stable
    for i <- 1..10 do
      disc = Tiannara.Core.WorldModel.Discovery.new(%{id: "unstable_#{i}", name: "Concept #{i}", stability: 0.1, domain: :cognition, originator_civ_id: civ_id})
      DiscoveryLedger.register_discovery(civ_id, disc)
    end
    
    # Need to manipulate the prediction engine or outcome struct directly?
    # Actually, the EconomyEngine tick will construct the outcome and call record_collapse.
    # It assumes prediction_accuracy is 0.1 statically right now in the engine.
    
    EconomyEngine.tick(civ_id) # Should starve
    
    # Sync to ensure EconomyEngine and Archive process their casts
    :sys.get_state(Tiannara.REL.EconomyEngine)
    :sys.get_state(Tiannara.Sentinel.EpistemologyArchive)
    
    records = EpistemologyArchive.get_all_records()
    spiral_record = Enum.find(records, fn r -> r.civilization_id == civ_id end)
    
    assert spiral_record != nil
    assert spiral_record.collapse_signature == :infinite_novelty_spiral
  end

  test "Truth Retention Test: Verify score is calculated based on stable discoveries" do
    assert {:ok, :shard_sea2} = ShardManager.spawn_shard(:shard_sea2)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_sea2, "TruthCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Consume energy to force collapse on next tick
    EconomyEngine.consume(civ_id, %{energy: 1000})
    
    # 4 stable, 1 unstable = 80% truth retention
    for i <- 1..4 do
      disc = Tiannara.Core.WorldModel.Discovery.new(%{id: "stable_#{i}", name: "Solid #{i}", stability: 0.9, domain: :cognition, originator_civ_id: civ_id})
      DiscoveryLedger.register_discovery(civ_id, disc)
    end
    
    disc = Tiannara.Core.WorldModel.Discovery.new(%{id: "unstable_x", name: "Bad", stability: 0.2, domain: :cognition, originator_civ_id: civ_id})
    DiscoveryLedger.register_discovery(civ_id, disc)
    
    EconomyEngine.tick(civ_id) # starve
    
    # Sync to ensure async cast is processed
    :sys.get_state(Tiannara.REL.EconomyEngine)
    :sys.get_state(Tiannara.Sentinel.EpistemologyArchive)
    
    records = EpistemologyArchive.get_all_records()
    truth_record = Enum.find(records, fn r -> r.civilization_id == civ_id end)
    
    assert truth_record.truth_retention_score == 0.8
  end

  test "Atlas Test: Atlas identifies dominant archetype based on truth retention" do
    # Inject a dummy record into EpistemologyArchive
    genome = Tiannara.Core.WorldModel.EpistemicGenome.new()
    budget = %Tiannara.REL.ResourceBudget{civilization_id: "AtlasCiv", shard_id: :shard_sea_atlas}
    
    # We must construct an outcome with a high truth_retention score manually for the test,
    # or just rely on EpistemologyArchive.record_collapse to compute it.
    # To get high truth retention, we register a stable discovery.
    disc = Tiannara.Core.WorldModel.Discovery.new(%{id: "atlas_stable", name: "Atlas Concept", stability: 0.9, domain: :cognition, originator_civ_id: "AtlasCiv"})
    Tiannara.REL.DiscoveryLedger.register_discovery("AtlasCiv", disc)
    
    Tiannara.Sentinel.EpistemologyArchive.record_collapse(budget, genome)
    :sys.get_state(Tiannara.Sentinel.EpistemologyArchive)
    
    {:ok, best_genome} = EpistemologyAtlas.find_dominant_archetype(:truth_retention_score)
    assert best_genome.__struct__ == Tiannara.Core.WorldModel.EpistemicGenome
  end

  test "Genealogy & Archaeology Test: Permanent ancestry and rediscovery detection" do
    disc1 = Tiannara.Core.WorldModel.Discovery.new(%{id: "anc_1", name: "Non-Euclidean Logistics", stability: 0.9, domain: :physics, originator_civ_id: "CivOld"})
    DiscoveryLedger.register_discovery("CivOld", disc1)
    
    # Trace ancestry
    path = DiscoveryGenealogy.get_ancestry("anc_1")
    assert length(path) == 1
    
    # Simulate a new civ rediscovering it later
    disc2 = Tiannara.Core.WorldModel.Discovery.new(%{id: "anc_2", name: "Non-Euclidean Logistics", stability: 0.9, domain: :physics, originator_civ_id: "CivNew"})
    
    # Check if rediscovery
    is_redis = DiscoveryGenealogy.is_rediscovery?(disc2)
    assert is_redis == true
    
    res = Tiannara.Sentinel.EpistemicArchaeology.analyze_for_precursors(disc2)
    assert {:rediscovery, "Non-Euclidean Logistics"} = res
  end
end
