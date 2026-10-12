defmodule Tiannara.Forecasting.ModelUpdateGateTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.ModelUpdateGate

  defp packet do
    %{
      candidate_id: "candidate-1",
      current_model_ref: "model-a",
      proposed_model_ref: "model-b",
      temporal_evaluation: %{
        holdout_locked: true,
        holdout_used_for_selection: false,
        selection_window: %{status: :measured}
      },
      calibration: %{certification_eligible: false},
      drift: %{certification_eligible: false},
      uncertainty: %{certification_eligible: false},
      multiple_testing: %{certification_eligible: false},
      holdout: %{status: :measured, certification_eligible: false}
    }
  end

  test "produces only an independent-review candidate" do
    assert {:ok, result} = ModelUpdateGate.assess(packet())
    assert result.disposition == :candidate_for_independent_review
    assert result.authorization == :not_granted
    assert result.deployment == :not_granted
    assert result.production_mutation == :forbidden
    assert result.human_review_required
    assert result.acl_required
    assert result.oavl_required
    assert result.cel_required
    assert result.certification_eligible == false
  end

  test "rejects unlocked holdout" do
    p = put_in(packet().temporal_evaluation.holdout_locked, false)
    assert {:error, :temporal_holdout_not_locked} = ModelUpdateGate.assess(p)
  end

  test "rejects analytics that self-certify" do
    p = put_in(packet().drift.certification_eligible, true)
    assert {:error, :analytics_self_certification_detected} = ModelUpdateGate.assess(p)
  end

  test "missing evidence remains an error" do
    p = Map.delete(packet(), :uncertainty)
    assert {:error, {:missing_evidence, :uncertainty}} = ModelUpdateGate.assess(p)
  end
end
