defmodule Tiannara.Forecasting.SignalValueTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Signal, SignalValue}

  defp sig(attrs) do
    Signal.new(attrs)
  end

  describe "measure/2" do
    test "returns :unknown predictive_value without outcome data" do
      s = sig(source: :market, observation: [1.0, 2.0])
      v = SignalValue.measure(s, [])
      assert v.predictive_value == :unknown
    end

    test "assessment basis is :insufficient_data when nothing measurable" do
      s = sig(source: :market, observation: 1) # scalar observation -> not a vector
      v = SignalValue.measure(s, [])
      assert v.redundancy == :unknown
    end

    test "redundancy is high for identical vector observations" do
      s1 = sig(source: :a, observation: [1.0, 2.0, 3.0])
      s2 = sig(source: :b, observation: [1.0, 2.0, 3.0])
      v = SignalValue.measure(s2, [s1])
      assert is_number(v.redundancy)
      assert_in_delta v.redundancy, 1.0, 0.0001
    end

    test "redundancy is low for orthogonal vector observations" do
      s1 = sig(source: :a, observation: [1.0, 0.0])
      s2 = sig(source: :b, observation: [0.0, 1.0])
      v = SignalValue.measure(s2, [s1])
      assert is_number(v.redundancy)
      refute v.redundancy > 0.01
    end
  end

  describe "compute_predictive_value/2" do
    test "returns :unknown with no outcomes (insufficient evidence)" do
      s = sig(source: :market, predictive_value: 0.8, observation: 1)
      assert SignalValue.compute_predictive_value(s, []) == :unknown
    end

    test "returns the recorded predictive value with outcomes present" do
      s = sig(source: :market, predictive_value: 0.8, observation: 1)
      assert_in_delta SignalValue.compute_predictive_value(s, [:x, :y, :z]), 0.8, 0.0001
    end
  end

  describe "compute_information_gain/2" do
    test "returns :unknown with no existing signals (no prior)" do
      s = sig(source: :a, observation: [1.0, 2.0])
      assert SignalValue.compute_information_gain(s, []) == :unknown
    end

    test "returns a non-negative number when a prior exists" do
      existing = [sig(source: :a, observation: [1.0, 2.0], source_reliability: 0.9)]
      s = sig(source: :b, observation: [1.0, 2.0])
      ig = SignalValue.compute_information_gain(s, existing)
      assert is_number(ig)
      assert ig >= 0
    end
  end
end
