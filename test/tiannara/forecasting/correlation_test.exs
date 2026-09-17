defmodule Tiannara.Forecasting.CorrelationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Signal, Correlation}

  describe "shares_origin?/2" do
    test "true when same source" do
      a = Signal.new(source: :market, observation: [1, 2])
      b = Signal.new(source: :market, observation: [2, 3])
      assert Correlation.shares_origin?(a, b)
    end

    test "true when sharing lineage (common parent)" do
      parent = Signal.new(source: :p, observation: [1, 2])
      a = Signal.new(source: :a, observation: [1, 2], lineage: [parent.id])
      b = Signal.new(source: :b, observation: [9, 8], lineage: [parent.id])
      assert Correlation.shares_origin?(a, b)
    end
  end

  describe "shares_dependency?/2" do
    test "true when sharing a model dependency" do
      a = Signal.new(source: :a, observation: 1, metadata: %{model_dependencies: [:model_x]})
      b = Signal.new(source: :b, observation: 1, metadata: %{model_dependencies: [:model_x]})
      assert Correlation.shares_dependency?(a, b)
    end

    test "false when no shared dependency" do
      a = Signal.new(source: :a, observation: 1, metadata: %{model_dependencies: [:x]})
      b = Signal.new(source: :b, observation: 1, metadata: %{model_dependencies: [:y]})
      refute Correlation.shares_dependency?(a, b)
    end
  end

  describe "correlation/2" do
    test "returns 1.0 for shared origin" do
      parent = Signal.new(source: :p, observation: [1, 2])
      a = Signal.new(source: :a, observation: [5, 6], lineage: [parent.id])
      b = Signal.new(source: :b, observation: [9, 8], lineage: [parent.id])
      assert Correlation.correlation(a, b) == 1.0
    end

    test "returns high correlation for same-origin" do
      a = Signal.new(source: :sensor, observation: [1.0, 2.0])
      b = Signal.new(source: :sensor, observation: [1.0, 2.0])
      assert Correlation.correlation(a, b) == 1.0
    end
  end

  describe "redundancy_index/1" do
    test "high for identical observations" do
      s1 = Signal.new(source: :a, observation: [1.0, 2.0, 3.0])
      s2 = Signal.new(source: :b, observation: [1.0, 2.0, 3.0])
      idx = Correlation.redundancy_index([s1, s2])
      assert is_number(idx)
      assert(idx > 0.9)
    end

    test "low for independent signals" do
      s1 = Signal.new(source: :a, observation: [1.0, 0.0])
      s2 = Signal.new(source: :b, observation: [0.0, 1.0])
      idx = Correlation.redundancy_index([s1, s2])
      assert is_number(idx)
      assert(idx < 0.1)
    end

    test ":unknown for single signal" do
      s1 = Signal.new(source: :a, observation: [1.0, 2.0])
      assert Correlation.redundancy_index([s1]) == :unknown
    end
  end

  describe "redundant_with/2" do
    test "returns signals sharing origin" do
      s1 = Signal.new(source: :a, observation: [1, 2])
      s2 = Signal.new(source: :b, observation: [3, 4])
      dup = Signal.new(source: :a, observation: [9, 8]) # same source as s1
      result = Correlation.redundant_with(s1, [s2, dup])
      assert dup.id in Enum.map(result, & &1.id)
    end
  end
end
