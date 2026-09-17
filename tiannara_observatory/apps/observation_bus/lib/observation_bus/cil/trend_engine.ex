defmodule ObservationBus.CIL.TrendEngine do
  @moduledoc """
  Computes long-term constitutional trajectories across multiple horizons.

  Supports 1-hour, 1-day, 1-week, 1-month, and 1-year horizons.
  Tracks metrics: discovery_velocity, theory_diversity, knowledge_growth,
  engineering_maturity, prediction_accuracy, unknown_density, evolution_efficiency.
  """

  use GenServer

  @metrics ~w(discovery_velocity theory_diversity knowledge_growth
              engineering_maturity prediction_accuracy unknown_density
              evolution_efficiency)a

  @horizons [%{label: "1h", seconds: 3600},
             %{label: "1d", seconds: 86400},
             %{label: "1w", seconds: 604800},
             %{label: "1m", seconds: 2_592_000},
             %{label: "1y", seconds: 31_536_000}]

  @table_name :cil_trend_data

  defstruct [:table, :data_points, :last_computation]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true,
                                   read_concurrency: true])
    {:ok, %{table: table, data_points: 0, last_computation: nil}}
  end

  @doc "Record a metric observation at the current time."
  @spec record(String.t() | atom(), float()) :: :ok
  def record(metric, value) when is_atom(metric) do
    GenServer.cast(__MODULE__, {:record, metric, value, DateTime.utc_now()})
  end
  def record(metric, value) do
    record(String.to_existing_atom(metric), value)
  end

  @doc "Compute trend for a metric across all horizons."
  @spec trend(atom()) :: map()
  def trend(metric) do
    GenServer.call(__MODULE__, {:trend, metric})
  end

  @doc "Compute trends for all metrics."
  @spec all_trends() :: %{atom() => map()}
  def all_trends do
    GenServer.call(__MODULE__, :all_trends)
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:record, metric, value, timestamp}, state) do
    key = {metric, timestamp}
    :ets.insert(@table_name, {key, value})
    {:noreply, %{state | data_points: state.data_points + 1}}
  end

  @impl true
  def handle_call({:trend, metric}, _from, state) do
    points = get_data_points(metric)
    horizons = compute_horizons(points, metric)
    {:reply, %{metric: metric, data_points: length(points), horizons: horizons}, state}
  end

  def handle_call(:all_trends, _from, state) do
    results = Enum.map(@metrics, fn m ->
      points = get_data_points(m)
      horizons = compute_horizons(points, m)
      {m, %{metric: m, data_points: length(points), horizons: horizons}}
    end)
    {:reply, Map.new(results), state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      data_points: state.data_points,
      last_computation: state.last_computation,
      metrics_tracked: @metrics
    }, state}
  end

  defp get_data_points(metric) do
    @table_name
    |> :ets.match({{metric, :"$1"}, :"$2"})
    |> Enum.map(fn [ts, val] -> {ts, val} end)
    |> Enum.sort_by(&elem(&1, 0), {:desc, DateTime})
  end

  defp compute_horizons(points, _metric) do
    now = DateTime.utc_now()
    Enum.map(@horizons, fn horizon ->
      window_points = Enum.filter(points, fn {ts, _} ->
        case DateTime.diff(now, ts, :second) do
          diff when diff <= horizon.seconds -> true
          _ -> false
        end
      end)

      values = Enum.map(window_points, &elem(&1, 1))
      count = length(values)

      %{
        horizon: horizon.label,
        sample_count: count,
        current: List.last(values),
        mean: if(count > 0, do: Enum.sum(values) / count, else: nil),
        min: if(count > 0, do: Enum.min(values), else: nil),
        max: if(count > 0, do: Enum.max(values), else: nil),
        slope: if(count >= 2, do: compute_slope(window_points), else: nil),
        direction: if(count >= 2, do: compute_direction(window_points), else: :stable)
      }
    end)
  end

  defp compute_slope(points) when length(points) < 2, do: 0.0
  defp compute_slope(points) do
    sorted = Enum.sort_by(points, &elem(&1, 0))
    values = Enum.map(sorted, &elem(&1, 1))
    n = length(values)
    xs = Enum.to_list(0..(n - 1))
    ys = values
    sum_x = Enum.sum(xs)
    sum_y = Enum.sum(ys)
    sum_xy = Enum.zip(xs, ys) |> Enum.map(fn {x, y} -> x * y end) |> Enum.sum()
    sum_x2 = Enum.map(xs, &(&1 * &1)) |> Enum.sum()
    (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x + 1.0e-10)
  end

  defp compute_direction(points) do
    slope = compute_slope(points)
    cond do
      slope > 0.05 -> :increasing
      slope < -0.05 -> :decreasing
      true -> :stable
    end
  end
end
