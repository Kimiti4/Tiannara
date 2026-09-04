defmodule Tiannara.Sentinel.ObservationBuffer do
  @moduledoc """
  Observation Buffer — ring buffer for recent observations.

  Stores the most recent N observations in memory for windowed analysis
  by PatternDetector and AnomalyClassifier. Older observations are evicted.

  ## Constitutional Alignment

    - Modularity: Isolated storage; can be replaced with time-series DB.
    - Observability: Buffer contents are fully inspectable.
    - Fault tolerance: Buffer loss is non-fatal; observations regenerate.
    - Scalability: Fixed memory footprint regardless of runtime duration.
    - Memory Philosophy: This is the "Data" stage; patterns and knowledge
      are extracted by higher-level modules.
  """

  use GenServer

  require Logger

  @default_max_size 10_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec append(map()) :: :ok
  def append(observation) do
    GenServer.cast(__MODULE__, {:append, observation})
  end

  @spec recent(non_neg_integer()) :: [map()]
  def recent(count \\ 50) do
    GenServer.call(__MODULE__, {:recent, count})
  end

  @spec by_type(atom(), non_neg_integer()) :: [map()]
  def by_type(type, count \\ 50) do
    GenServer.call(__MODULE__, {:by_type, type, count})
  end

  @spec window(DateTime.t(), DateTime.t()) :: [map()]
  def window(from, to) do
    GenServer.call(__MODULE__, {:window, from, to})
  end

  @spec total_observations() :: non_neg_integer()
  def total_observations do
    GenServer.call(__MODULE__, :total_observations)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec clear() :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @impl true
  def init(opts) do
    max_size = Keyword.get(opts, :max_size, @default_max_size)
    {:ok, %{buffer: :queue.new(), max_size: max_size, current_size: 0, total_received: 0, total_evicted: 0}}
  end

  @impl true
  def handle_cast({:append, observation}, state) do
    buffer = :queue.in(observation, state.buffer)

    {buffer, current_size, evicted} =
      if state.current_size >= state.max_size do
        {{:value, _old}, trimmed} = :queue.out(buffer)
        {trimmed, state.current_size, state.total_evicted + 1}
      else
        {buffer, state.current_size + 1, state.total_evicted}
      end

    {:noreply, %{state | buffer: buffer, current_size: current_size, total_received: state.total_received + 1, total_evicted: evicted}}
  end

  @impl true
  def handle_cast(:clear, state) do
    {:noreply, %{state | buffer: :queue.new(), current_size: 0}}
  end

  @impl true
  def handle_call({:recent, count}, _from, state) do
    observations = state.buffer |> :queue.to_list() |> Enum.take(-count) |> Enum.reverse()
    {:reply, observations, state}
  end

  @impl true
  def handle_call({:by_type, type, count}, _from, state) do
    observations = state.buffer |> :queue.to_list() |> Enum.filter(fn obs -> obs[:type] == type end) |> Enum.take(-count) |> Enum.reverse()
    {:reply, observations, state}
  end

  @impl true
  def handle_call({:window, from, to}, _from, state) do
    observations = state.buffer |> :queue.to_list() |> Enum.filter(fn obs ->
      ts = obs[:timestamp]
      ts != nil and DateTime.compare(ts, from) != :lt and DateTime.compare(ts, to) != :gt
    end)
    {:reply, observations, state}
  end

  @impl true
  def handle_call(:total_observations, _from, state) do
    {:reply, state.total_received, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{current_size: state.current_size, max_size: state.max_size, total_received: state.total_received, total_evicted: state.total_evicted}, state}
  end
end
