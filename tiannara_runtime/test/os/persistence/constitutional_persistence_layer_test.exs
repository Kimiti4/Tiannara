defmodule TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayerTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer

  test "records an event and attaches a hash without crashing" do
    assert {:ok, event} = ConstitutionalPersistenceLayer.record_event(:sentinel_event, %{job: :runtime_metrics})
    assert is_binary(event.hash)
    assert is_binary(event.previous_hash)
    assert event.event_type == :sentinel_event
  end
end
