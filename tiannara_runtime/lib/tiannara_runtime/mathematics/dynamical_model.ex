defmodule TiannaraRuntime.Mathematics.DynamicalModel do
  @moduledoc """
  Explicit representation of continuous-time dynamical models.

  This layer defines equations and metadata; it does not claim that the model
  describes reality or that a numerical trajectory is validated.
  """

  def define(state_variables, derivatives, parameters \ []) 
      when is_list(state_variables) and is_list(derivatives) and is_list(parameters) do
    if length(state_variables) == length(derivatives) do
      {:ok, %{
        state_variables: state_variables,
        derivatives: derivatives,
        parameters: parameters,
        model_status: :formal_model,
        reality_status: :unvalidated,
        certification_eligible: false
      }}
    else
      {:error, :state_derivative_dimension_mismatch}
    end
  end

  def trajectory_evidence(model, trajectory, evidence_class \ :simulation) do
    {:ok, %{
      model: model,
      trajectory: trajectory,
      evidence_class: evidence_class,
      reality_status: :unvalidated,
      certification_eligible: false
    }}
  end
end
