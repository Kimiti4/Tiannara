defmodule Tiannara.Research.DirectorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.Director

  setup do
    start_supervised!(Tiannara.Research.Director)
    start_supervised!(TiannaraOS.UnknownRegistry)

    TiannaraOS.UnknownRegistry.register(%{
      id: :un1, question: "What causes the observed entropy anomaly?",
      description: "High-priority unknown in rea_evolution",
      domain_id: :rea_evolution, category: :knowledge_gap, priority: :high
    })

    TiannaraOS.UnknownRegistry.register(%{
      id: :un2, question: "How does DVR impact long-term stability?",
      description: "Validates long-term DVR impacts",
      domain_id: :sopl_governance, category: :untested_hypothesis, priority: :medium
    })

    :ok
  end

  test "director generates proposals with uncertainty reduction and explanation reasons" do
    proposals = Director.generate_proposals()

    assert length(proposals) == 2

    prop1 = Enum.find(proposals, & &1.target_unknown_id == "un1")
    assert prop1.target_unknown_id == "un1"
    assert is_float(prop1.expected_uncertainty_reduction)
    assert prop1.expected_uncertainty_reduction > 0 and prop1.expected_uncertainty_reduction <= 1.0
    assert String.contains?(prop1.reason_explanation, "unknown in rea_evolution")

    prop2 = Enum.find(proposals, & &1.target_unknown_id == "un2")
    assert prop2.target_unknown_id == "un2"
    assert is_float(prop2.expected_uncertainty_reduction)
    assert prop2.expected_uncertainty_reduction > 0 and prop2.expected_uncertainty_reduction <= 1.0
    assert String.contains?(prop2.reason_explanation, "unknown in sopl_governance")
  end
end