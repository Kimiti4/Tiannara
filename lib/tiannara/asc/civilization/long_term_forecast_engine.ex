defmodule Tiannara.ASC.Civilization.LongTermForecastEngine do
  use GenServer

  @horizons [10, 25, 50, 100]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def forecast(world_state, policy_results) do
    GenServer.call(__MODULE__, {:forecast, world_state, policy_results}, 60_000)
  end

  @impl true
  def init(_opts), do: {:ok, %{forecasts: 0}}

  @impl true
  def handle_call({:forecast, world_state, _policy_results}, _from, state) do
    projections = Enum.map(@horizons, fn years -> project_state(world_state, years) end)

    result = %{
      horizon_years: 100, projections: projections,
      key_uncertainties: ["Technological paradigm shifts (unpredictable)", "Climate feedback loops (non-linear)",
        "Geopolitical stability (volatile)", "Population dynamics (long lag times)", "Resource discovery/depletion (uncertain)"],
      scenario_range: %{optimistic_factor: 1.2, pessimistic_factor: 0.8},
      confidence: 0.6, forecasted_at: DateTime.utc_now()
    }
    {:reply, {:ok, result}, %{state | forecasts: state.forecasts + 1}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp project_state(world_state, years) do
    uncertainty = min(0.9, years * 0.008)
    projected = Map.new(world_state, fn
      {:updated_at, v} -> {:updated_at, v}
      {key, value} when is_number(value) -> {key, min(1.0, value * :math.pow(1.015, years))}
      {key, value} -> {key, value}
    end)
    %{years: years, state: projected, uncertainty: uncertainty, confidence: max(0.1, 1.0 - uncertainty)}
  end
end
