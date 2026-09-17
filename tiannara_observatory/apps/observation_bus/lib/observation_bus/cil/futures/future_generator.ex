defmodule ObservationBus.CIL.Futures.FutureGenerator do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_futures, do: GenServer.call(__MODULE__, :list)
  def get_future(id), do: GenServer.call(__MODULE__, {:get, id})
  def generate(type), do: GenServer.call(__MODULE__, {:generate, type})
  def generate_scenario(name, params), do: GenServer.call(__MODULE__, {:scenario, name, params})

  @future_types [:deterministic, :stochastic, :adversarial, :optimistic, :catastrophic]

  @impl true
  def init(_opts) do
    futures = Enum.map(1..20, fn i ->
      type = Enum.random(@future_types)
      %{
        id: "future_#{i}",
        name: "Future #{i}",
        type: type,
        probability: :rand.uniform() * 0.8 + 0.1,
        benefit: :rand.uniform() * 0.7 + 0.2,
        risk: :rand.uniform() * 0.6,
        fitness: :rand.uniform() * 0.8 + 0.1,
        scientific_progress: :rand.uniform() * 0.7 + 0.2,
        engineering_progress: :rand.uniform() * 0.6 + 0.2,
        safety: :rand.uniform() * 0.5 + 0.3,
        sustainability: :rand.uniform() * 0.6 + 0.2,
        constitution_alignment: :rand.uniform() * 0.7 + 0.2,
        branches: Enum.map(1..(:rand.uniform(5) + 2), fn j -> "branch_#{i}_#{j}" end),
        generated_at: DateTime.utc_now()
      }
    end)
    {:ok, %{futures: futures, scenarios: %{}}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.futures, state}
  def handle_call({:get, id}, _from, state) do
    {:reply, Enum.find(state.futures, &(&1.id == id)), state}
  end
  def handle_call({:generate, type}, _from, state) when type in @future_types do
    n = length(state.futures) + 1
    future = %{
      id: "future_#{n}",
      name: "Future #{n} (#{type})",
      type: type,
      probability: :rand.uniform() * 0.8,
      benefit: :rand.uniform() * 0.8,
      risk: :rand.uniform() * 0.6,
      fitness: :rand.uniform() * 0.8,
      scientific_progress: :rand.uniform() * 0.8,
      engineering_progress: :rand.uniform() * 0.8,
      safety: :rand.uniform() * 0.7,
      sustainability: :rand.uniform() * 0.7,
      constitution_alignment: :rand.uniform() * 0.8,
      branches: [],
      generated_at: DateTime.utc_now()
    }
    {:reply, future, %{state | futures: [future | state.futures]}}
  end
  def handle_call({:scenario, name, params}, _from, state) do
    scenario = %{name: name, params: params, created_at: DateTime.utc_now()}
    {:reply, scenario, %{state | scenarios: Map.put(state.scenarios, name, scenario)}}
  end
end
