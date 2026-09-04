defmodule Tiannara.CEL.Workflow.Steps.Observation do
  @moduledoc """
  Observation step — the first stage of the scientific method.
  Gathers raw data from observatories, sensors, or existing knowledge.
  """
  @behaviour Tiannara.CEL.Workflow.Step

  @impl true
  def step_type, do: :observation

  @impl true
  def required_capability, do: :observation_gathering

  @impl true
  def validate_input(input) do
    cond do
      not Map.has_key?(input, :target) -> {:error, :missing_target}
      not Map.has_key?(input, :observation_type) -> {:error, :missing_observation_type}
      true -> :ok
    end
  end

  @impl true
  def execute(_input, _context) do
    # Truthful: no real observation provider is wired in this configuration.
    # Returns explicit unavailability instead of fabricated raw data.
    {:error, {:unavailable, :real_step_provider_not_wired}}
  end

  @impl true
  def compensate(_input, _result, _context), do: :ok

  @impl true
  def metadata, do: %{description: "Gathers raw observational data (real provider not wired)"}
end
