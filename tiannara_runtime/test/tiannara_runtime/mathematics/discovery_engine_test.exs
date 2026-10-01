defmodule TiannaraRuntime.Mathematics.DiscoveryEngineTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.DiscoveryEngine
  alias TiannaraRuntime.Mathematics.SymbolicEngine

  test "derivation produces a candidate formula, not a theorem" do
    {:ok, x} = SymbolicEngine.variable("x")
    {:ok, candidate} = DiscoveryEngine.derive(x, :differentiate, "x")

    assert candidate.status == :derived_candidate
    assert candidate.proof_required == true
    assert candidate.certification_eligible == false
  end

  test "discovery emits bounded proof obligations" do
    {:ok, x} = SymbolicEngine.variable("x")
    {:ok, discovery} = DiscoveryEngine.discover(x, variable: "x", budget: 100)

    assert length(discovery.candidates) <= 64
    assert discovery.certification_eligible == false
    assert Enum.all?(discovery.proof_obligations, &(&1.status == :unproven))
  end

  test "non-symbolic input fails closed" do
    assert {:error, :symbolic_expression_required} = DiscoveryEngine.discover("x")
  end
end
