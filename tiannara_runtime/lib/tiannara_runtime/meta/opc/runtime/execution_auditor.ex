defmodule Tiannara.Meta.OPC.Runtime.ExecutionAuditor do
  @moduledoc """
  Phase 5F.6 — Execution Auditor

  Tracks and logs every observer physics execution that passes through
  the OPC pipeline. Provides an execution count and per-observer history
  for telemetry and debugging.

  ## Usage

      GenServer.cast(ExecutionAuditor, {:execution, "obs_001"})
      {:ok, 42} = ExecutionAuditor.execution_count()
  """

  use GenServer
  require Logger

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns the total number of executions recorded."
  def execution_count do
    GenServer.call(__MODULE__, :execution_count)
  end

  @doc "Returns per-observer execution counts."
  def observer_stats do
    GenServer.call(__MODULE__, :observer_stats)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("📜 [ExecutionAuditor] Initialized")
    {:ok, %{executions: 0, per_observer: %{}}}
  end

  @impl true
  def handle_cast({:execution, observer_id}, state) do
    Logger.info("📜 [ExecutionAuditor] Execution logged for #{observer_id}")

    per_observer =
      Map.update(state.per_observer, observer_id, 1, &(&1 + 1))

    {:noreply, %{state | executions: state.executions + 1, per_observer: per_observer}}
  end

  @impl true
  def handle_call(:execution_count, _from, state) do
    {:reply, {:ok, state.executions}, state}
  end

  @impl true
  def handle_call(:observer_stats, _from, state) do
    {:reply, {:ok, state.per_observer}, state}
  end
end
