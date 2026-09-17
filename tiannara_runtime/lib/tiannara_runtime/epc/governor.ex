defmodule Tiannara.EPC.Governor do
  @moduledoc """
  Evolution Pressure Control: Governor.
  Deployable Discrete-Time GenServer.
  """
  
  use GenServer
  require Logger

  @tick_ms 500

  def start_link(init), do: GenServer.start_link(__MODULE__, init, name: __MODULE__)

  def init(state) do
    Logger.info("🛡️ [EPC Governor] Booting production-safe GenServer...")
    schedule_tick()
    {:ok, state}
  end

  def handle_info(:tick, state) do
    # 1. read ecosystem state
    s = Tiannara.EPC.StateTensor.snapshot()

    # 2. MSCL boundary check (hard safety gate)
    :ok = validate_mscl!(s)

    # 3. compute objective
    j = Tiannara.EPC.Objective.compute(s)

    # 4. estimate coupling matrix
    a_hat = Tiannara.EPC.CouplingMatrix.estimate(s)

    # 5. stability analysis
    stability = Tiannara.EPC.StabilityMonitor.check(a_hat, s)

    # 6. compute control vector (bounded)
    u_raw = Tiannara.EPC.ControlLaw.compute(s, j, a_hat, stability)
    u = clamp_control(u_raw)

    # 7. apply to OLEF + GRCC
    apply_pressure(u)

    # 8. CIS feedback logging
    log_cis(%{s: s, j: j, u: u, stability: stability})

    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_ms)
  end

  defp clamp_control(u) do
    Map.new(u, fn {k, v} ->
      {k, max(-1.0, min(1.0, v))}
    end)
  end
  
  defp validate_mscl!(s) do
    state = case :sys.get_state(Tiannara.MSCL.Supervisor) do
      %{collapse_risk: cr, critical_collapse_risk: ccr, global_pressure: gp, max_global_pressure: mgp} = st ->
        st
      _ -> %{collapse_risk: 0.0, critical_collapse_risk: 0.85, global_pressure: 0.0, max_global_pressure: 10000.0}
    end
    cond do
      state.collapse_risk >= state.critical_collapse_risk ->
        raise "MSCL violation: collapse_risk #{Float.round(state.collapse_risk, 4)} >= #{state.critical_collapse_risk}"
      state.global_pressure >= state.max_global_pressure ->
        raise "MSCL violation: global_pressure #{Float.round(state.global_pressure, 4)} >= #{state.max_global_pressure}"
      s.l > 0.95 ->
        raise "MSCL violation: MSCL load #{Float.round(s.l, 4)} exceeds 0.95"
      true ->
        :ok
    end
  end

  defp apply_pressure(u) do
    entropy_pressure = abs(Map.get(u, :entropy, 0.0))
    coherence_pressure = abs(Map.get(u, :coherence, 0.0))
    total_pressure = min(1.0, entropy_pressure + coherence_pressure)
    Tiannara.MSCL.Supervisor.report_pressure("epc_governor", total_pressure * 1000.0)
  end
  defp log_cis(data) do
    Logger.info("⚙️ [EPC TICK] J: #{Float.round(data.j, 4)} | Risk: #{Float.round(data.stability.risk, 4)}")
    Logger.debug("   -> Control Vector: #{inspect(data.u)}")
  end
end
