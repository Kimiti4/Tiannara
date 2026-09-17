defmodule ObservationBus.CIL.Strategy.StrategicPlanner do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @horizons [:d30, :m6, :y2, :y10, :y50]

  def get_plan(horizon) when horizon in @horizons do
    GenServer.call(__MODULE__, {:get_plan, horizon})
  end

  def list_plans, do: GenServer.call(__MODULE__, :list_plans)
  def update_priority(horizon, domain, priority) do
    GenServer.cast(__MODULE__, {:update_priority, horizon, domain, priority})
  end

  @impl true
  def init(_opts) do
    state = %{
      plans: Enum.into(@horizons, %{}, &{&1, initial_plan(&1)}),
      updated_at: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:get_plan, horizon}, _from, state) do
    {:reply, Map.get(state.plans, horizon, %{}), state}
  end

  def handle_call(:list_plans, _from, state) do
    {:reply, state.plans, state}
  end

  @impl true
  def handle_cast({:update_priority, horizon, domain, priority}, state) do
    plans = update_in(state.plans, [horizon, domain], fn _ -> priority end)
    {:noreply, %{state | plans: plans, updated_at: DateTime.utc_now()}}
  end

  defp initial_plan(horizon) do
    %{
      horizon: horizon,
      domains: %{
        mathematics: 0.3, physics: 0.3, biology: 0.2, computing: 0.1, engineering: 0.1
      },
      priorities: %{},
      focus_areas: [],
      updated_at: DateTime.utc_now()
    }
  end
end
