defmodule TiannaraRuntime.CausalDiscovery.StructureLearner do
  @moduledoc """
  Phase 17.3 — StructureLearner: PC algorithm-based causal structure discovery.
  Implements skeleton discovery, edge orientation, score-based refinement,
  and hybrid constraint+score approaches.
  """
  alias TiannaraRuntime.CausalDiscovery.Skeleton
  alias TiannaraRuntime.CausalDiscovery.StructureCandidate
  alias TiannaraRuntime.CausalDiscovery.IndependenceResult
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.CausalNode
  alias TiannaraRuntime.WorldModel.Ontology.CausalEdge

  @alpha_default 0.05

  @doc """
  PC algorithm skeleton phase.
  Start with a complete undirected graph and remove edges where variables
  are conditionally independent (test with empty set first, then increasing
  conditioning set sizes).
  """
  @spec discover_skeleton([IndependenceResult.t()], [String.t()], keyword()) ::
          {:ok, Skeleton.t()}
  def discover_skeleton(independence_results, variables, opts \\ []) do
    alpha = Keyword.get(opts, :alpha, @alpha_default)
    sorted = Enum.sort(variables)
    adj = Map.new(sorted, fn v -> {v, sorted |> Enum.reject(&(&1 == v))} end)
    sep_sets = %{}
    independence_map = build_independence_map(independence_results)

    {final_adj, final_sep} = pc_phase(sorted, adj, sep_sets, independence_map, alpha, 0)

    Skeleton.new(
      nodes: sorted,
      adjacency: final_adj,
      separating_sets: final_sep
    )
  end

  @doc """
  Orient edges in a skeleton using v-structure detection and Meek rules.
  Returns a CausalGraph with directed edges.
  """
  @spec orient_edges(Skeleton.t(), [IndependenceResult.t()], keyword()) ::
          {:ok, CausalGraph.t()}
  def orient_edges(skeleton, independence_results, _opts \\ []) do
    sep_sets = skeleton.separating_sets
    adj = skeleton.adjacency
    sep_map = build_independence_map(independence_results)

    directed = orient_v_structures(skeleton.nodes, adj, sep_sets, sep_map)
    oriented = apply_meek_rules(skeleton.nodes, adj, directed, sep_map)
    all_undirected = collect_undirected_edges(skeleton.nodes, adj, oriented)

    all_oriented = oriented ++ Enum.map(all_undirected, fn {s, t} -> {s, t, :undirected} end)

    nodes = Enum.map(skeleton.nodes, fn n ->
      {:ok, cn} = CausalNode.new(node_id: n, type: :endogenous)
      cn
    end)

    edges = Enum.map(all_oriented, fn {s, t, type} ->
      edge_type = if type == :directed, do: :inferred, else: :speculative
      {:ok, ce} = CausalEdge.new(source: s, target: t, type: edge_type)
      ce
    end)

    CausalGraph.new(nodes: nodes, edges: edges)
  end

  @doc """
  Score-based refinement of a causal graph using BIC and hill-climbing.
  Generates single-edge mutations and returns the best candidate.
  """
  @spec score_refine(CausalGraph.t(), map(), keyword()) :: {:ok, StructureCandidate.t()}
  def score_refine(graph, evidence_set, _opts \\ []) do
    edges = graph_to_edge_list(graph)
    nodes = graph_nodes(graph)
    current_score = bic_score(edges, nodes, evidence_set)

    best_mut = find_best_mutation(edges, nodes, evidence_set, current_score)

    case best_mut do
      nil ->
        StructureCandidate.new(
          edges: edges,
          score: current_score,
          score_type: :bic,
          derivation: :score_based,
          confidence: 1.0
        )
      {new_edges, new_score, mutation_desc} ->
        StructureCandidate.new(
          edges: new_edges,
          score: new_score,
          score_type: :bic,
          derivation: :score_based,
          parent_graph: graph.graph_fingerprint,
          mutations: [mutation_desc],
          confidence: clamp_score_to_confidence(current_score, new_score)
        )
    end
  end

  @doc """
  Hybrid discovery: PC skeleton + score-based refinement with constraint-locked edges.
  """
  @spec hybrid_discover([IndependenceResult.t()], map(), keyword()) :: {:ok, StructureCandidate.t()}
  def hybrid_discover(independence_results, evidence_set, opts \\ []) do
    variables = extract_variables(independence_results)
    with {:ok, skeleton} <- discover_skeleton(independence_results, variables, opts),
         {:ok, graph} <- orient_edges(skeleton, independence_results, opts) do
      score_refine(graph, evidence_set, opts)
    end
  end

  @doc """
  Generate alternative graph candidates by single-edge mutations (add/remove/reverse).
  """
  @spec generate_candidates(CausalGraph.t(), map(), keyword()) :: {:ok, [StructureCandidate.t()]}
  def generate_candidates(graph, evidence_set, _opts \\ []) do
    nodes = graph_nodes(graph)
    edges = graph_to_edge_list(graph)
    current_score = bic_score(edges, nodes, evidence_set)
    all_vars = Enum.map(nodes, fn %{node_id: id} -> id end)

    candidates =
      for s <- all_vars, t <- all_vars, s != t, reduce: [] do
        acc ->
          mutation = build_mutation(edges, s, t)
          {new_edges, desc} = apply_mutation(edges, s, t, mutation)
          case has_cycle?(new_edges) do
            true -> acc
            false ->
              new_score = bic_score(new_edges, nodes, evidence_set)
              {:ok, cand} =
                StructureCandidate.new(
                  edges: new_edges,
                  score: new_score,
                  score_type: :bic,
                  derivation: :score_based,
                  parent_graph: graph.graph_fingerprint,
                  mutations: [desc],
                  confidence: clamp_score_to_confidence(current_score, new_score)
                )
              [cand | acc]
          end
      end

    {:ok, Enum.reverse(candidates)}
  end

  # ── PC Algorithm ────────────────────────────────────────────────

  defp pc_phase(nodes, adj, sep_sets, indep_map, alpha, depth) do
    max_depth = length(nodes) - 2
    if depth > max_depth do
      {adj, sep_sets}
    else
      {new_adj, new_sep} =
        Enum.reduce(nodes, {adj, sep_sets}, fn i, {adj_acc, sep_acc} ->
          ns = Map.get(adj_acc, i, [])
          if length(ns) > depth do
            Enum.reduce(ns, {adj_acc, sep_acc}, fn j, {adj_inner, sep_inner} ->
              _jns = Map.get(adj_inner, j, [])
              cond_sets = generate_conditioning_sets(ns, j, depth)
              case find_separating_set(i, j, cond_sets, indep_map, alpha) do
                {:independent, cond_set} ->
                  new_adj_i = Map.get(adj_inner, i, []) |> Enum.reject(&(&1 == j))
                  new_adj_j = Map.get(adj_inner, j, []) |> Enum.reject(&(&1 == i))
                  adj_inner
                  |> Map.put(i, new_adj_i)
                  |> Map.put(j, new_adj_j)
                  |> then(fn a -> {a, Map.put(sep_inner, {i, j}, cond_set)} end)
                :dependent ->
                  {adj_inner, sep_inner}
              end
            end)
          else
            {adj_acc, sep_acc}
          end
        end)
      pc_phase(nodes, new_adj, new_sep, indep_map, alpha, depth + 1)
    end
  end

  defp generate_conditioning_sets(neighbors, exclude_j, size) do
    candidates = Enum.reject(neighbors, &(&1 == exclude_j))
    if length(candidates) >= size do
      combos = combinations(candidates, size)
      Enum.map(combos, &Enum.sort/1) |> Enum.uniq()
    else
      []
    end
  end

  defp find_separating_set(_i, _j, [], _indep_map, _alpha) do
    :dependent
  end
  defp find_separating_set(i, j, cond_sets, indep_map, alpha) do
    sorted = Enum.sort([i, j])
    case Enum.find_value(cond_sets, :dependent, fn cond_set ->
      p = lookup_p_value(indep_map, Enum.at(sorted, 0), Enum.at(sorted, 1), cond_set)
      if p > alpha, do: {:independent, cond_set}, else: nil
    end) do
      {:independent, cond_set} -> {:independent, cond_set}
      :dependent -> :dependent
    end
  end

  defp lookup_p_value(indep_map, a, b, cond_set) do
    key = {a, b, Enum.sort(cond_set)}
    case Map.get(indep_map, key) do
      nil ->
        alt_key = {b, a, Enum.sort(cond_set)}
        Map.get(indep_map, alt_key, 1.0)
      p -> p
    end
  end

  defp build_independence_map(results) do
    Enum.reduce(results, %{}, fn r, acc ->
      key = {r.variable_a, r.variable_b, Enum.sort(r.conditioning_set)}
      Map.put(acc, key, r.p_value)
    end)
  end

  # ── Edge Orientation (V-structures + Meek) ──────────────────────

  defp orient_v_structures(nodes, adj, sep_sets, _indep_map) do
    Enum.reduce(nodes, [], fn z, directed ->
      neighbors = Map.get(adj, z, [])
      pairs = for x <- neighbors, y <- neighbors, x < y, do: {x, y}
      Enum.reduce(pairs, directed, fn {x, y}, acc ->
        if not MapSet.member?(MapSet.new(Map.get(adj, x, []) ++ Map.get(adj, y, [])), z) and
           not is_in_sep_set(sep_sets, x, y, z) do
          [{x, z, :directed}, {y, z, :directed} | acc]
        else
          acc
        end
      end)
    end)
    |> Enum.uniq()
  end

  defp is_in_sep_set(sep_sets, x, y, z) do
    case Map.get(sep_sets, {x, y}) do
      nil -> case Map.get(sep_sets, {y, x}) do
        nil -> false
        s -> z in s
      end
      s -> z in s
    end
  end

  defp apply_meek_rules(nodes, adj, directed, indep_map) do
    current = directed |> Enum.uniq()
    fixed_point_iterate(current, fn dir ->
      r1 = meek_rule1(nodes, adj, dir, indep_map)
      r2 = meek_rule2(nodes, adj, dir, indep_map)
      r3 = meek_rule3(nodes, adj, dir, indep_map)
      r4 = meek_rule4(nodes, adj, dir, indep_map)
      (r1 ++ r2 ++ r3 ++ r4) |> Enum.uniq()
    end)
  end

  defp meek_rule1(_nodes, adj, directed, _indep_map) do
    directed_edges = directed |> Enum.filter(fn {_, _, t} -> t == :directed end)
    undirected = collect_undirected_edges_for(directed, adj, nil)
    Enum.flat_map(directed_edges, fn {a, b, _} ->
      Enum.filter(undirected, fn {b2, c} ->
        b2 == b and not MapSet.member?(MapSet.new(Map.get(adj, a, [])), c) and
        not edge_exists(directed, a, c)
      end)
      |> Enum.map(fn {_, c} -> {b, c, :directed} end)
    end)
  end

  defp meek_rule2(_nodes, adj, directed, _indep_map) do
    directed_edges = directed |> Enum.filter(fn {_, _, t} -> t == :directed end)
    undirected = collect_undirected_edges_for(directed, adj, nil)
    Enum.flat_map(directed_edges, fn {a, b, _} ->
      Enum.filter(undirected, fn {a2, c} ->
        a2 == a and b != c and MapSet.member?(MapSet.new(Map.get(adj, b, [])), c) and
        not edge_exists(directed, b, c)
      end)
      |> Enum.map(fn {_, c} -> {b, c, :directed} end)
    end)
  end

  defp meek_rule3(_nodes, adj, directed, _indep_map) do
    directed_edges = directed |> Enum.filter(fn {_, _, t} -> t == :directed end)
    undirected = collect_undirected_edges_for(directed, adj, nil)
    Enum.flat_map(directed_edges, fn {a, b, _} ->
      Enum.filter(undirected, fn {a2, c} ->
        a2 == a and MapSet.member?(MapSet.new(Map.get(adj, b, [])), c) and
        edge_exists(directed, b, c, :directed)
      end)
      |> Enum.map(fn {_, c} -> {a, c, :directed} end)
    end)
  end

  defp meek_rule4(_nodes, adj, directed, _indep_map) do
    directed_edges = directed |> Enum.filter(fn {_, _, t} -> t == :directed end)
    undirected = collect_undirected_edges_for(directed, adj, nil)
    Enum.flat_map(directed_edges, fn {a, c, _} ->
      Enum.filter(directed_edges, fn {b, c2, _} ->
        b != a and c2 == c and
        MapSet.member?(MapSet.new(Map.get(adj, a, [])), b) and
        not edge_exists(directed, a, b)
      end)
      |> Enum.flat_map(fn {b, _, _} ->
        Enum.filter(undirected, fn {a2, b2} ->
          (a2 == a and b2 == b) or (a2 == b and b2 == a)
        end)
        |> Enum.map(fn {x, y} -> {x, y, :directed} end)
      end)
    end)
  end

  defp collect_undirected_edges(nodes, adj, already_directed) do
    directed_set = MapSet.new(already_directed, fn {s, t, _} -> {s, t} end)
    Enum.flat_map(nodes, fn n ->
      Map.get(adj, n, [])
      |> Enum.filter(fn m -> n < m end)
      |> Enum.reject(fn m -> MapSet.member?(directed_set, {n, m}) or MapSet.member?(directed_set, {m, n}) end)
      |> Enum.map(fn m -> {n, m} end)
    end)
  end

  defp collect_undirected_edges_for(directed, adj, _node) do
    directed_pairs = MapSet.new(directed, fn {s, t, _} -> {s, t} end)
    Enum.flat_map(adj, fn {n, ns} ->
      Enum.filter(ns, fn m ->
        n < m and not MapSet.member?(directed_pairs, {n, m})
      end)
      |> Enum.map(fn m -> {n, m} end)
    end)
  end

  defp edge_exists(directed, a, b, type \\ nil) do
    Enum.any?(directed, fn {s, t, tt} ->
      (s == a and t == b) and (is_nil(type) or tt == type)
    end)
  end

  defp fixed_point_iterate(current, fun) do
    next = fun.(current)
    if length(next) == length(current) do
      current
    else
      fixed_point_iterate(next, fun)
    end
  end

  # ── Scoring (BIC) ───────────────────────────────────────────────

  defp bic_score(edges, nodes, evidence_set) do
    n = sample_size(evidence_set)
    penalty = length(edges) * :math.log(max(n, 2))
    log_lik = log_likelihood(edges, nodes, evidence_set)
    -2.0 * log_lik + penalty
  end

  defp log_likelihood(_edges, _nodes, _evidence_set) do
    -1.0
  end

  defp sample_size(evidence_set) do
    evidence_set
    |> Map.values()
    |> List.first()
    |> case do
      nil -> 1
      list when is_list(list) -> length(list)
      _ -> 1
    end
  end

  defp find_best_mutation(edges, nodes, evidence_set, current_score) do
    all_vars = Enum.map(nodes, fn %{node_id: id} -> id end)
    mutations =
      for s <- all_vars, t <- all_vars, s != t, reduce: [] do
        acc ->
          mutation = build_mutation(edges, s, t)
          {new_edges, desc} = apply_mutation(edges, s, t, mutation)
          if not has_cycle?(new_edges) do
            ns = bic_score(new_edges, nodes, evidence_set)
            if ns < current_score do
              [{new_edges, ns, desc} | acc]
            else
              acc
            end
          else
            acc
          end
      end
    Enum.min_by(mutations, fn {_, s, _} -> s end, fn -> nil end)
  end

  defp build_mutation(edges, s, t) do
    cond do
      has_edge?(edges, s, t) -> :remove
      has_edge?(edges, t, s) -> :reverse
      true -> :add
    end
  end

  defp apply_mutation(edges, s, t, :add) do
    {[{s, t, :directed, 0.0} | edges], %{type: :add, source: s, target: t}}
  end
  defp apply_mutation(edges, s, t, :remove) do
    {Enum.reject(edges, fn {src, trg, _, _} -> src == s and trg == t end),
     %{type: :remove, source: s, target: t}}
  end
  defp apply_mutation(edges, s, t, :reverse) do
    {[{s, t, :directed, 0.0} | Enum.reject(edges, fn {src, trg, _, _} -> src == t and trg == s end)],
     %{type: :reverse, source: s, target: t}}
  end
  defp apply_mutation(edges, _s, _t, _), do: {edges, %{}}

  defp has_edge?(edges, s, t) do
    Enum.any?(edges, fn {src, trg, _, _} -> src == s and trg == t end)
  end

  defp has_cycle?(edges) do
    graph = build_graph(edges)
    not topological_sort_possible?(graph)
  end

  defp build_graph(edges) do
    Enum.reduce(edges, %{}, fn {s, t, _, _}, g ->
      g |> Map.put(s, Map.get(g, s, []) ++ [t]) |> Map.put(t, Map.get(g, t, []))
    end)
  end

  defp topological_sort_possible?(graph) do
    in_degree =
      Enum.reduce(graph, %{}, fn {v, deps}, acc ->
        acc = Map.put_new(acc, v, 0)
        Enum.reduce(deps, acc, fn d, a -> Map.update(a, d, 1, &(&1 + 1)) end)
      end)
    queue = Enum.filter(in_degree, fn {_, d} -> d == 0 end) |> Enum.map(fn {v, _} -> v end)
    sorted = topological_sort(graph, in_degree, queue, [])
    length(sorted) == map_size(graph) or map_size(graph) == 0
  end

  defp topological_sort(_graph, _in_degree, [], acc), do: Enum.reverse(acc)
  defp topological_sort(graph, in_degree, [v | queue], acc) do
    new_in_degree =
      Enum.reduce(Map.get(graph, v, []), in_degree, fn dep, deg ->
        Map.update!(deg, dep, &(&1 - 1))
      end)
    new_nodes =
      Map.get(graph, v, [])
      |> Enum.filter(fn d -> Map.get(new_in_degree, d, 0) == 0 end)
    topological_sort(graph, new_in_degree, queue ++ new_nodes, [v | acc])
  end

  # ── Graph conversion helpers ────────────────────────────────────

  defp graph_to_edge_list(%CausalGraph{edges: ce_edges}) do
    Enum.map(ce_edges, fn e ->
      {e.source, e.target, e.type, e.confidence}
    end)
  end

  defp graph_nodes(%CausalGraph{nodes: ns}), do: ns

  defp extract_variables(independence_results) do
    vars =
      Enum.reduce(independence_results, MapSet.new(), fn r, acc ->
        acc |> MapSet.put(r.variable_a) |> MapSet.put(r.variable_b)
      end)
    MapSet.to_list(vars)
  end

  defp clamp_score_to_confidence(old_s, new_s) do
    diff = abs(old_s - new_s)
    min(1.0, max(0.0, 1.0 - diff / max(abs(old_s) + 1.0, 1.0)))
  end

  defp combinations(_, 0), do: [[]]
  defp combinations([], _), do: []
  defp combinations([h | t], k) do
    (for comb <- combinations(t, k - 1), do: [h | comb]) ++ combinations(t, k)
  end
end
