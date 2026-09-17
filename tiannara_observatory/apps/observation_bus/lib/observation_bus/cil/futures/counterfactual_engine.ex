defmodule ObservationBus.CIL.Futures.CounterfactualEngine do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_counterfactuals, do: GenServer.call(__MODULE__, :list)
  def get_counterfactual(id), do: GenServer.call(__MODULE__, {:get, id})
  def create(description, changes), do: GenServer.call(__MODULE__, {:create, description, changes})

  @impl true
  def init(_opts) do
    counterfactuals = [
      %{id: "cf_1", description: "Fusion energy achieved by 2035", changes: %{energy: 0.8, economy: 0.6, climate: 0.7}, divergence_score: 0.75, created_at: DateTime.utc_now()},
      %{id: "cf_2", description: "No AGI developed by 2050", changes: %{computing: -0.3, economy: -0.2, governance: 0.1}, divergence_score: 0.45, created_at: DateTime.utc_now()},
      %{id: "cf_3", description: "Asteroid impact 2030 (1km)", changes: %{infrastructure: -0.9, population: -0.3, governance: 0.5}, divergence_score: 0.85, created_at: DateTime.utc_now()},
      %{id: "cf_4", description: "Global carbon neutrality by 2040", changes: %{energy: 0.5, economy: 0.3, climate: 0.8}, divergence_score: 0.55, created_at: DateTime.utc_now()},
      %{id: "cf_5", description: "Molecular manufacturing matures 2045", changes: %{materials: 0.9, manufacturing: 0.8, economy: 0.7}, divergence_score: 0.8, created_at: DateTime.utc_now()},
    ]
    {:ok, %{counterfactuals: counterfactuals}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.counterfactuals, state}
  def handle_call({:get, id}, _from, state) do
    {:reply, Enum.find(state.counterfactuals, &(&1.id == id)), state}
  end
  def handle_call({:create, description, changes}, _from, state) do
    n = length(state.counterfactuals) + 1
    cf = %{id: "cf_#{n}", description: description, changes: changes, divergence_score: :rand.uniform() * 0.8 + 0.1, created_at: DateTime.utc_now()}
    {:reply, cf, %{state | counterfactuals: [cf | state.counterfactuals]}}
  end
end
