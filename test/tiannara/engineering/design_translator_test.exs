defmodule Tiannara.Engineering.DesignTranslatorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Engineering.DesignTranslator
  alias Tiannara.Engineering.Domain.{EngineeringInsight, EngineeringDesign}

  defp test_insight do
    EngineeringInsight.new(%{
      source_discovery_id: "disc_1",
      principle_statement: "Boundary condition divergence explains sensor discrepancy",
      domain: :sensor_fusion,
      confidence: 0.85,
      evidence_count: 5
    })
  end

  describe "translate/1" do
    test "produces 1-3 designs" do
      designs = DesignTranslator.translate(test_insight())
      assert length(designs) >= 1
      assert length(designs) <= 3
    end

    test "every design has a verification plan" do
      designs = DesignTranslator.translate(test_insight())
      assert Enum.all?(designs, &(&1.verification_plan != nil))
    end

    test "every design references the source insight" do
      insight = test_insight()
      designs = DesignTranslator.translate(insight)
      assert Enum.all?(designs, &(&1.insight_id == insight.id))
    end

    test "every design has components" do
      designs = DesignTranslator.translate(test_insight())
      assert Enum.all?(designs, &(length(&1.components) >= 2))
    end

    test "designs have different approaches" do
      designs = DesignTranslator.translate(test_insight())
      approaches = Enum.map(designs, fn d -> hd(d.lineage).approach end)
      assert length(Enum.uniq(approaches)) == length(designs)
    end
  end
end
