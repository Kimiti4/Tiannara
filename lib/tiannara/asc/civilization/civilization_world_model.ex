defmodule Tiannara.ASC.Civilization.WorldModel do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def current_state, do: GenServer.call(__MODULE__, :current_state)
  def update_from_deployments(payload), do: GenServer.cast(__MODULE__, {:update, payload})
  def project(domain, years), do: GenServer.call(__MODULE__, {:project, domain, years})

  @impl true
  def init(_opts) do
    {:ok, %{state: initial_state(), history: [], updates: 0, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:current_state, _from, state), do: {:reply, state.state, state}

  def handle_call({:project, domain, years}, _from, state) do
    current = Map.get(state.state, domain, 0.5)
    projected = current * :math.pow(1.02, years)
    {:reply, %{domain: domain, current: current, projected: min(1.0, projected), years: years, uncertainty: min(0.9, years * 0.01)}, state}
  end

  @impl true
  def handle_cast({:update, payload}, state) do
    new_state = apply_updates(state.state, payload)
    {:noreply, %{state | state: new_state, history: [new_state | state.history] |> Enum.take(365), updates: state.updates + 1}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp initial_state do
    %{
      technology: 0.6, economics: 0.5, governance: 0.5, ecology: 0.4,
      medicine: 0.6, logistics: 0.5, education: 0.5, energy: 0.4,
      manufacturing: 0.5, scientific_output: 0.5, population_wellbeing: 0.5,
      sustainability_index: 0.4, innovation_rate: 0.5, knowledge_retention: 0.6,
      updated_at: DateTime.utc_now()
    }
  end

  defp apply_updates(state, payload) do
    deployments = get_in(payload, [:result, :designs]) || 0
    tech_boost = deployments * 0.001
    %{state |
      technology: min(1.0, state.technology + tech_boost),
      manufacturing: min(1.0, state.manufacturing + deployments * 0.0005),
      scientific_output: min(1.0, state.scientific_output + tech_boost * 0.5),
      updated_at: DateTime.utc_now()
    }
  end
end
