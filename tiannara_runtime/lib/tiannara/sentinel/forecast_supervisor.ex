defmodule Tiannara.Sentinel.ForecastSupervisor do
  @moduledoc """
  Supervises the statistical forecasting subsystem.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.Sentinel.Forecasting.EntropyTracker,
      Tiannara.Sentinel.Forecasting.DivergenceAnalyzer,
      Tiannara.Sentinel.Forecasting.CollapseForecaster
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
