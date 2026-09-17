defmodule ObservatoryState.Scientific do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  @impl true
  def init(_opts) do
    :ets.new(:obs_scientific_state, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(:obs_scientific_state, key) do
      [{^key, value}] -> {:reply, {:ok, value}, state}
      [] -> {:reply, :not_found, state}
    end
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    :ets.insert(:obs_scientific_state, {key, value})
    {:noreply, state}
  end
end
