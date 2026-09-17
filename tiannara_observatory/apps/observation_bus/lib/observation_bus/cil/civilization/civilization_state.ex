defmodule ObservationBus.CIL.Civilization.CivilizationState do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_state, do: GenServer.call(__MODULE__, :get)
  def update_dimension(key, value), do: GenServer.cast(__MODULE__, {:update, key, value})

  @impl true
  def init(_opts) do
    state = %{
      scientific_capability: 0.65,
      engineering_capability: 0.55,
      infrastructure: 0.50,
      education: 0.60,
      innovation: 0.58,
      energy: 0.45,
      governance: 0.62,
      resilience: 0.55,
      updated_at: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:update, key, value}, state) when is_atom(key) do
    if Map.has_key?(state, key) do
      {:noreply, Map.put(state, key, value) |> Map.put(:updated_at, DateTime.utc_now())}
    else
      {:noreply, state}
    end
  end
end
