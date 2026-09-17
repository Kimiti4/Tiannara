defmodule Tiannara.Interface.CognitiveInterfaceTest do
  use ExUnit.Case, async: false

  alias Tiannara.Interface.CognitiveInterface


  describe "supervisor" do
    test "starts and returns status" do
      status = CognitiveInterface.status()
      assert status.conversations
      assert status.notifications
      assert status.dialogues
      assert status.collaborations
    end

    test "reports healthy" do
      health = CognitiveInterface.health()
      assert health.status == :healthy
      assert is_integer(health.active_conversations)
      assert is_integer(health.pending_notifications)
    end
  end

  describe "surface_discovery" do
    test "surfaces a discovery through notification" do
      assert {:ok, _id} = CognitiveInterface.surface_discovery(%{
        type: :anomaly, source: :sentinel, severity: :warning,
        domain: :memory, signal: "leak", confidence: 0.85,
        rationale: "Memory growth detected"
      })
    end
  end

  describe "initiate_dialogue" do
    test "initiates a scientific dialogue" do
      assert {:ok, _id} = CognitiveInterface.initiate_dialogue(:memory_analysis, %{
        observation: "Memory usage increasing", evidence: [], confidence: 0.7
      })
    end
  end

  describe "handle_human_input" do
    test "returns error for unknown conversation" do
      assert {:error, :conversation_not_found} = CognitiveInterface.handle_human_input("nonexistent", "hello")
    end
  end

  describe "pending_notifications" do
    test "returns a list" do
      assert is_list(CognitiveInterface.pending_notifications())
    end
  end
end
