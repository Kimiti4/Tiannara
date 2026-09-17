defmodule ObservationBus.CIL.Civilization.KnowledgeEconomy do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_metrics, do: GenServer.call(__MODULE__, :get)

  @impl true
  def init(_opts) do
    state = %{
      knowledge_production: 0.62,
      knowledge_transfer: 0.55,
      innovation_velocity: 0.48,
      scientific_workforce: 0.35,
      engineering_productivity: 0.52,
      publications_per_year: 2_500_000,
      patent_rate: 0.04,
      r_and_d_gdp_ratio: 0.028,
      updated_at: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}
end
