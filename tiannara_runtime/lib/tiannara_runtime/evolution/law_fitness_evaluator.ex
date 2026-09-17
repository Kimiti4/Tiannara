defmodule Tiannara.Meta.Evolution.LawFitnessEvaluator do
  @moduledoc """
  LawFitnessEvaluator - Evaluates fitness and survivability of compiled laws.
  """

  def evaluate(metrics) do
    coherence = Map.get(metrics, :causal_coherence, 0.0)
    efficiency = Map.get(metrics, :energy_efficiency, 0.0)
    survivability = Map.get(metrics, :observer_survivability, 0.0)

    # Simple logic: survives if all are above 0.5
    survives = coherence > 0.5 and efficiency > 0.5 and survivability > 0.5

    %{
      survives?: survives,
      score: (coherence + efficiency + survivability) / 3.0
    }
  end
end
