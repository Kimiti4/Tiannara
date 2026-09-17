defmodule Tiannara.Forecasting.BaseRateEngineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.BaseRateEngine

  defp br(attrs) do
    BaseRateEngine.new(Map.merge(%{reference_class: "class", historical_frequency: 0.6}, Map.new(attrs)))
  end

  describe "new/1 and validate/1" do
    test "constructs a BaseRate with default history unavailable" do
      b = BaseRateEngine.new(reference_class: "x")
      assert b.historical_frequency == :unknown
      assert {:ok, ^b} = BaseRateEngine.validate(b)
    end

    test "missing reference_class is rejected" do
      b = BaseRateEngine.new(historical_frequency: 0.5)
      assert BaseRateEngine.validate(b) == {:error, :missing_reference_class}
    end

    test "out-of-bounds frequency is rejected" do
      assert BaseRateEngine.validate(br(historical_frequency: 1.5)) == {:error, :frequency_out_of_bounds}
      assert BaseRateEngine.validate(br(historical_frequency: -0.1)) == {:error, :frequency_out_of_bounds}
    end

    test "non-numeric non-:unknown frequency rejected" do
      assert BaseRateEngine.validate(br(historical_frequency: "0.5")) ==
               {:error, :invalid_historical_frequency}
    end

    test ":unknown frequency is valid (absence of data, distinct from 0.0)" do
      b = br(historical_frequency: :unknown)
      assert BaseRateEngine.validate(b) == {:ok, b}
    end
  end

  describe "available?/1" do
    test "true only when historical_frequency is a number" do
      assert BaseRateEngine.available?(br(historical_frequency: 0.6))
      refute BaseRateEngine.available?(br(historical_frequency: :unknown))
      b = br(historical_frequency: nil)
      refute BaseRateEngine.available?(b)
    end
  end

  describe "compare/2" do
    test "shows base rate and current evidence side-by-side without preferring either" do
      b = br(historical_frequency: 0.4, data_quality: :medium, base_rate_uncertainty: 0.1)
      cmp = BaseRateEngine.compare(b, 0.65)
      assert cmp.base_rate == 0.4
      assert cmp.current_evidence == 0.65
      assert cmp.data_quality == :medium
      assert cmp.base_rate_uncertainty == 0.1
    end
  end

  describe "normalize_frequency/1" do
    test "normalizes a frequency into [0,1] as an evidence report" do
      report = BaseRateEngine.normalize_frequency(br(historical_frequency: 0.7))
      refute is_nil(report)
    end

    test "returns :unknown report for an unknown frequency" do
      assert BaseRateEngine.normalize_frequency(br(historical_frequency: :unknown)) ==
               %{status: :unknown, result: :unknown}
    end
  end
end