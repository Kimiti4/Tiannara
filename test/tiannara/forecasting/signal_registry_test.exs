defmodule Tiannara.Forecasting.SignalRegistryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Signal, SignalRegistry}

  setup do
    start_supervised!(SignalRegistry)
    :ets.delete_all_objects(:efdi_signal_registry)
    :ok
  end

  defp sig(attrs) do
    m = Map.new(attrs)
    Signal.new(Map.put(m, :id, m[:id] || "sig_#{System.unique_integer([:positive])}"))
  end

  describe "register/1" do
    test "registers and retrieves a signal" do
      s = sig(source: :market, observation: 0.12, domain: :economics)
      assert {:ok, stored} = SignalRegistry.register(s)
      assert {:ok, fetched} = SignalRegistry.get(stored.id)
      assert fetched.id == stored.id
      assert fetched.observation == 0.12
    end

    test "does not double-count an identical observation (dedup)" do
      s1 = sig(source: :market, observation: [1, 2, 3])
      {:ok, stored1} = SignalRegistry.register(s1)
      s2 = sig(source: :market, observation: [1, 2, 3])
      {:ok, stored2} = SignalRegistry.register(s2)

      # Same dedup key returns the existing signal; no double count.
      assert stored1.id == stored2.id
    end

    test "registers distinct observations from same source" do
      a = sig(source: :market, observation: [1, 2, 3])
      b = sig(source: :market, observation: [9, 8, 7])
      {:ok, _} = SignalRegistry.register(a)
      {:ok, _} = SignalRegistry.register(b)
      assert length(SignalRegistry.list_by_source(:market)) == 2
    end

    test "rejects an invalid signal" do
      s = Signal.new(observation: 1) # missing source
      assert {:error, :missing_source} = SignalRegistry.register(s)
    end
  end

  describe "query" do
    test "list_by_source" do
      {:ok, _} = SignalRegistry.register(sig(source: :sensor_a, observation: 1))
      {:ok, _} = SignalRegistry.register(sig(source: :sensor_a, observation: 2))
      {:ok, _} = SignalRegistry.register(sig(source: :sensor_b, observation: 3))

      a = SignalRegistry.list_by_source(:sensor_a)
      b = SignalRegistry.list_by_source(:sensor_b)
      assert length(a) == 2
      assert length(b) == 1
    end

    test "list_by_domain" do
      {:ok, _} = SignalRegistry.register(sig(source: :s, observation: 1, domain: :ecology))
      {:ok, _} = SignalRegistry.register(sig(source: :t, observation: 2, domain: :ecology))
      {:ok, _} = SignalRegistry.register(sig(source: :u, observation: 3, domain: :economics))

      assert length(SignalRegistry.list_by_domain(:ecology)) == 2
      assert length(SignalRegistry.list_by_domain(:economics)) == 1
    end

    test "list_in_range honors timestamps" do
      now = DateTime.utc_now()
      past = DateTime.add(now, -100)
      {:ok, _} = SignalRegistry.register(sig(source: :s, observation: 1, timestamp: past))

      from = DateTime.add(now, -200)
      to = DateTime.add(now, -50)
      assert length(SignalRegistry.list_in_range(from, to)) == 1

      far = DateTime.add(now, 100)
      assert SignalRegistry.list_in_range(far, DateTime.add(far, 1)) == []
    end

    test "list_active excludes expired signals" do
      past = DateTime.add(DateTime.utc_now(), -3600)
      {:ok, _} = SignalRegistry.register(sig(source: :s, observation: 1, expires_at: past))
      {:ok, _} = SignalRegistry.register(sig(source: :t, observation: 2))

      assert length(SignalRegistry.list_active()) == 1
    end
  end

  describe "supersede/2" do
    test "creates a new version and keeps the original" do
      {:ok, original} = SignalRegistry.register(sig(source: :market, observation: 0.12))
      {:ok, updated} = SignalRegistry.supersede(original.id, observation: 0.15)

      assert updated.version == 2
      assert updated.observation == 0.15
      assert updated.supersedes == original.id

      # Original is preserved and retrievable.
      {:ok, fetched_original} = SignalRegistry.get(original.id)
      assert fetched_original.observation == 0.12
      assert fetched_original.version == 1
    end

    test "returns :not_found for an unknown id" do
      assert {:error, :not_found} = SignalRegistry.supersede("nope", observation: 1)
    end
  end

  describe "stats/health" do
    test "stats reflect count" do
      {:ok, _} = SignalRegistry.register(sig(source: :s, observation: 1))
      {:ok, _} = SignalRegistry.register(sig(source: :s, observation: 2))
      {:ok, _} = SignalRegistry.register(sig(source: :t, observation: 3))
      stats = SignalRegistry.stats()
      assert stats.count == 3
    end

    test "health reports ets availability" do
      h = SignalRegistry.health()
      assert h.ets_available == true
    end
  end

  describe "get/1" do
    test "returns :error for unknown id" do
      assert SignalRegistry.get("unknown") == :error
    end
  end
end
