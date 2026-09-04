defmodule Tiannara.Report.ProgressiveAggregator do
  @moduledoc "Aggregates 19M causal impacts into viewport-ready telemetry slices."
  use GenStage

  def start_link(opts), do: GenStage.start_link(__MODULE__, opts)

  @impl true
  def init(%{source_pid: source}) do
    {:producer, %{demand: 0, buffer: [], source: source}}
  end

  @impl true
  def handle_demand(_incoming, %{buffer: _buffer, source: _source} = state) do
    # Pull only what the dashboard requested (viewport-aware)
    # Mocking history pull for now
    # events = Tiannara.Sentinel.History.pull(source, incoming)
    events = []
    
    if events == [] do
      {:noreply, [], %{state | demand: 0}}
    else
      aggregated = Enum.chunk_every(events, 500) |> Enum.map(&summarize_slice/1)
      {:noreply, aggregated, %{state | demand: 0}}
    end
  end

  def handle_events(new_events, %{buffer: buffer} = state) do
    {:noreply, [Enum.chunk_every(buffer ++ new_events, 500)], %{state | buffer: []}}
  end

  defp summarize_slice(slice) do
    %{
      epoch_range: {hd(slice).epoch, List.last(slice).epoch},
      avg_entropy: Enum.reduce(slice, 0.0, &(&2 + &1.entropy)) / length(slice),
      peak_pressure: Enum.max_by(slice, & &1.pressure).pressure,
      mutation_count: Enum.count(slice, & &1.mutation_triggered),
      sample_coordinates: Enum.take_random(slice, 50) |> Enum.map(&Map.take(&1, [:x, :y, :z, :id]))
    }
  end
end
