defmodule TiannaraRuntime.Mathematics.ConvergenceEvidence do
  @moduledoc """
  Compares numerical solutions across resolutions.

  This measures empirical convergence behavior. It never upgrades that
  observation into a proof of convergence without an independent theorem or
  verified mathematical backend.
  """

  def compare(coarse, fine) when is_number(coarse) and is_number(fine) do
    {:ok, %{difference: abs(coarse - fine),
            evidence_class: :numerical_convergence_observation,
            convergence_status: :observed_only,
            proof_status: :unproved,
            certification_eligible: false}}
  end

  def compare(_, _), do: {:error, :numeric_solution_required}

  def verify_rate(_samples, _expected_order),
    do: {:error, :convergence_theorem_verifier_required}
end
