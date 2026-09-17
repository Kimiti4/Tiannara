defmodule MetricsEngine.QueryEngine do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def query_metrics(name, start_time, end_time, opts \\ []) do
    GenServer.call(__MODULE__, {:query, name, start_time, end_time, opts})
  end

  def list_metric_names(domain \\ nil) do
    GenServer.call(__MODULE__, {:list_names, domain})
  end

  @impl true
  def init(_opts) do
    {:ok, %{cache: %{}}}
  end

  @impl true
  def handle_call({:query, name, start_time, end_time, opts}, _from, state) do
    import Ecto.Query

    query =
      from(mp in MetricsEngine.Schema.MetricPoint,
        where: mp.name == ^name,
        where: mp.timestamp >= ^start_time,
        where: mp.timestamp <= ^end_time,
        order_by: [asc: mp.timestamp]
      )

    query =
      if opts[:domain] do
        from(q in query, where: q.domain == ^opts[:domain])
      else
        query
      end

    query =
      if opts[:limit] do
        from(q in query, limit: ^opts[:limit])
      else
        query
      end

    results = MetricsEngine.Repo.all(query)

    points =
      Enum.map(results, fn r ->
        %{timestamp: r.timestamp, value: r.value, domain: r.domain, metadata: r.metadata}
      end)

    stats =
      if points != [] do
        values = Enum.map(points, fn p -> p.value end)
        sorted = Enum.sort(values)

        %{
          count: length(values),
          min: List.first(sorted),
          max: List.last(sorted),
          mean: Enum.sum(values) / length(values),
          first: Map.get(points |> List.first(), :value),
          last: Map.get(points |> List.last(), :value)
        }
      else
        %{count: 0}
      end

    {:reply,
     %{name: name, points: points, stats: stats, start_time: start_time, end_time: end_time},
     state}
  end

  @impl true
  def handle_call({:list_names, domain}, _from, state) do
    import Ecto.Query

    query =
      if domain do
        from(mp in MetricsEngine.Schema.MetricPoint,
          where: mp.domain == ^domain,
          select: mp.name,
          distinct: true
        )
      else
        from(mp in MetricsEngine.Schema.MetricPoint,
          select: mp.name,
          distinct: true
        )
      end

    names = MetricsEngine.Repo.all(query)
    {:reply, names, state}
  end
end
