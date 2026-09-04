defmodule Tiannara.CEL.Workflow.Steps.Validation do
  @moduledoc """
  Validation step — verifies experimental results through replication and peer review.
  """
  @behaviour Tiannara.CEL.Workflow.Step

  @impl true
  def step_type, do: :validation

  @impl true
  def required_capability, do: :result_validation

  @impl true
  def validate_input(input) do
    if Map.has_key?(input, :experiment_results), do: :ok, else: {:error, :missing_results}
  end

  @impl true
  def execute(_input, _context) do
    # Truthful: no real validation provider is wired in this configuration.
    # Returns explicit unavailability instead of fabricated replication rates.
    {:error, {:unavailable, :real_step_provider_not_wired}}
  end

  @impl true
  def compensate(_input, _result, _context), do: :ok

  @impl true
  def metadata, do: %{description: "Validates experimental results through replication (real provider not wired)"}
end
