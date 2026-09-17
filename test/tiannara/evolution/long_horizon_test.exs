defmodule Tiannara.Evolution.LongHorizonTest do
  use ExUnit.Case, async: true

  alias Tiannara.Evolution.{LongHorizon, Metrics}

  # SR-4 (Option C): moduletag removed so this test enters the default
  # `mix test` suite. Per the SR-3 design, this prevents future regressions
  # in Trajectory.analyze/1 from escaping the default verification path.

  defp base_metrics(score \\ 10.0) do
    %Metrics{
      capability: %{composite_score: score},
      epistemic: %{contradiction_count: 0},
      architectural: %{coupling_index: 0.1, memory: 100.0},
      constitutional: %{invariant_violations: 0}
    }
  end

  defp improving_generator do
    fn _state, index ->
      %{
        id: :"prop-#{index}",
        hypothesis_id: :"hyp-#{index}",
        experiment_id: :"exp-#{index}",
        evidence_ids: [:"ev-#{index}"],
        new_version: "0.0.#{index}",
        next_state: %{generation: index},
        capstone_result: %{certified?: true, test_results: :pass, certification_result: :certified},
        metrics_after: %Metrics{
          capability: %{composite_score: 10.0 + index * 1.0},
          epistemic: %{contradiction_count: 0},
          architectural: %{coupling_index: 0.1, memory: 100.0},
          constitutional: %{invariant_violations: 0}
        }
      }
    end
  end

  defp stagnating_generator do
    fn _state, index ->
      %{
        id: :"prop-#{index}",
        hypothesis_id: :"hyp-#{index}",
        capstone_result: %{certified?: true, test_results: :pass, certification_result: :certified},
        metrics_after: base_metrics(10.0) # no gain
      }
    end
  end

  defp epistemic_drift_generator do
    fn _state, index ->
      %{
        id: :"prop-#{index}",
        hypothesis_id: :"hyp-#{index}",
        capstone_result: %{certified?: true, test_results: :pass, certification_result: :certified},
        metrics_after: %Metrics{
          capability: %{composite_score: 10.0 + index},
          epistemic: %{contradiction_count: index}, # contradictions accumulate
          architectural: %{coupling_index: 0.1},
          constitutional: %{invariant_violations: 0}
        }
      }
    end
  end

  defp governance_violation_generator do
    fn _state, index ->
      %{
        id: :"prop-#{index}",
        hypothesis_id: :"hyp-#{index}",
        capstone_result: %{certified?: true, test_results: :pass, certification_result: :certified},
        metrics_after: %Metrics{
          capability: %{composite_score: 10.0 + index},
          epistemic: %{contradiction_count: 0},
          architectural: %{coupling_index: 0.1},
          constitutional: %{invariant_violations: 1} # violates invariant
        }
      }
    end
  end

  test "healthy evolution: sustained validated improvement" do
    result =
      LongHorizon.run(%{state: :baseline},
        cycles: 6,
        generator: improving_generator(),
        initial_metrics: base_metrics()
      )

    assert result.trajectory.verdict == :healthy_evolution
    assert result.trajectory.capability_trend == :improving
    assert result.trajectory.accepted_cycles == 6
    assert result.trajectory.certification_rate == 1.0
    assert result.trajectory.lineage_integrity == :intact
    refute result.trajectory.stagnation?
  end

  test "stagnation is detected when gains plateau" do
    result =
      LongHorizon.run(%{state: :baseline},
        cycles: 6,
        generator: stagnating_generator(),
        initial_metrics: base_metrics()
      )

    assert result.trajectory.stagnation?
    assert result.trajectory.verdict == :stagnating
  end

  test "epistemic drift is detected when contradictions accumulate" do
    result =
      LongHorizon.run(%{state: :baseline},
        cycles: 6,
        generator: epistemic_drift_generator(),
        initial_metrics: base_metrics()
      )

    assert result.trajectory.epistemic_drift == :accumulating
    assert result.trajectory.verdict == :drifting
  end

  test "governance violations are caught even when benchmarks improve" do
    result =
      LongHorizon.run(%{state: :baseline},
        cycles: 6,
        generator: governance_violation_generator(),
        initial_metrics: base_metrics()
      )

    # Every cycle should be rejected due to constitutional violation
    assert result.trajectory.accepted_cycles == 0
    assert result.trajectory.regression_rate == 1.0
    # Since nothing was accepted, constitutional_drift stays stable (no accepted violations)
    # but the rejections prove the guardrail works
    assert Enum.all?(result.lineage, &(&1.decision == :rejected))
  end

  test "lineage integrity is preserved across accepted and rejected cycles" do
    mixed_generator = fn _state, index ->
      base = improving_generator().(nil, index)

      if rem(index, 2) == 0 do
        # every even cycle violates constitution -> rejected
        %{base | metrics_after: %Metrics{base.metrics_after | constitutional: %{invariant_violations: 1}}}
      else
        base
      end
    end

    result =
      LongHorizon.run(%{state: :baseline},
        cycles: 6,
        generator: mixed_generator,
        initial_metrics: base_metrics()
      )

    assert result.trajectory.lineage_integrity == :intact

    # Verify parent chain
    result.lineage
    |> Enum.with_index()
    |> Enum.each(fn {cycle, idx} ->
      expected = if idx == 0, do: nil, else: Enum.at(result.lineage, idx - 1).cycle_id
      assert cycle.parent_cycle_id == expected
    end)
  end
end