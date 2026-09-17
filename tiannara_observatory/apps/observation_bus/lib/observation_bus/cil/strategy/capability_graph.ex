defmodule ObservationBus.CIL.Strategy.CapabilityGraph do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_capability(id), do: GenServer.call(__MODULE__, {:get, id})
  def list_capabilities, do: GenServer.call(__MODULE__, :list)
  def get_dependencies(id), do: GenServer.call(__MODULE__, {:dependencies, id})
  def get_dependents(id), do: GenServer.call(__MODULE__, {:dependents, id})
  def register_capability(id, attrs) do
    GenServer.cast(__MODULE__, {:register, id, attrs})
  end
  def link(parent, child) do
    GenServer.cast(__MODULE__, {:link, parent, child})
  end

  @impl true
  def init(_opts) do
    state = %{
      nodes: %{
        mathematics: %{id: :mathematics, name: "Mathematics", trl: 9.0, domains: [:fundamental]},
        simulation: %{id: :simulation, name: "Simulation", trl: 8.0, domains: [:computing]},
        physics: %{id: :physics, name: "Physics", trl: 8.5, domains: [:fundamental]},
        materials: %{id: :materials, name: "Materials Science", trl: 7.0, domains: [:engineering]},
        fusion: %{id: :fusion, name: "Fusion Energy", trl: 4.0, domains: [:energy]},
        computing: %{id: :computing, name: "Computing", trl: 8.0, domains: [:computing]},
        ai: %{id: :ai, name: "Artificial Intelligence", trl: 7.0, domains: [:computing]},
        biotechnology: %{id: :biotechnology, name: "Biotechnology", trl: 6.0, domains: [:biology]},
        nanotechnology: %{id: :nanotechnology, name: "Nanotechnology", trl: 5.0, domains: [:engineering]},
        space: %{id: :space, name: "Space Infrastructure", trl: 5.0, domains: [:engineering]},
        civilization: %{id: :civilization, name: "Civilization", trl: 0, domains: [:meta]}
      },
      edges: %{
        mathematics: [:simulation, :physics, :computing],
        simulation: [:materials, :fusion, :ai],
        physics: [:materials, :fusion, :nanotechnology, :space],
        materials: [:nanotechnology, :space, :fusion],
        computing: [:ai, :simulation],
        ai: [:biotechnology, :nanotechnology],
        biotechnology: [],
        nanotechnology: [:space, :materials],
        fusion: [:space, :civilization],
        space: [:civilization]
      }
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:get, id}, _from, state), do: {:reply, Map.get(state.nodes, id), state}
  def handle_call(:list, _from, state), do: {:reply, state.nodes, state}
  def handle_call({:dependencies, id}, _from, state) do
    deps = Map.get(state.edges, id, []) |> Enum.map(&Map.get(state.nodes, &1)) |> Enum.reject(&is_nil/1)
    {:reply, deps, state}
  end
  def handle_call({:dependents, id}, _from, state) do
    deps = Enum.filter(state.edges, fn {_k, v} -> id in v end) |> Enum.map(fn {k, _} -> Map.get(state.nodes, k) end) |> Enum.reject(&is_nil/1)
    {:reply, deps, state}
  end

  @impl true
  def handle_cast({:register, id, attrs}, state) do
    {:noreply, put_in(state.nodes[id], attrs)}
  end
  def handle_cast({:link, parent, child}, state) do
    edges = Map.update(state.edges, parent, [child], fn existing -> [child | existing] |> Enum.uniq() end)
    {:noreply, %{state | edges: edges}}
  end
end
