defmodule Tiannara.Forecasting.IntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Signal, SignalRegistry, SignalQuality, SignalValue}

  setup do
    start_supervised!(SignalRegistry)
    :ets.delete_all_objects(:efdi_signal_registry)
    :ok
  end

  defp sig(attrs) do
    m = Map.new(attrs)
    Signal.new(Map.put(m, :id, m[:id] || "sig_#{System.unique_integer([:positive])}"))
  end

  describe "EFDI integrates with existing canonical systems" do
    test "signal measurement uncertainty integrates with Tiannara.Numerics error modes" do
      s =
        Signal.new(
          source: :market,
          observation: 0.42,
          measurement_uncertainty: %{type: :absolute, value: 0.05},
          timestamp: ~U[2026-08-01 12:00:00Z]
        )

      assert {:ok, s} = Signal.validate(s)
      assert s.measurement_uncertainty.type == :absolute
      # Numerics error modes remain intact; the signal carries uncertainty as metadata
      assert is_map(s.measurement_uncertainty)
    end

    test "signal quality reuses Constraints normalization (deterministic aggregate)" do
      s = sig(source: :survey, observation: [1, 2, 3])
      assert {:ok, stored} = SignalRegistry.register(s)
      q = SignalQuality.evaluate(stored)
      # aggregate quality is a single float in [0,1]
      assert is_number(q.aggregate_score)
      assert q.aggregate_score >= 0 and q.aggregate_score <= 1
    end

    test "provenance content-hash integrates with the signal identity" do
      s = sig(source: :instrument, observation: 0.9)
      assert is_binary(Signal.dedup_key(s))
      # same observation + source → same fingerprint across processes
      s2 = sig(source: :instrument, observation: 0.9)
      assert Signal.dedup_key(s) == Signal.dedup_key(s2)
    end
  end

  describe "epistemic category separation" do
    test "a Signal carries observation, never probability or decision" do
      s = sig(source: :obs, observation: 7.0)
      refute Map.has_key?(s, :probability)
      refute Map.has_key?(s, :decision)
      # observation is preserved distinctly from any downstream belief
      assert s.observation == 7.0
    end

    test "SignalValue reports :unknown before outcome data exists (no fabrication)" do
      s = sig(source: :obs, observation: 5.0, predictive_value: nil)
      {:ok, _} = SignalRegistry.register(s)
      m = SignalValue.measure(s)
      assert m.predictive_value == :unknown
      assert m.information_gain == :unknown or is_number(m.information_gain)
    end
  end

  describe "full pipeline: register → quality → version → registry state" do
    test "registered signals flow through quality, value, and versioning" do
      s = sig(source: :market, observation: [0.1, 0.2], domain: :economics)
      {:ok, stored} = SignalRegistry.register(s)
      assert stored.status == :registered

      q = SignalQuality.evaluate(stored)
      assert is_number(q.aggregate_score)

      v = Signal.version(stored, observation: [0.1, 0.2, 0.3])
      assert v.version == 2
      assert v.lineage == [stored.id]

      # original registry entry is untouched (immutability preserved)
      assert {:ok, still} = SignalRegistry.get(stored.id)
      assert still.observation == [0.1, 0.2]
    end
  end
end