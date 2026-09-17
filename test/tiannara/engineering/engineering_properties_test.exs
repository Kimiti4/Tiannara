defmodule Tiannara.Engineering.EngineeringPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Engineering.{DesignTranslator, DesignEvaluator, VerificationPlanner}
  alias Tiannara.Engineering.Domain.EngineeringInsight

  describe "DesignTranslator invariants" do
    property "always produces 1-3 designs for any valid insight" do
      check all confidence <- float(min: 0.1, max: 1.0),
                domain <- member_of([:physics, :biology, :computing, :materials, :unknown]) do
        insight = EngineeringInsight.new(%{
          source_discovery_id: "disc_prop",
          principle_statement: "Property test principle",
          domain: domain,
          confidence: confidence,
          evidence_count: 3
        })

        designs = DesignTranslator.translate(insight)
        assert length(designs) >= 1
        assert length(designs) <= 3
      end
    end

    property "every design has a complete verification plan" do
      check all confidence <- float(min: 0.1, max: 1.0) do
        insight = EngineeringInsight.new(%{
          source_discovery_id: "disc_prop",
          principle_statement: "Verification test",
          domain: :test,
          confidence: confidence,
          evidence_count: 2
        })

        designs = DesignTranslator.translate(insight)

        Enum.each(designs, fn design ->
          assert design.verification_plan != nil
          assert VerificationPlanner.validate_completeness(design.verification_plan) == :ok
        end)
      end
    end
  end

  describe "DesignEvaluator invariants" do
    property "composite score is always in [0.0, 1.0]" do
      check all confidence <- float(min: 0.1, max: 1.0),
                safety <- float(min: 0.0, max: 1.0) do
        insight = EngineeringInsight.new(%{
          source_discovery_id: "disc_prop",
          principle_statement: "Score bounds test",
          domain: :test,
          confidence: confidence,
          evidence_count: 3
        })

        designs = DesignTranslator.translate(insight)

        Enum.each(designs, fn design ->
          design = %{design | safety_score: safety}
          eval = DesignEvaluator.evaluate(design)
          assert eval.composite_score >= 0.0
          assert eval.composite_score <= 1.0
        end)
      end
    end

    property "approval_decision is always a valid atom" do
      check all confidence <- float(min: 0.1, max: 1.0) do
        insight = EngineeringInsight.new(%{
          source_discovery_id: "disc_prop",
          principle_statement: "Decision test",
          domain: :test,
          confidence: confidence,
          evidence_count: 3
        })

        designs = DesignTranslator.translate(insight)

        Enum.each(designs, fn design ->
          decision = DesignEvaluator.approval_decision(design)
          assert decision in [:approve, :revise, :reject]
        end)
      end
    end
  end
end
