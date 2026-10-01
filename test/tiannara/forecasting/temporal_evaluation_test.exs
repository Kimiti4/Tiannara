defmodule Tiannara.Forecasting.TemporalEvaluationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.TemporalEvaluation

  defp record(id, at) do
    %{forecast_id: id, forecast_created_at: at, status: :resolved_not_certified,
      evidence_status: :simulated_observation,
      scores: %{brier: 0.1, log_loss: 0.2, directional_accuracy: 1}}
  end

  test "keeps post-cutoff forecasts in locked holdout" do
    cutoff = ~U[2026-09-10 00:00:00Z]
    records =
      for i <- 1..10 do
        day = if i <= 5, do: 1 + i, else: 11 + i
        record(Integer.to_string(i), DateTime.add(cutoff, day - 10, :day))
      end

    assert {:ok, result} = TemporalEvaluation.evaluate(records, cutoff)
    assert length(result.selection_ids) == 5
    assert length(result.holdout_ids) == 5
    assert result.holdout_locked
    assert result.holdout_used_for_selection == false
    assert result.winner == :not_assigned
  end

  test "requires enough observations in both temporal windows" do
    cutoff = ~U[2026-09-10 00:00:00Z]
    records = for i <- 1..9, do: record(Integer.to_string(i), DateTime.add(cutoff, i - 6, :day))
    assert {:error, :selection_window_insufficient} = TemporalEvaluation.evaluate(records, cutoff)
  end

  test "rejects records without forecast creation time" do
    assert {:error, :forecast_creation_time_required} =
      TemporalEvaluation.evaluate(
        [%{forecast_id: "x", status: :resolved_not_certified}],
        ~U[2026-09-10 00:00:00Z]
      )
  end
end
