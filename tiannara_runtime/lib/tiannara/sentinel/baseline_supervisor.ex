defmodule Tiannara.Sentinel.BaselineSupervisor do
  @moduledoc """
  Supervises the baseline learning subsystem, which determines what is "normal"
  before any interventions can occur.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.Sentinel.Baseline.TrendMemory,
      Tiannara.Sentinel.Baseline.AnomalyThresholds,
      Tiannara.Sentinel.Baseline.BaselineBuilder
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
