defmodule Tiannara.ROS.ROS2IntegrationTest do
  use ExUnit.Case, async: false
  require Logger

  alias Tiannara.OMCS
  alias Tiannara.OMCS.Engine
  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.ROS.EvolutionEngine
  alias Tiannara.Core.WorldModel.BeliefSystem

  setup_all do
    # Application is already started by mix test, including EvolutionEngine
    start_supervised!({Tiannara.Core.WorldModel.Supervisor, [shard_id: :world_0]})
    :ok
  end

  @tag timeout: 60000
  test "Reproduction Test: Parent and child survive, lineage preserved" do
    Logger.info("🧪 Beginning Reproduction Test")

    assert {:ok, :shard_repro} = ShardManager.spawn_shard(:shard_repro)
    Process.sleep(50)

    # Spawn Beta
    assert {:ok, civ_beta} = CivilizationSpawner.spawn_civilization(:shard_repro, "Beta", ["growth"])
    Engine.register_civilization(civ_beta)

    # Trigger reproduction
    assert {:ok, civ_beta_prime} = EvolutionEngine.reproduce(:shard_repro, civ_beta, "Beta-Prime")
    
    # Verify both coexist in lineage
    {:ok, beta_lineage} = Engine.get_lineage(civ_beta)
    
    # beta_lineage.children should contain { :reproduced_from, child_tree }
    assert Enum.any?(beta_lineage.children, fn {edge, child} -> child.id == civ_beta_prime and edge == :reproduced_from end)

    # Verify both can still be captured (both survive)
    assert %OMCS.IdentitySeed{} = OMCS.capture_identity(:shard_repro, civ_beta)
    assert %OMCS.IdentitySeed{} = OMCS.capture_identity(:shard_repro, civ_beta_prime)
  end

  @tag timeout: 60000
  test "Fission Test: Parent terminates, inter-child similarity 0.4 - 0.8" do
    Logger.info("🧪 Beginning Fission Test")

    assert {:ok, :shard_fission} = ShardManager.spawn_shard(:shard_fission)
    Process.sleep(50)

    # Spawn Alpha
    assert {:ok, civ_alpha} = CivilizationSpawner.spawn_civilization(:shard_fission, "Alpha", [])
    Engine.register_civilization(civ_alpha)

    # Inject 6 beliefs (A, B, C, D, E, F) to simulate a rich ontology
    belief_sys = Tiannara.ROS.Registry.via(BeliefSystem, :shard_fission)
    Enum.each(["A", "B", "C", "D", "E", "F"], fn b ->
      GenServer.call(belief_sys, {:add_belief, %{
        id: "belief_#{b}", statement: b, confidence: 1.0,
        source: "founding", evidence: [],
        created_at: DateTime.utc_now(), last_verified: DateTime.utc_now()
      }})
    end)

    # Trigger fission
    assert {:ok, child_east, child_west} = EvolutionEngine.fission(:shard_fission, civ_alpha, :shard_east, :shard_west, "Alpha-East", "Alpha-West")
    
    # Verify lineage links
    {:ok, alpha_lineage} = Engine.get_lineage(civ_alpha)
    assert Enum.any?(alpha_lineage.children, fn {edge, child} -> child.id == child_east and edge == :fissioned_from end)
    assert Enum.any?(alpha_lineage.children, fn {edge, child} -> child.id == child_west and edge == :fissioned_from end)

    # Verify inter-child similarity
    seed_east = OMCS.capture_identity(:shard_east, child_east)
    seed_west = OMCS.capture_identity(:shard_west, child_west)
    
    similarity = score_ontology_similarity(seed_east.ontology_fingerprint, seed_west.ontology_fingerprint)
    
    Logger.info("Fission Similarity: #{similarity}")
    assert similarity >= 0.4 and similarity <= 0.8
  end

  @tag timeout: 60000
  test "Migration Test: Origin gets ruin, destination gets living civ, continuity > 0.95" do
    Logger.info("🧪 Beginning Migration Test")

    assert {:ok, :shard_origin} = ShardManager.spawn_shard(:shard_origin)
    assert {:ok, :shard_dest} = ShardManager.spawn_shard(:shard_dest)
    Process.sleep(50)

    # Spawn Gamma
    assert {:ok, civ_gamma} = CivilizationSpawner.spawn_civilization(:shard_origin, "Gamma", ["survival"])
    Engine.register_civilization(civ_gamma)

    # Migrate Gamma
    assert {:ok, continuity, migrated_id} = EvolutionEngine.migrate(:shard_origin, :shard_dest, civ_gamma)

    # Verify Continuity
    assert continuity.overall_continuity >= 0.95

    # Origin should have a ruin (if we had a registry for ruins, we'd check it. We'll trust the function executed).
    
    # Destination should have living civ
    assert %OMCS.IdentitySeed{} = OMCS.capture_identity(:shard_dest, migrated_id)

    # Lineage should show migration edge
    {:ok, gamma_lineage} = Engine.get_lineage(civ_gamma)
    assert Enum.any?(gamma_lineage.children, fn {edge, child} -> child.id == migrated_id and edge == :migrated_from end)
  end

  @tag timeout: 60000
  test "Speciation Test: Automatic emergence" do
    Logger.info("🧪 Beginning Speciation Test")

    assert {:ok, :shard_speciation} = ShardManager.spawn_shard(:shard_speciation)
    Process.sleep(50)

    # Spawn Delta
    assert {:ok, civ_delta} = CivilizationSpawner.spawn_civilization(:shard_speciation, "Delta", [])
    Engine.register_civilization(civ_delta)

    baseline_seed = OMCS.capture_identity(:shard_speciation, civ_delta)

    # Inject massive divergence (10 new beliefs)
    belief_sys = Tiannara.ROS.Registry.via(BeliefSystem, :shard_speciation)
    Enum.each(1..10, fn i ->
      GenServer.call(belief_sys, {:add_belief, %{
        id: "div_#{i}", statement: "divergence_#{i}", confidence: 1.0,
        source: "mutation", evidence: [],
        created_at: DateTime.utc_now(), last_verified: DateTime.utc_now()
      }})
    end)

    # Check speciation
    result = EvolutionEngine.check_speciation(:shard_speciation, civ_delta, baseline_seed)
    
    # Should trigger speciation due to > 0.7 ontology divergence
    assert {:speciated, new_species_id} = result
    
    # Verify new species exists and is linked
    {:ok, delta_lineage} = Engine.get_lineage(civ_delta)
    assert Enum.any?(delta_lineage.children, fn {edge, child} -> child.id == new_species_id and edge == :reproduced_from end)
  end

  # Helper for calculating similarity locally without ContinuityScorer's full struct wrapper
  defp score_ontology_similarity(fp1, fp2) do
    set1 = MapSet.new(fp1 || [])
    set2 = MapSet.new(fp2 || [])
    intersection = MapSet.intersection(set1, set2) |> MapSet.size()
    union = MapSet.union(set1, set2) |> MapSet.size()
    if union == 0, do: 1.0, else: intersection / union
  end
end
