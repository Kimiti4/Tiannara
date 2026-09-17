defmodule Tiannara.OED.Quarantine.ContradictionTracker do
  @moduledoc """
  🗃️ Quarantine Subsystem Contradiction Tracker.

  Logs, indexes, and tracks specific structural and logical contradictions found
  in candidate rules during ACM and OAVL evaluations.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Logs a new contradiction event for a rule type.
  """
  @spec record_conflict(rule_type :: atom(), conflict_description :: String.t()) :: :ok
  def record_conflict(rule_type, conflict_description) do
    GenServer.cast(__MODULE__, {:record, rule_type, conflict_description})
  end

  @doc """
  Queries active contradictions.
  """
  @spec get_conflicts() :: map()
  def get_conflicts do
    GenServer.call(__MODULE__, :get_conflicts)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:record, rule_type, desc}, state) do
    new_state = Map.update(state, rule_type, [desc], &[desc | &1])
    Logger.warning("🗃️ [Contradiction Tracker] Logged conflict for #{rule_type}: #{desc}")
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_conflicts, _from, state) do
    {:reply, state, state}
  end
end
