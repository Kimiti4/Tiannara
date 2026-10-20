defmodule Tiannara.Meta.Evolution.LawFitnessEvaluatorTest do
  use ExUnit.Case

  alias Tiannara.Meta.Evolution.LawFitnessEvaluator

  test "evaluates stable laws" do
    result =
      LawFitnessEvaluator.evaluate(%{
        causal_coherence: 0.9,
        energy_efficiency: 0.8,
        observer_survivability: 0.95
      })

    assert result.survives? == true
  end
end
