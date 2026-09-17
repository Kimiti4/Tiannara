defmodule ObservationBus.CIL.Civilization.InfrastructureEvolution do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_infrastructure, do: GenServer.call(__MODULE__, :get)
  def get_sector(sector), do: GenServer.call(__MODULE__, {:sector, sector})

  @impl true
  def init(_opts) do
    sectors = %{
      energy: %{name: "Energy", maturity: 0.55, capacity: 5000, growth_rate: 0.03, bottlenecks: [:storage, :distribution]},
      water: %{name: "Water", maturity: 0.70, capacity: 8000, growth_rate: 0.01, bottlenecks: [:desalination, :purification]},
      agriculture: %{name: "Agriculture", maturity: 0.65, capacity: 6000, growth_rate: 0.02, bottlenecks: [:soil_depletion, :climate]},
      transportation: %{name: "Transportation", maturity: 0.60, capacity: 4000, growth_rate: 0.015, bottlenecks: [:electrification, :autonomy]},
      communications: %{name: "Communications", maturity: 0.75, capacity: 9000, growth_rate: 0.05, bottlenecks: [:bandwidth, :coverage]},
      computing: %{name: "Computing", maturity: 0.70, capacity: 10000, growth_rate: 0.08, bottlenecks: [:energy, :manufacturing]},
      healthcare: %{name: "Healthcare", maturity: 0.60, capacity: 5000, growth_rate: 0.025, bottlenecks: [:access, :cost]},
    }
    {:ok, %{sectors: sectors, overall_maturity: 0.65}}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}
  def handle_call({:sector, sector}, _from, state), do: {:reply, Map.get(state.sectors, sector), state}
end
