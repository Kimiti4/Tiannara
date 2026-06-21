defmodule Tiannara.REA.Causal.ChannelMonitor do
  @moduledoc """
  Observes actual causal channel propagation from the Graph registry.
  
  Tracks:
    - predictive_power: Pearson correlation between signal and target fitness
    - stabilization_effect: Variance reduction in target population (NOT information gain)
    - collapse_correlation: Signal absence → extinction frequency
  
  All metrics are computed from actual propagated signals, not proxies.
  """
  use GenServer
  
  alias Tiannara.REA.Causal.Graph
  
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  
  @doc "Record epoch snapshot using actual graph observations."
  @spec record_epoch(non_neg_integer(), %{atom() => float()}, %{atom() => %{fitness: float(), population: integer(), extinctions: integer()}}) :: :ok
  def record_epoch(epoch, pressures, population_stats) do
    GenServer.cast(__MODULE__, {:record, epoch, pressures, population_stats})
  end
  
  @doc "Generate ecological metrics for all channels."
  @spec generate_ecology_report() :: map()
  def generate_ecology_report, do: GenServer.call(__MODULE__, :generate_report)
  
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)
  
  @impl true
  def init(_), do: {:ok, %{snapshots: []}}
  
  @impl true
  def handle_cast({:record, epoch, pressures, pop_stats}, state) do
    snapshot = %{epoch: epoch, pressures: pressures, pop_stats: pop_stats}
    {:noreply, %{state | snapshots: [snapshot | state.snapshots]}}
  end
  
  @impl true
  def handle_call(:generate_report, _from, state) do
    sorted = Enum.sort_by(state.snapshots, & &1.epoch)
    channels = Graph.all()
    
    report =
      channels
      |> Enum.map(fn ch ->
        history = Graph.channel_history(ch.id)
        metrics = compute_metrics(history, sorted, ch.target.population)
        {ch.id, Map.put(metrics, :channel, ch)}
      end)
      |> Map.new()
    
    {:reply, report, state}
  end
  
  @impl true
  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{snapshots: []}}
  
  defp compute_metrics(channel_history, snapshots, target_pop) do
    if length(channel_history) < 10 or length(snapshots) < 10 do
      %{predictive_power: 0.0, stabilization_effect: 0.0, collapse_correlation: 0.0, samples: length(channel_history)}
    else
      # Align history with snapshots by epoch
      history_map = Map.new(channel_history, &{&1.epoch, &1})
      
      aligned =
        snapshots
        |> Enum.filter(fn snap -> Map.has_key?(history_map, snap.epoch) end)
        |> Enum.map(fn snap ->
          hist = Map.get(history_map, snap.epoch)
          pop = Map.get(snap.pop_stats, target_pop, %{fitness: 0.0, extinctions: 0})
          %{
            signal: hist.signal_avg,
            fitness: pop.fitness,
            extinctions: pop.extinctions
          }
        end)
      
      signals = Enum.map(aligned, & &1.signal)
      fitnesses = Enum.map(aligned, & &1.fitness)
      extinctions = Enum.map(aligned, & &1.extinctions)
      
      %{
        predictive_power: pearson_correlation(signals, fitnesses),
        stabilization_effect: compute_stabilization_effect(signals, fitnesses),
        collapse_correlation: pearson_correlation(signals, Enum.map(extinctions, &(1.0 - &1))),
        samples: length(aligned)
      }
    end
  end
  
  defp pearson_correlation(x, y) do
    n = length(x)
    sum_x = Enum.sum(x)
    sum_y = Enum.sum(y)
    sum_xy = Enum.zip(x, y) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    sum_x2 = Enum.map(x, &(&1 * &1)) |> Enum.sum()
    sum_y2 = Enum.map(y, &(&1 * &1)) |> Enum.sum()
    
    numerator = n * sum_xy - sum_x * sum_y
    denominator = :math.sqrt(max(0.0, (n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y)))
    
    if denominator == 0.0, do: 0.0, else: numerator / denominator
  end
  
  defp compute_stabilization_effect(signals, fitnesses) do
    high_signal = Enum.zip(signals, fitnesses) |> Enum.filter(fn {s, _} -> s > 0.5 end) |> Enum.map(&elem(&1, 1))
    low_signal = Enum.zip(signals, fitnesses) |> Enum.filter(fn {s, _} -> s <= 0.5 end) |> Enum.map(&elem(&1, 1))
    
    var_high = variance(high_signal)
    var_low = variance(low_signal)
    
    # Positive if high signal reduces variance (stabilizes)
    (var_low - var_high) |> max(0.0)
  end
  
  defp variance([]), do: 0.0
  defp variance(vals) do
    m = Enum.sum(vals) / length(vals)
    vals |> Enum.map(&((&1 - m) * (&1 - m))) |> Enum.sum() |> Kernel./(length(vals))
  end
end
