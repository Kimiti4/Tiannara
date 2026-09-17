defmodule Tiannara.Interface.ConversationManagerTest do
  use ExUnit.Case, async: false

  alias Tiannara.Interface.ConversationManager

  describe "create" do
    test "creates a conversation with unique id" do
      assert {:ok, id1} = ConversationManager.create(:topic_a, %{evidence: ["e1"]}, :test)
      assert {:ok, id2} = ConversationManager.create(:topic_b, %{confidence: 0.8}, :test)
      assert id1 != id2
    end

    test "increments active count" do
      before = ConversationManager.active_count()
      ConversationManager.create(:t, %{}, :test)
      assert ConversationManager.active_count() == before + 1
    end
  end

  describe "handle_input" do
    setup do
      {:ok, id} = ConversationManager.create(:test_topic, %{evidence: ["e1"], confidence: 0.7}, :test)
      %{conversation_id: id}
    end

    test "processes human input and returns tiannara response", %{conversation_id: id} do
      assert {:ok, response} = ConversationManager.handle_input(id, "What do you see?")
      assert response.role == :tiannara
      assert response.content != nil
      assert response.evidence == ["e1"]
      assert response.confidence == 0.7
    end

    test "returns error for unknown conversation" do
      assert {:error, :conversation_not_found} = ConversationManager.handle_input("bad_id", "hello")
    end
  end

  describe "append_response" do
    setup do
      {:ok, id} = ConversationManager.create(:t, %{}, :test)
      %{conversation_id: id}
    end

    test "appends tiannara response to conversation", %{conversation_id: id} do
      assert :ok = ConversationManager.append_response(id, %{content: "Analysis complete", evidence: [], confidence: 0.9})
    end
  end

  describe "resolve" do
    setup do
      {:ok, id} = ConversationManager.create(:t, %{}, :test)
      %{conversation_id: id}
    end

    test "resolves a conversation", %{conversation_id: id} do
      assert :ok = ConversationManager.resolve(id)
      assert is_integer(ConversationManager.active_count())
    end
  end

  describe "status" do
    test "returns correct metrics" do
      status = ConversationManager.status()
      assert is_integer(status.total_conversations)
      assert is_integer(status.total_created)
      assert is_integer(status.total_resolved)
    end
  end
end
