defmodule Tiannara.Omega.HumanDelivery.ExplanationTest do
  use ExUnit.Case
  alias Tiannara.Omega.HumanDelivery.Explanation

  test "builds and renders explanation" do
    package = %{
      explanation_id: :expl_123,
      detected: "system overload",
      investigated: "memory usage",
      hypotheses: ["memory leak", "concurrent load"],
      selected_experiment: %{id: :exp_memleak},
      generated_candidate: %{id: :cand_456},
      sandbox_result: %{status: :pass},
      certification_confidence: 0.93,
      uncertainty: %{source: "incomplete data"},
      evidence: ["log: high memory", "trace: GC pressure"],
      lineage: [:decision_abc, :analysis_xyz]
    }

    explanation = Explanation.build(package)
    narrative = Explanation.render_narrative(explanation)

    assert String.contains?(narrative, "system overload")
    assert String.contains?(narrative, "hypotheses")
    assert String.contains?(narrative, "memory leak")
    assert String.contains?(narrative, "concurrent load")
    assert String.contains?(narrative, "exp_memleak")
    assert String.contains?(narrative, "cand_456")
    assert String.contains?(narrative, "passed sandbox")
    assert String.contains?(narrative, "Certification confidence is 0.93")
    assert String.contains?(narrative, "Uncertainty")
    assert String.contains?(narrative, "Lineage trace")
    assert String.contains?(narrative, "deployment requires human authorization")
  end
end
