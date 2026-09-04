defmodule Tiannara.Executive.Cognitive.WorkingMemory do
  @moduledoc """
  Working Memory — short-term executive scratch space.

  Holds transient data for the current cognitive cycle: observations,
  context, priorities, plans, and execution results. Cleared or archived
  at cycle boundaries.
  """

  use GenServer

  require Logger

  @max_slots 256
  @ttl_ms :timer.minutes(10)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec store(atom(), term()) :: :ok
  def store(slot, value) do
    GenServer.cast(__MODULE__, {:store, slot, value})
  end

  @spec retrieve(atom()) :: term() | nil
  def retrieve(slot) do
    GenServer.call(__MODULE__, {:retrieve, slot})
  end

  @spec clear() :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec slots() :: [atom()]
  def slots do
    GenServer.call(__MODULE__, :slots)
  end

  @impl true
  def init(_opts) do
    {:ok, %{memory: %{}, timestamps: %{}, stores: 0, retrieves: 0, clears: 0}}
  end

  @impl true
  def handle_cast({:store, slot, value}, state) do
    now = System.monotonic_time(:millisecond)
    memory = Map.put(state.memory, slot, value)
    timestamps = Map.put(state.timestamps, slot, now)
    {memory, timestamps} = evict_expired(memory, timestamps, now)
    {:noreply, %{state | memory: memory, timestamps: timestamps, stores: state.stores + 1}}
  end

  @impl true
  def handle_cast(:clear, state) do
    {:noreply, %{state | memory: %{}, timestamps: %{}, clears: state.clears + 1}}
  end

  @impl true
  def handle_call({:retrieve, slot}, _from, state) do
    {:reply, Map.get(state.memory, slot), %{state | retrieves: state.retrieves + 1}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{slots: map_size(state.memory), stores: state.stores, retrieves: state.retrieves, clears: state.clears}, state}
  end

  @impl true
  def handle_call(:slots, _from, state) do
    {:reply, Map.keys(state.memory), state}
  end

  defp evict_expired(memory, timestamps, now) do
    expired = timestamps
      |> Enum.filter(fn {_slot, ts} -> now - ts > @ttl_ms end)
      |> Enum.map(fn {slot, _ts} -> slot end)
    {Map.drop(memory, expired), Map.drop(timestamps, expired)}
  end
end
