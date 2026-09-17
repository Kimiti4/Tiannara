defmodule Tiannara.ASC.Civilization.PropertyTest do
  use ExUnit.Case, async: true

  setup do
    for mod <- [
      Tiannara.ASC.Civilization.SustainabilityEngine,
      Tiannara.ASC.Civilization.GlobalRiskEngine,
      Tiannara.ASC.Civilization.IntergenerationalEquityEngine
    ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    :ok
  end

  describe "Sustainability invariants" do
    test "sustainability score is always in [0.0, 1.0] for various inputs" do
      Enum.each([0.0, 0.3, 0.5, 0.7, 1.0], fn ecology ->
        Enum.each([0.0, 0.3, 0.5, 0.7, 1.0], fn energy ->
          world_state = %{ecology: ecology, energy: energy, sustainability_index: (ecology + energy) / 2}
          {:ok, result} = Tiannara.ASC.Civilization.SustainabilityEngine.evaluate(world_state)
          assert result.score >= 0.0 and result.score <= 1.0
        end)
      end)
    end
  end

  describe "Risk invariants" do
    test "overall risk is always in [0.0, 1.0]" do
      Enum.each([0.0, 0.3, 0.5, 0.7, 1.0], fn medicine ->
        Enum.each([0.0, 0.3, 0.5, 0.7, 1.0], fn ecology ->
          world_state = %{medicine: medicine, ecology: ecology, economics: 0.5, governance: 0.5, technology: 0.6}
          {:ok, risk} = Tiannara.ASC.Civilization.GlobalRiskEngine.assess(world_state)
          assert risk.overall_risk >= 0.0 and risk.overall_risk <= 1.0
        end)
      end)
    end
  end

  describe "Intergenerational equity invariants" do
    test "equity score is always in [0.0, 1.0]" do
      Enum.each([0.0, 0.3, 0.5, 0.7, 1.0], fn ecology ->
        Enum.each([0.0, 0.3, 0.5, 0.7, 1.0], fn energy ->
          world_state = %{ecology: ecology, energy: energy, sustainability_index: 0.5, knowledge_retention: 0.6, governance: 0.5}
          {:ok, result} = Tiannara.ASC.Civilization.IntergenerationalEquityEngine.evaluate(world_state)
          assert result.score >= 0.0 and result.score <= 1.0
        end)
      end)
    end
  end
end
