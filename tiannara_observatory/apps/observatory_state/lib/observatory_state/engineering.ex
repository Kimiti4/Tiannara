defmodule ObservatoryState.Engineering do
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
    :ets.new(:obs_engineering_state, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    result =
      case :ets.lookup(:obs_engineering_state, key) do
        [{^key, value}] -> {:ok, value}
        [] -> :not_found
      end

    {:reply, result, state}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    :ets.insert(:obs_engineering_state, {key, value})
    {:noreply, state}
  end
end
