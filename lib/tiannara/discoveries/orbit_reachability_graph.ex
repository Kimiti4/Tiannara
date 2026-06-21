defmodule Tiannara.REA.OrbitReachabilityNode do
  @derive Jason.Encoder
  defstruct [
    :orbit_id,            # atom: :stability_orbit, :collapse_recovery_orbit, :other_orbit_0, :other_orbit_1
    :orbit_type,          # atom: :elite, :transient, :brittle, :sink
    :frequency,           # integer
    :residency_score,     # float
    :stability_score,     # float
    :gsi,                 # float
    :agency,              # float
    :robustness,          # float
    :generativity,        # float
    :orbit_vector,        # list of floats: [gsi, agency, robustness, generativity]
    :orbit_potential,     # float
    :orbit_confidence,    # float
    :gateway_score        # float
  ]
end

defmodule Tiannara.REA.OrbitReachabilityEdge do
  @derive Jason.Encoder
  defstruct [
    :source_orbit,            # atom
    :target_orbit,            # atom
    :transition_probability,  # float
    :energy_cost,             # float
    :gateway_required,        # boolean
    :gateway_orbits,          # list of atoms
    :expected_epochs,         # float
    :success_probability,     # float
    :hysteresis_penalty       # float
  ]
end

defmodule Tiannara.REA.OrbitReachabilityGraph do
  @moduledoc """
  Constructs, persists, and exports the Orbit Reachability Graph.
  """

  alias Tiannara.REA.OrbitReachabilityNode
  alias Tiannara.REA.OrbitReachabilityEdge
  alias Tiannara.OrbitTransitions

  @ndjson_path "data/orbit_reachability.ndjson"
  @csv_path "data/orbit_reachability_matrix.csv"

  @doc """
  Builds the entire reachability graph from transitions and state archives,
  persists it, and exports the reachability matrix.
  """
  def build_and_persist do
    # 1. Load transitions and states
    transitions = OrbitTransitions.all()
    states = load_orbit_states()

    # Calculate global metrics
    total_states = length(states)
    grouped_states = Enum.group_by(states, & &1.orbit_id)

    # 2. Build Nodes
    nodes = Enum.map([:stability_orbit, :collapse_recovery_orbit, :other_orbit_0, :other_orbit_1], fn orbit_id ->
      orbit_states = Map.get(grouped_states, to_string(orbit_id), [])
      frequency = length(orbit_states)
      residency_score = if total_states > 0, do: frequency / total_states, else: 0.0

      # Find self-loop transition for stability score
      self_loop = Enum.find(transitions, &(&1.from_orbit == orbit_id and &1.to_orbit == orbit_id))
      stability_score = if self_loop, do: self_loop.probability, else: 0.0

      # Compute coordinate centroids
      {gsi_sum, agency_sum, rob_sum, gen_sum} =
        Enum.reduce(orbit_states, {0.0, 0.0, 0.0, 0.0}, fn s, {g, a, r, n} ->
          {g + (s.gsi || 0.0), a + (s.agency || 0.0), r + (s.robustness || 0.0), n + (s.generativity || 0.0)}
        end)

      gsi = if frequency > 0, do: gsi_sum / frequency, else: 0.5
      agency = if frequency > 0, do: agency_sum / frequency, else: 0.5
      robustness = if frequency > 0, do: rob_sum / frequency, else: 0.5
      generativity = if frequency > 0, do: gen_sum / frequency, else: 0.5

      # Classify Orbit Type
      orbit_type =
        cond do
          residency_score > 0.4 and stability_score > 0.5 -> :elite
          stability_score < 0.35 -> :brittle
          stability_score > 0.70 -> :sink
          true -> :transient
        end

      # Calculate Orbit Potential (Attraction strength)
      # Strongly stable orbits with high residency act as attractors.
      orbit_potential = Float.round(min(1.0, max(0.0, (residency_score * 0.4) + (stability_score * 0.6))), 4)

      %OrbitReachabilityNode{
        orbit_id: orbit_id,
        orbit_type: orbit_type,
        frequency: frequency,
        residency_score: Float.round(residency_score, 4),
        stability_score: Float.round(stability_score, 4),
        gsi: Float.round(gsi, 4),
        agency: Float.round(agency, 4),
        robustness: Float.round(robustness, 4),
        generativity: Float.round(generativity, 4),
        orbit_vector: [Float.round(gsi, 4), Float.round(agency, 4), Float.round(robustness, 4), Float.round(generativity, 4)],
        orbit_potential: orbit_potential,
        orbit_confidence: 1.0,
        gateway_score: 0.0 # Will be populated by detector
      }
    end)

    # 3. Build preliminary edges
    edges =
      for source <- nodes, target <- nodes do
        trans = Enum.find(transitions, &(&1.from_orbit == source.orbit_id and &1.to_orbit == target.orbit_id))
        
        transition_probability = if trans, do: trans.probability, else: 0.0
        energy_cost = if trans, do: trans.transition_cost, else: 1.0
        expected_epochs = if trans, do: trans.average_duration, else: 10.0
        
        success_probability =
          if trans && trans.attempts > 0 do
            trans.successes / trans.attempts
          else
            0.0
          end

        # Calculate reverse edge cost for hysteresis penalty
        reverse_trans = Enum.find(transitions, &(&1.from_orbit == target.orbit_id and &1.to_orbit == source.orbit_id))
        reverse_cost = if reverse_trans, do: reverse_trans.transition_cost, else: 1.0
        hysteresis_penalty = Float.round(max(0.0, reverse_cost - energy_cost) * 0.5, 4)

        %OrbitReachabilityEdge{
          source_orbit: source.orbit_id,
          target_orbit: target.orbit_id,
          transition_probability: Float.round(transition_probability, 4),
          energy_cost: Float.round(energy_cost, 4),
          gateway_required: false,
          gateway_orbits: [],
          expected_epochs: Float.round(expected_epochs, 2),
          success_probability: Float.round(success_probability, 4),
          hysteresis_penalty: hysteresis_penalty
        }
      end

    # 4. Integrate Gateway & Centrality detection to populate gateway scores and required gateway paths
    # We will invoke the detector to calculate betweenness centrality and gateway classifications
    # Since modules are compiled in order, we can calculate gateway scores here.
    nodes = populate_gateway_scores(nodes, edges)
    edges = populate_gateway_requirements(edges, nodes)

    # 5. Save NDJSON
    save_ndjson(nodes, edges)

    # 6. Export CSV Matrix
    export_matrix_csv(edges)

    {:ok, nodes, edges}
  end

  @doc """
  Loads the list of nodes and edges from NDJSON.
  """
  def load do
    if File.exists?(@ndjson_path) do
      lines =
        @ndjson_path
        |> File.stream!()
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> Stream.map(fn line -> Jason.decode!(line, keys: :atoms) end)
        |> Enum.to_list()

      nodes =
        lines
        |> Enum.filter(&(&1.type == "node"))
        |> Enum.map(fn %{data: d} ->
          d = Map.update!(d, :orbit_id, &String.to_atom(to_string(&1)))
              |> Map.update!(:orbit_type, &String.to_atom(to_string(&1)))
          struct(OrbitReachabilityNode, d)
        end)

      edges =
        lines
        |> Enum.filter(&(&1.type == "edge"))
        |> Enum.map(fn %{data: d} ->
          d = Map.update!(d, :source_orbit, &String.to_atom(to_string(&1)))
              |> Map.update!(:target_orbit, &String.to_atom(to_string(&1)))
              |> Map.update!(:gateway_orbits, fn list -> Enum.map(list, &String.to_atom(to_string(&1))) end)
          struct(OrbitReachabilityEdge, d)
        end)

      if nodes == [] do
        {:ok, nodes, edges} = build_and_persist()
        {nodes, edges}
      else
        {nodes, edges}
      end
    else
      # If the file does not exist, build it dynamically on the fly
      {:ok, nodes, edges} = build_and_persist()
      {nodes, edges}
    end
  end

  # --- PRIVATE HELPERS ---

  defp load_orbit_states do
    path = "data/orbit_states.ndjson"
    if File.exists?(path) do
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line -> Jason.decode!(line, keys: :atoms) end)
      |> Enum.to_list()
    else
      []
    end
  end

  defp save_ndjson(nodes, edges) do
    File.mkdir_p!(Path.dirname(@ndjson_path))
    node_lines = Enum.map(nodes, fn n -> Jason.encode!(%{type: "node", data: n}) <> "\n" end)
    edge_lines = Enum.map(edges, fn e -> Jason.encode!(%{type: "edge", data: e}) <> "\n" end)
    File.write!(@ndjson_path, Enum.join(node_lines ++ edge_lines, ""))
  end

  defp export_matrix_csv(edges) do
    File.mkdir_p!(Path.dirname(@csv_path))
    static_csv_path = "priv/static/data/orbit_reachability_matrix.csv"
    File.mkdir_p!(Path.dirname(static_csv_path))
    
    header = "From,To,Probability,EnergyCost,ExpectedEpochs\n"
    rows =
      edges
      |> Enum.map(fn e ->
        "#{e.source_orbit},#{e.target_orbit},#{e.transition_probability},#{e.energy_cost},#{e.expected_epochs}\n"
      end)
      |> Enum.join("")

    File.write!(@csv_path, header <> rows)
    File.write!(static_csv_path, header <> rows)
  end

  # Standard betweenness centrality implementation for gateway scores
  defp populate_gateway_scores(nodes, edges) do
    # Calculate shortest paths between all pairs of nodes
    node_ids = Enum.map(nodes, & &1.orbit_id)
    all_pairs = for s <- node_ids, t <- node_ids, s != t, do: {s, t}

    # Compute shortest paths using a simple BFS / Dijkstra since graph is tiny and weights are energy costs
    shortest_paths =
      Enum.reduce(all_pairs, %{}, fn {s, t}, acc ->
        case find_shortest_paths(s, t, edges) do
          [] -> acc
          paths -> Map.put(acc, {s, t}, paths)
        end
      end)

    # Calculate centrality counts
    centrality_counts =
      Enum.reduce(node_ids, %{}, fn v, acc ->
        # Count paths where v is an intermediate node (not start or end)
        score =
          Enum.reduce(shortest_paths, 0.0, fn {{s, t}, paths}, sum ->
            if s != v and t != v do
              paths_through_v = Enum.filter(paths, & v in &1)
              sum + (length(paths_through_v) / length(paths))
            else
              sum
            end
          end)
        Map.put(acc, v, score)
      end)

    # Normalize scores (max possible is (k-1)*(k-2)/2 for undirected, or similar for directed. Let's divide by max score found or normalizer)
    max_score = Enum.map(centrality_counts, &elem(&1, 1)) |> Enum.max() |> max(1.0)

    Enum.map(nodes, fn node ->
      score = Map.get(centrality_counts, node.orbit_id, 0.0) / max_score
      %{node | gateway_score: Float.round(score, 4)}
    end)
  end

  # Helper to find shortest paths using energy cost
  defp find_shortest_paths(start, target, edges) do
    # Tiny graph: find all simple paths, then choose the ones with minimum sum of energy cost
    paths = find_all_simple_paths(start, target, edges, [start])
    if paths == [] do
      []
    else
      path_costs =
        Enum.map(paths, fn path ->
          cost =
            path
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.map(fn [u, v] ->
              edge = Enum.find(edges, &(&1.source_orbit == u and &1.target_orbit == v))
              # If edge probability is very low (e.g. < 0.01), treat as near-impossible
              if edge && edge.transition_probability > 0.01 do
                edge.energy_cost
              else
                999.0
              end
            end)
            |> Enum.sum()
          {path, cost}
        end)

      min_cost = path_costs |> Enum.map(&elem(&1, 1)) |> Enum.min()

      if min_cost >= 999.0 do
        []
      else
        path_costs
        |> Enum.filter(&(elem(&1, 1) <= min_cost + 0.0001))
        |> Enum.map(&elem(&1, 0))
      end
    end
  end

  defp find_all_simple_paths(curr, target, edges, visited) do
    if curr == target do
      [[target]]
    else
      neighbors =
        edges
        |> Enum.filter(&(&1.source_orbit == curr and &1.target_orbit not in visited))
        |> Enum.map(& &1.target_orbit)

      Enum.flat_map(neighbors, fn n ->
        find_all_simple_paths(n, target, edges, visited ++ [n])
        |> Enum.map(fn path -> [curr | path] end)
      end)
    end
  end

  # Populate gateway required and list of gateway nodes for each edge
  defp populate_gateway_requirements(edges, nodes) do
    Enum.map(edges, fn edge ->
      # A gateway is required if the direct probability is extremely low but an indirect path is much more likely
      # Or if we compute the highest probability path and it has intermediate nodes
      u = edge.source_orbit
      v = edge.target_orbit

      if u == v do
        edge
      else
        # Find highest probability path from u to v
        case find_highest_probability_path(u, v, edges) do
          {:ok, path, prob} ->
            # If path has length > 2 (meaning intermediate nodes exist) and its joint probability is significantly higher
            # than the direct transition probability, we classify it as requiring a gateway
            intermediates = path -- [u, v]
            if intermediates != [] and prob > edge.transition_probability * 1.5 do
              # We only select intermediate nodes that are classified as gateways or have high gateway scores
              gateway_nodes =
                Enum.filter(intermediates, fn node_id ->
                  node = Enum.find(nodes, & &1.orbit_id == node_id)
                  node && (node.gateway_score > 0.1 || node.orbit_type == :transient)
                end)

              %{edge |
                gateway_required: gateway_nodes != [],
                gateway_orbits: gateway_nodes
              }
            else
              edge
            end
          _ ->
            edge
        end
      end
    end)
  end

  # Dijkstra to find highest probability path (maximizes product of probabilities, i.e., minimizes -ln(p))
  defp find_highest_probability_path(start, target, edges) do
    paths = find_all_simple_paths(start, target, edges, [start])
    if paths == [] do
      {:error, :unreachable}
    else
      path_probs =
        Enum.map(paths, fn path ->
          prob =
            path
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.map(fn [u, v] ->
              e = Enum.find(edges, &(&1.source_orbit == u and &1.target_orbit == v))
              if e, do: e.transition_probability, else: 0.0
            end)
            |> Enum.reduce(1.0, & &1 * &2)
          {path, prob}
        end)

      {best_path, max_prob} = Enum.max_by(path_probs, &elem(&1, 1))
      if max_prob > 0.0 do
        {:ok, best_path, max_prob}
      else
        {:error, :unreachable}
      end
    end
  end
end
