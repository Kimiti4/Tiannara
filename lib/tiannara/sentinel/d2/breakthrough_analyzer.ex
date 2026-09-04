defmodule Tiannara.Sentinel.D2.BreakthroughContext do
  @moduledoc "Context snapshot when a monumental breakthrough occurs."
  defstruct [
    :species_id,
    :operators,
    :diseases,
    :tension,
    :truth_capital,
    :shard,
    :epoch,
    :origin_type
  ]
end

defmodule Tiannara.Sentinel.D2.BreakthroughAnalyzer do
  @moduledoc """
  D.2: Captures the conditions under which monumental breakthroughs emerge.
  """
  use GenServer
  require Logger
  alias Tiannara.Sentinel.D2.BreakthroughContext

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records a major breakthrough discovery."
  def record_breakthrough(discovery_id, impact_score, civ_id, context \\ %{}) do
    GenServer.cast(__MODULE__, {:record, discovery_id, impact_score, civ_id, context})
  end

  @doc "Retrieves all breakthroughs."
  def get_breakthroughs do
    GenServer.call(__MODULE__, :get_breakthroughs, :infinity)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting D.2 BreakthroughAnalyzer")
    {:ok, %{records: []}}
  end

  @impl true
  def handle_cast({:record, disc_id, impact, civ_id, context_map}, state) do
    b_ctx = %BreakthroughContext{
      species_id: Map.get(context_map, :species_id, "unknown"),
      operators: Map.get(context_map, :operators, []),
      diseases: Map.get(context_map, :diseases, []),
      tension: Map.get(context_map, :tension, 0.0),
      truth_capital: Map.get(context_map, :truth_capital, 0.0),
      shard: Map.get(context_map, :shard, "unknown"),
      epoch: Map.get(context_map, :epoch, 0),
      origin_type: Map.get(context_map, :origin_type, :random_derived)
    }

    record = %{
      discovery_id: disc_id,
      impact_score: impact,
      civilization_id: civ_id,
      context: b_ctx,
      timestamp: System.system_time(:millisecond)
    }

    Logger.info("💡 [BreakthroughAnalyzer] Recorded breakthrough #{disc_id} (Impact: #{impact}) from #{civ_id} (Origin: #{b_ctx.origin_type})")
    {:noreply, %{state | records: [record | state.records]}}
  end

  @impl true
  def handle_call(:get_breakthroughs, _from, state) do
    {:reply, state.records, state}
  end

  @impl true
  def handle_call(:calculate_dar, _from, state) do
    meta_count = Enum.count(state.records, fn r -> r.context.origin_type == :meta_derived end)
    random_count = Enum.count(state.records, fn r -> r.context.origin_type == :random_derived end)
    
    dar = if random_count > 0 do
      meta_count / random_count
    else
      if meta_count > 0, do: 999.0, else: 0.0
    end
    
    {:reply, dar, state}
  end

  @doc "Calculates the Directed Advantage Ratio (DAR)."
  def calculate_dar do
    GenServer.call(__MODULE__, :calculate_dar, :infinity)
  end
end
