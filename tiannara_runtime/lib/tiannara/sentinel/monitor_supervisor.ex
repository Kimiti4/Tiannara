defmodule Tiannara.Sentinel.MonitorSupervisor do
  @moduledoc """
  Supervises all specialized passive monitors.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.Sentinel.Monitors.RuntimeMonitor,
      Tiannara.Sentinel.Monitors.PressureMonitor,
      Tiannara.Sentinel.Monitors.EcologicalMonitor,
      Tiannara.Sentinel.Monitors.SemanticMonitor,
      Tiannara.Sentinel.Monitors.CausalMonitor,
      Tiannara.Sentinel.Monitors.CollapseMonitor,
      Tiannara.Sentinel.Monitors.EmergenceMonitor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
