defmodule Tiannara.ASC.Civilization.PolicySimulationTest do
  use ExUnit.Case, async: false

  setup do
    for mod <- [
      Tiannara.ASC.Civilization.PolicySimulationEngine,
      Tiannara.ASC.Civilization.WorldModel,
      Tiannara.ASC.Civilization.GlobalRiskEngine
    ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    :ok
  end

  test "simulates policies across all domains" do
    world_state = Tiannara.ASC.Civilization.WorldModel.current_state()
    {:ok, risk} = Tiannara.ASC.Civilization.GlobalRiskEngine.assess(world_state)
    {:ok, results} = Tiannara.ASC.Civilization.PolicySimulationEngine.simulate(world_state, risk)

    assert Map.has_key?(results, :government)
    assert Map.has_key?(results, :economics)
    assert Map.has_key?(results, :infrastructure)
    assert Map.has_key?(results, :healthcare)
    assert Map.has_key?(results, :risk_adjusted)
  end

  test "risk adjustment reduces projections" do
    world_state = Tiannara.ASC.Civilization.WorldModel.current_state()
    {:ok, risk} = Tiannara.ASC.Civilization.GlobalRiskEngine.assess(world_state)
    {:ok, results} = Tiannara.ASC.Civilization.PolicySimulationEngine.simulate(world_state, risk)

    assert results.risk_adjusted.adjustment_factor <= 1.0
    assert results.risk_adjusted.adjustment_factor > 0.0
  end
end
