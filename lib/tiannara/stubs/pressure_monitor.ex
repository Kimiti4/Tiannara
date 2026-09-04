defmodule Tiannara.Sentinel.PressureMonitor do
  use Tiannara.Stub, subsystem: :sentinel, phase: "Omega+", priority: :high

  def get_latest_deltas do
    stub_result(:get_latest_deltas, [], %{tick: System.monotonic_time(:millisecond), worlds: []})
  end
end
