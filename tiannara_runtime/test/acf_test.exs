defmodule TiannaraRuntime.ACFTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.ACF.{Auditor, StatsTracker}

  setup do
    if Process.whereis(StatsTracker) do
      StatsTracker.reset_stats()
    end
    :ok
  end

  test "auditor passes optimal meta-ops" do
    meta_op = %{
      cost_estimate: 0.5,
      anchors: ["anchor_1"]
    }

    assert Auditor.audit(meta_op) == :ok
    
    if Process.whereis(StatsTracker) do
      stats = StatsTracker.get_stats()
      assert stats.total_audits == 1
      assert stats.passed == 1
      assert stats.rejected == 0
    end
  end

  test "auditor rejects causal violation ops" do
    meta_op = %{
      cost_estimate: -1.0,
      anchors: ["anchor_1"]
    }

    assert Auditor.audit(meta_op) == {:reject, :causal_violation}
    
    if Process.whereis(StatsTracker) do
      stats = StatsTracker.get_stats()
      assert stats.total_audits == 1
      assert stats.rejected == 1
      assert stats.rejections_by_reason.causal_violation == 1
    end
  end

  test "auditor rejects complexity ceiling overflow ops" do
    meta_op = %{
      cost_estimate: 0.9,
      anchors: ["anchor_1"]
    }

    assert Auditor.audit(meta_op) == {:reject, :runtime_overflow}
    
    if Process.whereis(StatsTracker) do
      stats = StatsTracker.get_stats()
      assert stats.total_audits == 1
      assert stats.rejected == 1
      assert stats.rejections_by_reason.runtime_overflow == 1
    end
  end

  test "stats tracker allows explicit reset" do
    if Process.whereis(StatsTracker) do
      StatsTracker.record_audit(:ok)
      StatsTracker.record_audit({:reject, :causal_violation})
      
      stats_before = StatsTracker.get_stats()
      assert stats_before.total_audits == 2
      
      StatsTracker.reset_stats()
      Process.sleep(10)
      
      stats_after = StatsTracker.get_stats()
      assert stats_after.total_audits == 0
    end
  end
end
