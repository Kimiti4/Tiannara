defmodule Tiannara.Evolution.HorizonHarnessTest do
  use ExUnit.Case, async: true

  alias Tiannara.Evolution.{Harness, Metrics, Cycle}

  # SR-4 (Option C): moduletag removed so this test enters the default
  # `mix test` suite. Per the SR-3 design, this prevents future regressions
  # in the evolution Harness from escaping the default verification path.

  defp base_metrics do
    %Metrics{
      capability: %{composite_score: 10.0},
      epistemic: %{contradiction_count: 0},
      architectural: %{coupling_index: 0.1},
      constitutional: %{invariant_violations: 0}
    }
  end

  defp good_proposal(idx) do
    %{
      id: :"prop-#{idx}",
      patch_id: :"patch-#{idx}",
      experiment_id: :"exp-#{idx}",
      hypothesis_id: :"hyp-#{idx}",
      evidence_ids: [:"ev-#{idx}"],
      constitutional_version: "1.0.0",
      new_version: "0.0.#{idx}",
      next_state: %{state: :improved},
      rejected_alternatives: [],
      capstone_result: %{certified?: true, test_results: :pass, certification_result: :certified},
      metrics_after: %Metrics{
        capability: %{composite_score: 12.0}, # +2.0 gain
        epistemic: %{contradiction_count: 0},
        architectural: %{coupling_index: 0.1},
        constitutional: %{invariant_violations: 0}
      }
    }
  end

  test "accepts a genuine improvement and preserves lineage" do
    proposals = [good_proposal(1)]
    lineage = Harness.run_cycles(%{state: :baseline}, proposals, initial_metrics: base_metrics())

    assert length(lineage) == 1
    [cycle] = lineage

    assert cycle.decision == :accepted
    assert cycle.cycle_id == :cycle_1
    assert cycle.parent_cycle_id == nil
    assert cycle.drift_metrics.capability.net_gain == 2.0
  end

  test "CRITICAL RULE: rejects a massive benchmark increase that violates the constitution" do
    bad_proposal = %{
      good_proposal(1)
      | metrics_after: %Metrics{
          capability: %{composite_score: 50.0}, # Massive benchmark increase
          epistemic: %{contradiction_count: 0},
          architectural: %{coupling_index: 0.1},
          constitutional: %{invariant_violations: 1} # But violates an invariant
        }
    }

    lineage = Harness.run_cycles(%{}, [bad_proposal], initial_metrics: base_metrics())
    [cycle] = lineage

    assert cycle.decision == :rejected
    assert {:constitutional_violation, 1} in cycle.rejection_reasons
  end

  test "rejects a benchmark increase that introduces epistemic contradictions" do
    bad_proposal = %{
      good_proposal(1)
      | metrics_after: %Metrics{
          capability: %{composite_score: 15.0},
          epistemic: %{contradiction_count: 3}, # Introduced 3 contradictions
          architectural: %{coupling_index: 0.1},
          constitutional: %{invariant_violations: 0}
        }
    }

    lineage = Harness.run_cycles(%{}, [bad_proposal], initial_metrics: base_metrics())
    [cycle] = lineage

    assert cycle.decision == :rejected
    assert {:epistemic_degradation, 3} in cycle.rejection_reasons
  end

  test "rejects a benchmark increase that degrades architectural health" do
    bad_proposal = %{
      good_proposal(1)
      | metrics_after: %Metrics{
          capability: %{composite_score: 15.0},
          epistemic: %{contradiction_count: 0},
          architectural: %{coupling_index: 0.5}, # Coupling spiked from 0.1 to 0.5
          constitutional: %{invariant_violations: 0}
        }
    }

    lineage = Harness.run_cycles(%{}, [bad_proposal], initial_metrics: base_metrics())
    [cycle] = lineage

    assert cycle.decision == :rejected
    assert {:architectural_degradation, _} =
             Enum.find(cycle.rejection_reasons, &match?({:architectural_degradation, _}, &1))
  end

  test "multi-cycle lineage tracks accepted/rejected states correctly" do
    proposals = [
      good_proposal(1),                  # Accepted
      %{good_proposal(2) | metrics_after: %Metrics{base_metrics() | constitutional: %{invariant_violations: 1}}}, # Rejected
      good_proposal(3)                   # Accepted
    ]

    lineage = Harness.run_cycles(%{state: :baseline}, proposals, initial_metrics: base_metrics())

    assert length(lineage) == 3

    [c1, c2, c3] = lineage

    assert c1.decision == :accepted
    assert c2.decision == :rejected
    assert c3.decision == :accepted

    # Lineage tracking
    assert c2.parent_cycle_id == :cycle_1
    assert c3.parent_cycle_id == :cycle_2

    # State rollback: c3 should build on c1's state, not c2's
    assert c3.rollback_state == %{state: :improved} # from c1
  end
end