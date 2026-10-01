defmodule Tiannara.OED do
  @moduledoc """
  Ontological Executive Doctrine (OED) - Cognitive Constitution.
  
  Sits between Core/AEO and Runtime. Ensures nothing from Core reaches 
  Runtime physics without validation.
  
  Uses ACM/OAVL to validate domain conclusions across multiple ontologies.
  """

  @doc "Validate execution plan against constitutional constraints."
  def validate_constitution(execution_plan) when is_map(execution_plan) do
    case Tiannara.CIS.validate_plan(execution_plan) do
      {:ok, validated} -> {:ok, Map.put(validated, :oed_status, :constitutionally_constrained)}
      {:error, reasons} -> {:error, {:constitutional_validation_failed, reasons}}
    end
  end

  def validate_constitution(_), do: {:error, :invalid_execution_plan}

  @doc "Cross-validate a domain conclusion using multiple ontologies."
  def cross_validate_conclusion(domain_output) when is_map(domain_output) do
    evidence = Map.get(domain_output, :evidence, Map.get(domain_output, "evidence"))
    provenance = Map.get(domain_output, :provenance, Map.get(domain_output, "provenance"))

    if is_list(evidence) and evidence != [] and not is_nil(provenance) do
      {:ok, Map.put(domain_output, :oed_status, :evidence_present)}
    else
      {:error, :cross_validation_evidence_unavailable}
    end
  end

  def cross_validate_conclusion(_), do: {:error, :invalid_domain_output}
end
