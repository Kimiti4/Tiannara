defmodule Graph do
  @moduledoc "Minimal directed adjacency graph compatibility implementation."

  def out_edges(%{edges: edges}, vertex) when is_list(edges) do
    Enum.filter(edges, fn
      {^vertex, _} -> true
      {^vertex, _, _} -> true
      %{from: ^vertex} -> true
      _ -> false
    end)
  end
  def out_edges(graph, vertex) when is_map(graph) do
    graph |> Map.get(vertex, []) |> List.wrap()
  end
  def out_edges(_, _), do: []
end
