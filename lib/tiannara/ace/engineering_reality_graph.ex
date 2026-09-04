defmodule Tiannara.ACE.EngineeringRealityGraph do
  @moduledoc """
  Engineering Reality Graph (ERG): specialized knowledge graph for engineering.
  Stores materials, components, processes, technologies, designs, constraints,
  failure modes, manufacturing methods, dependencies, and performance data.

  Transforms: Discovery → Material Property → Component Design → Prototype → Capability
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def add_material(pid, material), do: GenServer.cast(pid, {:add, :material, material})
  def add_component(pid, component), do: GenServer.cast(pid, {:add, :component, component})
  def add_process(pid, process), do: GenServer.cast(pid, {:add, :process, process})
  def add_capability(pid, capability), do: GenServer.cast(pid, {:add, :capability, capability})

  def find_materials(pid, query), do: GenServer.call(pid, {:find, :material, query})
  def find_components(pid, query), do: GenServer.call(pid, {:find, :component, query})
  def get_capability_lineage(pid, cap_id), do: GenServer.call(pid, {:lineage, cap_id})

  def discover_dependencies(pid, capability), do: GenServer.call(pid, {:dependencies, capability})

  @impl true
  def init(_) do
    {:ok, %{
      materials: %{},
      components: %{},
      processes: %{},
      capabilities: %{},
      relationships: %{}
    }}
  end

  @impl true
  def handle_cast({:add, type, item}, state) do
    collection = Map.get(state, type, %{})
    updated = Map.put(collection, item.id, item)
    {:noreply, Map.put(state, type, updated)}
  end

  @impl true
  def handle_call({:find, type, query}, _from, state) do
    results = state
    |> Map.get(type, %{})
    |> Map.values()
    |> Enum.filter(fn item -> matches_query?(item, query) end)
    {:reply, results, state}
  end

  @impl true
  def handle_call({:lineage, cap_id}, _from, state) do
    lineage = trace_lineage(cap_id, state.capabilities, [])
    {:reply, lineage, state}
  end

  @impl true
  def handle_call({:dependencies, capability}, _from, state) do
    deps = resolve_dependencies(capability.dependencies, state)
    {:reply, deps, state}
  end

  defp matches_query?(item, query) do
    Enum.all?(query, fn {key, value} -> Map.get(item, key) == value end)
  end

  defp trace_lineage(cap_id, capabilities, acc) do
    case Map.get(capabilities, cap_id) do
      nil -> acc
      cap ->
        new_acc = [cap | acc]
        case cap.evolution_history do
          [] -> new_acc
          [parent_id | _] -> trace_lineage(parent_id, capabilities, new_acc)
        end
    end
  end

  defp resolve_dependencies(dep_ids, state) do
    Enum.map(dep_ids, fn dep_id ->
      Map.get(state.capabilities, dep_id) || Map.get(state.components, dep_id)
    end)
    |> Enum.reject(&is_nil/1)
  end
end
