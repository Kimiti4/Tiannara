# priv/boot_verification.exs
# Live Ecological Runtime Verification Harness
# Boots the Minimal Ecological Kernel (MEK) and traces system recovery

require Logger

# 1. Attach Telemetry Handlers
defmodule Tiannara.Telemetry.LiveMonitor do
  def handle_event([:tiannara, :a10, :phase_change], measurements, metadata, _config) do
    Logger.warning("A10 Phase Transition: #{inspect(metadata.phase)} | Drift Mag: #{measurements.magnitude} | Elasticity: #{measurements.elasticity}")
  end
  
  def handle_event([:tiannara, :cis, :immune_action], _measurements, metadata, _config) do
    Logger.notice("CIS Immune Intervention: #{inspect(metadata.decision)}")
  end
end

# Ensure base dependencies are started without booting the main application
Application.ensure_all_started(:telemetry)
Application.ensure_all_started(:logger)

:telemetry.attach(
  "a10-live-monitor",
  [:tiannara, :a10, :phase_change],
  &Tiannara.Telemetry.LiveMonitor.handle_event/4,
  nil
)

:telemetry.attach(
  "cis-live-monitor",
  [:tiannara, :cis, :immune_action],
  &Tiannara.Telemetry.LiveMonitor.handle_event/4,
  nil
)

Logger.info("Starting Minimal Ecological Kernel (MEK) in Isolation...")

# 2. Boot MEK (Ensure it's not already started)
pid = case Tiannara.P9XEcosystem.Supervisor.start_link([]) do
  {:ok, pid} -> 
    Logger.info("MEK Booted. PID: #{inspect(pid)}")
    pid
  {:error, {:already_started, pid}} ->
    Logger.info("MEK was already running. PID: #{inspect(pid)}")
    pid
end

# Wait for stabilization
Process.sleep(1000)

Logger.info("--- Initiating Calibration Tests ---")

# 3. Test A: Pressure Surge (Should trigger Phase D and CIS recovery)
Tiannara.Audit.CalibrationRunner.inject_pressure_surge()

Process.sleep(2000)

# 4. Test B: Entropy Spike
Tiannara.Audit.CalibrationRunner.inject_entropy_spike()

Process.sleep(2000)

# 5. Test C: Hard Fault Simulation
Tiannara.Audit.CalibrationRunner.simulate_constraint_fault()

Process.sleep(2000)

Logger.info("--- Verification Sequence Complete. Shutting down MEK. ---")
Process.exit(pid, :normal)
