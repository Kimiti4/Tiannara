defmodule Tiannara.Autonomy.ImprovementEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.ImprovementEngine

  describe "identify" do
    test "returns opportunities with required fields" do
      opportunities = ImprovementEngine.identify()
      assert is_list(opportunities)
      if length(opportunities) > 0 do
        opp = hd(opportunities)
        assert opp.id != nil
        assert opp.category in [:bottleneck, :scalability, :reliability, :performance, :knowledge]
        assert opp.target != nil
        assert opp.description != nil
        assert is_float(opp.estimated_impact)
        assert opp.estimated_impact >= 0 and opp.estimated_impact <= 1.0
      end
    end

    test "returns at most 10 opportunities" do
      opportunities = ImprovementEngine.identify()
      assert length(opportunities) <= 10
    end

    test "returns sorted by estimated_impact descending" do
      opportunities = ImprovementEngine.identify()
      impacts = Enum.map(opportunities, & &1.estimated_impact)
      assert impacts == Enum.sort(impacts, :desc)
    end
  end

  describe "status" do
    test "updates after identification" do
      before = ImprovementEngine.status().total_identified
      ImprovementEngine.identify()
      status = ImprovementEngine.status()
      assert status.total_identified >= before
      assert status.last_identification_at != nil
    end
  end
end
