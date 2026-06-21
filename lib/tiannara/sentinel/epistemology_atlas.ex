defmodule Tiannara.Sentinel.EpistemologyAtlas do
  @moduledoc """
  SEA-2: Analyzes historical EpistemologyRecords to cluster and identify winning archetypes.
  Maps genome configurations to outcomes like survival time, discovery yield, and truth stability.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.EpistemologyArchive

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Analyzes all records and returns the dominant epistemic archetype for a given metric."
  def find_dominant_archetype(metric) do
    GenServer.call(__MODULE__, {:find_dominant, metric})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Sentinel Epistemology Atlas")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:find_dominant, metric}, _from, state) do
    records = EpistemologyArchive.get_all_records()
    if length(records) == 0 do
      {:reply, {:error, :no_records}, state}
    else
      best = Enum.max_by(records, fn r -> Map.get(r, metric, 0.0) end)
      {:reply, {:ok, best.genome}, state}
    end
  end
end
