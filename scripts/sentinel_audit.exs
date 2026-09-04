defmodule Tiannara.SentinelTest do
  @moduledoc """
  Verifies the Sentinel's ability to detect and triage anomalies.
  """
  require Logger

  def run_audit do
    Logger.info("🧪 [AUDIT] Starting Sentinel Architectural Audit...")

    # 1. Simulate MSCL pressure anomaly
    Logger.info("🧪 [AUDIT] Simulating MSCL pressure anomaly...")
    Tiannara.Sentinel.TelemetryHub.broadcast(:mscl, :pressure, %{value: 0.98})
    
    # 2. Simulate GRCC diversity anomaly
    Logger.info("🧪 [AUDIT] Simulating GRCC diversity anomaly...")
    Tiannara.Sentinel.TelemetryHub.broadcast(:grcc, :diversity, %{entropy: 0.15})
    
    # 3. Simulate CTL consistency anomaly
    Logger.info("🧪 [AUDIT] Simulating CTL consistency anomaly...")
    Tiannara.Sentinel.TelemetryHub.broadcast(:ctl, :consistency, %{divergence: 0.75})

    # Wait for async processing
    Process.sleep(1000)
    Logger.info("🧪 [AUDIT] Sentinel Audit complete. Check logs for triage results.")
  end
end

Tiannara.SentinelTest.run_audit()
