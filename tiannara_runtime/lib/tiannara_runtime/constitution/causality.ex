defmodule Tiannara.Constitution.Causality do
  @moduledoc """
  Constitutional Invariant: Causal Non-Paradox
  
  ∄ c_i → c_i
  
  Ensures that no proposed execution state creates a closed causal loop
  (a paradox where an event is its own cause) within the L0 substrate.
  """

  @doc """
  Validates a proposed execution graph for causal loops.
  
  Returns `:ok` or `{:error, reason}`.
  """
  def validate(causal_links) do
    nodes = causal_links
    |> Enum.flat_map(fn {s, t} -> [s, t] end)
    |> Enum.uniq()

    adjacency = Enum.reduce(causal_links, %{}, fn {source, target}, acc ->
      Map.update(acc, source, [target], &[target | &1])
    end)

    if detect_cycle(nodes, adjacency) do
      {:error, :causality_violation_paradox_detected}
    else
      :ok
    end
  end

  defp detect_cycle(nodes, adjacency) do
    Enum.any?(nodes, fn start ->
      visited = MapSet.new()
      stack = MapSet.new()
      dfs_cycle?(start, adjacency, visited, stack)
    end)
  end

  defp dfs_cycle?(node, adjacency, visited, stack) do
    cond do
      MapSet.member?(stack, node) ->
        true
      MapSet.member?(visited, node) ->
        false
      true ->
        new_visited = MapSet.put(visited, node)
        new_stack = MapSet.put(stack, node)
        neighbors = Map.get(adjacency, node, [])
        has_cycle = Enum.any?(neighbors, fn neighbor ->
          dfs_cycle?(neighbor, adjacency, new_visited, new_stack)
        end)
        has_cycle
    end
  end
end
