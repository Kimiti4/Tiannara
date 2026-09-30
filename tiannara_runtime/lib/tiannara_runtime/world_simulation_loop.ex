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

  def research(world_id, domain, hypothesis, context \\ %{}) do
    case TiannaraRuntime.WorldRegistry.get_world(world_id) do
      {:ok, world} ->
        merged = Map.merge(Map.get(world, :config, %{}), context)
        Tiannara.World.ScientificResearch.investigate(domain, hypothesis, merged)
      error -> error
    end
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
      schedule_tick(state.tick_interval)
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
      schedule_tick(state.tick_interval)
      {:noreply, %{state | tick_count: state.tick_count + 1}}
    else
      {:noreply, state}
    end
  end

  defp schedule_tick(interval), do: Process.send_after(self(), :tick, interval)

  defp execute_tick(state) do
    world_id = state.world_id
    try do
      with {:ok, cal_result} <- execute_cal_step(world_id),
           {:ok, cis_result} <- execute_cis_step(world_id, cal_result),
           :ok <- update_world_state(world_id, cal_result, cis_result),
           :ok <- publish_events(world_id, cal_result, cis_result),
           :ok <- store_memory_snapshot(world_id, cal_result, cis_result) do
        :ok
      else
        {:error, reason} -> Logger.error("World #{world_id} tick not executed: #{inspect(reason)}")
      end
    rescue
      e ->
        Logger.error("Error in world #{world_id} tick: #{inspect(e)}")
    end
  end

  defp execute_cal_step(world_id) do
    case Registry.lookup(TiannaraRuntime.WorldProcessRegistry, world_id) do
      [{supervisor_pid, _}] ->
        children = Supervisor.which_children(supervisor_pid)
        state_manager_pid = find_child(children, TiannaraRuntime.WorldStateManager)
        if state_manager_pid do
          {:ok, world_state} = TiannaraRuntime.WorldStateManager.get_state(state_manager_pid)
          case TiannaraRuntime.CAL.Engine.step(world_state.cal_state) do
            {:ok, cal_result} ->
              TiannaraRuntime.WorldStateManager.update_cal_state(state_manager_pid, cal_result)
              {:ok, cal_result}
            {:error, reason} -> {:error, reason}
          end
        else
          {:error, :world_state_manager_unavailable}
        end
      [] ->
        {:error, :world_not_running}
    end
  end

  defp execute_cis_step(world_id, cal_result) do
    case Registry.lookup(TiannaraRuntime.WorldProcessRegistry, world_id) do
      [{supervisor_pid, _}] ->
        children = Supervisor.which_children(supervisor_pid)
        state_manager_pid = find_child(children, TiannaraRuntime.WorldStateManager)
        if state_manager_pid do
          {:ok, world_state} = TiannaraRuntime.WorldStateManager.get_state(state_manager_pid)
          with {:ok, cal_score} <- require_numeric(cal_result, :arbitration_score),
               {:ok, entropy} <- require_numeric(world_state.system_metrics, :entropy),
               {:ok, entropy_delta} <- optional_numeric(cal_result, :entropy_delta, 0.0) do
            effective_metrics =
              world_state.system_metrics
              |> Map.put(:entropy, min(1.0, max(0.0, entropy + entropy_delta)))
              |> Map.put(:coherence, min(1.0, max(0.0, cal_score)))

            case TiannaraRuntime.CIS.Engine.evaluate(
                   world_state.cis_state,
                   cal_result,
                   effective_metrics
                 ) do
              {:error, reason} -> {:error, reason}
              cis_result ->
                TiannaraRuntime.WorldStateManager.update_cis_state(state_manager_pid, cis_result)
                TiannaraRuntime.WorldStateManager.update_metrics(state_manager_pid, cis_result.metrics)
                {:ok, cis_result}
            end
          else
            {:error, reason} -> {:error, {:invalid_cis_inputs, reason}}
          end
        else
          {:error, :world_state_manager_unavailable}
        end
      [] ->
        {:error, :world_not_running}
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
    with {:ok, arbitration_score} <- require_numeric(cal_result, :arbitration_score),
         {:ok, stability_score} <- require_numeric(cis_result, :stability_score) do
      fitness = (arbitration_score + stability_score) / 2.0
      TiannaraRuntime.WorldRegistry.update_fitness(world_id, fitness)
      :ok
    else
      {:error, reason} -> {:error, {:invalid_fitness_inputs, reason}}
    end
  end

  defp require_numeric(map, key) do
    case Map.get(map, key) do
      value when is_number(value) -> {:ok, value / 1.0}
      _ -> {:error, {:missing_numeric_metric, key}}
    end
  end

  defp optional_numeric(map, key, default) do
    case Map.get(map, key) do
      nil -> {:ok, default}
      value when is_number(value) -> {:ok, value / 1.0}
      _ -> {:error, {:invalid_numeric_metric, key}}
    end
  end

  defp publish_events(world_id, cal_result, cis_result) do
    case Registry.lookup(TiannaraRuntime.WorldRegistry, world_id) do
      [{supervisor_pid, _}] ->
        processor = find_child(Supervisor.which_children(supervisor_pid), TiannaraRuntime.WorldEventProcessor)
        if processor do
          TiannaraRuntime.WorldEventProcessor.publish_cal_event(processor, cal_result)
          TiannaraRuntime.WorldEventProcessor.publish_cis_event(processor, cis_result)
          TiannaraRuntime.WorldEventProcessor.publish_state_update(processor, %{cal: cal_result, cis: cis_result})
          :ok
        else
          {:error, :event_processor_unavailable}
        end
      [] -> {:error, :world_not_running}
    end
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
            timestamp: System.system_time(:millisecond)
          }
          TiannaraRuntime.WorldMemoryStore.append_snapshot(memory_store_pid, snapshot_data)
          :ok
        else
          {:error, :memory_store_unavailable}
        end
      [] ->
        {:error, :world_not_running}
    end
  end

  defp find_child(children, module) do
    Enum.find_value(children, fn {child_module, child_pid, _, _} ->
      if child_module == module, do: child_pid
    end)
  end
end
