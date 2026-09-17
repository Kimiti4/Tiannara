defmodule ObservationBus.CIL.Futures.FutureArchive do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_simulations, do: GenServer.call(__MODULE__, :list)
  def get_simulation(id), do: GenServer.call(__MODULE__, {:get, id})
  def search(query), do: GenServer.call(__MODULE__, {:search, query})
  def archive(simulation), do: GenServer.cast(__MODULE__, {:archive, simulation})

  @impl true
  def init(_opts) do
    types = [:deterministic, :stochastic, :adversarial, :optimistic, :catastrophic]
    simulations = Enum.map(1..50, fn i ->
      %{
        id: "sim_#{i}",
        name: "Simulation #{i}",
        type: Enum.random(types),
        fitness: :rand.uniform() * 0.8 + 0.1,
        branches: :rand.uniform(100) + 10,
        generated_at: DateTime.add(DateTime.utc_now(), -:rand.uniform(86400 * 30), :second),
        archived: false
      }
    end)
    {:ok, %{simulations: simulations, total_archived: 50}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.simulations, state}
  def handle_call({:get, id}, _from, state) do
    {:reply, Enum.find(state.simulations, &(&1.id == id)), state}
  end
  def handle_call({:search, query}, _from, state) do
    results = Enum.filter(state.simulations, fn s ->
      String.contains?(String.downcase(s.name), String.downcase(query))
    end)
    {:reply, results, state}
  end

  @impl true
  def handle_cast({:archive, simulation}, state) do
    sim = Map.put(simulation, :archived, true)
    {:noreply, %{state | simulations: [sim | state.simulations], total_archived: state.total_archived + 1}}
  end
end
