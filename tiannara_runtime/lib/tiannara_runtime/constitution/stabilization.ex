defmodule Tiannara.Constitution.Stabilization do
  @moduledoc """
  Constitutional Invariant: Stabilization Budget
  
  ∑ ||I_i|| ≤ B_{max}
  
  Ensures that the sum total of interventions or stability pressure applied 
  to the system does not exceed the maximum allowed runtime budget. 
  Prevents overregulation and stabilization death spirals.
  """

  @doc """
  Validates if a proposed intervention sum exceeds the absolute maximum budget.
  
  Returns `:ok` or `{:error, reason}`.
  """
  def validate(current_interventions, proposed_intervention_cost, max_budget) do
    if current_interventions + proposed_intervention_cost > max_budget do
      {:error, :stabilization_violation_budget_exceeded}
    else
      :ok
    end
  end
end
