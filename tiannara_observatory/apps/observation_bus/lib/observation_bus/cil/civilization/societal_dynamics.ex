defmodule ObservationBus.CIL.Civilization.SocietalDynamics do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_dynamics, do: GenServer.call(__MODULE__, :get)

  @impl true
  def init(_opts) do
    state = %{
      population: 8_100_000_000,
      literacy_rate: 0.87,
      higher_education_rate: 0.40,
      collaboration_index: 0.55,
      institutional_quality: 0.60,
      scientific_culture: 0.45,
      urbanization: 0.57,
      life_expectancy: 73.5,
      updated_at: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}
end
