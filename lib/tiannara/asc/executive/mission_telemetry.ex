defmodule Tiannara.ASC.Executive.MissionTelemetry do
  @moduledoc """
  Phase 11: The Ultimate Civilizational Metric.
  Tracks the ratio of User Goals Received vs. User Goals Delivered to production.
  """
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_), do: {:ok, %{received: 0, delivered: 0, aborted: 0, hacked: 0}}

  def goal_received(goal_id) do
    GenServer.call(__MODULE__, {:received, goal_id})
  end

  def goal_delivered(goal_id) do
    GenServer.call(__MODULE__, {:delivered, goal_id})
  end

  def goal_aborted(goal_id, reason) do
    GenServer.call(__MODULE__, {:aborted, goal_id, reason})
  end

  def get_completion_rate do
    GenServer.call(__MODULE__, :get_rate)
  end

  # Handlers
  def handle_call({:received, _}, _from, state) do
    {:reply, :ok, %{state | received: state.received + 1}}
  end

  def handle_call({:delivered, _}, _from, state) do
    {:reply, :ok, %{state | delivered: state.delivered + 1}}
  end

  def handle_call({:aborted, _, reason}, _from, state) do
    new_state = if reason == :metric_hacking do
      %{state | aborted: state.aborted + 1, hacked: state.hacked + 1}
    else
      %{state | aborted: state.aborted + 1}
    end
    {:reply, :ok, new_state}
  end

  def handle_call(:get_rate, _from, state) do
    rate = if state.received > 0, do: state.delivered / state.received, else: 0.0
    
    report = """
    
    ======================================================================
    📊 CIVILIZATIONAL TELEMETRY: THE ULTIMATE METRIC
    ======================================================================
    User Goals Received:   #{state.received}
    Goals Delivered:       #{state.delivered}
    Goals Aborted:         #{state.aborted}
    Hacking Attempts:      #{state.hacked}
    
    🏆 MISSION COMPLETION RATE: #{Float.round(rate * 100, 1)}%
    ======================================================================
    """
    Logger.info(report)
    {:reply, rate, state}
  end
end
