defmodule TiannaraRuntime.WorldScientificClosureTest do
  use ExUnit.Case, async: true

  test "CAL is deterministic and does not invent coalitions" do
    state = %{coalitions: [%{id: :a, demand: 0.4}], arbitration_weights: %{a: 0.8}}
    assert {:ok, first} = TiannaraRuntime.CAL.Engine.step(state)
    assert {:ok, second} = TiannaraRuntime.CAL.Engine.step(state)
    assert first == second
    assert first.decisions_made == [%{coalition: :a, demand: 0.4, support: 0.8, admitted: true}]
  end

  test "CIS reacts to observed entropy instead of claiming success" do
    result = TiannaraRuntime.CIS.Engine.evaluate(%{}, %{entropy_delta: 0.0}, %{entropy: 0.95, coherence: 0.5, stability_score: 0.5})
    assert result.decision == :constrain
    assert hd(result.interventions).status == :proposed
  end

  test "world genome carries parent lineage into child" do
    parent = Tiannara.Genetics.WorldGenome.new("W-parent")
    child = Tiannara.Genetics.WorldGenome.new("W-child", ["W-parent"])
    assert child.parent_ids == ["W-parent"]
    assert child.generation == 1
    assert parent.generation == 0
  end
end
