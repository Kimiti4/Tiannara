defmodule ObservationBus.CIL.Civilization.KardashevEngine do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_status, do: GenServer.call(__MODULE__, :status)
  def get_projection, do: GenServer.call(__MODULE__, :projection)

  @impl true
  def init(_opts) do
    state = %{
      current_level: 0.72,
      energy_consumption_tw: 18_000,
      planetary_capacity_tw: 174_000,
      stellar_capacity_tw: 386_000_000_000_000,
      growth_rate: 0.025,
      limiting_factors: [:energy_storage, :fusion, :space_infrastructure],
      projected_level_50y: 0.85,
      projected_level_100y: 1.05,
      projected_level_500y: 1.40,
      updated_at: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state, state}
  def handle_call(:projection, _from, state) do
    projection = %{
      current: state.current_level,
      p50: state.projected_level_50y,
      p100: state.projected_level_100y,
      p500: state.projected_level_500y,
      type_I_eta: estimate_eta(state.current_level, 1.0, state.growth_rate),
      type_II_eta: estimate_eta(state.current_level, 2.0, state.growth_rate),
      limiting_factors: state.limiting_factors
    }
    {:reply, projection, state}
  end

  defp estimate_eta(current, target, rate) when rate > 0 do
    years = (target - current) / rate * 100
    max(0, round(years))
  end
  defp estimate_eta(_, _, _), do: :infinity
end
