defmodule Tiannara.Forecasting.AdvancedHardeningTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.{RegimeDetector, SequentialBayes, Counterforecast}

  test "regime detector reports a candidate rather than certifying a regime change" do
    series = List.duplicate(1.0, 6) ++ List.duplicate(10.0, 6)
    assert {:ok, report} = RegimeDetector.detect(series, min_segment: 5, mean_shift_threshold: 1.0)
    assert report.status == :candidate_detected
    assert report.evidence_class == :observational_hypothesis
    assert Enum.all?(report.candidates, &(&1.status == :candidate))
  end

  test "sequential Bayes requires explicit likelihoods" do
    assert {:ok, result} = SequentialBayes.update(0.5, 0.8, 0.2)
    assert result.posterior == 0.8
  end

  test "invalid Bayesian inputs fail closed" do
    assert {:error, :invalid_prior} = SequentialBayes.update(2.0, 0.8, 0.2)
  end

  test "counterforecasting creates required adversarial tests" do
    assert {:ok, review} = Counterforecast.build(%{id: :primary}, [%{id: :alternative}])
    assert :disconfirming_evidence in review.required_tests
    assert review.status == :adversarial_review_required
  end
end
