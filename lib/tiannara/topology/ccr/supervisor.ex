defmodule Tiannara.Topology.CCR.Supervisor do
  @moduledoc """
  CCR (Cosmological Compiler Reflection) supervisor.

  Coordinates compiler reflection, meta-compilation, and strategic optimization services.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main CCR system
      {Tiannara.Topology.CCR, []},
      
      # Meta-compilation engine
      {Tiannara.Topology.CCR.MetaCompilation, []},
      
      # Compiler performance analyzer
      {Tiannara.Topology.CCR.PerformanceAnalyzer, []},
      
      # Anomaly detector
      {Tiannara.Topology.CCR.AnomalyDetector, []},
      
      # Strategy optimizer
      {Tiannara.Topology.CCR.StrategyOptimizer, []}
    ]

    Logger.info("Initializing CCR supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end