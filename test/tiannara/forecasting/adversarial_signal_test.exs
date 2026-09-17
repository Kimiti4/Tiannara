defmodule Tiannara.Forecasting.AdversarialSignalTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Signal, SignalQuality, SignalValue}

  describe "adversarial signal robustness" do
    test "a signal with nil source is rejected" do
      assert {:error, :missing_source} = Signal.new(observation: 1) |> Signal.validate()
    end

    test "a signal with nil observation is rejected" do
      assert {:error, :missing_observation} = Signal.new(source: :s) |> Signal.validate()
    end

    test "a signal with a future timestamp still evaluates (no crash)" do
      future = DateTime.add(DateTime.utc_now(), 3600 * 24)
      s = Signal.new(source: :s, observation: [1.0, 2.0], timestamp: future)
      q = SignalQuality.evaluate(s, DateTime.utc_now())
      assert is_struct(q, SignalQuality)
    end

    test "an expired signal is flagged as invalid (validity 0)" do
      past = DateTime.add(DateTime.utc_now(), -3600)
      s = Signal.new(source: :s, observation: [1.0], expires_at: past)
      assert SignalQuality.evaluate_validity(s) == 0.0
    end

    test "a signal with all nil quality fields evaluates to mostly unknown" do
      s = Signal.new(source: :s, observation: [1.0])
      q = SignalQuality.evaluate(s)
      # reliability + independence + persistence are :unknown for a bare signal
      assert q.reliability == :unknown
      assert q.independence == :unknown
      assert q.persistence == :unknown
    end

    test "contradictory metadata (high reliability but nil source_reliability) is tolerated" do
      s = Signal.new(source: :s, observation: 1, reliability: 0.9)
      q = SignalQuality.evaluate(s)
      assert_in_delta q.reliability, 0.9, 0.0001
    end

    test "measurement_uncertainty as a non-map does not crash quality evaluation" do
      s = Signal.new(source: :s, observation: [1.0], measurement_uncertainty: 5)
      q = SignalQuality.evaluate(s)
      assert is_struct(q, SignalQuality)
    end

    test "scalar observation yields :unknown redundancy (not measured, not fabricated)" do
      s = Signal.new(source: :s, observation: 1.5)
      v = SignalValue.measure(s, [])
      assert v.redundancy == :unknown
    end

    test "empty existing signal set yields :unknown for redundancy and information gain" do
      s = Signal.new(source: :s, observation: [1.0, 2.0])
      v = SignalValue.measure(s, [])
      assert v.redundancy == :unknown
      assert v.information_gain == :unknown
    end

    test "missing provenance does not crash and integrity is not falsely asserted" do
      s = Signal.new(source: :s, observation: [1.0])
      # provenance defaults to %{kind: :observation}
      assert s.provenance.kind == :observation
    end
  end
end
