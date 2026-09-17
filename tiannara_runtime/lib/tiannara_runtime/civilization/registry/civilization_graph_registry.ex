defmodule TiannaraRuntime.Civilization.Registry.CivilizationGraphRegistry do
  def initialize() do
    {:ok, %{nodes: %{}, edges: %{}, adjacency: %{}, created_at: :erlang.unique_integer([:positive])}}
  end

  def add_node(registry, node_id, node_type) when node_type in [:civilization, :institution, :infrastructure, :economy, :technology, :knowledge, :governance, :culture] do
    if Map.has_key?(registry.nodes, node_id) do
      {:error, {:duplicate_node, node_id}}
    else
      node = %{id: node_id, type: node_type}
      {:ok, %{registry | nodes: Map.put(registry.nodes, node_id, node), adjacency: Map.put(registry.adjacency, node_id, [])}}
    end
  end

  def add_node(_registry, _node_id, _node_type) do
    {:error, :invalid_node_type}
  end

  def add_edge(registry, source_id, target_id, edge_type) when edge_type in [:depends_on, :governs, :funds, :supports, :produces, :requires, :inherits, :evolved_from] do
    case {Map.has_key?(registry.nodes, source_id), Map.has_key?(registry.nodes, target_id)} do
      {false, _} -> {:error, {:source_not_found, source_id}}
      {_, false} -> {:error, {:target_not_found, target_id}}
      {true, true} ->
        edge_id = "e_#{source_id}_#{target_id}_#{edge_type}"
        if Map.has_key?(registry.edges, edge_id) do
          {:error, {:duplicate_edge, edge_id}}
        else
          edge = %{id: edge_id, source: source_id, target: target_id, type: edge_type}
          current_adj = Map.get(registry.adjacency, source_id, [])
          {:ok, %{registry | edges: Map.put(registry.edges, edge_id, edge), adjacency: Map.put(registry.adjacency, source_id, current_adj ++ [target_id])}}
        end
    end
  end

  def add_edge(_registry, _source_id, _target_id, _edge_type) do
    {:error, :invalid_edge_type}
  end

  def traverse(registry) do
    result = find_topological_order(registry)
    case result do
      {:error, _} = err -> err
      {:ok, order} ->
        ordered = Enum.map(order, fn id ->
          edges_from = Enum.filter(Map.values(registry.edges), fn e -> Map.get(e, :source) == id end)
          %{node: Map.get(registry.nodes, id), edges: edges_from}
        end)
        {:ok, ordered}
    end
  end

  def lookup(registry, node_id) do
    case Map.get(registry.nodes, node_id) do
      nil -> {:error, :not_found}
      node -> {:ok, node}
    end
  end

  def register(registry, item) do
    id = Map.get(item, :id)
    if Map.has_key?(registry.nodes, id) do
      {:error, {:duplicate, id}}
    else
      updated = %{registry | nodes: Map.put(registry.nodes, id, item), adjacency: Map.put(registry.adjacency, id, [])}
      {:ok, updated}
    end
  end

  def remove(registry, id) do
    case Map.has_key?(registry.nodes, id) do
      false -> {:error, :not_found}
      true ->
        edges_to_remove = Enum.filter(Map.values(registry.edges), fn e -> Map.get(e, :source) == id or Map.get(e, :target) == id end)
        removed_ids = Enum.map(edges_to_remove, fn e -> Map.get(e, :id) end)
        remaining_edges = Map.drop(registry.edges, removed_ids)
        remaining_adj = Map.delete(registry.adjacency, id)
        remaining_adj = Enum.reduce(removed_ids, remaining_adj, fn eid, acc ->
          edge = Map.get(registry.edges, eid)
          src = Map.get(edge, :source)
          if src != id do
            src_adj = Map.get(acc, src, [])
            Map.put(acc, src, Enum.reject(src_adj, fn tid -> tid == id end))
          else
            acc
          end
        end)
        {:ok, %{registry | nodes: Map.delete(registry.nodes, id), edges: remaining_edges, adjacency: remaining_adj}}
    end
  end

  def list(registry) do
    {:ok, Map.values(registry.nodes)}
  end

  def count(registry) do
    {:ok, %{nodes: map_size(registry.nodes), edges: map_size(registry.edges)}}
  end

  def validate(registry) do
    node_ids = MapSet.new(Map.keys(registry.nodes))
    ref_errors = Enum.reduce(Map.values(registry.edges), [], fn edge, acc ->
      source = Map.get(edge, :source)
      target = Map.get(edge, :target)
      src_err = if MapSet.member?(node_ids, source), do: nil, else: {:broken_reference, source}
      tgt_err = if MapSet.member?(node_ids, target), do: nil, else: {:broken_reference, target}
      [src_err, tgt_err | acc]
    end) |> Enum.filter(& &1)

    cycle_result = find_cycle(registry)
    cycle_err = case cycle_result do
      nil -> nil
      path -> {:cycle_detected, path}
    end

    errors = if is_nil(cycle_err), do: ref_errors, else: [cycle_err | ref_errors]
    if errors == [], do: :ok, else: {:error, errors}
  end

  defp find_topological_order(registry) do
    in_degree = compute_in_degree(registry)
    queue = Enum.reduce(in_degree, [], fn {node_id, deg}, acc ->
      if deg == 0, do: [node_id | acc], else: acc
    end)
    order = do_topological_sort(queue, MapSet.new(), in_degree, registry, [])
    sorted_ids = elem(order, 0)
    if length(sorted_ids) == map_size(registry.nodes) do
      {:ok, sorted_ids}
    else
      all = MapSet.new(Map.keys(registry.nodes))
      sorted = MapSet.new(sorted_ids)
      not_sorted = MapSet.difference(all, sorted) |> MapSet.to_list()
      {:error, {:cycle, not_sorted}}
    end
  end

  defp do_topological_sort([], _visited, _in_degree, _registry, acc), do: {Enum.reverse(acc), MapSet.new()}
  defp do_topological_sort(queue, visited, in_degree, registry, acc) do
    [current | rest] = queue
    new_visited = MapSet.put(visited, current)
    neighbors = Map.get(registry.adjacency, current, [])
    {new_queue, new_in_degree} = Enum.reduce(neighbors, {rest, in_degree}, fn nbr, {q, deg} ->
      if not MapSet.member?(new_visited, nbr) do
        current_deg = Map.get(deg, nbr)
        new_deg = if current_deg - 1 < 0, do: 0, else: current_deg - 1
        updated_q = if new_deg == 0 and not Enum.member?(q, nbr), do: q ++ [nbr], else: q
        {updated_q, Map.put(deg, nbr, new_deg)}
      else
        {q, deg}
      end
    end)
    do_topological_sort(new_queue, new_visited, new_in_degree, registry, acc ++ [current])
  end

  defp compute_in_degree(registry) do
    init = Map.new(Map.keys(registry.nodes), fn k -> {k, 0} end)
    Enum.reduce(Map.values(registry.edges), init, fn edge, acc ->
      target = Map.get(edge, :target)
      Map.update!(acc, target, fn count -> count + 1 end)
    end)
  end

  defp find_cycle(registry) do
    all_nodes = Map.keys(registry.nodes)
    visited = MapSet.new()
    rec_stack = MapSet.new()
    result = Enum.reduce_while(all_nodes, {visited, rec_stack, nil}, fn node_id, {vis, rec, _found} ->
      if not MapSet.member?(vis, node_id) do
        case detect_cycle(node_id, registry, vis, rec, []) do
          {true, path} -> {:halt, {vis, rec, path}}
          {false, new_vis, new_rec} -> {:cont, {new_vis, new_rec, nil}}
        end
      else
        {:cont, {vis, rec, nil}}
      end
    end)
    case result do
      {_, _, nil} -> nil
      {_, _, path} -> path
    end
  end

  defp detect_cycle(node_id, registry, visited, rec_stack, path) do
    new_vis = MapSet.put(visited, node_id)
    new_rec = MapSet.put(rec_stack, node_id)
    new_path = path ++ [node_id]
    neighbors = Map.get(registry.adjacency, node_id, [])
    result = Enum.reduce_while(neighbors, {false, new_vis, new_rec, new_path}, fn nbr, {_found, vis, rec, pth} ->
      if not MapSet.member?(vis, nbr) do
        case detect_cycle(nbr, registry, vis, rec, pth) do
          {true, cycle_path} -> {:halt, {true, vis, rec, cycle_path}}
          {false, new_vis2, new_rec2} -> {:cont, {false, new_vis2, new_rec2, pth}}
        end
      else
        if MapSet.member?(rec, nbr) do
          cycle_start_pos = Enum.find_index(pth, fn p -> p == nbr end)
          cycle_path = Enum.slice(pth, cycle_start_pos, length(pth) - cycle_start_pos) ++ [nbr]
          {:halt, {true, vis, rec, cycle_path}}
        else
          {:cont, {false, vis, rec, pth}}
        end
      end
    end)
    case result do
      {true, _vis, _rec, cycle_path} -> {true, cycle_path}
      {true, cycle_path} -> {true, cycle_path}
      {false, vis, rec, _} -> {false, vis, MapSet.delete(rec, node_id)}
    end
  end
end
