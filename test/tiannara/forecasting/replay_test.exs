defmodule Tiannara.Forecasting.ReplayTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Signal, SignalRegistry, Provenance}

  setup do
    start_supervised!(SignalRegistry)
    :ets.delete_all_objects(:efdi_signal_registry)
    :ok
  end

  defp sig(attrs), do: Signal.new(attrs)

  describe "replay / lineage determinism" do
    test "deterministic content hash across registrations (reproducible)" do
      s1 = sig(source: :market, observation: [1.0, 2.0])
      s2 = sig(source: :market, observation: [1.0, 2.0])

      {:ok, r1} = SignalRegistry.register(s1)
      {:ok, r2} = SignalRegistry.register(s2)

      # dedup: identical observation from same source returns the first register
      assert r1.id == r2.id
      assert Provenance.content_hash(r1) == Provenance.content_hash(r2)
    end

    test "re-registering the same signal idempotently returns the stored record" do
      s = sig(source: :market, observation: [1.0, 2.0])
      {:ok, first} = SignalRegistry.register(s)
      {:ok, second} = SignalRegistry.register(s)
      assert first.id == second.id
      assert SignalRegistry.stats().count == 1
    end

    test "all_ids supports replay enumeration" do
      {:ok, _} = SignalRegistry.register(sig(source: :a, observation: [1]))
      {:ok, _} = SignalRegistry.register(sig(source: :b, observation: [2]))
      ids = SignalRegistry.all_ids()
      assert length(ids) == 2
    end

    test "provenance lineage is preserved through versions (no historical revisionism)" do
      original = sig(source: :market, observation: 0.1)
      {:ok, orig} = SignalRegistry.register(original)
      {:ok, v2} = SignalRegistry.supersede(orig.id, observation: 0.2)

      assert orig.id in v2.lineage
      assert v2.provenance.source_event_id == orig.id

      # The historical forecast is never overwritten.
      {:ok, fetched_orig} = SignalRegistry.get(orig.id)
      assert fetched_orig.observation == 0.1
    end
  end
end
