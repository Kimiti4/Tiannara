defmodule TiannaraRuntime.Mathematics.LyapunovKernel do
  @moduledoc """
  Conservative Lyapunov-certificate substrate.

  A candidate function is never declared a stability certificate merely because
  a simulation appears stable. Positivity and derivative conditions must be
  supplied as verified mathematical evidence.
  """

  def candidate(function, equilibrium) do
    {:ok, %{function: function, equilibrium: equilibrium,
            status: :candidate, certificate_status: :unproved,
            certification_eligible: false}}
  end

  def verify(candidate, evidence) when is_map(candidate) and is_map(evidence) do
    positivity = Map.get(evidence, :positive_definite)
    derivative = Map.get(evidence, :derivative_condition)

    cond do
      positivity == :proved and derivative == :negative_definite ->
        {:ok, Map.merge(candidate, %{
          certificate_status: :local_asymptotic_stability_candidate,
          evidence_class: :mathematical_proof,
          certification_eligible: false,
          evidence: evidence
        })}
      positivity == :proved and derivative == :nonpositive ->
        {:ok, Map.merge(candidate, %{
          certificate_status: :local_stability_candidate,
          evidence_class: :mathematical_proof,
          certification_eligible: false,
          evidence: evidence
        })}
      true ->
        {:ok, Map.merge(candidate, %{
          certificate_status: :unproved,
          evidence: evidence,
          certification_eligible: false
        })}
    end
  end

  def verify(_, _), do: {:error, :lyapunov_evidence_required}
end
