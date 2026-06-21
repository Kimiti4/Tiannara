defmodule Tiannara.REA.MultiObjectivePlanner do
  @moduledoc """
  Dijkstra-based multi-objective path planning over the Orbit Reachability Graph.
  Supports shortest path, lowest energy, highest probability, and maximum residency.
  """

  alias Tiannara.REA.OrbitReachabilityGraph
  alias Tiannara.REA.OrbitDistance

  @doc """
  Plans the optimal trajectory path from `current_orbit` to `desired_orbit`
  under the selected `objective` (:shortest_path | :lowest_energy | :highest_probability | :maximum_residency).
  """
  def plan(current_orbit, desired_orbit, objective) do
    # Load reachability graph
    {nodes, edges} = OrbitReachabilityGraph.load()

    # Find nodes by ID
    current_node = Enum.find(nodes, & &1.orbit_id == current_orbit)
    desired_node = Enum.find(nodes, & &1.orbit_id == desired_orbit)

    cond do
      is_nil(current_node) or is_nil(desired_node) ->
        {:error, :orbit_not_found}

      current_orbit == desired_orbit ->
        {:ok, %{
          path: [current_orbit],
          success_probability: 1.0,
          expected_epochs: 0.0,
          energy_cost: 0.0,
          recommended_interventions: [],
          recommended_policies: []
        }}

      true ->
        case run_dijkstra(current_orbit, desired_orbit, nodes, edges, objective) do
          {:ok, path} ->
            # Calculate aggregate metrics along the path
            metrics = aggregate_path_metrics(path, edges, nodes)
            {:ok, Map.put(metrics, :path, path)}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # Dijkstra pathfinder
  defp run_dijkstra(start, target, nodes, edges, objective) do
    node_ids = Enum.map(nodes, & &1.orbit_id)
    
    # Initialize distances and predecessors
    dist = Enum.reduce(node_ids, %{}, fn id, acc -> Map.put(acc, id, 999999.0) end)
    dist = Map.put(dist, start, 0.0)
    prev = %{}

    # Queue of nodes to visit
    unvisited = MapSet.new(node_ids)

    do_dijkstra(unvisited, dist, prev, target, edges, nodes, objective)
  end

  defp do_dijkstra(unvisited, dist, prev, target, edges, nodes, objective) do
    if MapSet.size(unvisited) == 0 do
      reconstruct_path(prev, target)
    else
      # Find vertex with minimum distance in unvisited
      u =
        unvisited
        |> Enum.min_by(fn id -> Map.get(dist, id, 999999.0) end, fn -> nil end)

      u_dist = Map.get(dist, u, 999999.0)

      if u == target || u_dist >= 999999.0 do
        if u_dist >= 999999.0 and u == target do
          {:error, :unreachable}
        else
          reconstruct_path(prev, target)
        end
      else
        unvisited = MapSet.delete(unvisited, u)

        # Get outgoing edges from u
        u_edges = Enum.filter(edges, &(&1.source_orbit == u))

        # Update neighbor distances
        {dist, prev} =
          Enum.reduce(u_edges, {dist, prev}, fn edge, {d_acc, p_acc} ->
            v = edge.target_orbit
            if MapSet.member?(unvisited, v) do
              weight = get_edge_weight(edge, nodes, objective)
              alt = u_dist + weight
              if alt < Map.get(d_acc, v) do
                {Map.put(d_acc, v, alt), Map.put(p_acc, v, u)}
              else
                {d_acc, p_acc}
              end
            else
              {d_acc, p_acc}
            end
          end)

        do_dijkstra(unvisited, dist, prev, target, edges, nodes, objective)
      end
    end
  end

  # Determine edge weight based on objective
  defp get_edge_weight(edge, nodes, objective) do
    target_node = Enum.find(nodes, & &1.orbit_id == edge.target_orbit)
    residency = if target_node, do: target_node.residency_score, else: 0.25

    case objective do
      :shortest_path ->
        edge.expected_epochs

      :lowest_energy ->
        edge.energy_cost + edge.hysteresis_penalty

      :highest_probability ->
        # Minimize negative log of probability
        -:math.log(edge.transition_probability + 0.0001)

      :maximum_residency ->
        # Minimize inverse residency to maximize residency
        1.0 / (residency + 0.0001)

      _ ->
        edge.energy_cost
    end
  end

  # Reconstruct path sequence
  defp reconstruct_path(prev, target) do
    path = build_path_sequence(prev, target, [])
    if hd(path) == nil do
      {:error, :unreachable}
    else
      {:ok, path}
    end
  end

  defp build_path_sequence(prev, curr, acc) do
    case Map.get(prev, curr) do
      nil -> [curr | acc]
      parent -> build_path_sequence(prev, parent, [curr | acc])
    end
  end

  # Aggregate metrics along computed path
  defp aggregate_path_metrics(path, edges, nodes) do
    steps = Enum.chunk_every(path, 2, 1, :discard)

    {sum_epochs, joint_prob, sum_energy, interventions} =
      Enum.reduce(steps, {0.0, 1.0, 0.0, []}, fn [u, v], {epochs, prob, energy, inters} ->
        edge = Enum.find(edges, &(&1.source_orbit == u and &1.target_orbit == v))
        
        step_epochs = if edge, do: edge.expected_epochs, else: 10.0
        step_prob = if edge, do: edge.transition_probability, else: 0.01
        step_energy = if edge, do: edge.energy_cost + edge.hysteresis_penalty, else: 1.0
        
        # Load transitions to find best intervention
        # Let's check which intervention has the highest success rate
        best_inter = find_best_intervention(u, v)

        {epochs + step_epochs, prob * step_prob, energy + step_energy, inters ++ [best_inter]}
      end)

    recommended_policies = Enum.map(interventions, &map_intervention_to_policy/1)

    %{
      success_probability: Float.round(joint_prob, 4),
      expected_epochs: Float.round(sum_epochs, 2),
      energy_cost: Float.round(sum_energy, 2),
      recommended_interventions: interventions,
      recommended_policies: recommended_policies
    }
  end

  # Find best intervention between two states
  defp find_best_intervention(u, v) do
    # Load transition matrix from file
    transitions = Tiannara.OrbitTransitions.all()
    trans = Enum.find(transitions, &(&1.from_orbit == u and &1.to_orbit == v))

    if trans && trans.interventions != [] do
      best = Enum.max_by(trans.interventions, fn %{success_rate: rate} -> rate end)
      best.intervention_id
    else
      # Fallbacks based on edge direction
      cond do
        u == :collapse_recovery_orbit and v == :stability_orbit -> "repair"
        u == :other_orbit_0 and v == :stability_orbit -> "preserve"
        v == :collapse_recovery_orbit -> "triage"
        true -> "explore"
      end
    end
  end

  # Maps an intervention name (explore, preserve, repair, triage) to a policy name (trader, phoenix, settler)
  defp map_intervention_to_policy(intervention) do
    case to_string(intervention) do
      "explore" -> :trader
      "preserve" -> :phoenix
      "repair" -> :settler
      "triage" -> :phoenix
      _ -> :trader
    end
  end
end
