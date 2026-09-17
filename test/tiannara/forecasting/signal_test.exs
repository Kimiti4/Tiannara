defmodule Tiannara.Forecasting.SignalTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.Signal

  describe "new/1" do
    test "builds a signal with defaults" do
      s = Signal.new(source: :market, observation: 0.12)
      assert s.source == :market
      assert s.observation == 0.12
      assert s.version == 1
      assert s.status == :registered
      assert s.domain == :cross_domain
      assert s.lineage == []
      assert s.provenance.kind == :observation
      assert is_binary(s.id)
      assert is_struct(s.timestamp, DateTime)
      assert is_struct(s.received_at, DateTime)
    end

    test "preserves explicit fields" do
      now = DateTime.utc_now()
      s =
        Signal.new(
          source: :sensor,
          observation: [1.0, 2.0],
          domain: :ecology,
          reliability: 0.9,
          independence: 0.7,
          source_reliability: 0.8,
          timestamp: now,
          status: :active,
          tags: [:a, :b],
          metadata: %{k: :v}
        )

      assert s.domain == :ecology
      assert s.reliability == 0.9
      assert s.independence == 0.7
      assert s.source_reliability == 0.8
      assert s.status == :active
      assert s.timestamp == now
      assert s.tags == [:a, :b]
      assert s.metadata == %{k: :v}
    end

    test "generates unique ids" do
      a = Signal.new(source: :x, observation: 1)
      b = Signal.new(source: :x, observation: 1)
      assert a.id != b.id
    end
  end

  describe "validate/1" do
    test "accepts a valid signal" do
      assert {:ok, s} = Signal.new(source: :market, observation: 1) |> Signal.validate()
      assert s.source == :market
    end

    test "rejects a signal with missing source" do
      assert {:error, :missing_source} = Signal.new(observation: 1) |> Signal.validate()
    end

    test "rejects a signal with missing observation" do
      assert {:error, :missing_observation} = Signal.new(source: :market) |> Signal.validate()
    end

    test "rejects a malformed measurement_uncertainty" do
      s = Signal.new(source: :market, observation: 1, measurement_uncertainty: "not-a-map")
      assert {:error, :malformed_measurement_uncertainty} = Signal.validate(s)
    end

    test "accepts a valid measurement_uncertainty map" do
      s = Signal.new(source: :market, observation: 1, measurement_uncertainty: %{type: :exact})
      assert {:ok, _} = Signal.validate(s)
    end
  end

  describe "version/2" do
    test "creates a new version without overwriting the original" do
      original = Signal.new(source: :market, observation: 0.12)
      updated = Signal.version(original, observation: 0.15)

      assert updated.id != original.id
      assert updated.version == 2
      assert updated.observation == 0.15
      assert original.observation == 0.12
      assert original.version == 1
      assert original.id in updated.lineage
      assert updated.provenance.kind == :derived
      assert updated.supersedes == original.id
    end
  end

  describe "expired?/2" do
    test "never expires when expires_at is nil" do
      s = Signal.new(source: :market, observation: 1)
      assert Signal.expired?(s, DateTime.utc_now()) == false
    end

    test "expires when expires_at is in the past" do
      past = DateTime.add(DateTime.utc_now(), -3600)
      s = Signal.new(source: :market, observation: 1, expires_at: past)
      assert Signal.expired?(s, DateTime.utc_now()) == true
    end

    test "does not expire when expires_at is in the future" do
      future = DateTime.add(DateTime.utc_now(), 3600)
      s = Signal.new(source: :market, observation: 1, expires_at: future)
      assert Signal.expired?(s, DateTime.utc_now()) == false
    end
  end

  describe "dedup_key/1" do
    test "is deterministic for identical source+observation" do
      a = Signal.new(source: :market, observation: [1, 2, 3])
      b = Signal.new(source: :market, observation: [1, 2, 3])
      assert Signal.dedup_key(a) == Signal.dedup_key(b)
    end

    test "differs when source differs" do
      a = Signal.new(source: :market, observation: [1, 2, 3])
      b = Signal.new(source: :sensor, observation: [1, 2, 3])
      refute Signal.dedup_key(a) == Signal.dedup_key(b)
    end

    test "differs when observation differs" do
      a = Signal.new(source: :market, observation: [1, 2, 3])
      b = Signal.new(source: :market, observation: [1, 2, 4])
      refute Signal.dedup_key(a) == Signal.dedup_key(b)
    end
  end
end
