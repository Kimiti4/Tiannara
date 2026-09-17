defmodule ObservationBus.CIL.Mission.MissionTimeline do
  @moduledoc """
  Interactive timeline for each mission's lifecycle.

  Tracks milestones, discoveries, engineering milestones, and completion
  events with timestamps, enabling full historical navigation.
  """
  use GenServer

  @table_name :cil_mission_timeline

  defstruct [:table, :total_events]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:bag, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_events: 0}}
  end

  @doc "Record a timeline event for a mission."
  @spec record(String.t(), String.t(), String.t(), map()) :: :ok
  def record(mission_id, event_type, description, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record, mission_id, event_type, description, metadata})
  end

  @doc "Get timeline for a mission."
  @spec get_timeline(String.t()) :: [map()]
  def get_timeline(mission_id) do
    @table_name
    |> :ets.lookup(mission_id)
    |> Enum.map(fn {^mission_id, entry} -> entry end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
  end

  @doc "Get timeline for all missions."
  @spec all_events() :: [map()]
  def all_events do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {mid, entry} -> Map.put(entry, :mission_id, mid) end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    |> Enum.take(100)
  end

  @impl true
  def handle_cast({:record, mission_id, event_type, description, metadata}, state) do
    entry = %{
      event_type: event_type, description: description, metadata: metadata,
      timestamp: DateTime.utc_now()
    }
    :ets.insert(@table_name, {mission_id, entry})
    {:noreply, %{state | total_events: state.total_events + 1}}
  end
end
