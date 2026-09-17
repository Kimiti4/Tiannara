defmodule MetricsEngine.ForecastEngine do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(name, value, timestamp \\ DateTime.utc_now()) do
    GenServer.cast(__MODULE__, {:record, name, value, timestamp})
  end

  def forecast(name, horizon \\ 5) do
    GenServer.call(__MODULE__, {:forecast, name, horizon})
  end

  @impl true
  def init(_opts) do
    {:ok, %{history: %{}}}
  end

  @impl true
  def handle_cast({:record, name, value, timestamp}, %{history: h} = state) do
    points = Map.get(h, name, [])
    trimmed = Enum.take(points, 9999)
    {:noreply, %{state | history: Map.put(h, name, [{timestamp, value} | trimmed])}}
  end

  @impl true
  def handle_call({:forecast, name, horizon}, _from, %{history: h} = state) do
    points = Map.get(h, name, [])
    values = Enum.map(points, fn {_, v} -> v end)

    prediction =
      cond do
        length(values) < 2 ->
          {:error, :insufficient_data}

        true ->
          {slope, intercept} = linear_regression(values)
          last_x = length(values) - 1

          predictions =
            Enum.map(1..horizon, fn step ->
              x = last_x + step
              %{step: step, predicted_value: slope * x + intercept}
            end)

          confidence = min(1.0, length(values) / 100.0)

          %{
            predictions: predictions,
            confidence: Float.round(confidence, 2),
            model: %{slope: slope, intercept: intercept},
            horizon: horizon,
            based_on: length(values)
          }
      end

    {:reply, prediction, state}
  end

  defp linear_regression(values) do
    n = length(values)
    xs = Enum.to_list(0..(n - 1))
    sum_x = Enum.sum(xs)
    sum_y = Enum.sum(values)
    sum_xy = Enum.zip(xs, values) |> Enum.map(fn {x, y} -> x * y end) |> Enum.sum()
    sum_x2 = Enum.map(xs, fn x -> x * x end) |> Enum.sum()

    slope =
      if n * sum_x2 - sum_x * sum_x != 0 do
        (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
      else
        0.0
      end

    intercept = (sum_y - slope * sum_x) / n
    {slope, intercept}
  end
end
