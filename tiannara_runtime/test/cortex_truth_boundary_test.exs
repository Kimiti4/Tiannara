defmodule TiannaraRuntime.CortexTruthBoundaryTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Cortex.ImmuneCortex
  alias TiannaraRuntime.Cortex.SafetyCortex

  test "immune risk assessment rejects incomplete telemetry" do
    assert {:error, :incomplete_or_invalid_metrics} =
             ImmuneCortex.assess_risk(:world_missing_metrics, %{entropy: 0.2})
  end

  test "immune risk assessment accepts complete measured telemetry" do
    assert %{risk_score: risk, action: :normal} =
             ImmuneCortex.assess_risk(:world_measured, %{
               entropy: 0.1,
               cascade_rate: 0.1,
               divergence: 0.1
             })

    assert is_float(risk)
    assert risk >= 0.0 and risk <= 1.0
  end

  test "safety cortex does not invent an unassessed risk" do
    if Process.whereis(SafetyCortex) do
      assert {:error, :risk_not_assessed} =
               SafetyCortex.get_risk(:world_never_assessed)
    end
  end
end
