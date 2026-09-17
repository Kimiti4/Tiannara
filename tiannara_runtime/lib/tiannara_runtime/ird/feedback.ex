defmodule TiannaraRuntime.IRD.Feedback do
  @moduledoc """
  Phase 5F.12 — IRD Feedback Collector

  Records outcome events for IRD proposals and provides runtime
  metrics for the intervention pipeline.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{history: [], counts: %{scheduled: 0, deferred: 0, executed: 0}}}
  end

  @doc "Record an outcome event from the IRD pipeline."
  def record_outcome(outcome) when is_map(outcome) do
    GenServer.cast(__MODULE__, {:record_outcome, outcome})
  end

  @doc "Get recent IRD feedback history."
  def get_history do
    GenServer.call(__MODULE__, :get_history)
  end

  @impl true
  def handle_cast({:record_outcome, outcome}, state) do
    Logger.debug("[IRD] Feedback recorded: #{inspect(outcome)}")

    new_counts = Map.update(state.counts, outcome.status, 1, &(&1 + 1))
    new_history = [Map.put(outcome, :recorded_at, DateTime.utc_now() |> DateTime.to_iso8601()) | Enum.take(state.history, 99)]

    {:noreply, %{state | history: new_history, counts: new_counts}}
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, {:ok, state.history}, state}
  end
end
