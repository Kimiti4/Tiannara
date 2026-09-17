defmodule Tiannara.Meta.OPC.Stabilization.ManifoldStability do
  @moduledoc """
  Phase 5F.6 — Manifold Stability Checker

  Validates that a compiled physics proposal will not destabilise the
  observer manifold. Checks for causal paradox injection, topology
  violations, and manifold curvature overflow.

  ## Checks

  - Causal ordering: no backward-in-time influences
  - Topology: no non-orientable manifold mutations
  - Curvature: Ricci scalar bounded within safe range

  ## Usage

      ast = {:op, :gravity, [{:var, :mass}, {:var, :r}]}
      :ok = ManifoldStability.validate(ast)
  """

  require Logger

  # Maximum allowed Ricci scalar curvature (normalised units)
  @max_curvature 0.95

  @doc """
  Validates manifold stability for the given AST.

  ## Returns
  - `:ok` — Manifold remains stable
  - `{:error, :causal_paradox}` — Backward causation detected
  - `{:error, :topology_violation}` — Non-orientable mutation detected
  - `{:error, :curvature_overflow}` — Ricci scalar exceeds safe bound
  """
  def validate(ast) do
    with :ok <- check_causal_ordering(ast),
         :ok <- check_topology(ast),
         :ok <- check_curvature(ast) do
      Logger.debug("✅ [ManifoldStability] Manifold stability validated")
      :ok
    end
  end

  # ── Private Checks ────────────────────────────────────────────────────────

  defp check_causal_ordering(ast) do
    if contains_backward_causation?(ast) do
      Logger.warning("🛑 [ManifoldStability] Causal paradox detected in AST")
      {:error, :causal_paradox}
    else
      :ok
    end
  end

  defp check_topology(ast) do
    if contains_topology_violation?(ast) do
      Logger.warning("🛑 [ManifoldStability] Topology violation detected in AST")
      {:error, :topology_violation}
    else
      :ok
    end
  end

  defp check_curvature(ast) do
    curvature = estimate_curvature(ast)

    if curvature > @max_curvature do
      Logger.warning(
        "🛑 [ManifoldStability] Curvature #{Float.round(curvature, 4)} exceeds maximum #{@max_curvature}"
      )

      {:error, :curvature_overflow}
    else
      :ok
    end
  end

  # ── Heuristic Detectors ───────────────────────────────────────────────────

  # Backward causation: operations that reference future state
  defp contains_backward_causation?({:op, :retrocausal, _}), do: true
  defp contains_backward_causation?({:op, :time_reverse, _}), do: true

  defp contains_backward_causation?({:op, _, args}) when is_list(args) do
    Enum.any?(args, &contains_backward_causation?/1)
  end

  defp contains_backward_causation?(list) when is_list(list) do
    Enum.any?(list, &contains_backward_causation?/1)
  end

  defp contains_backward_causation?(_), do: false

  # Topology violations: non-orientable manifold operations
  defp contains_topology_violation?({:op, :mobius_fold, _}), do: true
  defp contains_topology_violation?({:op, :klein_bottle, _}), do: true

  defp contains_topology_violation?({:op, _, args}) when is_list(args) do
    Enum.any?(args, &contains_topology_violation?/1)
  end

  defp contains_topology_violation?(list) when is_list(list) do
    Enum.any?(list, &contains_topology_violation?/1)
  end

  defp contains_topology_violation?(_), do: false

  # Curvature: estimated from AST structural complexity
  defp estimate_curvature(ast) do
    node_count = count_nodes(ast)
    # Normalise: 100 nodes ≈ curvature 1.0
    min(node_count / 100.0, 1.0)
  end

  defp count_nodes({:op, _, args}) when is_list(args) do
    1 + Enum.sum(Enum.map(args, &count_nodes/1))
  end

  defp count_nodes(list) when is_list(list) do
    Enum.sum(Enum.map(list, &count_nodes/1))
  end

  defp count_nodes(_), do: 1
end
