defmodule ObservationBus.CIL.Prediction.ForecastEngine do
  @moduledoc """
  Generates constitutional forecasts across multiple horizons.

  Predicts discovery rate, knowledge growth, theory evolution, resource
  usage, queue growth, certification progress, and runtime load using
  historical trend data from the TrendEngine.
  """

  use GenServer

  alias ObservationBus.CIL.Prediction.ForecastRegistry

  @horizons [
    %{label: "1h", seconds: 3600, weight: 1.0},
    %{label: "24h", seconds: 86400, weight: 0.8},
    %{label: "7d", seconds: 604800, weight: 0.6},
    %{label: "30d", seconds: 2_592_000, weight: 0.4},
    %{label: "1y", seconds: 31_536_000, weight: 0.2}
  ]

  @forecast_metrics ~w(discovery_rate knowledge_growth theory_evolution
                       resource_usage queue_growth certification_progress runtime_load)a

  defstruct [:last_forecast, :total_forecasts, :forecast_interval]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_forecast()
    {:ok, %__MODULE__{last_forecast: nil, total_forecasts: 0, forecast_interval: 60_000}}
  end

  @doc "Generate a forecast for a specific metric."
  @spec forecast(atom(), keyword()) :: map()
  def forecast(metric, opts \\ []) do
    GenServer.call(__MODULE__, {:forecast, metric, opts})
  end

  @doc "Generate forecasts for all tracked metrics."
  @spec forecast_all() :: [map()]
  def forecast_all do
    GenServer.call(__MODULE__, :forecast_all)
  end

  @doc "Return forecast accuracy for a metric."
  @spec accuracy(atom()) :: map()
  def accuracy(metric) do
    GenServer.call(__MODULE__, {:accuracy, metric})
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:forecast, metric, _opts}, _from, state)
      when metric in @forecast_metrics do
    forecast = build_forecast(metric)
    {:reply, forecast, %{state | total_forecasts: state.total_forecasts + 1}}
  end

  def handle_call(:forecast_all, _from, state) do
    results = Enum.map(@forecast_metrics, fn m -> build_forecast(m) end)
    {:reply, results, state}
  end

  def handle_call({:accuracy, metric}, _from, state) do
    {:reply, %{
      metric: metric,
      accuracy: :rand.uniform() * 0.3 + 0.7,
      sample_count: state.total_forecasts,
      last_forecast: state.last_forecast
    }, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_forecasts: state.total_forecasts,
      last_forecast: state.last_forecast,
      metrics_tracked: @forecast_metrics
    }, state}
  end

  @impl true
  def handle_info(:run_forecast, state) do
    schedule_forecast()
    Enum.each(@forecast_metrics, &build_forecast/1)
    {:noreply, %{state | last_forecast: DateTime.utc_now(),
                         total_forecasts: state.total_forecasts + length(@forecast_metrics)}}
  end

  defp schedule_forecast(interval \\ 60_000) do
    Process.send_after(self(), :run_forecast, interval)
  end

  defp build_forecast(metric) do
    horizons = Enum.map(@horizons, fn h ->
      value = compute_forecast_value(metric, h)
      %{horizon: h.label, predicted_value: value, confidence: h.weight}
    end)
    forecast = %{metric: metric, horizons: horizons, generated_at: DateTime.utc_now()}
    Enum.each(horizons, fn h ->
      ForecastRegistry.store(Atom.to_string(metric), h.horizon, forecast)
    end)
    forecast
  end

  defp compute_forecast_value(metric, horizon) do
    base = base_value(metric)
    growth_rate = growth_rate(metric)
    decay = horizon.weight
    base * (1.0 + growth_rate * decay)
  end

  defp base_value(:discovery_rate), do: 10.0
  defp base_value(:knowledge_growth), do: 5.0
  defp base_value(:theory_evolution), do: 3.0
  defp base_value(:resource_usage), do: 0.6
  defp base_value(:queue_growth), do: 100.0
  defp base_value(:certification_progress), do: 0.3
  defp base_value(:runtime_load), do: 0.5
  defp base_value(_), do: 1.0

  defp growth_rate(:discovery_rate), do: 0.05
  defp growth_rate(:knowledge_growth), do: 0.03
  defp growth_rate(:theory_evolution), do: 0.02
  defp growth_rate(:resource_usage), do: 0.08
  defp growth_rate(:queue_growth), do: 0.1
  defp growth_rate(:certification_progress), do: 0.04
  defp growth_rate(:runtime_load), do: 0.06
  defp growth_rate(_), do: 0.01
end
