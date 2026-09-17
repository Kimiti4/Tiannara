defmodule Tiannara.Chaos.BlueprintTest do
  use ExUnit.Case, async: true

  alias Tiannara.Chaos.{Blueprint, Runner}

  test "catalog covers all 17 required faults" do
    assert Blueprint.count() == 17
  end

  test "every fault has non-empty lifecycle expectations" do
    for f <- Blueprint.all() do
      assert f.detection != [], "#{f.id} missing detection"
      assert f.containment != [], "#{f.id} missing containment"
      assert f.recovery != [], "#{f.id} missing recovery"
      assert f.evidence_preservation != [], "#{f.id} missing evidence_preservation"
      assert f.verification != [], "#{f.id} missing verification"
    end
  end

  test "runner refuses non-isolated env" do
    fault = Blueprint.get(:dets_corruption)
    assert_raise RuntimeError, fn -> Runner.Mock.inject(fault, []) end
  end

  test "runner accepts isolated env" do
    fault = Blueprint.get(:dets_corruption)
    assert :ok = Runner.Mock.inject(fault, isolated: true)
  end

  test "redis fault declares cache-is-derived invariant" do
    fault = Blueprint.get(:redis_unavailable)
    assert Enum.member?(fault.evidence_preservation, :cache_is_derived_data_only)
    assert Enum.member?(fault.verification, :no_epistemic_data_lost)
  end
end
