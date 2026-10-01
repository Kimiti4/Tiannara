defmodule TiannaraRuntime.WorldRegistry do
  @moduledoc "Canonical control-plane registry for active worlds and immutable parent lineage."
  use GenServer
  require Logger

  defstruct worlds: %{}, lineage: %{}, active_count: 0, total_created: 0

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def create_world(parent_world_id \\ nil, config \\ %{}), do: GenServer.call(__MODULE__, {:create_world, parent_world_id, config})
  def create_world_with_id(world_id, parent_world_id \\ nil, config \\ %{}), do: GenServer.call(__MODULE__, {:create_world_with_id, world_id, parent_world_id, config})
  def get_world(world_id), do: GenServer.call(__MODULE__, {:get_world, world_id})
  def list_worlds, do: GenServer.call(__MODULE__, :list_worlds)
  def lineage(world_id), do: GenServer.call(__MODULE__, {:lineage, world_id})
  def get_active_count, do: GenServer.call(__MODULE__, :get_active_count)
  def update_fitness(world_id, fitness), do: GenServer.cast(__MODULE__, {:update_fitness, world_id, fitness})
  def terminate_world(world_id), do: GenServer.cast(__MODULE__, {:terminate_world, world_id})
  def add_child(parent_id, child_id), do: GenServer.cast(__MODULE__, {:add_child, parent_id, child_id})

  @impl true
  def init(_opts), do: {:ok, %__MODULE__{}}

  @impl true
  def handle_call({:create_world, parent, config}, _from, state) do
    create(state, Map.get(config, :id) || Map.get(config, "id") || "W-#{UUID.uuid4()}", parent, config)
  end

  @impl true
  def handle_call({:create_world_with_id, id, parent, config}, _from, state), do: create(state, id, parent, config)

  @impl true
  def handle_call({:get_world, id}, _from, state), do: {:reply, Map.fetch(state.worlds, id), state}

  @impl true
  def handle_call(:list_worlds, _from, state) do
    {:reply, {:ok, state.worlds |> Map.values() |> Enum.filter(&(&1.status == :active))}, state}
  end

  @impl true
  def handle_call({:lineage, id}, _from, state) do
    case Map.fetch(state.worlds, id) do
      {:ok, world} -> {:reply, {:ok, %{parent: world.parent_world, children: Map.get(state.lineage, id, [])}}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_active_count, _from, state), do: {:reply, {:ok, state.active_count}, state}

  @impl true
  def handle_cast({:update_fitness, id, fitness}, state) do
    case Map.fetch(state.worlds, id) do
      {:ok, world} -> {:noreply, %{state | worlds: Map.put(state.worlds, id, %{world | fitness: fitness, last_updated: System.system_time(:millisecond)})}}
      :error -> {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:terminate_world, id}, state) do
    case Map.fetch(state.worlds, id) do
      {:ok, %{status: :active} = world} ->
        worlds = Map.put(state.worlds, id, %{world | status: :extinct, last_updated: System.system_time(:millisecond)})
        {:noreply, %{state | worlds: worlds, active_count: max(0, state.active_count - 1)}}
      _ -> {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:add_child, parent, child}, state) do
    if Map.has_key?(state.worlds, parent) and Map.has_key?(state.worlds, child) do
      {:noreply, %{state | lineage: Map.update(state.lineage, parent, [child], fn ids -> Enum.uniq([child | ids]) end)}}
    else
      {:noreply, state}
    end
  end

  defp create(state, id, parent, config) do
    cond do
      Map.has_key?(state.worlds, id) -> {:reply, {:error, :world_id_exists}, state}
      parent != nil and not Map.has_key?(state.worlds, parent) -> {:reply, {:error, :parent_world_not_found}, state}
      true ->
        generation = if parent, do: state.worlds[parent].generation + 1, else: Map.get(config, :generation, 0)
        genome =
          case Map.get(config, :genome) do
            %Tiannara.Genetics.WorldGenome{} = value -> value
            _ -> Tiannara.Genetics.WorldGenome.new(id, if(parent, do: [parent], else: []))
          end
        world = %{id: id, parent_world: parent, generation: generation, genome: genome, config: config, status: :active, fitness: 0.0, created_at: System.system_time(:millisecond), last_updated: System.system_time(:millisecond)}
        case Process.whereis(TiannaraRuntime.WorldRuntimeSupervisor) do
          nil ->
            {:reply, {:error, :world_runtime_supervisor_unavailable}, state}
          _ ->
            case DynamicSupervisor.start_child(TiannaraRuntime.WorldRuntimeSupervisor, {TiannaraRuntime.WorldSupervisor, world}) do
              {:ok, _pid} ->
                lineage = if parent, do: Map.update(state.lineage, parent, [id], fn ids -> Enum.uniq([id | ids]) end), else: state.lineage
                {:reply, {:ok, id}, %{state | worlds: Map.put(state.worlds, id, world), lineage: lineage, active_count: state.active_count + 1, total_created: state.total_created + 1}}
              {:error, reason} ->
                {:reply, {:error, {:world_runtime_start_failed, reason}}, state}
            end
        end
    end
  end
end
