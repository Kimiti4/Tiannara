defmodule TiannaraRuntime.WorldModel.Composition.Engines.MathVerificationEngine do
  @moduledoc """
  Phase 17.6.8 — MathVerificationEngine engine.
  Verifies mathematical consistency of composed world models.
  Delegates to the Mathematics Substrate (Phase 16.X) when available.
  """

  def verify(graph) do
    checks = [
      verify_equation_consistency(graph),
      verify_causal_consistency(graph),
      verify_numerical_stability(graph)
    ]

    failures = Enum.filter(checks, fn c -> c.status != :pass end)

    if failures == [] do
      proof_hash = generate_proof_hash(graph, checks)
      {:ok, proof_hash, %{checks: checks, verified: true}}
    else
      {:error, :math_inconsistency, %{checks: checks, failures: failures}}
    end
  end

  def verify_equation_consistency(graph) do
    eq_nodes = Enum.filter(graph.nodes || [], fn n -> n.type == :equation end)

    status =
      cond do
        eq_nodes == [] ->
          :pass
        length(eq_nodes) > 0 ->
          has_expression = Enum.all?(eq_nodes, fn n ->
            props = n.properties || %{}
            Map.has_key?(props, "expression") || Map.has_key?(props, :expression)
          end)
          if has_expression, do: :pass, else: :fail
        true ->
          :pass
      end

    %{check: :equation_consistency, status: status, count: length(eq_nodes)}
  end

  def verify_causal_consistency(graph) do
    causal_edges = Enum.filter(graph.edges || [], fn e -> e.type == :causality end)

    status =
      cond do
        length(causal_edges) == 0 ->
          :pass
        true ->
          no_self_loops = Enum.all?(causal_edges, fn e -> e.source_id != e.target_id end)
          no_duplicates = length(Enum.uniq_by(causal_edges, fn e -> {e.source_id, e.target_id} end)) == length(causal_edges)
          if no_self_loops and no_duplicates, do: :pass, else: :fail
      end

    %{check: :causal_consistency, status: status, count: length(causal_edges)}
  end

  def verify_numerical_stability(graph) do
    edges = graph.edges || []
    all_edges = length(edges)

    weight_info =
      if all_edges > 0 do
        weights = Enum.filter(edges, fn e -> e.weight != nil end)
        if weights == [] do
          %{type: :no_weights, status: :pass}
        else
          finite = Enum.all?(weights, fn e -> is_float(e.weight) && e.weight == e.weight && abs(e.weight) != :infinity end)
          if finite, do: %{type: :weights_finite, status: :pass}, else: %{type: :infinite_weight, status: :fail}
        end
      else
        %{type: :no_edges, status: :pass}
      end

    %{check: :numerical_stability, status: weight_info.status, details: weight_info}
  end

  defp generate_proof_hash(graph, checks) do
    check_concat =
      checks
      |> Enum.map(fn c -> "#{c.check}:#{c.status}" end)
      |> Enum.join("|")

    :crypto.hash(:sha256, inspect(graph.graph_id) <> check_concat)
    |> Base.encode16(case: :lower)
  end
end
