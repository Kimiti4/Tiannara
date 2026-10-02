defmodule Tiannara.Sentinel.MathematicalEvidence do
  @moduledoc """
  Structured evidence record for mathematical research.

  Sentinel stores the evidence artifact and provenance; it does not promote an
  artifact to a theorem merely because it was submitted.
  """

  @type t :: %{
          id: String.t(),
          kind: atom(),
          status: atom(),
          artifact: map(),
          provenance: map(),
          stored_at: DateTime.t()
        }

  @spec build(atom(), map(), map()) :: {:ok, t()} | {:error, term()}
  def build(kind, artifact, provenance)
      when is_atom(kind) and is_map(artifact) and is_map(provenance) do
    with :ok <- validate(kind, artifact, provenance) do
      {:ok, %{
        id: "math-evidence-#{System.unique_integer([:positive])}",
        kind: kind,
        status: status(kind, artifact),
        artifact: artifact,
        provenance: provenance,
        stored_at: DateTime.utc_now()
      }}
    end
  end

  def build(_, _, _), do: {:error, :invalid_mathematical_evidence}

  defp validate(:proof_checked, artifact, provenance) do
    with :ok <- required(artifact, [:status, :assumptions, :conclusion, :checked_steps, :kernel]),
         true <- artifact.status == :proven_under_assumptions,
         true <- is_binary(artifact.kernel),
         true <- Map.has_key?(provenance, :proof_steps) do
      :ok
    else
      false -> {:error, :invalid_proof_evidence}
      {:error, _} = error -> error
    end
  end

  defp validate(:counterexample_found, artifact, provenance) do
    with :ok <- required(artifact, [:status, :witness, :tested_cases, :domain]),
         true <- artifact.status == :counterexample_found,
         true <- Map.has_key?(provenance, :search_definition) do
      :ok
    else
      false -> {:error, :invalid_counterexample_evidence}
      {:error, _} = error -> error
    end
  end

  defp validate(:bounded_non_falsification, artifact, provenance) do
    with :ok <- required(artifact, [:status, :tested_cases, :domain, :search_complete]),
         true <- artifact.status == :no_counterexample_in_domain,
         true <- artifact.search_complete == true,
         true <- Map.has_key?(provenance, :search_definition) do
      :ok
    else
      false -> {:error, :invalid_bounded_search_evidence}
      {:error, _} = error -> error
    end
  end

  defp validate(:test_result, artifact, provenance) do
    with :ok <- required(artifact, [:test_id, :status, :result]),
         true <- Map.has_key?(provenance, :execution_id) do
      :ok
    else
      false -> {:error, :execution_provenance_required}
      {:error, _} = error -> error
    end
  end

  defp validate(_, _, _), do: {:error, :unsupported_mathematical_evidence}

  defp required(map, keys) do
    case Enum.find(keys, &(not Map.has_key?(map, &1))) do
      nil -> :ok
      key -> {:error, {:missing_field, key}}
    end
  end

  defp status(:proof_checked, _), do: :proven_under_assumptions
  defp status(:counterexample_found, _), do: :refuted_in_tested_domain
  defp status(:bounded_non_falsification, _), do: :survived_tested_domain
  defp status(:test_result, artifact), do: Map.get(artifact, :status, :observed)
end
