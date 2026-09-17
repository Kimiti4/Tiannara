defmodule MetricsEngine.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      MetricsEngine.Counter,
      MetricsEngine.Gauge,
      MetricsEngine.Histogram,
      MetricsEngine.TimeWindow,
      MetricsEngine.WindowManager,
      MetricsEngine.TrendEngine,
      MetricsEngine.ForecastEngine,
      MetricsEngine.AggregationEngine,
      MetricsEngine.AlertEngine,
      MetricsEngine.Persistence,
      MetricsEngine.QueryEngine
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
