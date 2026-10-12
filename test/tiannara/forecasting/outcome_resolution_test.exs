defmodule Tiannara.Forecasting.OutcomeResolutionTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.{Outcome, OutcomeResolution}
  alias Tiannara.Forecasting.Contracts.Forecast

  defp forecast do
    %Forecast{id: "f-1", question: "Will event occur?", outcomes: ["yes", "no"],
      probabilities: [0.7, 0.3], forecast_version: "v1",
      created_at: ~U[2026-09-01 00:00:00Z]}
  end

  test "resolves with explicit simulation evidence without certifying" do
    f = forecast()
    o = Outcome.new(f.id, "yes", observed_at: ~U[2026-09-02 00:00:00Z])
    assert {:ok, r} = OutcomeResolution.resolve(f, o, %{evidence_class: :simulated, execution_mode: :simulation})
    assert r.status == :resolved_not_certified
    assert r.evidence_status == :simulated_observation
    assert r.scores.brier == 0.09
  end

  test "rejects forecast id mismatch" do
    f = forecast()
    o = Outcome.new("other", "yes", observed_at: ~U[2026-09-02 00:00:00Z])
    assert {:error, :forecast_id_mismatch} = OutcomeResolution.resolve(f, o)
  end

  test "rejects hindsight contamination" do
    f = forecast()
    o = Outcome.new(f.id, "yes", observed_at: ~U[2026-08-31 23:59:59Z])
    assert {:error, :hindsight_contamination} = OutcomeResolution.resolve(f, o)
  end

  test "real evidence requires real execution" do
    f = forecast()
    o = Outcome.new(f.id, "yes", observed_at: ~U[2026-09-02 00:00:00Z])
    assert {:error, :real_evidence_requires_real_execution} =
      OutcomeResolution.resolve(f, o, %{evidence_class: :real, execution_mode: :simulation})
  end
end
