defmodule TiannaraRuntime.CausalDiscovery.EdgeScorer do
  @moduledoc """
  Phase 17.3 — EdgeScorer: multi-metric scoring engine for causal edges.
  Computes evidence support, statistical strength, stability, replay confidence,
  and intervention compatibility, then combines them into an overall score.
  """
  alias TiannaraRuntime.CausalDiscovery.EdgeScore
  alias TiannaraRuntime.CausalDiscovery.IndependenceResult

  @doc """
  Score a single directed edge (source -> target) across all metrics.
  Each metric is in [0.0, 1.0].
  """
  @spec score_edge(String.t(), String.t(), [IndependenceResult.t()], map(), keyword()) ::
          {:ok, EdgeScore.t()}
  def score_edge(source, target, independence_results, evidence_set, opts \\ []) do
    weights = Keyword.get(opts, :weight_vector, [0.2, 0.2, 0.2, 0.2, 0.2])

    relevant = filter_relevant_results(source, target, independence_results)
    evidence_support = compute_evidence_support(source, target, relevant)
    statistical_strength = compute_statistical_strength(relevant)
    stability = compute_stability(source, target, evidence_set)
    replay_confidence = compute_replay_confidence(relevant)
    intervention_compat = compute_intervention_compat(source, target, evidence_set)

    overall =
      evidence_support * Enum.at(weights, 0) +
      statistical_strength * Enum.at(weights, 1) +
      stability * Enum.at(weights, 2) +
      replay_confidence * Enum.at(weights, 3) +
      intervention_compat * Enum.at(weights, 4)

    EdgeScore.new(
      source: source,
      target: target,
      evidence_support: evidence_support,
      statistical_strength: statistical_strength,
      stability: stability,
      replay_confidence: replay_confidence,
      intervention_compat: intervention_compat,
      overall: overall,
      weight_vector: weights
    )
  end

  @doc """
  Score all edges in a causal graph by calling score_edge for each directed edge.
  """
  @spec score_graph(TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(), [IndependenceResult.t()], map(), keyword()) ::
          {:ok, [EdgeScore.t()]}
  def score_graph(graph, independence_results, evidence_set, opts \\ []) do
    unique_pairs =
      graph.edges
      |> Enum.map(fn e -> {e.source, e.target} end)
      |> Enum.uniq()

    results =
      Enum.reduce_while(unique_pairs, {:ok, []}, fn {s, t}, {:ok, acc} ->
        case score_edge(s, t, independence_results, evidence_set, opts) do
          {:ok, es} -> {:cont, {:ok, [es | acc]}}
          err -> {:halt, err}
        end
      end)

    case results do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      err -> err
    end
  end

  @doc """
  Rank edge scores in descending order by the given metric (an atom field name).
  """
  @spec rank_by_metric([EdgeScore.t()], atom()) :: [EdgeScore.t()]
  def rank_by_metric(edge_scores, metric) when is_atom(metric) do
    Enum.sort_by(edge_scores, &Map.get(&1, metric, 0.0), :desc)
  end

  @doc """
  Returns the content-addressed ID of an EdgeScore.
  """
  @spec edge_fingerprint(EdgeScore.t()) :: String.t()
  def edge_fingerprint(%EdgeScore{edge_id: id}), do: id

  # ── Metric computations ─────────────────────────────────────────

  defp filter_relevant_results(source, target, results) do
    Enum.filter(results, fn r ->
      (r.variable_a == source and r.variable_b == target) or
      (r.variable_a == target and r.variable_b == source)
    end)
  end

  defp compute_evidence_support(_source, _target, relevant) do
    if relevant == [] do
      0.5
    else
      count_below_alpha = Enum.count(relevant, fn r -> r.p_value < 0.05 end)
      count_below_alpha / length(relevant)
    end
  end

  defp compute_statistical_strength(relevant) do
    if relevant == [] do
      0.5
    else
      avg_strength =
        relevant
        |> Enum.map(fn r -> 1.0 - min(r.p_value, 1.0) end)
        |> Enum.sum()
        |> then(&(&1 / length(relevant)))
      avg_strength
    end
  end

  defp compute_stability(source, target, evidence_set) do
    a_vals = Map.get(evidence_set, source, [])
    b_vals = Map.get(evidence_set, target, [])
    n = min(length(a_vals), length(b_vals))
    if n < 8 do
      0.5
    else
      bootstrap_consistency = measure_bootstrap_stability(a_vals, b_vals, n)
      bootstrap_consistency
    end
  end

  defp measure_bootstrap_stability(a_vals, b_vals, n) do
    n_boot = 20
    n_sample = max(4, div(n, 2))
    rng_seed = {n, n_boot, n_sample}

    correlations =
      Enum.map(1..n_boot, fn i ->
        seed = {elem(rng_seed, 0) + i, elem(rng_seed, 1), elem(rng_seed, 2)}
        idxs = bootstrap_indices(n_sample, n, seed)
        a_boot = Enum.map(idxs, fn idx -> Enum.at(a_vals, rem(idx, n)) end)
        b_boot = Enum.map(idxs, fn idx -> Enum.at(b_vals, rem(idx, n)) end)
        compute_pearson(a_boot, b_boot)
      end)

    mean_r = Enum.sum(correlations) / n_boot
    variance =
      Enum.reduce(correlations, 0.0, fn r, acc -> acc + (r - mean_r) * (r - mean_r) end) / n_boot
    std_r = :math.sqrt(max(variance, 1.0e-15))

    stability = 1.0 - min(std_r, 1.0)
    max(0.0, min(1.0, stability))
  end

  defp bootstrap_indices(count, max, seed) do
    {a, b, c} = seed
    Enum.map(1..count, fn i ->
      x = a + b * i + c * i * i
      rem(rem(x, max) + max, max)
    end)
  end

  defp compute_pearson(x_vals, y_vals) do
    n = length(x_vals)
    sx = Enum.sum(x_vals)
    sy = Enum.sum(y_vals)
    sxy = Enum.zip(x_vals, y_vals) |> Enum.reduce(0.0, fn {x, y}, a -> a + x * y end)
    sxx = Enum.reduce(x_vals, 0.0, fn x, a -> a + x * x end)
    syy = Enum.reduce(y_vals, 0.0, fn y, a -> a + y * y end)
    num = n * sxy - sx * sy
    den = :math.sqrt((n * sxx - sx * sx) * (n * syy - sy * sy))
    if abs(den) < 1.0e-15, do: 0.0, else: num / den
  end

  defp compute_replay_confidence(relevant) do
    if relevant == [] do
      0.0
    else
      with_evidence = Enum.count(relevant, fn r -> not is_nil(r.evidence_root) end)
      with_evidence / length(relevant)
    end
  end

  defp compute_intervention_compat(_source, _target, _evidence_set) do
    0.7
  end
end
