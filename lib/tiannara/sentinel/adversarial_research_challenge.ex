defmodule Tiannara.Sentinel.AdversarialResearchChallenge do
  @moduledoc """
  Evidence-producing adversarial challenge orchestration.

  A challenger is an injected, real domain-specific function. This module never
  fabricates counterexamples or treats an unsearched space as universally safe.
  """

  @type challenger :: (map(), map(), map() -> {:ok, map()} | {:error, term()})

  @spec run(map(), map(), map(), challenger() | nil) :: {:ok, map()} | {:error, term()}
  def run(simulation, validation, replication, challenger)
      when is_map(simulation) and is_map(validation) and is_map(replication) do
    with :ok <- require_challenger(challenger),
         {:ok, result} <- invoke(challenger, simulation, validation, replication),
         :ok <- validate_result(result) do
      {:ok,
       Map.merge(result, %{
         challenge_type: :adversarial,
         certification_eligible: false,
         epistemic_boundary: :tested_domain_only
       })}
    end
  end

  def run(_, _, _, _), do: {:error, :invalid_adversarial_challenge_input}

  defp require_challenger(fun) when is_function(fun, 3), do: :ok
  defp require_challenger(_), do: {:error, :adversarial_challenger_unavailable}

  defp invoke(fun, simulation, validation, replication) do
    case fun.(simulation, validation, replication) do
      {:ok, result} when is_map(result) -> {:ok, result}
      {:error, reason} -> {:error, {:challenge_execution_failed, reason}}
      other -> {:error, {:invalid_challenge_result, other}}
    end
  rescue
    exception -> {:error, {:challenge_execution_crashed, exception}}
  end

  defp validate_result(result) do
    with true <- Map.get(result, :status) in [:survived, :counterexample_found, :inconclusive],
         true <- is_list(Map.get(result, :tests, [])),
         true <- is_list(Map.get(result, :counterevidence, [])),
         true <- is_map(Map.get(result, :search_scope, %{})) do
      :ok
    else
      _ -> {:error, :invalid_adversarial_evidence}
    end
  end
end
