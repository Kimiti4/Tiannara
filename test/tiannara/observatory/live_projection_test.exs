defmodule Tiannara.Observatory.LiveProjectionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Observatory.LiveProjection
  alias Tiannara.CEL.Services.EventBus

  test "exposes an ordered snapshot and event cursor" do
    assert %{sequence: sequence, event_count: event_count, subscribed: subscribed} = LiveProjection.status()
    assert sequence >= 0
    assert event_count >= 0
    assert is_boolean(subscribed)
    assert {:ok, %{sequence: ^sequence, entities: entities}} = LiveProjection.snapshot()
    assert is_map(entities)
    assert {:ok, events} = LiveProjection.events_since(sequence)
    assert events == []
  end

  test "rejects invalid event cursors" do
    assert {:error, :invalid_sequence} = LiveProjection.events_since(-1)
  end

  test "advances its cursor from a world event" do
    before = LiveProjection.status().sequence

    assert {:ok, _event_id, _offset} =
             EventBus.publish("world.entity.created", %{entity_id: :projection_probe})

    assert_eventually(fn -> LiveProjection.status().sequence > before end)
    assert {:ok, events} = LiveProjection.events_since(before)
    assert Enum.any?(events, &(&1.topic == "world.entity.created"))
  end

  defp assert_eventually(predicate, attempts \\ 20)
  defp assert_eventually(predicate, 0), do: assert predicate.()

  defp assert_eventually(predicate, attempts) do
    if predicate.() do
      :ok
    else
      Process.sleep(10)
      assert_eventually(predicate, attempts - 1)
    end
  end
end