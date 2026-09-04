defmodule Tiannara.Discovery.Optimization.ActiveLearner do
  alias Tiannara.Discovery.Domain.{HypothesisSpec, ExperimentPlan}

  @spec select_next([ExperimentPlan.t()], [HypothesisSpec.t()]) :: {ExperimentPlan.t(), float()} | nil
  def select_next([], _hypotheses), do: nil
  def select_next(experiments, hypotheses) when is_list(experiments) do
    experiments
    |> Enum.map(fn exp -> {exp, compute_eig(exp, hypotheses)} end)
    |> Enum.max_by(fn {_exp, eig} -> eig end)
  end

  @spec rank_by_eig([ExperimentPlan.t()], [HypothesisSpec.t()]) :: [{ExperimentPlan.t(), float()}]
  def rank_by_eig(experiments, hypotheses) do
    experiments
    |> Enum.map(fn exp -> {exp, compute_eig(exp, hypotheses)} end)
    |> Enum.sort_by(fn {_exp, eig} -> eig end, :desc)
  end

  @spec compute_eig(ExperimentPlan.t(), [HypothesisSpec.t()]) :: float()
  def compute_eig(%ExperimentPlan{} = exp, hypotheses) do
    hypothesis = Enum.find(hypotheses, &(&1.id == exp.hypothesis_id))
    if hypothesis == nil do
      0.0
    else
      uncertainty_reduction = hypothesis.expected_information_gain
      novelty = Map.get(hypothesis.metadata, :novelty, 1.0 - hypothesis.risk)
      cost = Map.get(exp.estimated_cost, :compute, 0) + Map.get(exp.estimated_cost, :time_hours, 0)
      cost_penalty = min(0.5, cost / 1000.0)
      max(0.0, uncertainty_reduction * novelty * (1.0 - cost_penalty))
    end
  end

  @spec ucb(ExperimentPlan.t(), [HypothesisSpec.t()], float()) :: float()
  def ucb(%ExperimentPlan{} = exp, hypotheses, kappa \\ 1.0) do
    hypothesis = Enum.find(hypotheses, &(&1.id == exp.hypothesis_id))
    if hypothesis == nil do
      0.0
    else
      mean = hypothesis.expected_information_gain
      std = hypothesis.risk
      mean + kappa * std
    end
  end

  @spec optimal_sequence([ExperimentPlan.t()], [HypothesisSpec.t()]) :: [ExperimentPlan.t()]
  def optimal_sequence(experiments, hypotheses) do
    do_optimal_sequence(experiments, hypotheses, [])
  end

  defp do_optimal_sequence([], _hypotheses, acc), do: Enum.reverse(acc)
  defp do_optimal_sequence(remaining, hypotheses, acc) do
    case select_next(remaining, hypotheses) do
      nil -> Enum.reverse(acc)
      {selected, _eig} ->
        updated_hypotheses = update_hypotheses_after_experiment(hypotheses, selected)
        remaining = List.delete(remaining, selected)
        do_optimal_sequence(remaining, updated_hypotheses, [selected | acc])
    end
  end

  defp update_hypotheses_after_experiment(hypotheses, %ExperimentPlan{} = exp) do
    Enum.map(hypotheses, fn hyp ->
      if hyp.id == exp.hypothesis_id do
        %{hyp | expected_information_gain: hyp.expected_information_gain * 0.5}
      else
        hyp
      end
    end)
  end
end
