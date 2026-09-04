defmodule Tiannara.Twp.WavefunctionSolver do
  @moduledoc """
  Solves the temporal wavefunction state for branch optimization.
  This module determines which branches should be preserved, compressed, archived, or removed.
  """

  @spec solve(map()) :: {:ok, map()} | {:error, term()}
  def solve(branch_state) do
    # Calculate survivability score
    survivability = case function_exported?(Tiannara.Twp.SurvivabilityEstimator, :estimate, 1) do
      true -> Tiannara.Twp.SurvivabilityEstimator.estimate(branch_state)
      false -> 0.5
    end

    # Determine action based on survivability
    action =
      cond do
        survivability >= 0.8 -> :preserve
        survivability >= 0.5 -> :continue
        survivability >= 0.2 -> :compress
        true -> :archive
      end

    {:ok, %{action: action, survivability: survivability}}
  end

  @spec estimate_persistence(map()) :: float()
  def estimate_persistence(branch_state) do
    # Persistence metric: Pt ∝ O × E
    # O = observer density
    # E = energetic consistency
    observer_density = Map.get(branch_state, :observer_density, 0)
    energetic_consistency = Map.get(branch_state, :energetic_consistency, 0)

    observer_density * energetic_consistency
  end
end