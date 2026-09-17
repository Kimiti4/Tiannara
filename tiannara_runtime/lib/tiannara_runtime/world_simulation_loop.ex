defmodule TiannaraRuntime.WorldSimulationLoop do
  use GenServer
  require Logger

  @default_tick_interval 50

  defstruct [
    world_id: nil,
    tick_interval: @default_tick_interval,
    tick_count: 0,
    running: false
  ]

  def start_link(world_config) do
    GenServer.start_link(__MODULE__, world_config)
  end

  def start_simulation(pid) do
    GenServer.cast(pid, :start_simulation)
  end

  def stop_simulation(pid) do
    GenServer.cast(pid, :stop_simulation)
  end

  @impl true
  def init(world_config) do
    world_id = world_config.id
    tick_interval = Map.get(world_config, :tick_interval, @default_tick_interval)
    {:ok, %__MODULE__{
      world_id: world_id,
      tick_interval: tick_interval,
      running: false
    }}
  end

  @impl true
  def handle_cast(:start_simulation, state) do
    if state.running do
      {:noreply, state}
    else
      schedule_tick()
      {:noreply, %{state | running: true}}
    end
  end

  @impl true
  def handle_cast(:stop_simulation, state) do
    {:noreply, %{state | running: false}}
  end

  @impl true
  def handle_info(:tick, state) do
    if state.running do
      execute_tick(state)
      schedule_tick()
      {:noreply, %{state | tick_count: state.tick_count + 1}}
    else
      {:noreply, state}
    end
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @default_tick_interval)
  end

  defp execute_tick(state) do
    world_id = state.world_id
    try do
      cal_result = execute_cal_step(world_id)
      cis_result = execute_cis_step(world_id, cal_result)
      update_world_state(world_id, cal_result, cis_result)
      publish_events(world_id, cal_result, cis_result)
      store_memory_snapshot(world_id, cal_result, cis_result)
    rescue
      e ->
        Logger.error("Error in world #{world_id} tick: #{inspect(e)}")
    end
  end

  defp execute_cal_step(world_id) do
    case Registry.lookup(TiannaraRuntime.WorldRegistry, world_id) do
      [{supervisor_pid, _}] ->
        children = Supervisor.which_children(supervisor_pid)
        state_manager_pid = find_child(children, TiannaraRuntime.WorldStateManager)
        if state_manager_pid do
          {:ok, world_state} = TiannaraRuntime.WorldStateManager.get_state(state_manager_pid)
          cal_result = TiannaraRuntime.CAL.Engine.step(world_state.cal_state)
          TiannaraRuntime.WorldStateManager.update_cal_state(state_manager_pid, cal_result)
          cal_result
        else
          default_cal_result()
        end
      [] ->
        default_cal_result()
    end
  end

  defp execute_cis_step(world_id, cal_result) do
    case Registry.lookup(TiannaraRuntime.WorldRegistry, world_id) do
      [{supervisor_pid, _}] ->
        children = Supervisor.which_children(supervisor_pid)
        state_manager_pid = find_child(children, TiannaraRuntime.WorldStateManager)
        if state_manager_pid do
          {:ok, world_state} = TiannaraRuntime.WorldStateManager.get_state(state_manager_pid)
          cis_result = TiannaraRuntime.CIS.Engine.evaluate(
            world_state.cis_state,
            cal_result,
            world_state.system_metrics
          )
          TiannaraRuntime.WorldStateManager.update_cis_state(state_manager_pid, cis_result)
          TiannaraRuntime.WorldStateManager.update_metrics(state_manager_pid, cis_result.metrics)
          cis_result
        else
          default_cis_result()
        end
      [] ->
        default_cis_result()
    end
  end

  defp default_cal_result do
    %{
      coalitions_updated: [],
      decisions_made: [],
      entropy: 0.0
    }
  end

  defp default_cis_result do
    %{
      interventions: [],
      stability_score: 1.0,
      thresholds_adjusted: [],
      metrics: %{}
    }
  end

  defp update_world_state(world_id, cal_result, cis_result) do
    Logger.debug("Updated state for world #{world_id}")
  end

  defp publish_events(world_id, cal_result, cis_result) do
    Logger.debug("Published events for world #{world_id}")
  end

  defp store_memory_snapshot(world_id, cal_result, cis_result) do
    case Registry.lookup(TiannaraRuntime.WorldRegistry, world_id) do
      [{supervisor_pid, _}] ->
        children = Supervisor.which_children(supervisor_pid)
        memory_store_pid = find_child(children, TiannaraRuntime.WorldMemoryStore)
        if memory_store_pid do
          snapshot_data = %{
            cal_result: cal_result,
            cis_result: cis_result,
            timestamp: :erlang.unique_integer([:positive])
          }
          TiannaraRuntime.WorldMemoryStore.append_snapshot(memory_store_pid, snapshot_data)
        end
      [] ->
        Logger.warning("World supervisor not found for #{world_id}")
    end
  end

  defp find_child(children, module) do
    Enum.find_value(children, fn {child_module, child_pid, _, _} ->
      if child_module == module, do: child_pid
    end)
  end
end
