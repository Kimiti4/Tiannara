defmodule TiannaraRuntime.Mathematics.DifferentialEquationKernel do
  @moduledoc """
  Explicit ODE problem representation with solver/evidence separation.

  Defining an equation is not solving it. A numerical trajectory is not a
  proof of correctness, uniqueness, stability, or correspondence to reality.
  """

  def define(derivatives, initial_conditions, domain, parameters \ []) 
      when is_list(derivatives) and is_map(initial_conditions) do
    {:ok, %{
      equation: derivatives,
      initial_conditions: initial_conditions,
      domain: domain,
      parameters: parameters,
      status: :defined,
      solution_status: :unsolved,
      reality_status: :unvalidated,
      certification_eligible: false
    }}
  end

  def attach_solution(problem, solution, evidence_class \ :numerical_approximation) do
    {:ok, Map.merge(problem, %{
      solution: solution,
      solution_status: :candidate_solution,
      solution_evidence_class: evidence_class,
      certification_eligible: false
    })}
  end

  def certify_solution(_problem, _solution, _evidence),
    do: {:error, :independent_solution_verifier_required}
end
