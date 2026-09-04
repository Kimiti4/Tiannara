defmodule Tiannara.Math.Graphs do
  @doc "Breadth-First Search shortest path in unweighted graph."
  def shortest_path(graph, start_node, end_node) do
    start = System.monotonic_time(:microsecond)
    result = bfs(graph, :queue.in({start_node, [start_node]}, :queue.new()), MapSet.new([start_node]), end_node)
    :telemetry.execute([:tiannara, :math, :operation], %{duration: System.monotonic_time(:microsecond) - start}, %{module: __MODULE__, operation: :shortest_path})
    result
  end

  defp bfs(graph, queue, visited, target) do
    case :queue.out(queue) do
      {:empty, _q} -> {:error, :no_path}
      {{:value, {node, path}}, rest} ->
        if node == target do
          {:ok, Enum.reverse(path)}
        else
          neighbors = Map.get(graph, node, [])
          {new_queue, new_visited} = Enum.reduce(neighbors, {rest, visited}, fn neighbor, {q, v} ->
            if MapSet.member?(v, neighbor), do: {q, v}, else: {:queue.in({neighbor, [neighbor | path]}, q), MapSet.put(v, neighbor)}
          end)
          bfs(graph, new_queue, new_visited, target)
        end
    end
  end
end
