defmodule MetricsEngine.TrendEngine do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(name, value, timestamp \\ DateTime.utc_now()) do
    GenServer.cast(__MODULE__, {:record, name, value, timestamp})
  end

  def trend(name, opts \\ []) do
    GenServer.call(__MODULE__, {:trend, name, opts})
  end

  @impl true
  def init(_opts) do
    {:ok, %{series: %{}}}
  end

  @impl true
  def handle_cast({:record, name, value, timestamp}, %{series: s} = state) do
    points = Map.get(s, name, [])
    trimmed = Enum.take(points, 999)
    {:noreply, %{state | series: Map.put(s, name, [{timestamp, value} | trimmed])}}
  end

  @impl true
  def handle_call({:trend, name, opts}, _from, %{series: s} = state) do
    points = Map.get(s, name, [])
    window = opts[:window] || 10

    recent = Enum.take(points, window)
    values = Enum.map(recent, fn {_, v} -> v end)

    trend =
      cond do
        length(values) < 2 ->
          :insufficient_data

        true ->
          {slope, intercept} = linear_regression(values)
          velocity = slope
          acceleration = if length(values) >= 3, do: compute_acceleration(values), else: 0.0

          %{
            slope: slope,
            intercept: intercept,
            velocity: velocity,
            acceleration: acceleration,
            direction:
              if(slope > 0, do: :increasing, else: if(slope < 0, do: :decreasing, else: :stable)),
            points_analyzed: length(values)
          }
      end

    {:reply, trend, state}
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

  defp compute_acceleration(values) do
    first_diff =
      values
      |> Enum.chunk_every(2, 1)
      |> Enum.filter(fn l -> length(l) == 2 end)
      |> Enum.map(fn [x, y] -> y - x end)

    case length(first_diff) do
      n when n >= 2 ->
        len = length(first_diff)
        last_two = Enum.slice(first_diff, len - 2, 2)
        Enum.at(last_two, 1) - Enum.at(last_two, 0)

      _ ->
        0.0
    end
  end
end
