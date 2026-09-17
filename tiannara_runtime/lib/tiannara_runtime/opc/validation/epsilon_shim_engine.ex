defmodule Tiannara.OPC.Validation.EpsilonShimEngine do
  @moduledoc """
  Phase 5F.6 — Automated Ontological Regularization (AOR) Engine

  Performs AST rewriting to inject dynamic ε-shims into dangerous operations,
  preventing runtime singularities without rejecting observer proposals.

  ## Core Concept

  When the compiler detects unbounded operations (division, logarithm, etc.),
  it rewrites the AST to include MSCL-Ω-bound regularization parameters.

  ## Mathematical Transformations

  ### Division Regularization
  ```
  Original:    A / B
  Regularized: A / sqrt(B² + ε²)
  ```

  ### Logarithm Regularization
  ```
  Original:    log(x)
  Regularized: log(abs(x) + ε)
  ```

  Where ε is a live pointer to MSCL-Ω thermodynamic budget.

  ## Usage

      ast = {:op, :/, [{:const, 1.0}, {:var, :x}]}
      {:ok, safe_ast} = EpsilonShimEngine.apply(ast, 0.5)
      # Returns AST with epsilon shim injected
  """

  require Logger

  @doc """
  Applies Automated Ontological Regularization to observer physics AST.

  ## Parameters
  - `ast`: The physics AST to regularize
  - `thermodynamic_budget`: Current MSCL-Ω budget (affects ε magnitude)

  ## Returns
  - `{:ok, regularized_ast}` — AST with safety shims injected
  """
  def apply(ast, thermodynamic_budget \\ 0.5) do
    Logger.debug("🛡️ [EpsilonShimEngine] Applying AOR regularization (budget: #{thermodynamic_budget})")

    epsilon = compute_epsilon(thermodynamic_budget)
    regularized_ast = rewrite_ast(ast, epsilon)

    {:ok, regularized_ast}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp compute_epsilon(budget) do
    # ε inversely proportional to budget
    # High budget → small ε (precise physics)
    # Low budget → large ε (fuzzy physics, prevents crashes)
    1.0 / (budget * 1000 + 0.001)
  end

  defp rewrite_ast({:op, :/, [numerator, denominator]}, epsilon) do
    # Rewrite division: A/B → A/sqrt(B² + ε²)
    Logger.info("🛡️ [AOR] Injecting ε-shim into division operation")

    {:op, :/, [
      rewrite_ast(numerator, epsilon),
      {:op, :sqrt, [
        {:op, :+, [
          {:op, :pow, [rewrite_ast(denominator, epsilon), 2]},
          {:op, :pow, [{:mscl_pointer, :epsilon_variance}, 2]}
        ]}
      ]}
    ]}
  end

  defp rewrite_ast({:op, :log, [argument]}, epsilon) do
    # Rewrite logarithm: log(x) → log(abs(x) + ε)
    Logger.info("🛡️ [AOR] Injecting ε-shim into logarithm operation")

    {:op, :log, [
      {:op, :+, [
        {:op, :abs, [rewrite_ast(argument, epsilon)]},
        {:mscl_pointer, :epsilon_variance}
      ]}
    ]}
  end

  defp rewrite_ast({:op, :sqrt, [argument]}, epsilon) do
    # Rewrite square root: sqrt(x) → sqrt(abs(x) + ε)
    Logger.debug("🛡️ [AOR] Adding safety bound to square root")

    {:op, :sqrt, [
      {:op, :+, [
        {:op, :abs, [rewrite_ast(argument, epsilon)]},
        {:mscl_pointer, :epsilon_variance}
      ]}
    ]}
  end

  defp rewrite_ast({:op, op_name, args}, epsilon) when is_list(args) do
    # Recursively process all arguments
    {:op, op_name, Enum.map(args, &rewrite_ast(&1, epsilon))}
  end

  defp rewrite_ast(list, epsilon) when is_list(list) do
    Enum.map(list, &rewrite_ast(&1, epsilon))
  end

  defp rewrite_ast(leaf_node, _epsilon) do
    # Pass through constants, variables, and other leaf nodes unchanged
    leaf_node
  end
end
