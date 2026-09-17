defmodule Tiannara.Meta.OPC.Stabilization.AORRegularizer do
  @moduledoc """
  Phase 5F.6 — Automated Ontological Regularizer (AOR)

  Traverses the Observer's AST and rewrites dangerous divisions,
  logarithms, and asymptotic tensors with dynamic MSCL-bound ε-shims.

  ## Mathematical Transformations

  ### Division Regularization
      Original:    A / B
      Regularized: A / sqrt(B² + ε²)

  ### Logarithm Regularization
      Original:    log(x)
      Regularized: log(abs(x) + ε)

  Where ε is a live pointer to the MSCL-Ω thermodynamic budget.

  ## Usage

      ast = {:op, :/, [{:const, 1.0}, {:var, :x}]}
      safe_ast = AORRegularizer.regularize(ast)
  """

  require Logger

  @doc """
  Regularizes an observer physics AST by injecting MSCL ε-shims into
  all potentially singular operations.

  ## Parameters
  - `ast`: The raw observer physics AST

  ## Returns
  - Regularized AST with ε-shims injected at all dangerous nodes
  """
  def regularize(ast) do
    walk(ast)
  end

  # ── Private AST Walker ────────────────────────────────────────────────────

  # Division: A / B → A / sqrt(B² + ε²)
  defp walk({:op, :/, [a, b]}) do
    Logger.warning("🛡️ [AOR] Division singularity regularized")

    {:op, :/,
     [
       walk(a),
       {:op, :sqrt,
        [
          {:op, :+,
           [
             {:op, :pow, [walk(b), 2]},
             {:mscl_pointer, :epsilon}
           ]}
        ]}
     ]}
  end

  # Logarithm: log(x) → log(abs(x) + ε)
  defp walk({:op, :log, [argument]}) do
    Logger.warning("🛡️ [AOR] Logarithm singularity regularized")

    {:op, :log,
     [
       {:op, :+,
        [
          {:op, :abs, [walk(argument)]},
          {:mscl_pointer, :epsilon}
        ]}
     ]}
  end

  # Square root: sqrt(x) → sqrt(abs(x) + ε)
  defp walk({:op, :sqrt, [argument]}) do
    Logger.debug("🛡️ [AOR] Square root domain regularized")

    {:op, :sqrt,
     [
       {:op, :+,
        [
          {:op, :abs, [walk(argument)]},
          {:mscl_pointer, :epsilon}
        ]}
     ]}
  end

  # Pass-through for all other operations — recurse into args
  defp walk({:op, op, args}) do
    {:op, op, Enum.map(args, &walk/1)}
  end

  # Pass-through for leaf nodes (constants, variables, pointers)
  defp walk(other), do: other
end
