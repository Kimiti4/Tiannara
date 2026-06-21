defmodule Tiannara.REA.Causal.PathAnalysis do
  @moduledoc """
  Discovers multi-hop causal pathways: A → B → C → D
  
  Individual channels may look mediocre, but the full pathway may be
  the true driver of cross-level survival. Without path analysis,
  REA-3 could prune critical intermediate channels.
  """
  
  alias Tiannara.REA.Causal.Graph
  
  @type path :: %{
    channels: [Tiannara.REA.Causal.Channel.t()],
    cumulative_predictive_power: float(),
    cumulative_stabilization: float(),
    cumulative_collapse_correlation: float(),
    depth: integer(),
    source_population: atom(),
    target_population: atom()
  }
  
  @doc "Analyze all significant pathways (depth 2-4)."
  @spec analyze_paths(map(), keyword()) :: [path()]
  def analyze_paths(ecology_report, opts \\ []) do
    min_depth = Keyword.get(opts, :min_depth, 2)
    max_depth = Keyword.get(opts, :max_depth, 4)
    min_power = Keyword.get(opts, :min_predictive_power, 0.1)
    
    channels = Graph.all()
    
    # Build adjacency list
    adjacency = build_adjacency(channels)
    
    # Find all paths of depth 2..max_depth
    paths =
      channels
      |> Enum.flat_map(fn start_ch ->
        find_paths(start_ch, adjacency, ecology_report, 1, max_depth, [start_ch])
      end)
      |> Enum.filter(fn p -> p.depth >= min_depth end)
      |> Enum.filter(fn p -> abs(p.cumulative_predictive_power) >= min_power end)
    
    paths
  end
  
  defp build_adjacency(channels) do
    channels
    |> Enum.group_by(& &1.target.population)
    |> Enum.map(fn {pop, incoming} ->
      {pop, Enum.map(incoming, & &1.source.population)}
    end)
    |> Map.new()
  end
  
  defp find_paths(current_ch, adjacency, report, depth, max_depth, path_so_far) do
    if depth >= max_depth do
      [build_path(path_so_far, report)]
    else
      target_pop = current_ch.target.population
      next_channels =
        Graph.outgoing(target_pop)
        |> Enum.filter(fn ch -> not Enum.any?(path_so_far, &(&1.id == ch.id)) end)  # avoid cycles
      
      if next_channels == [] do
        [build_path(path_so_far, report)]
      else
        Enum.flat_map(next_channels, fn next_ch ->
          find_paths(next_ch, adjacency, report, depth + 1, max_depth, path_so_far ++ [next_ch])
        end)
      end
    end
  end
  
  defp build_path(channels, report) do
    metrics = Enum.map(channels, &Map.get(report, &1.id, %{predictive_power: 0.0, stabilization_effect: 0.0, collapse_correlation: 0.0}))
    
    %{
      channels: channels,
      cumulative_predictive_power: Enum.map(metrics, & &1.predictive_power) |> Enum.sum() |> Kernel./(length(metrics)),
      cumulative_stabilization: Enum.map(metrics, & &1.stabilization_effect) |> Enum.sum() |> Kernel./(length(metrics)),
      cumulative_collapse_correlation: Enum.map(metrics, & &1.collapse_correlation) |> Enum.sum() |> Kernel./(length(metrics)),
      depth: length(channels),
      source_population: hd(channels).source.population,
      target_population: List.last(channels).target.population
    }
  end
end
