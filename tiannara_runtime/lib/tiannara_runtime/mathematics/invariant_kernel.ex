defmodule TiannaraRuntime.Mathematics.InvariantKernel do
  @moduledoc """
  Represents conserved/invariant quantities with explicit proof evidence.

  An invariant observed in simulation is not automatically a mathematical
  invariant and never becomes a physical conservation law without domain
  validation.
  """

  def candidate(expression, dynamics) do
    {:ok, %{expression: expression, dynamics: dynamics,
            invariant_status: :candidate, evidence_class: :symbolic,
            certification_eligible: false}}
  end

  def verify(candidate, evidence) when is_map(candidate) and is_map(evidence) do
    if Map.get(evidence, :derivative_along_flow) == :zero_proved do
      {:ok, Map.merge(candidate, %{
        invariant_status: :mathematically_proved,
        evidence_class: :mathematical_proof,
        evidence: evidence,
        certification_eligible: false
      })}
    else
      {:ok, Map.merge(candidate, %{
        invariant_status: :unproved,
        evidence: evidence,
        certification_eligible: false
      })}
    end
  end

  def verify(_, _), do: {:error, :invariant_evidence_required}
end
