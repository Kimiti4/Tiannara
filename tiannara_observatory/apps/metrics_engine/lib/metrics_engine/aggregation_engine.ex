defmodule MetricsEngine.AggregationEngine do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def aggregate(name, function, window_ms \\ 60_000) do
    GenServer.call(__MODULE__, {:aggregate, name, function, window_ms})
  end

  def record(name, value) do
    GenServer.cast(__MODULE__, {:record, name, value})
  end

  @impl true
  def init(_opts) do
    {:ok, %{buckets: %{}}}
  end

  @impl true
  def handle_cast({:record, name, value}, %{buckets: b} = state) do
    now = System.monotonic_time(:millisecond)
    bucket_id = name
    points = Map.get(b, bucket_id, [])
    fresh = [{now, value} | points] |> Enum.take(10_000)
    {:noreply, %{state | buckets: Map.put(b, bucket_id, fresh)}}
  end

  @impl true
  def handle_call({:aggregate, name, function, window_ms}, _from, %{buckets: b} = state) do
    now = System.monotonic_time(:millisecond)
    points = Map.get(b, name, [])
    windowed = Enum.filter(points, fn {t, _} -> now - t < window_ms end)
    values = Enum.map(windowed, fn {_, v} -> v end)

    result =
      case function do
        :sum ->
          Enum.sum(values)

        :avg ->
          if values == [], do: 0.0, else: Enum.sum(values) / length(values)

        :min ->
          Enum.min(values, fn -> 0 end)

        :max ->
          Enum.max(values, fn -> 0 end)

        :count ->
          length(values)

        :rate ->
          if window_ms > 0, do: length(values) / (window_ms / 1000), else: 0.0

        :variance ->
          mean = if values == [], do: 0, else: Enum.sum(values) / length(values)

          if length(values) > 1 do
            Enum.reduce(values, 0.0, fn v, acc -> acc + (v - mean) ** 2 end) /
              (length(values) - 1)
          else
            0.0
          end

        :stddev ->
          mean = if values == [], do: 0, else: Enum.sum(values) / length(values)

          if length(values) > 1 do
            variance =
              Enum.reduce(values, 0.0, fn v, acc -> acc + (v - mean) ** 2 end) /
                (length(values) - 1)

            :math.sqrt(variance)
          else
            0.0
          end

        other ->
          {:error, :unknown_function, other}
      end

    {:reply, %{function: function, result: result, points: length(values), window_ms: window_ms},
     state}
  end
end
