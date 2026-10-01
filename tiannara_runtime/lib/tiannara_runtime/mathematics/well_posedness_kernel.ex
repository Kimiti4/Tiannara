defmodule TiannaraRuntime.Mathematics.WellPosednessKernel do
  @moduledoc """
  Conservative representation of existence/uniqueness evidence for ODEs.

  The kernel never infers well-posedness from a successful numerical run.
  """

  def define(problem) when is_map(problem) do
    {:ok, Map.merge(problem, %{
      existence_status: :unproved,
      uniqueness_status: :unproved,
      well_posed_status: :unproved,
      certification_eligible: false
    })}
  end

  def verify(problem, evidence) when is_map(problem) and is_map(evidence) do
    existence = Map.get(evidence, :existence)
    uniqueness = Map.get(evidence, :uniqueness)

    status =
      cond do
        existence == :proved and uniqueness == :proved -> :locally_well_posed_candidate
        existence == :proved -> :existence_established
        true -> :unproved
      end

    {:ok, Map.merge(problem, %{
      existence_status: existence || :unproved,
      uniqueness_status: uniqueness || :unproved,
      well_posed_status: status,
      evidence: evidence,
      certification_eligible: false
    })}
  end

  def verify(_, _), do: {:error, :well_posedness_evidence_required}
end
