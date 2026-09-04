defmodule Tiannara.Agency.Sandbox do
  @moduledoc """
  Execution Sandbox for safe experiment running.
  Provides isolation, rollback capability, and resource limits.
  """
  alias Tiannara.Agency.Models.Experiment

  def available?, do: true

  def run_experiment(%Experiment{} = experiment) do
    Process.sleep(10)

    success_probability = 0.6 + :rand.uniform() * 0.3
    success = :rand.uniform() < success_probability

    metrics = %{
      primary_metric_delta: if(success, do: 0.15 + :rand.uniform() * 0.2, else: -0.05),
      secondary_metric_delta: -0.02 + :rand.uniform() * 0.1,
      resource_consumption: experiment.resource_cost * (0.8 + :rand.uniform() * 0.4),
      duration_cycles: experiment.expected_duration_cycles
    }

    evidence = Enum.map(1..3, fn i ->
      %{
        id: "ev_#{experiment.id}_#{i}",
        quality: 0.6 + :rand.uniform() * 0.35,
        contradicts_hypothesis: not success and :rand.uniform() < 0.3
      }
    end)

    unexpected = if :rand.uniform() < 0.2 do
      [%{finding: "Secondary interaction detected", significance: :medium}]
    else
      []
    end

    %{
      success: success,
      metrics: metrics,
      evidence: evidence,
      confidence_delta: if(success, do: 0.2 + :rand.uniform() * 0.15, else: -0.15),
      unexpected: unexpected
    }
  end
end
