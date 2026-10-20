defmodule TiannaraRuntime.Monitoring.TelemetryPublisherTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.Monitoring.TelemetryPublisher

  setup do
    if is_nil(Process.whereis(TelemetryPublisher)) do
      start_supervised!(TelemetryPublisher)
    end
    :ok
  end

  test "returns metrics map with valid structure" do
    metrics = TelemetryPublisher.get_metrics()

    assert is_map(metrics)
    assert is_map(metrics[:grcc])
    assert metrics[:grcc][:channel] == :grcc
    assert is_map(metrics[:olef])
    assert is_number(metrics[:olef][:pressure])
    assert is_map(metrics[:cis])
    assert is_integer(metrics[:cis][:anomaly_count])
  end

  test "ticks without crashing" do
    Process.sleep(150)
    assert Process.alive?(Process.whereis(TelemetryPublisher))
  end
end
