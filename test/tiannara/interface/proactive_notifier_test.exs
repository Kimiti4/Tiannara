defmodule Tiannara.Interface.ProactiveNotifierTest do
  use ExUnit.Case, async: false

  alias Tiannara.Interface.ProactiveNotifier

  defp sample_discovery(opts \\ []) do
    %{
      type: opts[:type] || :anomaly,
      source: opts[:source] || :sentinel,
      severity: opts[:severity] || :warning,
      domain: :memory, signal: "leak",
      title: opts[:title] || "Memory leak detected",
      confidence: opts[:confidence] || 0.85,
      rationale: "Memory growth detected",
      recommended_action: "Investigate"
    }
  end

  describe "notify" do
    test "sends notification and returns id" do
      assert {:ok, id} = ProactiveNotifier.notify(sample_discovery())
      assert is_binary(id)
    end

    test "rejects duplicates by presented title and source" do
      d1 = sample_discovery(type: :other, title: "Dedup Title", source: :dedup_src)
      assert {:ok, _id} = ProactiveNotifier.notify(d1)
      d2 = sample_discovery(type: :other, title: "Dedup Title", source: :dedup_src)
      assert {:error, :deduplicated} = ProactiveNotifier.notify(d2)
    end

    test "rate limits after limit reached" do
      st = ProactiveNotifier.status()
      limit = st.rate_limit_per_hour
      remaining = limit - st.window_count
      for i <- 1..remaining do
        d = sample_discovery(type: :other, title: "rate_fill_#{i}", source: "rate_fill_#{i}", severity: :info, confidence: 0.5)
        assert {:ok, _} = ProactiveNotifier.notify(d)
      end
      extra = sample_discovery(type: :other, title: "rate_extra", source: :rate_extra, severity: :info, confidence: 0.5)
      assert {:error, :rate_limited} = ProactiveNotifier.notify(extra)
    end

    test "emergency severity bypasses rate limit" do
      st = ProactiveNotifier.status()
      limit = st.rate_limit_per_hour
      remaining = limit - st.window_count
      for i <- 1..max(remaining, 1) do
        d = sample_discovery(type: :other, title: "emerg_fill_#{i}", source: "emerg_fill_#{i}", severity: :info, confidence: 0.5)
        ProactiveNotifier.notify(d)
      end
      assert {:ok, _} = ProactiveNotifier.notify(sample_discovery(severity: :emergency, source: :emergency_bypass))
    end
  end

  describe "pending" do
    test "returns unacknowledged notifications sorted" do
      before = length(ProactiveNotifier.pending())
      assert {:ok, _id} = ProactiveNotifier.notify(sample_discovery(title: "pending_first", source: :pending_a))
      assert length(ProactiveNotifier.pending()) == before + 1
    end
  end

  describe "acknowledge" do
    test "marks notification as acknowledged" do
      assert {:ok, id} = ProactiveNotifier.notify(sample_discovery(source: :ack_test))
      assert :ok = ProactiveNotifier.acknowledge(id)
      assert Enum.find(ProactiveNotifier.pending(), fn n -> n.id == id end) == nil
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = ProactiveNotifier.acknowledge("invalid")
    end
  end

  describe "metrics" do
    test "pending_count returns correct count" do
      before = ProactiveNotifier.pending_count()
      ProactiveNotifier.notify(sample_discovery(source: :metric_m1))
      assert ProactiveNotifier.pending_count() == before + 1
    end

    test "total_sent returns correct count" do
      before = ProactiveNotifier.total_sent()
      ProactiveNotifier.notify(sample_discovery(source: :metric_ts1))
      assert ProactiveNotifier.total_sent() == before + 1
    end
  end

  describe "status" do
    test "returns status metrics" do
      status = ProactiveNotifier.status()
      assert is_integer(status.total_sent)
      assert is_integer(status.total_rate_limited)
      assert is_integer(status.total_deduplicated)
      assert is_integer(status.pending)
      assert is_integer(status.rate_limit_per_hour)
    end
  end
end
