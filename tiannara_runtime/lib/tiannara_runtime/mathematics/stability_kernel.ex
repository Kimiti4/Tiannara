defmodule TiannaraRuntime.Mathematics.StabilityKernel do
  @moduledoc """
  Conservative stability-analysis substrate.

  It records equilibria and verified local stability results. Numerical
  trajectories and sampled behavior remain observations, not proofs of
  stability.
  """

  def equilibrium(state, derivative) do
    {:ok, %{state: state, derivative: derivative, status: :candidate_equilibrium,
            evidence_class: :symbolic, certification_eligible: false}}
  end

  def verify_local_linearization(%{jacobian: jacobian, evidence: %{status: :proved}} = claim) do
    {:ok, %{claim: claim, stability_status: :requires_eigenvalue_analysis,
            evidence_class: :symbolic, certification_eligible: false}}
  end

  def verify_local_linearization(%{evidence: _}),
    do: {:error, :verified_jacobian_evidence_required}

  def classify_observed_trajectory(trajectory) when is_list(trajectory) do
    {:ok, %{trajectory: trajectory, stability_status: :observed_behavior,
            evidence_class: :observation, certification_eligible: false}}
  end

  def classify_observed_trajectory(_), do: {:error, :trajectory_required}
end
