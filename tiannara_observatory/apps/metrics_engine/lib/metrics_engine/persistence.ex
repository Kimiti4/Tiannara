defmodule MetricsEngine.Persistence do
  use GenServer

  @flush_interval_ms 5_000
  @batch_size 100

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def enqueue(name, value, domain, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:enqueue, name, value, domain, metadata})
  end

  @impl true
  def init(_opts) do
    schedule_flush()
    {:ok, %{buffer: [], total_queued: 0, total_flushed: 0, failed: 0}}
  end

  @impl true
  def handle_cast(
        {:enqueue, name, value, domain, metadata},
        %{buffer: buf, total_queued: q} = state
      ) do
    point = %{
      name: name,
      value: value,
      unit: infer_unit(name),
      domain: domain,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }

    {:noreply, %{state | buffer: [point | buf], total_queued: q + 1}}
  end

  @impl true
  def handle_info(:flush, %{buffer: buf, total_flushed: f, failed: fail} = state) do
    schedule_flush()

    if buf != [] do
      batch = Enum.take(buf, @batch_size)
      remaining = Enum.drop(buf, @batch_size)

      case MetricsEngine.Repo.insert_all(MetricsEngine.Schema.MetricPoint, batch) do
        {count, _} ->
          {:noreply, %{state | buffer: remaining, total_flushed: f + count}}

        _ ->
          {:noreply, %{state | buffer: remaining, failed: fail + length(batch)}}
      end
    else
      {:noreply, state}
    end
  end

  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval_ms)
  end

  defp infer_unit(name) do
    cond do
      String.contains?(name, "count") or String.contains?(name, "total") ->
        "count"

      String.contains?(name, "latency") or String.contains?(name, "duration") or
          String.contains?(name, "time") ->
        "ms"

      String.contains?(name, "bytes") or String.contains?(name, "size") ->
        "bytes"

      String.contains?(name, "rate") or String.contains?(name, "throughput") ->
        "events/sec"

      String.contains?(name, "pct") or String.contains?(name, "percent") ->
        "%"

      true ->
        "units"
    end
  end
end
