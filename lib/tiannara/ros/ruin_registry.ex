defmodule Tiannara.ROS.RuinRegistry do
  @moduledoc """
  A central registry storing all %CivilizationRuin{} objects.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def store(ruin) do
    GenServer.call(__MODULE__, {:store, ruin})
  end

  def get(civ_id) do
    GenServer.call(__MODULE__, {:get, civ_id})
  end
  
  def exists?(civ_id) do
    GenServer.call(__MODULE__, {:exists?, civ_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}} # civ_id -> ruin
  end

  @impl true
  def handle_call({:store, ruin}, _from, state) do
    # Assuming ruin is either a struct or a map, we key by the original_civ_id or civ_id.
    id = Map.get(ruin, :civ_id) || Map.get(ruin, :original_civ_id)
    new_state = Map.put(state, id, ruin)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get, civ_id}, _from, state) do
    {:reply, Map.get(state, civ_id), state}
  end
  
  @impl true
  def handle_call({:exists?, civ_id}, _from, state) do
    {:reply, Map.has_key?(state, civ_id), state}
  end
end
