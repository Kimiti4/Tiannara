defmodule TiannaraRuntime.WorldForkEngine do
  require Logger

  def fork(parent_world_id, mutation \\ %{}) do
    with {:ok, parent_world} <- get_parent_world(parent_world_id),
         :ok <- check_fork_conditions(parent_world),
         {:ok, child_world_id} <- create_child_world(parent_world, mutation) do
      Logger.info("Forked world #{parent_world_id} -> #{child_world_id}")
      publish_fork_event(parent_world_id, child_world_id, mutation)
      {:ok, child_world_id}
    else
      {:error, reason} ->
        Logger.error("Fork failed for world #{parent_world_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def crisis_fork(parent_world_id) do
    mutation = %{
      fork_type: :crisis,
      isolation_mode: true,
      created_at: :erlang.unique_integer([:positive])
    }
    fork(parent_world_id, mutation)
  end

  defp get_parent_world(parent_world_id) do
    case TiannaraRuntime.WorldRegistry.get_world(parent_world_id) do
      {:ok, world} ->
        if world.status == :active do
          {:ok, world}
        else
          {:error, :parent_world_inactive}
        end
      {:error, _} ->
        {:error, :parent_world_not_found}
    end
  end

  defp check_fork_conditions(parent_world) do
    case TiannaraRuntime.MultiWorld.ResourceQuota.check_quota(parent_world.id) do
      :ok -> :ok
      {:violation, reasons} -> {:error, {:quota_violation, reasons}}
      {:warning, _reasons} -> :ok
    end
  end

  defp create_child_world(parent_world, mutation) do
    child_world_id = "W-#{UUID.uuid4()}"
    cloned_state = deep_clone_state(parent_world)
    mutated_config = apply_mutation(parent_world.config, mutation)
    child_config = %{
      id: child_world_id,
      parent_world: parent_world.id,
      generation: parent_world.generation + 1,
      state: cloned_state,
      config: mutated_config,
      status: :active,
      fitness: 0.0
    }
    case TiannaraRuntime.WorldRegistry.create_world(parent_world.id, child_config) do
      {:ok, ^child_world_id} ->
        spawn_world_supervisor(child_config)
        TiannaraRuntime.WorldRegistry.add_child(parent_world.id, child_world_id)
        {:ok, child_world_id}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp deep_clone_state(world) do
    %{
      cal_state: Map.get(world, :cal_state, %{}),
      cis_state: Map.get(world, :cis_state, %{}),
      coalitions: Map.get(world, :coalitions, []),
      entropy: Map.get(world, :entropy, 0.0),
      coherence: Map.get(world, :coherence, 0.0)
    }
  end

  defp apply_mutation(base_config, mutation) do
    Map.merge(base_config, mutation, fn _key, _old_val, new_val -> new_val end)
  end

  defp spawn_world_supervisor(world_config) do
    case DynamicSupervisor.start_child(
           TiannaraRuntime.WorldRuntimeSupervisor,
           {TiannaraRuntime.WorldSupervisor, world_config}
         ) do
      {:ok, _pid} ->
        Logger.info("Spawned WorldSupervisor for #{world_config.id}")
        :ok
      {:error, reason} ->
        Logger.error("Failed to spawn WorldSupervisor: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp publish_fork_event(parent_id, child_id, mutation) do
    event = %{
      type: "world_fork",
      parent_world: parent_id,
      child_world: child_id,
      mutation: mutation,
      timestamp: :erlang.unique_integer([:positive])
    }
    json_payload = Jason.encode!(event)
    TiannaraRuntime.NATS.Bus.publish("tiannara.worlds.all.forks", json_payload)
    :ok
  end
end
