defmodule TiannaraRuntime.Mathematics.CounterexampleLearner do
  @moduledoc """
  Converts explicit counterexamples into candidate search constraints.

  Learned constraints are hypotheses about the search space. They are not
  promoted to mathematical facts without independent validation.
  """

  def learn({:falsified, evidence}, candidate) when is_map(evidence) do
    {:ok, %{candidate_id: candidate_id(candidate), source: :counterexample,
      evidence: evidence, status: :constraint_candidate, certification_eligible: false}}
  end

  def learn({:inconclusive, details}, candidate) when is_map(details) do
    {:ok, %{candidate_id: candidate_id(candidate), source: :inconclusive_result,
      evidence: details, status: :research_observation, certification_eligible: false}}
  end

  def learn(_, _), do: {:error, :no_learnable_counterexample}

  def validate_constraint(constraint, validator) when is_function(validator, 1) do
    case validator.(constraint) do
      {:supported, evidence} -> {:ok, %{constraint: constraint, status: :supported, evidence: evidence}}
      {:rejected, evidence} -> {:ok, %{constraint: constraint, status: :rejected, evidence: evidence}}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_constraint_validator_result}
    end
  end

  defp candidate_id(%{expression: expression}), do: :erlang.phash2(expression)
  defp candidate_id(_), do: :unknown
end
