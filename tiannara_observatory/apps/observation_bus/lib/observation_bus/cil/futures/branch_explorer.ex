defmodule ObservationBus.CIL.Futures.BranchExplorer do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_tree, do: GenServer.call(__MODULE__, :tree)
  def get_branch(id), do: GenServer.call(__MODULE__, {:branch, id})
  def explore(future_id, depth), do: GenServer.call(__MODULE__, {:explore, future_id, depth})

  @impl true
  def init(_opts) do
    tree = %{
      root: %{id: "present", name: "Present", children: ["future_a", "future_b", "future_c", "future_d"]},
      future_a: %{id: "future_a", name: "Accelerated Growth", probability: 0.25, benefit: 0.85, risk: 0.6, fitness: 0.7, children: ["future_a1", "future_a2"]},
      future_a1: %{id: "future_a1", name: "AGI Breakthrough", probability: 0.12, benefit: 0.9, risk: 0.75, fitness: 0.65, children: []},
      future_a2: %{id: "future_a2", name: "Energy Abundance", probability: 0.13, benefit: 0.8, risk: 0.4, fitness: 0.78, children: []},
      future_b: %{id: "future_b", name: "Stable Plateau", probability: 0.30, benefit: 0.6, risk: 0.3, fitness: 0.72, children: ["future_b1"]},
      future_b1: %{id: "future_b1", name: "Gradual Reform", probability: 0.30, benefit: 0.55, risk: 0.25, fitness: 0.75, children: []},
      future_c: %{id: "future_c", name: "Collapse & Recovery", probability: 0.20, benefit: 0.4, risk: 0.85, fitness: 0.35, children: ["future_c1"]},
      future_c1: %{id: "future_c1", name: "Resilient Rebuild", probability: 0.15, benefit: 0.5, risk: 0.6, fitness: 0.45, children: []},
      future_d: %{id: "future_d", name: "Transformation", probability: 0.25, benefit: 0.9, risk: 0.7, fitness: 0.8, children: ["future_d1", "future_d2"]},
      future_d1: %{id: "future_d1", name: "Post-Scarcity", probability: 0.10, benefit: 0.95, risk: 0.5, fitness: 0.85, children: []},
      future_d2: %{id: "future_d2", name: "Global Governance", probability: 0.15, benefit: 0.7, risk: 0.4, fitness: 0.72, children: []},
    }
    {:ok, %{tree: tree, total_branches: map_size(tree)}}
  end

  @impl true
  def handle_call(:tree, _from, state), do: {:reply, state.tree, state}
  def handle_call({:branch, id}, _from, state) do
    {:reply, Map.get(state.tree, String.to_atom(id)) || Map.get(state.tree, id), state}
  end
  def handle_call({:explore, _future_id, depth}, _from, state) when depth > 0 do
    node_count = min(depth * 3, 30)
    {:reply, %{generated: node_count, depth: depth}, state}
  end
end
