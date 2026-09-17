defmodule Tiannara.OED.OAVL.EpistemicCost do
  @moduledoc """
  📐 OAVL Epistemic Cost.

  Evaluates candidate configuration rules against complexity budgets (proof size,
  observer interpretability ratios, semantic compression ratio, and reconciliation overhead).
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Computes the complexity weight and epistemic cost indices of the rule configuration.
  """
  @spec calculate_cost(rule :: map()) :: {:ok, map()} | {:error, String.t()}
  def calculate_cost(rule) do
    GenServer.call(__MODULE__, {:calculate, rule})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:calculate, rule}, _from, state) do
    cost_metrics = evaluate_cost(rule)
    {:reply, {:ok, cost_metrics}, state}
  end

  # ==================== Internal Cost Evaluators ====================

  defp evaluate_cost(rule) do
    ast_size = calculate_nodes(rule.body)

    # 1. Proof complexity (proportional to AST size)
    proof_complexity = ast_size * 10

    # 2. Observer interpretability (smaller is more interpretable)
    interpretability = Float.round(1.0 / (1.0 + ast_size * 0.05), 3)

    # 3. Compression ratio (ratio of parsed config to rules size)
    compression_ratio = Float.round(120.0 / (120.0 + ast_size), 3)

    # 4. Reconciliation overhead
    reconciliation_overhead = ast_size * 2.5

    %{
      proof_complexity: proof_complexity,
      interpretability: interpretability,
      compression_ratio: compression_ratio,
      reconciliation_overhead: reconciliation_overhead,
      total_cost: proof_complexity + reconciliation_overhead
    }
  end

  defp calculate_nodes({:if, _cond, then_b, else_b}) do
    3 + calculate_nodes(then_b) + calculate_nodes(else_b)
  end

  defp calculate_nodes({_op, a, b}) when is_tuple(a) or is_tuple(b) do
    2 + calculate_nodes(a) + calculate_nodes(b)
  end

  defp calculate_nodes(_), do: 1
end
