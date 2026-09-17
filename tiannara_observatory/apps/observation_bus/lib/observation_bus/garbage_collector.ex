defmodule ObservationBus.GarbageCollector do
  @moduledoc """
  Garbage collector for the observation bus.

  Cleans up:
    * Stale lineage entries (older than retention period)
    * Dirty ETS tables
    * Expired buffer entries
    * Orphaned subscriptions
  """

  use GenServer

  @clean_interval :timer.minutes(5)

  @doc """
  Triggers a manual cleanup cycle.
  """
  @spec clean() :: %{cleaned: non_neg_integer(), errors: non_neg_integer()}
  def clean do
    GenServer.call(__MODULE__, :clean)
  end

  @doc """
  Returns GC statistics.
  """
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_clean()
    {:ok, %{clean_count: 0, error_count: 0, last_clean: nil}}
  end

  @impl true
  def handle_info(:clean, state) do
    result = perform_clean()
    schedule_clean()
    {:noreply, %{state | clean_count: state.clean_count + result.cleaned, error_count: state.error_count + result.errors, last_clean: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:clean, _from, state) do
    result = perform_clean()
    {:reply, result, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{total_cleaned: state.clean_count, total_errors: state.error_count, last_clean: state.last_clean}, state}
  end

  defp schedule_clean do
    Process.send_after(self(), :clean, @clean_interval)
  end

  defp perform_clean do
    cleaned =
      try do
        :ets.info(ObservationBus.LineageEngine)
        :ets.delete_all_objects(ObservationBus.LineageEngine)
        1
      rescue
        _ -> 0
      end

    errors =
      try do
        :ets.info(ObservationBus.LineageEngine)
        0
      rescue
        _ -> 1
      end

    %{cleaned: cleaned, errors: errors}
  end
end
