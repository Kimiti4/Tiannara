defmodule Tiannara.Interface.HumanCollaborationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Interface.HumanCollaboration

  describe "request" do
    test "creates collaboration in inform mode" do
      assert {:ok, id} = HumanCollaboration.request(:inform, :status_update, %{data: "ok"}, "Routine update")
      assert is_binary(id)
    end

    test "creates collaboration in consult mode" do
      assert {:ok, _id} = HumanCollaboration.request(:consult, :strategy, %{options: ["A", "B"]}, "Need input")
    end

    test "creates collaboration in approve mode" do
      assert {:ok, _id} = HumanCollaboration.request(:approve, :deployment, %{risk: :low}, "Please approve")
    end

    test "creates collaboration in collaborate mode" do
      assert {:ok, _id} = HumanCollaboration.request(:collaborate, :design, %{draft: "plan"}, "Let's work together")
    end

    test "creates collaboration in escalate mode" do
      assert {:ok, _id} = HumanCollaboration.request(:escalate, :incident, %{severity: :critical}, "Need immediate attention")
    end
  end

  describe "respond" do
    setup do
      {:ok, id} = HumanCollaboration.request(:consult, :test, %{}, "test rationale")
      %{collaboration_id: id}
    end

    test "resolves a pending collaboration", %{collaboration_id: id} do
      assert :ok = HumanCollaboration.respond(id, "Approved with conditions")
      assert is_integer(HumanCollaboration.active_count())
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = HumanCollaboration.respond("invalid", "response")
    end
  end

  describe "active" do
    test "returns only pending/active collaborations" do
      before = length(HumanCollaboration.active())
      HumanCollaboration.request(:inform, :t1, %{}, "r1")
      HumanCollaboration.request(:consult, :t2, %{}, "r2")
      assert length(HumanCollaboration.active()) == before + 2
    end
  end

  describe "active_count" do
    test "returns correct count" do
      before = HumanCollaboration.active_count()
      HumanCollaboration.request(:inform, :t, %{}, "r")
      assert HumanCollaboration.active_count() == before + 1
    end
  end

  describe "status" do
    test "returns metrics" do
      status = HumanCollaboration.status()
      assert is_integer(status.total_requested)
      assert is_integer(status.total_resolved)
      assert is_integer(status.active)
    end
  end
end
