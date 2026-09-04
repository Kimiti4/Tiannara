defmodule Tiannara.ASC.Executive.CivilizationMetrics do
  @moduledoc """
  The Apex Fitness Metric for the Tiannara Civilization Operating System.
  Tracks the 'Mission Completion Rate' - the ultimate measure of the 
  system's ability to translate human goals into delivered reality.
  """
  use GenServer
  require Logger

  @table :asc_civilization_metrics

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [:named_table, :public, :set])
    :ets.insert(@table, {:total_missions, 0})
    :ets.insert(@table, {:completed_missions, 0})
    {:ok, %{}}
  end

  def record_mission_conclusion(status) do
    :ets.update_counter(@table, :total_missions, {2, 1})
    
    if status == :achieved do
      :ets.update_counter(@table, :completed_missions, {2, 1})
    end
    
    report_completion_rate()
  end

  def report_completion_rate do
    [{:total_missions, total}] = :ets.lookup(@table, :total_missions)
    [{:completed_missions, completed}] = :ets.lookup(@table, :completed_missions)
    
    rate = if total == 0, do: 0.0, else: Float.round(completed / total, 2)
    
    Logger.info("""
    
    =========================================================
    🌐 CIVILIZATION METRICS
    =========================================================
    Total Missions Initiated: #{total}
    Missions Achieved:        #{completed}
    Mission Completion Rate:  #{rate * 100}%
    =========================================================
    """)
    
    rate
  end
end
