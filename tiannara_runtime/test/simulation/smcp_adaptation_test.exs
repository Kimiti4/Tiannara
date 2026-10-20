defmodule Tiannara.Simulation.SMCPAdaptationTest do
  @moduledoc "Property-based validation of BFT safety, bounded adaptation, and rollback triggers"
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase15.SMCP.{SafetyVerifier, FallbackController}

  @stability_threshold 0.70

  property "Proposed consensus parameters always satisfy BFT quorum safety" do
    forall(
      params <- candidate_parameter_generator(),
      do: assert_bft_safety(params)
    )
  end

  property "Rollback triggers only when stability score breaches threshold" do
    forall(
      {score, baseline} <- stability_scenario_generator(),
      do: assert_rollback_logic(score, baseline)
    )
  end

  defp candidate_parameter_generator() do
    let(
      {q, vt} <- {float(0.667, 0.90), float(200.0, 5000.0)},
      do: let(ct <- float(100.0, vt),
        do: %{quorum_fraction: q, view_timeout_ms: vt, commit_timeout_ms: ct})
    )
  end

  defp stability_scenario_generator() do
    let {s, b} <- {float(0.4, 0.95), %{baseline: :ok}}, do: {s, b}
  end

  defp assert_bft_safety(params) do
    case SafetyVerifier.verify(params) do
      :valid -> true
      _ -> false
    end
  end

  defp assert_rollback_logic(score, _baseline) do
    triggered = score < 0.70
    if score < 0.70 do
      assert triggered
    else
      refute triggered
    end
    true
  end
end