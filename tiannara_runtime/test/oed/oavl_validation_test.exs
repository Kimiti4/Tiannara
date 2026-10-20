defmodule Tiannara.OED.OAVL.ValidationTest do
  use ExUnit.Case, async: false

  alias Tiannara.OED.OAVL.{
    OntologyValidator,
    SubstrateIndependence,
    HiddenAssumptionDetector,
    CausalConsistency,
    SemanticDriftAnalyzer,
    EpistemicCost,
    GlobalizationGate
  }

  setup do
    start_supervised!(Tiannara.OED.OAVL.OntologyValidator)
    start_supervised!(Tiannara.OED.OAVL.HiddenAssumptionDetector)
    start_supervised!(Tiannara.OED.OAVL.EpistemicCost)
    start_supervised!(Tiannara.OED.OAVL.SemanticDriftAnalyzer)
    :ok
  end

  describe "OntologyValidator" do
    test "passes flat AST and catches infinite regress" do
      flat_rule = %{
        type: :diffusion_policy,
        body: {:diffuse, :pressure_field, 0.05, {:cap, 1.0}}
      }

      assert {:ok, :valid} == OntologyValidator.validate(flat_rule)

      deep_rule = %{
        type: :diffusion_policy,
        body: {:if, true, {:if, true, {:if, true, {:if, true, {:if, true, {:if, true, :ignore}}}}}}
      }

      assert {:error, reason} = OntologyValidator.validate(deep_rule)
      assert reason =~ "infinite regress"
    end
  end

  describe "SubstrateIndependence" do
    test "rejects command execution leaks" do
      leaky_rule = %{
        type: :compression_policy,
        body: {:apply, :system_cmd, ["rm -rf"]}
      }

      assert {:error, reason} = SubstrateIndependence.verify(leaky_rule)
      assert reason =~ "Substrate leak"
    end
  end

  describe "HiddenAssumptionDetector" do
    test "rejects constant division by zero" do
      bad_rule = %{
        type: :compression_policy,
        body: {:div, :entropy_level, 0}
      }

      assert {:error, reason} = HiddenAssumptionDetector.detect(bad_rule)
      assert reason =~ "division by constant zero"
    end
  end

  describe "EpistemicCost and SemanticDrift" do
    test "calculates cost matrices and recursive drift index" do
      rule = %{
        type: :compression_policy,
        body: {:if, true, :ignore, :ignore}
      }

      assert {:ok, metrics} = EpistemicCost.calculate_cost(rule)
      assert metrics.proof_complexity > 0
      assert metrics.interpretability > 0.0

      assert {:ok, drift} = SemanticDriftAnalyzer.analyze_drift(rule)
      assert drift == 0.05
    end
  end
end
