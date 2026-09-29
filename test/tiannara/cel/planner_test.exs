defmodule Tiannara.CEL.PlannerTest do
  use ExUnit.Case, async: false

  test "builds a bounded plan from an engineering objective" do
    start_supervised!(Tiannara.CEL.Planner)
    assert {:ok, plan} = Tiannara.CEL.Planner.plan("research and design an automation system, then verify it")
    assert plan.steps == [:research, :design, :verification, :evidence_report]
    assert plan.bounded
  end

  test "OED rejects privileged unreviewed actions" do
    assert {:error, :privileged_action_requires_human_gate} =
             Tiannara.OED.validate_constitution(%{objective: "deploy", steps: [:design, :unreviewed_deploy]})
  end
end
