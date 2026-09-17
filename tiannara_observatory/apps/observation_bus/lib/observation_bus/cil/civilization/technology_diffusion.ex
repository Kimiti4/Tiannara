defmodule ObservationBus.CIL.Civilization.TechnologyDiffusion do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_technologies, do: GenServer.call(__MODULE__, :list)
  def get_diffusion(id), do: GenServer.call(__MODULE__, {:get, id})
  def advance_stage(id), do: GenServer.cast(__MODULE__, {:advance, id})

  @impl true
  def init(_opts) do
    technologies = %{
      internet: %{id: :internet, name: "Internet", stage: :global_diffusion, adoption_rate: 0.87, year_discovered: 1969, years_to_engineering: 15, years_to_manufacturing: 10, years_to_adoption: 20, years_to_global: 10},
      mobile: %{id: :mobile, name: "Mobile Communications", stage: :global_diffusion, adoption_rate: 0.92, year_discovered: 1973, years_to_engineering: 10, years_to_manufacturing: 8, years_to_adoption: 15, years_to_global: 12},
      solar: %{id: :solar, name: "Solar Energy", stage: :adoption, adoption_rate: 0.35, year_discovered: 1954, years_to_engineering: 25, years_to_manufacturing: 15, years_to_adoption: 30, years_to_global: nil},
      ai: %{id: :ai, name: "Artificial Intelligence", stage: :adoption, adoption_rate: 0.25, year_discovered: 1956, years_to_engineering: 40, years_to_manufacturing: 15, years_to_adoption: 10, years_to_global: nil},
      fusion: %{id: :fusion, name: "Fusion Energy", stage: :discovery, adoption_rate: 0.0, year_discovered: 1950, years_to_engineering: nil, years_to_manufacturing: nil, years_to_adoption: nil, years_to_global: nil},
      quantum: %{id: :quantum, name: "Quantum Computing", stage: :engineering, adoption_rate: 0.02, year_discovered: 1980, years_to_engineering: 40, years_to_manufacturing: nil, years_to_adoption: nil, years_to_global: nil},
    }
    {:ok, %{technologies: technologies}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.technologies, state}
  def handle_call({:get, id}, _from, state), do: {:reply, Map.get(state.technologies, id), state}

  @impl true
  def handle_cast({:advance, id}, state) do
    tech = Map.get(state.technologies, id)
    if tech do
      next_stage = next(tech.stage)
      {:noreply, put_in(state.technologies[id], Map.put(tech, :stage, next_stage))}
    else
      {:noreply, state}
    end
  end

  defp next(:discovery), do: :engineering
  defp next(:engineering), do: :manufacturing
  defp next(:manufacturing), do: :adoption
  defp next(:adoption), do: :global_diffusion
  defp next(:global_diffusion), do: :global_diffusion
end
