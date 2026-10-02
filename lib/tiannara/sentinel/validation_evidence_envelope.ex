defmodule Tiannara.Sentinel.ValidationEvidenceEnvelope do
  @moduledoc """
  Canonical envelope passed between evidence-producing systems and ACL/OAVL.

  It prevents validators from receiving an untraceable bare conclusion.
  """

  @required [:evidence_id, :theory_id, :outcome, :observations, :counterevidence,
             :assumptions, :provenance, :execution_mode, :evidence_class]

  @spec build(map()) :: {:ok, map()} | {:error, term()}
  def build(evidence) when is_map(evidence) do
    with :ok <- required_fields(evidence),
         :ok <- validate_mode(evidence),
         :ok <- validate_outcome(evidence) do
      {:ok, Map.put(evidence, :certification_eligible, false)}
    end
  end

  def build(_), do: {:error, :invalid_validation_evidence}

  defp required_fields(e) do
    case Enum.find(@required, &(not Map.has_key?(e, &1))) do
      nil -> :ok
      key -> {:error, {:missing_evidence_field, key}}
    end
  end

  defp validate_mode(e) do
    if e.execution_mode in [:simulation, :real_execution] and
       e.evidence_class in [:simulated, :real],
      do: :ok,
      else: {:error, :invalid_evidence_mode}
  end

  defp validate_outcome(e) do
    if e.outcome in [:supported, :refuted, :inconclusive, :mixed],
      do: :ok,
      else: {:error, :invalid_evidence_outcome}
  end
end
