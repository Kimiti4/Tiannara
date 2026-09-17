defmodule ObservationBus.CIL.Prediction.ForecastRegistry do
  @moduledoc """
  ETS-backed registry for constitutional forecasts.

  Stores forecasts keyed by metric name and horizon, enabling
  lookup of predictions across all forecast dimensions.
  """
  use GenServer

  @table_name :cil_forecast_registry

  defstruct [:table, :total_forecasts]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true,
                                   read_concurrency: true])
    {:ok, %{table: table, total_forecasts: 0}}
  end

  @doc "Store a forecast."
  @spec store(String.t(), String.t(), map()) :: :ok
  def store(metric, horizon, forecast) do
    GenServer.cast(__MODULE__, {:store, metric, horizon, forecast, DateTime.utc_now()})
  end

  @doc "Get forecast for a metric and horizon."
  @spec get(String.t(), String.t()) :: map() | nil
  def get(metric, horizon) do
    case :ets.lookup(@table_name, {metric, horizon}) do
      [{_, forecast}] -> forecast
      [] -> nil
    end
  end

  @doc "List all forecasts for a metric."
  @spec list_for_metric(String.t()) :: [map()]
  def list_for_metric(metric) do
    @table_name
    |> :ets.match({{metric, :"$1"}, :"$2"})
    |> Enum.map(fn [horizon, forecast] -> Map.put(forecast, :horizon, horizon) end)
  end

  @doc "List all stored forecasts."
  @spec all() :: [map()]
  def all do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {{metric, horizon}, forecast} ->
      Map.put(Map.put(forecast, :metric, metric), :horizon, horizon)
    end)
  end

  @doc "Return registry stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:store, metric, horizon, forecast, now}, state) do
    :ets.insert(@table_name, {{metric, horizon}, Map.put(forecast, :stored_at, now)})
    {:noreply, %{state | total_forecasts: state.total_forecasts + 1}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_forecasts: state.total_forecasts,
      unique_metrics: :ets.info(@table_name, :size)
    }, state}
  end
end
