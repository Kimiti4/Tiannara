defmodule ObservationBus.CIL.Strategy.TechnologyRoadmap do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_technology(id), do: GenServer.call(__MODULE__, {:get, id})
  def list_technologies, do: GenServer.call(__MODULE__, :list)
  def update_trl(id, trl), do: GenServer.cast(__MODULE__, {:update_trl, id, trl})

  @impl true
  def init(_opts) do
    state = %{
      technologies: %{
        fusion: %{id: :fusion, name: "Fusion Energy", trl: 4.0, risk: 0.6, benefit: 0.9, est_discovery_months: 60, est_engineering_months: 120, dependencies: [:plasma_physics, :materials, :superconductors], required_research: [:plasma_confinement, :wall_materials]},
        agi: %{id: :agi, name: "Artificial General Intelligence", trl: 3.0, risk: 0.7, benefit: 0.95, est_discovery_months: 36, est_engineering_months: 60, dependencies: [:computing, :neuroscience, :algorithms], required_research: [:architecture, :training]},
        quantum_computing: %{id: :quantum_computing, name: "Quantum Computing", trl: 4.0, risk: 0.5, benefit: 0.85, est_discovery_months: 48, est_engineering_months: 84, dependencies: [:physics, :materials, :cryogenics], required_research: [:qubit_stability, :error_correction]},
        space_elevator: %{id: :space_elevator, name: "Space Elevator", trl: 2.0, risk: 0.8, benefit: 0.8, est_discovery_months: 120, est_engineering_months: 240, dependencies: [:materials, :robotics, :energy], required_research: [:nanotubes, :climbing_mechanisms]},
        nanotech: %{id: :nanotech, name: "Molecular Nanotechnology", trl: 3.0, risk: 0.6, benefit: 0.9, est_discovery_months: 72, est_engineering_months: 120, dependencies: [:chemistry, :physics, :computing], required_research: [:self_assembly, :molecular_manufacturing]},
        bioprinting: %{id: :bioprinting, name: "Bioprinting", trl: 5.0, risk: 0.4, benefit: 0.7, est_discovery_months: 24, est_engineering_months: 36, dependencies: [:biology, :materials, :computing], required_research: [:scaffold_materials, :cell_cultures]}
      }
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:get, id}, _from, state), do: {:reply, Map.get(state.technologies, id), state}
  def handle_call(:list, _from, state), do: {:reply, state.technologies, state}

  @impl true
  def handle_cast({:update_trl, id, trl}, state) do
    tech = Map.get(state.technologies, id)
    if tech do
      {:noreply, put_in(state.technologies[id], Map.put(tech, :trl, trl))}
    else
      {:noreply, state}
    end
  end
end
