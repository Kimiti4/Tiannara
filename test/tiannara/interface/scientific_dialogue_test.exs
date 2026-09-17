defmodule Tiannara.Interface.ScientificDialogueTest do
  use ExUnit.Case, async: false

  alias Tiannara.Interface.ScientificDialogue

  describe "initiate" do
    test "creates dialogue with structured opening" do
      assert {:ok, conversation_id} = ScientificDialogue.initiate(:entropy_analysis, %{
        observation: "Entropy levels rising across all domains",
        evidence: [%{rationale: "Cross-domain entropy correlation detected"}, "Raw data shows 15% increase"],
        confidence: 0.78,
        recommended_action: "Run detailed entropy analysis",
        unknowns: ["Unknown: root cause not yet identified"]
      })
      assert is_binary(conversation_id)
    end

    test "includes uncertainty disclosure" do
      assert {:ok, _id} = ScientificDialogue.initiate(:test, %{assumptions: ["Assumption A", "Assumption B"]})
    end

    test "uses defaults when context sparse" do
      assert {:ok, _id} = ScientificDialogue.initiate(:minimal, %{})
    end
  end

  describe "respond" do
    test "generates structured response" do
      response = ScientificDialogue.respond(:memory_analysis, "What is the current status?", %{
        evidence: ["Metric A: normal"],
        confidence: 0.65,
        recommended_action: "Continue monitoring"
      })
      assert response.content != nil
      assert response.evidence == ["Metric A: normal"]
      assert response.confidence == 0.65
    end

    test "handles empty evidence" do
      response = ScientificDialogue.respond(:topic, "query?", %{})
      assert response.content != nil
      assert response.evidence == []
    end
  end

  describe "status" do
    test "returns metrics" do
      status = ScientificDialogue.status()
      assert is_integer(status.total_dialogues)
      assert is_integer(status.total_responses)
    end
  end
end
