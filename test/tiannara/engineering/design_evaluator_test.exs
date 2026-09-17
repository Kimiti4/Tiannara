defmodule Tiannara.Engineering.DesignEvaluatorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Engineering.{DesignTranslator, DesignEvaluator, VerificationPlanner}
  alias Tiannara.Engineering.Domain.{EngineeringInsight, EngineeringDesign}

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

  describe "evaluate/1" do
    test "produces a valid evaluation" do
      design = test_design()
      eval = DesignEvaluator.evaluate(design)

      assert eval.design_id == design.id
      assert eval.composite_score >= 0.0
      assert eval.composite_score <= 1.0
      assert eval.feasibility >= 0.0
      assert eval.safety >= 0.0
    end

    test "identifies weakest dimension" do
      design = test_design()
      eval = DesignEvaluator.evaluate(design)

      {dim, val} = eval.weakest_dimension
      assert dim in DesignEvaluator.dimensions()
      assert val >= 0.0
    end
  end

  describe "approval_decision/1" do
    test "returns :approve for high-quality designs" do
      design = %{test_design() | feasibility: 0.9, safety_score: 0.9}
      assert DesignEvaluator.approval_decision(design) == :approve
    end

    test "returns :reject for unsafe designs" do
      design = %{test_design() | safety_score: 0.2}
      assert DesignEvaluator.approval_decision(design) == :reject
    end
  end

  describe "rank/1" do
    test "sorts by composite score descending" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_1",
        principle_statement: "Test",
        domain: :test,
        confidence: 0.9,
        evidence_count: 5
      })
      designs = DesignTranslator.translate(insight)
      ranked = DesignEvaluator.rank(designs)

      scores = Enum.map(ranked, fn {_d, eval} -> eval.composite_score end)
      assert scores == Enum.sort(scores, :desc)
    end
  end
end
