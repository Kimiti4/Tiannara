defmodule Tiannara.Simulation.ScenarioBuilderTest do
  use ExUnit.Case, async: true

  alias Tiannara.Simulation.ScenarioBuilder
  alias Tiannara.Simulation.Domain.SimulationScenario
  alias Tiannara.Engineering.Domain.{EngineeringInsight, EngineeringDesign}
  alias Tiannara.Engineering.DesignTranslator

  defp test_design do
    insight = EngineeringInsight.new(%{
      source_discovery_id: "disc_1",
      principle_statement: "Test principle",
      domain: :test_domain,
      confidence: 0.8,
      evidence_count: 3
    })
    [design | _] = DesignTranslator.translate(insight)
    design
  end

  describe "build/1" do
    test "produces a valid scenario" do
      design = test_design()
      scenario = ScenarioBuilder.build(design)

      assert is_struct(scenario, SimulationScenario)
      assert scenario.design_id == design.id
      assert scenario.horizons == [10, 50, 100]
      assert length(scenario.injected_changes) >= 1
    end

    test "scenario passes validation" do
      design = test_design()
      scenario = ScenarioBuilder.build(design)
      assert ScenarioBuilder.validate(scenario) == :ok
    end
  end

  describe "build_variants/2" do
    test "produces base + N variants" do
      design = test_design()
      variants = ScenarioBuilder.build_variants(design, 3)
      assert length(variants) == 4
    end
  end

  describe "validate/1" do
    test "rejects scenario with no design_id" do
      scenario = SimulationScenario.new(%{injected_changes: [%{type: :test}]})
      assert {:error, :missing_design_id} = ScenarioBuilder.validate(scenario)
    end

    test "rejects scenario with no injected changes" do
      scenario = SimulationScenario.new(%{design_id: "d1", injected_changes: []})
      assert {:error, :no_injected_changes} = ScenarioBuilder.validate(scenario)
    end
  end
end
