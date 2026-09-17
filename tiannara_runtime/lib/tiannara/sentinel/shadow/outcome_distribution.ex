defmodule Tiannara.Sentinel.Shadow.OutcomeDistribution do
  @moduledoc """
  Formats and aggregates the explicitly generated epistemic trajectories.
  """

  def aggregate(trajectories) do
    # For structured epistemic trajectories, we mostly just pass them through
    # or group them if needed. For C.1A++, we keep them structured so they are explainable.
    Enum.map(trajectories, fn traj ->
      %{
        scenario: traj.type,
        projected_entropy: traj.entropy_delta,
        projected_novelty: traj.novelty_delta,
        fitness_score: traj.fitness.total
      }
    end)
  end
end
