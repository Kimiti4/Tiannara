defmodule Tiannara.Sentinel.ObservationBufferTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.ObservationBuffer

  setup do
    ObservationBuffer.clear()
    :ok
  end

  describe "ObservationBuffer" do
    test "append and recent" do
      obs = %{id: "test1", type: :vm_health, value: %{x: 1}, timestamp: DateTime.utc_now()}
      assert :ok = ObservationBuffer.append(obs)
      assert ObservationBuffer.recent(10) == [obs]
    end

    test "recent returns most recent N" do
      Enum.each(1..5, fn i ->
        ObservationBuffer.append(%{id: "t#{i}", type: :test, value: %{n: i}, timestamp: DateTime.utc_now()})
      end)
      assert length(ObservationBuffer.recent(3)) == 3
    end

    test "by_type filters observations" do
      ObservationBuffer.append(%{id: "m1", type: :memory_pressure, value: %{}, timestamp: DateTime.utc_now()})
      ObservationBuffer.append(%{id: "v1", type: :vm_health, value: %{}, timestamp: DateTime.utc_now()})
      assert length(ObservationBuffer.by_type(:memory_pressure)) == 1
      assert length(ObservationBuffer.by_type(:vm_health)) == 1
    end

    test "total_observations returns count" do
      ObservationBuffer.clear()
      Enum.each(1..3, fn i ->
        ObservationBuffer.append(%{id: "t#{i}", type: :test, value: %{}, timestamp: DateTime.utc_now()})
      end)
      assert ObservationBuffer.total_observations() >= 3
    end

    test "status returns buffer info" do
      status = ObservationBuffer.status()
      assert Map.has_key?(status, :current_size)
      assert Map.has_key?(status, :max_size)
      assert Map.has_key?(status, :total_received)
      assert Map.has_key?(status, :total_evicted)
    end

    test "clear removes all data" do
      ObservationBuffer.append(%{id: "c1", type: :test, value: %{}, timestamp: DateTime.utc_now()})
      assert :ok = ObservationBuffer.clear()
      assert ObservationBuffer.recent() == []
    end
  end
end
