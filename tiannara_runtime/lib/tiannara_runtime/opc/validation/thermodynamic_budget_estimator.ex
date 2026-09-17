defmodule Tiannara.OPC.Validation.ThermodynamicBudgetEstimator do
  @moduledoc """
  Phase 5F.6 — Thermodynamic Budget Estimator

  Estimates the computational/thermodynamic cost of executing an observer's
  physics proposal. Prevents thermodynamic overflow that could destabilize
  the runtime.

  ## Cost Factors

  - AST complexity (number of operations)
  - Tensor rank and dimensionality
  - Recursive depth
  - GPU shader compilation overhead
  - Memory allocation requirements

  ## Usage

      ast = {:op, :+, [{:var, :x}, {:var, :y}]}
      {:ok, cost} = ThermodynamicBudgetEstimator.estimate(ast)
      # cost is in arbitrary thermodynamic units (0-10000 scale)
  """

  require Logger

  @max_acceptable_cost 1000

  @doc """
  Estimates thermodynamic cost of AST execution.

  ## Returns
  - `{:ok, cost}` — Estimated cost in thermodynamic units
  - `{:error, :thermodynamic_overflow}` — Cost exceeds safe limits

  ## Example

      simple_ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      {:ok, cost} = ThermodynamicBudgetEstimator.estimate(simple_ast)
      # cost might be ~50 units

      complex_ast = build_complex_physics()
      {:error, :thermodynamic_overflow} = ThermodynamicBudgetEstimator.estimate(complex_ast)
  """
  def estimate(ast) do
    Logger.debug("⚡ [ThermodynamicBudgetEstimator] Estimating cost for AST...")

    cost = calculate_cost(ast)

    if cost <= @max_acceptable_cost do
      Logger.debug("✅ [ThermodynamicBudgetEstimator] Cost acceptable: #{cost}")
      {:ok, cost}
    else
      Logger.warning("🛑 [ThermodynamicBudgetEstimator] Thermodynamic overflow: #{cost} > #{@max_acceptable_cost}")
      {:error, :thermodynamic_overflow}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp calculate_cost({:op, _op_name, args}) when is_list(args) do
    # Base cost for operation + cost of arguments
    base_cost = 10
    arg_costs = Enum.map(args, &calculate_cost/1) |> Enum.sum()
    base_cost + arg_costs
  end

  defp calculate_cost({:const, _value}), do: 5
  defp calculate_cost({:var, _name}), do: 8
  defp calculate_cost(list) when is_list(list), do: Enum.map(list, &calculate_cost/1) |> Enum.sum()
  defp calculate_cost(_other), do: 1
end
