defmodule Tiannara.ROS.ROS1IntegrationTest do
  use ExUnit.Case, async: false
  require Logger

  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.Core.WorldModel.EntityRegistry

  setup_all do
    start_supervised!({Tiannara.Core.WorldModel.Supervisor, [shard_id: :world_0]})
    :ok
  end

  test "Phase ROS-1: Sustain 3 independent civilizations without polluting World-0" do
    Logger.info("🧪 Beginning Phase ROS-1 Execution Test")

    # 1. Spawn Shards
    assert {:ok, :shard_alpha} = ShardManager.spawn_shard(:shard_alpha)
    assert {:ok, :shard_beta} = ShardManager.spawn_shard(:shard_beta)
    assert {:ok, :shard_gamma} = ShardManager.spawn_shard(:shard_gamma)

    # Allow supervisors to boot
    Process.sleep(100)

    # 2. Inject Civilizations
    assert {:ok, alpha_id} = CivilizationSpawner.spawn_civilization(:shard_alpha, "Alpha", ["dominate_trade"])
    assert {:ok, beta_id} = CivilizationSpawner.spawn_civilization(:shard_beta, "Beta", ["pure_knowledge"])
    assert {:ok, gamma_id} = CivilizationSpawner.spawn_civilization(:shard_gamma, "Gamma", ["survival_only"])

    # 3. Verify Isolation (World-0 should NOT have these civilizations)
    {:ok, world_0_entities} = EntityRegistry.list_entities(:world_0)
    assert Enum.empty?(Enum.filter(world_0_entities, fn e -> e.name in ["Alpha", "Beta", "Gamma"] end))

    # 4. Verify Independence (Each shard should ONLY have its own civilization)
    {:ok, alpha_entities} = EntityRegistry.list_entities(:shard_alpha)
    assert length(alpha_entities) == 1
    assert hd(alpha_entities).id == alpha_id

    {:ok, beta_entities} = EntityRegistry.list_entities(:shard_beta)
    assert length(beta_entities) == 1
    assert hd(beta_entities).id == beta_id

    {:ok, gamma_entities} = EntityRegistry.list_entities(:shard_gamma)
    assert length(gamma_entities) == 1
    assert hd(gamma_entities).id == gamma_id

    Logger.info("✅ Phase ROS-1 Complete: 3 independent civilizations sustained successfully.")
  end
end
