defmodule Tiannara.REL.REL1IntegrationTest do
  use ExUnit.Case, async: false
  require Logger

  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.ROS.EvolutionEngine
  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger
  alias Tiannara.Core.WorldModel.Discovery

  setup_all do
    start_supervised!({Tiannara.Core.WorldModel.Supervisor, [shard_id: :world_0]})
    :ok
  end

  @tag timeout: 60000
  test "Scarcity Test: Cannot reproduce infinitely due to Energy/Compute constraints" do
    Logger.info("🧪 Beginning Scarcity Test")
    
    assert {:ok, :shard_scarcity} = ShardManager.spawn_shard(:shard_scarcity)
    
    # Spawn civilization (gets 1000 Energy, 1000 Compute)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_scarcity, "ScarceCiv", [])
    Tiannara.OMCS.Engine.register_civilization(civ_id)
    
    # Reproduction costs 500 E, 100 C. We should be able to do it exactly twice.
    assert {:ok, child_1} = EvolutionEngine.reproduce(:shard_scarcity, civ_id, "ScarceCiv-1")
    assert {:ok, child_2} = EvolutionEngine.reproduce(:shard_scarcity, civ_id, "ScarceCiv-2")
    
    # Third time should fail with :insufficient_funds
    result = EvolutionEngine.reproduce(:shard_scarcity, civ_id, "ScarceCiv-3")
    assert {:error, :insufficient_funds} = result

    # Verify Budget
    budget = EconomyEngine.get_budget(civ_id)
    assert budget.energy == 0
    assert budget.compute == 800
  end

  @tag timeout: 60000
  test "Maintenance & Starvation Test: Ontology size passively drains energy into starvation and dormancy" do
    Logger.info("🧪 Beginning Maintenance Test")

    assert {:ok, :shard_maint} = ShardManager.spawn_shard(:shard_maint)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_maint, "MaintCiv", [])
    Tiannara.OMCS.Engine.register_civilization(civ_id)
    
    # We will just tick the EconomyEngine directly 50 times.
    # Base maintenance is 5 energy per tick if ontology is small. 5 * 50 = 250 energy drain.
    # We'll tick it 160 times -> 160 * 5 = 800 energy drain. 1000 - 800 = 200.
    # At < 200 energy, it should enter :starving.
    
    Enum.each(1..165, fn _ -> EconomyEngine.tick(civ_id) end)
    # Give GenServer messages time to process
    Process.sleep(100)

    budget = EconomyEngine.get_budget(civ_id)
    # Energy should be 1000 - (165 * 5) = 175
    assert budget.energy == 175
    assert budget.state == :starving

    # Tick another 50 times. 50 * 5 = 250 energy drain. Will hit 0.
    Enum.each(1..50, fn _ -> EconomyEngine.tick(civ_id) end)
    Process.sleep(100)

    budget2 = EconomyEngine.get_budget(civ_id)
    assert budget2.energy == 0
    assert budget2.state == :dormant
    assert budget2.ticks_dormant > 0

    # Try reproduction while dormant. Should fail.
    result = EvolutionEngine.reproduce(:shard_maint, civ_id, "GhostCiv")
    assert {:error, :dormant} = result
  end

  @tag timeout: 60000
  test "Discovery Test: Spend resources to unlock, pay maintenance, and forget during starvation" do
    Logger.info("🧪 Beginning Discovery Test")

    assert {:ok, :shard_disc} = ShardManager.spawn_shard(:shard_disc)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_disc, "Discoverer", [])
    Tiannara.OMCS.Engine.register_civilization(civ_id)
    
    # Register a new discovery
    disc = Discovery.new(%{id: "disc_fire", name: "Fire", domain: "physics", originator_civ_id: civ_id, complexity_cost: 100})
    assert :ok = DiscoveryLedger.register_discovery(civ_id, disc)

    # Verify ownership
    known = DiscoveryLedger.get_known_discoveries(civ_id)
    assert length(known) == 1
    assert hd(known).name == "Fire"

    # Tick ledger maintenance. Fire costs 100 Ontological Capital and 50 Compute.
    DiscoveryLedger.tick_maintenance(civ_id)
    Process.sleep(50)

    budget = EconomyEngine.get_budget(civ_id)
    assert budget.ontological_capital == 900
    assert budget.compute == 950

    # Drain their capital to 50
    EconomyEngine.consume(civ_id, %{ontological_capital: 850})
    
    # Tick again. Cost is 100, they only have 50. They should forget it.
    DiscoveryLedger.tick_maintenance(civ_id)
    Process.sleep(50)

    known_after = DiscoveryLedger.get_known_discoveries(civ_id)
    assert length(known_after) == 0
  end
end
