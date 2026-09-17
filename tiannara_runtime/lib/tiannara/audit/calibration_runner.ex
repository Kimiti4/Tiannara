defmodule Tiannara.Audit.CalibrationRunner do
  @moduledoc """
  Failure Injection DSL & Live Ecological Calibration Harness.
  Injects controlled faults to verify MSCL/OLEF/CIS closed-loop negative feedback stability.
  """
  alias Tiannara.EventBus
  require Logger

  @doc """
  Injects an entropy spike to test CIS diffusion recovery.
  """
  def inject_entropy_spike do
    Logger.info("💉 Injecting Entropy Spike into GRCC...")
    send(Process.whereis(Tiannara.GRCC.EntropyController), {:entropy_tick, 0.95})
  end

  @doc """
  Injects a massive pressure surge to test OLEF diffusion and A10 drift detection.
  """
  def inject_pressure_surge do
    Logger.info("🌊 Injecting Pressure Surge into OLEF...")
    GenServer.cast(Tiannara.OLEF.PressureSolver, {:pressure_update, 500.0})
  end

  @doc """
  Simulates a hard fault in the MSCL ConstraintEngine without actually killing the process,
  preserving causal tracing.
  """
  def simulate_constraint_fault do
    Logger.info("💥 Simulating MSCL ConstraintEngine Hard Fault...")
    send(Process.whereis(Tiannara.MSCL.ConstraintEngine), {:simulate_failure, :constraint_engine, :hard_fault})
  end
end
