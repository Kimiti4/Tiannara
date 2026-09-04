defmodule Tiannara.OMCE.Supervisor do
  @moduledoc "Ontological Memory Continuity Extension — extended memory and continuity services"
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.OMCE.MemoryContinuity,
      Tiannara.OMCE.ContinuityIndex
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.OMCE.MemoryContinuity do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OMCE] MemoryContinuity initialized")
    {:ok, %{continuity_log: [], bridge_count: 0}}
  end
  def bridge(source, target), do: GenServer.cast(__MODULE__, {:bridge, source, target})
  def status, do: GenServer.call(__MODULE__, :status)
  @impl true
  def handle_cast({:bridge, source, target}, state) do
    {:noreply, %{state | continuity_log: [%{source: source, target: target, bridged_at: DateTime.utc_now()} | state.continuity_log], bridge_count: state.bridge_count + 1}}
  end
  @impl true
  def handle_call(:status, _from, state), do: {:reply, %{bridges: state.bridge_count, recent: Enum.take(state.continuity_log, 10)}, state}
end

defmodule Tiannara.OMCE.ContinuityIndex do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OMCE] ContinuityIndex initialized")
    {:ok, %{index: %{}, coherence_score: 1.0}}
  end
  def index_entry(key, value), do: GenServer.cast(__MODULE__, {:index, key, value})
  def coherence, do: GenServer.call(__MODULE__, :coherence)
  @impl true
  def handle_cast({:index, key, value}, state) do
    {:noreply, %{state | index: Map.put(state.index, key, value), coherence_score: max(0.0, state.coherence_score - 0.01)}}
  end
  @impl true
  def handle_call(:coherence, _from, state), do: {:reply, state.coherence_score, state}
end
