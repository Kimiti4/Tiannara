defmodule Tiannara.REA.Causal.NecessityTester do
  @moduledoc """
  Counterfactual testing: disable a channel, measure Δ metrics.
  
  This reveals which channels are truly necessary, not just correlated.
  A channel with high predictive power but low necessity may be redundant.
  """
  
  alias Tiannara.REA.{SimulationRunner, LineageRegistry, ArchaeologyRegistry}
  alias Tiannara.REA.Causal.{Graph, ChannelMonitor, Topology}
  
  @type necessity_result :: %{
    channel_id: binary(),
    channel_name: atom(),
    delta_diversity: float(),
    delta_truth_retention: float(),
    delta_resilience: float(),
    delta_innovation: float(),
    delta_extinctions: float(),
    necessity_score: float()
  }
  
  @doc "Test necessity of a single channel."
  @spec test_channel(Tiannara.REA.Causal.Channel.t(), map()) :: necessity_result()
  def test_channel(channel, baseline_config) do
    # Run baseline
    baseline = run_with_config(baseline_config, _disable_channel: nil)
    
    # Run with channel disabled
    disabled = run_with_config(baseline_config, disable_channel: channel.id)
    
    compute_deltas(channel, baseline, disabled)
  end
  
  @doc "Test necessity of all channels."
  @spec test_all_channels([Tiannara.REA.Causal.Channel.t()], map()) :: [necessity_result()]
  def test_all_channels(channels, baseline_config) do
    channels
    |> Enum.map(&test_channel(&1, baseline_config))
    |> Enum.sort_by(& &1.necessity_score, :desc)
  end
  
  defp run_with_config(config, opts) do
    disable_ch = Keyword.get(opts, :disable_channel)
    
    # Reset state
    if Code.ensure_loaded?(LineageRegistry), do: LineageRegistry.reset()
    if Code.ensure_loaded?(ArchaeologyRegistry), do: ArchaeologyRegistry.reset()
    ChannelMonitor.reset()
    Graph.flush()
    Graph.load_topology(Topology.default())
    
    if disable_ch, do: Graph.set_enabled(disable_ch, false)
    
    # Run simulation (shortened for necessity testing)
    short_config = %{config | epochs: min(config.epochs, 5000)}
    result = SimulationRunner.run(short_config)
    
    # Extract final metrics
    universe = result.universe
    %{
      diversity: compute_avg_diversity(universe),
      truth_retention: compute_avg_truth_retention(universe),
      resilience: compute_avg_resilience(universe),
      innovation: compute_avg_innovation(universe),
      extinctions: count_total_extinctions(universe)
    }
  end
  
  defp compute_deltas(channel, baseline, disabled) do
    delta_div = disabled.diversity - baseline.diversity
    delta_truth = disabled.truth_retention - baseline.truth_retention
    delta_res = disabled.resilience - baseline.resilience
    delta_inn = disabled.innovation - baseline.innovation
    delta_ext = disabled.extinctions - baseline.extinctions
    
    # Necessity score: weighted sum of negative impacts
    necessity =
      abs(delta_div) * 0.25 +
      abs(delta_truth) * 0.25 +
      abs(delta_res) * 0.25 +
      abs(delta_inn) * 0.25 -
      delta_ext * 0.1  # more extinctions = more necessary
    
    %{
      channel_id: channel.id,
      channel_name: channel.name,
      delta_diversity: delta_div,
      delta_truth_retention: delta_truth,
      delta_resilience: delta_res,
      delta_innovation: delta_inn,
      delta_extinctions: delta_ext,
      necessity_score: necessity
    }
  end
  
  defp compute_avg_diversity(universe) do
    universe.metrics
    |> Enum.map(fn {_, m} -> Map.get(m, :diversity, 0.0) end)
    |> Enum.sum()
    |> Kernel./(max(map_size(universe.metrics), 1))
  end
  
  defp compute_avg_truth_retention(universe) do
    case universe.populations[:civilization] do
      nil -> 0.0
      pop ->
        if length(pop.organisms) == 0, do: 0.0, else:
          pop.organisms
          |> Enum.map(&Map.get(&1, :truth_stock, 0.0))
          |> Enum.sum()
          |> Kernel./(max(length(pop.organisms), 1))
    end
  end
  
  defp compute_avg_resilience(universe) do
    case universe.populations[:meta_genome] do
      nil -> 0.0
      pop ->
        if length(pop.organisms) == 0, do: 0.0, else:
          pop.organisms
          |> Enum.map(&Map.get(&1, :resilience, 0.0))
          |> Enum.sum()
          |> Kernel./(max(length(pop.organisms), 1))
    end
  end
  
  defp compute_avg_innovation(universe) do
    case universe.populations[:meta_genome] do
      nil -> 0.0
      pop ->
        if length(pop.organisms) == 0, do: 0.0, else:
          pop.organisms
          |> Enum.map(&Map.get(&1, :innovation_rate, 0.0))
          |> Enum.sum()
          |> Kernel./(max(length(pop.organisms), 1))
    end
  end
  
  defp count_total_extinctions(universe) do
    universe.metrics
    |> Enum.map(fn {_, m} -> Map.get(m, :extinctions, 0) end)
    |> Enum.sum()
  end
end
