defmodule TiannaraRuntime.ACF.StatsTracker do
  @moduledoc """
  Stateful GenServer that tracks Axiomatic Conservation Framework (ACF) audit metrics.
  """

  use GenServer
  require Logger

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("📊 [ACF] StatsTracker initialized")
    {:ok, %{total_audits: 0, passed: 0, rejected: 0, rejections_by_reason: %{}}}
  end

  # ==================== Public API ====================

  @doc """
  Record the result of an audit.
  """
  def record_audit(result, reason \\ nil) do
    GenServer.cast(__MODULE__, {:record_audit, result, reason})
  end

  @doc """
  Get the accumulated audit statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Reset all statistics.
  """
  def reset_stats do
    GenServer.cast(__MODULE__, :reset_stats)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_cast({:record_audit, :ok, _reason}, state) do
    new_state = %{
      state |
      total_audits: state.total_audits + 1,
      passed: state.passed + 1
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:record_audit, {:reject, reason}, _}, state) do
    new_rejections = Map.update(state.rejections_by_reason, reason, 1, &(&1 + 1))
    new_state = %{
      state |
      total_audits: state.total_audits + 1,
      rejected: state.rejected + 1,
      rejections_by_reason: new_rejections
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:record_audit, {:error, reason}, _}, state) do
    new_rejections = Map.update(state.rejections_by_reason, reason, 1, &(&1 + 1))
    new_state = %{
      state |
      total_audits: state.total_audits + 1,
      rejected: state.rejected + 1,
      rejections_by_reason: new_rejections
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:reset_stats, _state) do
    {:noreply, %{total_audits: 0, passed: 0, rejected: 0, rejections_by_reason: %{}}}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end
end
