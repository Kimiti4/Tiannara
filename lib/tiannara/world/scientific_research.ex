defmodule Tiannara.World.ScientificResearch do
  @moduledoc """
  Canonical world-level scientific method.

  It never upgrades a hypothesis to a discovery merely because a simulation ran.
  Every stage has an explicit epistemic status. Mathematical operations are
  supplied by registered domain modules; unavailable solvers remain unavailable.
  """

  alias Tiannara.Discovery.Validation.EvidenceAuditor
  alias Tiannara.Math.Probability

  @spec investigate(module(), map(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def investigate(domain, hypothesis, context \\ %{}, opts \\ []) when is_atom(domain) and is_map(hypothesis) do
    replications = Keyword.get(opts, :replications, 3)

    with :ok <- require_domain(domain),
         {:ok, mathematical_check} <- mathematical_consistency(hypothesis),
         {:ok, first} <- simulate(domain, hypothesis, context),
         {:ok, validation} <- validate(domain, first),
         {:ok, replicas} <- replicate(domain, hypothesis, context, replications),
         defense <- defend(first, replicas, validation) do
      {:ok, %{
        status: final_status(validation, defense),
        hypothesis: hypothesis,
        mathematical_check: mathematical_check,
        simulation: first,
        validation: validation,
        replication: replicas,
        defense: defense,
        provenance: %{
          domain: domain,
          repetitions: replications,
          deterministic_replication: replicas.deterministic,
          generated_at: DateTime.utc_now()
        }
      }}
    end
  end

  defp require_domain(domain) do
    if function_exported?(domain, :simulate, 2) and function_exported?(domain, :validate, 1),
      do: :ok,
      else: {:error, :domain_execution_unavailable}
  end

  defp mathematical_consistency(%{prior: p, likelihood: l, evidence_probability: e})
       when is_number(p) and is_number(l) and is_number(e) do
    case Probability.bayes_update(p, l, e) do
      {:ok, posterior} -> {:ok, %{method: :bayes_update, posterior: posterior}}
      error -> error
    end
  end

  defp mathematical_consistency(_), do: {:ok, %{status: :no_registered_math_premises}}

  defp simulate(domain, hypothesis, context) do
    case domain.simulate(hypothesis, context) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, {:simulation_unavailable, reason}}
      other -> {:error, {:invalid_simulation_result, other}}
    end
  end

  defp validate(domain, result) do
    case domain.validate(%{model: result}) do
      {:ok, verification} -> {:ok, verification}
      {:error, reason} -> {:error, {:verification_unavailable, reason}}
      other -> {:error, {:invalid_validation_result, other}}
    end
  end

  defp replicate(domain, hypothesis, context, count) do
    runs =
      Enum.reduce_while(1..max(count, 1), {:ok, []}, fn _, {:ok, acc} ->
        case simulate(domain, hypothesis, context) do
          {:ok, result} -> {:cont, {:ok, [result | acc]}}
          error -> {:halt, error}
        end
      end)

    case runs do
      {:ok, results} ->
        hashes = Enum.map(results, fn result -> :crypto.hash(:sha256, :erlang.term_to_binary(result)) end)
        {:ok, %{
          count: length(results),
          deterministic: length(Enum.uniq(hashes)) == 1,
          result_hashes: Enum.map(hashes, &Base.encode16(&1, case: :lower))
        }}
      error -> error
    end
  end

  defp defend(simulation, replication, validation) do
    %{
      replication_consistent: replication.deterministic,
      structural_validation: Map.get(validation, :valid, false),
      evidence_audit: EvidenceAuditor.audit_chain([
        %{id: "simulation", parent_evidence_id: nil, timestamp: DateTime.utc_now()}
      ]),
      adversarial_challenge: :not_implemented,
      proof_status: if(Map.get(validation, :verification_method) in [:formal_proof, :formal_verification],
        do: :bounded_proof,
        else: :bounded_structural_verification)
    }
  end

  defp final_status(validation, defense) do
    cond do
      defense.replication_consistent and Map.get(validation, :valid, false) -> :bounded_verified
      defense.replication_consistent -> :replicated_unverified
      true -> :inconclusive
    end
  end
end
