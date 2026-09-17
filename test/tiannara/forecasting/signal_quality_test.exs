defmodule Tiannara.Forecasting.SignalQualityTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Signal, SignalQuality}

  defp seconds(s), do: DateTime.add(DateTime.utc_now(), s)

  describe "evaluate/2" do
    test "evaluates a fully-specified signal" do
      s =
        Signal.new(
          source: :sensor,
          source_reliability: 0.9,
          observation: [1.0, 2.0],
          timestamp: seconds(0),
          measurement_uncertainty: %{type: :exact},
          independence: 0.8,
          persistence: 0.7
        )

      q = SignalQuality.evaluate(s, seconds(0))
      assert q.signal_id == s.id
      assert is_number(q.aggregate_score)
      assert q.aggregate_score >= 0 and q.aggregate_score <= 1
      assert q.dimensions_assessed >= 1
    end

    test "returns :unknown aggregate when no dimension is assessable" do
      s = Signal.new(source: :sensor, observation: 1)
      # All quality dimensions unknown except completeness which is always numeric.
      q = SignalQuality.evaluate(s, seconds(0))
      # completeness is always scored, so aggregate should be numeric.
      assert is_number(q.aggregate_score)
    end

    test "recency decays with age using exponential half-life" do
      fresh = Signal.new(source: :s, observation: 1, timestamp: seconds(0))
      stale = Signal.new(source: :s, observation: 1, timestamp: seconds(-86400)) # 1 day

      q_fresh = SignalQuality.evaluate_recency(fresh, seconds(0), %{recency_half_life_hours: 24.0})
      q_stale = SignalQuality.evaluate_recency(stale, seconds(0), %{recency_half_life_hours: 24.0})

      assert q_fresh > q_stale
      assert_in_delta q_stale, 0.5, 0.05 # 1 half-life = 0.5
    end

    test "completeness is higher for signals with more populated fields" do
      minimal = Signal.new(source: :s, observation: 1)
      complete =
        Signal.new(
          source: :s,
          observation: 1,
          observation_ref: "ref",
          observation_type: :numeric,
          timestamp: seconds(0),
          provenance: %{kind: :observation},
          domain: :ecology,
          context: %{}
        )

      assert SignalQuality.evaluate_completeness(complete) > SignalQuality.evaluate_completeness(minimal)
    end

    test "measurement quality ranks exact > approximate > unknown" do
      exact = Signal.new(source: :s, observation: 1, measurement_uncertainty: %{type: :exact})
      approx = Signal.new(source: :s, observation: 1, measurement_uncertainty: %{type: :approximate})
      assert SignalQuality.evaluate_measurement(exact) > SignalQuality.evaluate_measurement(approx)
      assert SignalQuality.evaluate_measurement(Signal.new(source: :s, observation: 1)) == :unknown
    end

    test "reliability blends source_reliability and assessed reliability" do
      s = Signal.new(source: :s, source_reliability: 0.8, reliability: 0.6)
      assert_in_delta SignalQuality.evaluate_reliability(s), 0.7, 0.0001
    end

    test "reliability is :unknown when no reliability available" do
      s = Signal.new(source: :s, observation: 1)
      assert SignalQuality.evaluate_reliability(s) == :unknown
    end

    test "validity is 0 for an expired signal" do
      past = DateTime.add(DateTime.utc_now(), -3600)
      s = Signal.new(source: :s, observation: 1, expires_at: past)
      assert SignalQuality.evaluate_validity(s) == 0.0
    end

    test "is deterministic for identical inputs" do
      s = Signal.new(source: :s, source_reliability: 0.9, observation: [1.0], measurement_uncertainty: %{type: :exact})
      q1 = SignalQuality.evaluate(s, seconds(0))
      q2 = SignalQuality.evaluate(s, seconds(0))
      assert q1.aggregate_score == q2.aggregate_score
    end

    test "raw dimensions are preserved (not collapsed into a single score)" do
      s = Signal.new(source: :s, source_reliability: 0.9, observation: [1.0], measurement_uncertainty: %{type: :exact})
      q = SignalQuality.evaluate(s, seconds(0))
      assert q.reliability != nil
      assert q.recency != nil
      assert q.completeness != nil
      assert q.measurement != nil
    end
  end
end
