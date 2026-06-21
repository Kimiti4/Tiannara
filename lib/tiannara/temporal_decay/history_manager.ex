defmodule Tiannara.TemporalDecay.HistoryManager do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      history_entries: %{},
      entry_importance: %{},
      config: %{min_retention_ms: 60000, max_retention_ms: 3600000, importance_threshold: 0.3, decay_rate: 0.95}
    }}
  end

  def record_history(entry_id, data, importance \\ 0.5) do
    GenServer.cast(__MODULE__, {:record, entry_id, data, importance})
  end

  def mark_anchor(entry_id) do
    GenServer.cast(__MODULE__, {:mark_anchor, entry_id})
  end

  def get_history_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def handle_cast({:record, entry_id, data, importance}, state) do
    entry = %{entry_id: entry_id, data: data, created_at: System.monotonic_time(:millisecond), is_anchor: false}
    new_entries = Map.put(state.history_entries, entry_id, entry)
    new_importance = Map.put(state.entry_importance, entry_id, importance)
    {:noreply, %{state | history_entries: new_entries, entry_importance: new_importance}}
  end

  def handle_cast({:mark_anchor, entry_id}, state) do
    new_entries = if Map.has_key?(state.history_entries, entry_id) do
      Map.update!(state.history_entries, entry_id, fn e -> Map.put(e, :is_anchor, true) end)
    else
      state.history_entries
    end
    Logger.debug("Temporal Decay: Marked #{entry_id} as anchor")
    {:noreply, %{state | history_entries: new_entries}}
  end

  def handle_call(:get_stats, _from, state) do
    stats = %{total_entries: map_size(state.history_entries), entries_tracked: length(state.entry_importance)}
    {:reply, stats, state}
  end
end
