defmodule Tiannara.Research.ResearchQueueTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.ResearchQueue

  describe "ResearchQueue" do
    test "pending_count returns count" do
      assert is_integer(ResearchQueue.pending_count())
    end

    test "running_count returns count" do
      assert is_integer(ResearchQueue.running_count())
    end

    test "status returns queue info" do
      status = ResearchQueue.status()
      assert Map.has_key?(status, :pending)
      assert Map.has_key?(status, :running)
      assert Map.has_key?(status, :total_enqueued)
      assert Map.has_key?(status, :total_dequeued)
    end
  end
end
