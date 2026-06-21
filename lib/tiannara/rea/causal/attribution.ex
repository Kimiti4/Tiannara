defmodule Tiannara.REA.Causal.Attribution do
  @moduledoc """
  Traces causal ancestry of a ruin.
  """
  
  alias Tiannara.REA.{EvolutionaryRuin, LineageRegistry}
  alias Tiannara.REA.Causal.{Graph, PressureField}
  
  @type attribution :: %{
    ruin_id: binary(),
    direct_pressures: map(),
    upstream_contributors: [{atom(), float()}],
    causal_depth: non_neg_integer(),
    primary_cause: atom() | nil
  }
  
  @spec attribute(EvolutionaryRuin.t()) :: attribution()
  def attribute(%EvolutionaryRuin{} = ruin) do
    target_pop = ruin.organism_type
    epoch = ruin.epoch
    
    direct = pressure_at_death(target_pop, epoch)
    upstream = trace_upstream(target_pop, epoch, _max_depth = 3)
    
    primary =
      upstream
      |> Enum.max_by(&elem(&1, 1), fn -> nil end)
      |> case do
        {cause, _} -> cause
        nil -> nil
      end
    
    %{
      ruin_id: ruin.organism_id,
      direct_pressures: direct,
      upstream_contributors: upstream,
      causal_depth: depth_of(upstream),
      primary_cause: primary
    }
  end
  
  defp pressure_at_death(target_pop, epoch) do
    PressureField.compute(target_pop, epoch)
  end
  
  defp trace_upstream(pop, epoch, max_depth) do
    do_trace([{pop, 1.0, 0}], epoch, max_depth, MapSet.new(), [])
  end
  
  defp do_trace([], _epoch, _max_depth, _visited, acc), do: acc
  defp do_trace([{_pop, _weight, depth} | _], _epoch, max_depth, _visited, acc) when depth >= max_depth, do: acc
  defp do_trace([{pop, influence, depth} | rest], epoch, max_depth, visited, acc) do
    if MapSet.member?(visited, pop) do
      do_trace(rest, epoch, max_depth, visited, acc)
    else
      visited = MapSet.put(visited, pop)
      incoming = Graph.incoming(pop)
      
      new_contributions =
        incoming
        |> Enum.map(fn ch ->
          source_pop = ch.source.population
          new_influence = influence * ch.weight * 0.7
          {source_pop, new_influence, depth + 1}
        end)
      
      new_acc =
        incoming
        |> Enum.map(fn ch -> {ch.source.population, influence * ch.weight} end)
        |> Enum.reduce(acc, fn {src, w}, a ->
          case List.keyfind(a, src, 0) do
            {^src, existing} -> List.keyreplace(a, src, 0, {src, existing + w})
            nil -> [{src, w} | a]
          end
        end)
      
      do_trace(new_contributions ++ rest, epoch, max_depth, visited, new_acc)
    end
  end
  
  defp depth_of(contributors) do
    case contributors do
      [] -> 0
      _ -> 1 + Enum.count(contributors, fn {_, w} -> w > 0.3 end)
    end
  end
end
