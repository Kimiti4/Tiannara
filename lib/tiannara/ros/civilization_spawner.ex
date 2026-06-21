defmodule Tiannara.ROS.CivilizationSpawner do
  @moduledoc """
  Responsible for spawning independent civilizations into specific Epistemic Branches (Shards).
  """

  require Logger

  @doc """
  Injects a new civilization lineage into the given shard.
  """
  def spawn_civilization(shard_id, lineage_name, goals \\ []) do
    Logger.info("🧬 [ROS] Spawning Civilization '#{lineage_name}' in Shard '#{shard_id}'")

    # 1. Create the Lineage Entity in the specific Shard
    entity = Tiannara.Core.WorldModel.Entity.new(
      "lineage:#{String.downcase(lineage_name)}",
      "Lineage",
      lineage_name,
      %{
        type: "civilization",
        status: "nascent",
        goals: goals,
        epistemic_genome: Tiannara.Core.WorldModel.EpistemicGenome.new()
      }
    )

    case Tiannara.Core.WorldModel.EntityRegistry.register_entity(entity, shard_id) do
      {:ok, entity_id} ->
        # 3. Register with EconomyEngine (REL-1)
        Tiannara.REL.EconomyEngine.register_civilization(shard_id, entity_id)

        # 4. Apply Latent Inheritance (LEOC-1)
        Tiannara.REL.SpawnEngine.apply_latent_inheritance(entity_id, shard_id)

        Logger.info("✅ Civilization #{lineage_name} successfully spawned in #{shard_id}")
        {:ok, entity_id}
      {:error, reason} ->
        Logger.error("❌ Failed to spawn civilization: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
