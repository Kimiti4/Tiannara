defmodule Tiannara.CEL.Workflow.Steps.Experiment do
  @moduledoc """
  Experiment step — designs and executes experiments to test hypotheses.
  """
  @behaviour Tiannara.CEL.Workflow.Step

  @impl true
  def step_type, do: :experiment

  @impl true
  def required_capability, do: :experiment_execution

  @impl true
  def validate_input(input) do
    cond do
      not Map.has_key?(input, :hypothesis) -> {:error, :missing_hypothesis}
      not Map.has_key?(input, :experiment_design) -> {:error, :missing_design}
      true -> :ok
    end
  end

  @impl true
  def execute(_input, _context) do
    # Truthful: no real experiment step provider is wired in this
    # configuration. Returns explicit unavailability instead of fabricated
    # experimental results.
    {:error, {:unavailable, :real_step_provider_not_wired}}
  end

  @impl true
  def compensate(_input, _result, _context), do: :ok

  @impl true
  def metadata, do: %{description: "Executes experiments to test hypotheses (real executor not wired)"}
end
