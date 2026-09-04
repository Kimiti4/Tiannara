defmodule Tiannara.CEL.Workflow.Steps.Hypothesis do
  @moduledoc """
  Hypothesis step — generates testable hypotheses from observations.
  """
  @behaviour Tiannara.CEL.Workflow.Step

  @impl true
  def step_type, do: :hypothesis

  @impl true
  def required_capability, do: :hypothesis_generation

  @impl true
  def validate_input(input) do
    if Map.has_key?(input, :observations), do: :ok, else: {:error, :missing_observations}
  end

  @impl true
  def execute(input, _context) do
    start_time = System.monotonic_time(:millisecond)

    hypotheses = generate_hypotheses(input.observations)
    duration = System.monotonic_time(:millisecond) - start_time

    {:ok, %{
      hypotheses: hypotheses,
      evidence: [%{type: :hypothesis_generation, count: length(hypotheses)}],
      confidence: 0.7,
      quality_metrics: %{hypothesis_count: length(hypotheses), testability_score: 0.8},
      resource_usage: %{compute: 50, memory: 100},
      duration_ms: duration
    }}
  end

  @impl true
  def compensate(_input, _result, _context), do: :ok

  @impl true
  def metadata, do: %{description: "Generates testable hypotheses from observations"}

  defp generate_hypotheses(_observations) do
    Enum.map(1..3, fn i ->
      %{
        id: "hyp_#{i}",
        statement: "Hypothesis #{i} based on observations",
        testable: true,
        prior_confidence: 0.5
      }
    end)
  end
end
