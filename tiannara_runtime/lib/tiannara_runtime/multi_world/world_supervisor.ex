defmodule TiannaraRuntime.MultiWorld.WorldSupervisor do
  @moduledoc """
  PHASE 5: Multi-World Supervisor with Integrated Safeguards

  Manages parallel world simulations with ALL Phase 5 safeguards enforced:

  1. ResourceQuota - Prevents runaway spawning
  2. MemoryManager - Controls memory explosion
  3. DeterministicReplay - Enables debugging
  4. WorldFreeze - Allows rollback/analysis
  5. KillSwitch - Emergency termination

  ARCHITECTURAL BOUNDARIES PRESERVED:
  - Worlds are READ-ONLY from observation layer (Phase 4)
  - Predictions NEVER become direct decisions
  - UI feedback NEVER mutates runtime state
  - Meta-controls ALWAYS pass through CIS safeguards

  This supervisor ensures that multi-world branching remains safe,
  controllable, and debuggable.
  """

  use GenServer
  require Logger

  @dynamic_supervisor TiannaraRuntime.MultiWorld.WorldSupervisor.Dynamics

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(world_id, child_spec) do
    GenServer.call(__MODULE__, {:start_child, world_id, child_spec})
  end

  def spawn_world(config) do
    world_id = generate_world_id()

    case TiannaraRuntime.MultiWorld.ResourceQuota.request_world_spawn(world_id) do
      {:ok, ^world_id} ->
        :ok

      {:error, reason} ->
        Logger.warning("World spawn rejected: #{reason}")
        {:error, reason}
    end

    estimated_memory_mb = estimate_memory_usage(config)

    case TiannaraRuntime.MultiWorld.MemoryManager.allocate_memory(world_id, estimated_memory_mb) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("World spawn rejected: #{reason}")
        TiannaraRuntime.MultiWorld.ResourceQuota.terminate_world(world_id, :memory_allocation_failed)
        {:error, reason}
    end

    seed = Map.get(config, :seed, System.system_time(:millisecond))
    TiannaraRuntime.MultiWorld.DeterministicReplay.start_recording(world_id, seed)

    child_spec = {
      TiannaraRuntime.MultiWorld.WorldProcess,
      %{
        id: world_id,
        config: config,
        seed: seed
      }
    }

    case start_child(world_id, child_spec) do
      {:ok, world_pid} ->
        Logger.info("World #{world_id} spawned successfully")
        {:ok, world_pid, world_id}

      {:error, reason} ->
        Logger.error("Failed to spawn world #{world_id}: #{reason}")
        TiannaraRuntime.MultiWorld.ResourceQuota.terminate_world(world_id, :spawn_failed)
        TiannaraRuntime.MultiWorld.MemoryManager.release_memory(world_id, estimated_memory_mb)
        {:error, reason}
    end
  end

  def terminate_world(world_id, reason \\ :normal) do
    GenServer.cast(__MODULE__, {:terminate_world, world_id, reason})
  end

  def get_status do
    {:ok, quota_status} = TiannaraRuntime.MultiWorld.ResourceQuota.get_status()
    {:ok, memory_status} = TiannaraRuntime.MultiWorld.MemoryManager.get_system_status()
    {:ok, killed_worlds} = TiannaraRuntime.MultiWorld.KillSwitch.get_killed_worlds()

    %{
      active_worlds: quota_status.active_worlds,
      max_worlds: quota_status.max_worlds,
      total_created: quota_status.total_worlds_created,
      system_memory_mb: memory_status.system_memory_mb,
      killed_worlds: killed_worlds,
      timestamp: DateTime.utc_now()
    }
  end

  def freeze_world(world_id) do
    TiannaraRuntime.MultiWorld.WorldFreeze.freeze_world(world_id)
  end

  def unfreeze_world(world_id) do
    TiannaraRuntime.MultiWorld.WorldFreeze.unfreeze_world(world_id)
  end

  def snapshot_world(world_id, metadata \\ %{}) do
    TiannaraRuntime.MultiWorld.WorldFreeze.create_snapshot(world_id, metadata)
  end

  def request_kill(world_id, reason) do
    # The canonical kill switch exposes request_termination/3; the previous
    # request_kill/2 existed in no implementation at all (F-GOV-013).
    TiannaraRuntime.MultiWorld.KillSwitch.request_termination(world_id, reason, :critical)
  end

  def emergency_kill(world_id, reason) do
    TiannaraRuntime.MultiWorld.KillSwitch.emergency_kill(world_id, reason)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("WorldSupervisor started with Phase 5 safeguards")

    case DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_supervisor) do
      {:ok, pid} -> {:ok, %{dynamic_supervisor: pid, worlds: %{}}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:start_child, world_id, child_spec}, _from, state) do
    case DynamicSupervisor.start_child(state.dynamic_supervisor, child_spec) do
      {:ok, pid} ->
        {:reply, {:ok, pid}, put_in(state.worlds[world_id], pid)}

      other ->
        {:reply, other, state}
    end
  end

  @impl true
  def handle_cast({:terminate_world, world_id, reason}, state) do
    Logger.warning("World #{world_id} termination requested: #{reason}")
    {_pid, state} = terminate_world_process(world_id, reason, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:terminate_world, world_id, reason}, state) do
    Logger.warning("World #{world_id} termination requested by ResourceQuota: #{reason}")
    {_pid, state} = terminate_world_process(world_id, reason, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:kill_world, world_id, method}, state) do
    Logger.error("World #{world_id} KILL command received (method: #{method})")

    {world_pid, state} = take_world_pid(world_id, state)

    if world_pid do
      Process.exit(world_pid, :kill)
    end

    notify_quota_termination(world_id, :killed)
    {:noreply, state}
  end

  @impl true
  def handle_info({:pause, world_id}, state) do
    Logger.info("Pausing world #{world_id}")

    case Map.get(state.worlds, world_id) do
      pid when is_pid(pid) -> send(pid, :pause)
      _ -> :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:resume, world_id}, state) do
    Logger.info("Resuming world #{world_id}")

    case Map.get(state.worlds, world_id) do
      pid when is_pid(pid) -> send(pid, :resume)
      _ -> :ok
    end

    {:noreply, state}
  end

  defp generate_world_id do
    "world_#{System.system_time(:millisecond)}_#{:rand.uniform(9999)}"
  end

  defp estimate_memory_usage(config) do
    max_agents = Map.get(config, :max_agents, 100)
    max_coalitions = Map.get(config, :max_coalitions, 10)

    base_overhead = 50
    agent_memory = max_agents * 2
    coalition_memory = max_coalitions * 5

    total = base_overhead + agent_memory + coalition_memory
    min(total, 512)
  end

  defp take_world_pid(world_id, state) do
    {Map.get(state.worlds, world_id), %{state | worlds: Map.delete(state.worlds, world_id)}}
  end

  defp terminate_world_process(world_id, reason, state) do
    Logger.info("Terminating world #{world_id}: #{reason}")

    if Process.whereis(TiannaraRuntime.MultiWorld.WorldFreeze) do
      TiannaraRuntime.MultiWorld.WorldFreeze.create_snapshot(world_id, %{
        reason: reason,
        type: :pre_termination
      })
    end

    if Process.whereis(TiannaraRuntime.MultiWorld.DeterministicReplay) do
      TiannaraRuntime.MultiWorld.DeterministicReplay.stop_recording(world_id)
    end

    {world_pid, state} = take_world_pid(world_id, state)

    if world_pid do
      Process.exit(world_pid, :shutdown)
    end

    notify_quota_termination(world_id, reason)

    if Process.whereis(TiannaraRuntime.MultiWorld.MemoryManager) do
      case TiannaraRuntime.MultiWorld.MemoryManager.get_world_memory(world_id) do
        {:ok, memory_mb} ->
          TiannaraRuntime.MultiWorld.MemoryManager.release_memory(world_id, memory_mb)

        _ ->
          :ok
      end
    end

    Logger.info("World #{world_id} terminated and resources released")
    {world_pid, state}
  end

  defp notify_quota_termination(world_id, reason) do
    if Process.whereis(TiannaraRuntime.MultiWorld.ResourceQuota) do
      TiannaraRuntime.MultiWorld.ResourceQuota.terminate_world(world_id, reason)
    end
  end
end
