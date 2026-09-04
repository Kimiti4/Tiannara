defmodule Tiannara.Discovery.Optimization.EarlyStoppingEvaluator do
  alias Tiannara.Discovery.Domain.{ExperimentPlan, DiscoveryResult}

  @spec evaluate(ExperimentPlan.t(), [DiscoveryResult.t()], map()) :: atom()
  def evaluate(%ExperimentPlan{} = plan, results_so_far, progress \\ %{}) do
    cond do
      falsification_met?(plan, results_so_far) -> :stop_failure
      success_met?(plan, results_so_far) -> :stop_success
      diminishing_returns?(results_so_far) -> :stop_futility
      budget_exceeded?(plan, progress) -> :stop_futility
      true -> :continue
    end
  end

  @spec optimal_stopping_point([DiscoveryResult.t()], float()) :: non_neg_integer()
  def optimal_stopping_point(results, threshold \\ 0.01) do
    if results == [] do
      0
    else
      results
      |> Enum.with_index()
      |> Enum.find(fn {result, _idx} -> abs(result.confidence_delta) < threshold end)
      |> case do
        nil -> length(results)
        {_result, idx} -> idx + 1
      end
    end
  end

  defp falsification_met?(%ExperimentPlan{failure_criteria: criteria}, results) do
    Enum.any?(results, fn r -> r.outcome == :refuted end) and criteria != nil and criteria != []
  end

  defp success_met?(%ExperimentPlan{success_criteria: criteria}, results) do
    confirmed_count = Enum.count(results, &(&1.outcome == :confirmed))
    total = length(results)
    total >= 3 and confirmed_count / total > 0.8 and criteria != nil and criteria != []
  end

  defp diminishing_returns?(results) do
    if length(results) < 5 do
      false
    else
      recent = Enum.take(results, -3)
      avg_delta = Enum.reduce(recent, 0.0, fn r, acc -> acc + abs(r.confidence_delta) end) / 3
      avg_delta < 0.01
    end
  end

  defp budget_exceeded?(%ExperimentPlan{estimated_cost: cost}, progress) do
    max_iterations = Map.get(cost, :max_iterations, 1000)
    current_iteration = Map.get(progress, :current_iteration, 0)
    current_iteration > max_iterations * 1.5
  end
end
