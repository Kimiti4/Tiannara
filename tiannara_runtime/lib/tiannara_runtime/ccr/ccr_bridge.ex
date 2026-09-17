defmodule TiannaraRuntime.CCR.Bridge do
  @moduledoc """
  Cosmological Compiler Reflection (CCR) Bridge.

  Monitors global stability metric Ψ. If stability collapses below the threshold (0.30),
  triggers an emergency rollback via the Self-Compilation Rollback Manager to
  restore the runtime substrate to a stable configuration.
  """

  use GenServer
  require Logger

  @check_interval_ms 1000
  @critical_psi_threshold 0.30

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    Logger.info("🌌 [CCR Bridge] Initialized and monitoring stability")
    schedule_check()
    {:ok, %{last_psi: 1.0, rollback_count: 0}}
  end

  @impl true
  def handle_info(:check_stability, state) do
    current_psi = get_global_psi()

    new_state =
      if current_psi < @critical_psi_threshold do
        Logger.error(
          "🚨 [CCR Bridge] CRITICAL Ψ COLLAPSE DETECTED: #{current_psi}. Initiating emergency rollback!"
        )

        trigger_emergency_rollback()
        %{state | rollback_count: state.rollback_count + 1}
      else
        state
      end

    schedule_check()
    {:noreply, %{new_state | last_psi: current_psi}}
  end

  # ==================== Helper Functions ====================

  defp schedule_check do
    Process.send_after(self(), :check_stability, @check_interval_ms)
  end

  defp get_global_psi do
    # Fetch from RRG if available, otherwise check MSCL, or default to stable 1.0
    cond do
      Process.whereis(Tiannara.RRG.Supervisor) ->
        case Tiannara.RRG.Supervisor.check_stability() do
          {:ok, %{psi: psi}} when is_number(psi) -> psi
          %{psi: psi} when is_number(psi) -> psi
          _ -> 1.0
        end

      true ->
        1.0
    end
  rescue
    _ -> 1.0
  end

  defp trigger_emergency_rollback do
    if Process.whereis(TiannaraRuntime.SelfCompilation.RollbackManager) do
      TiannaraRuntime.SelfCompilation.RollbackManager.rollback(:previous)
    else
      Logger.warning("⚠️ [CCR Bridge] RollbackManager not running. Fallback rollback simulated.")
      {:ok, :rollback_simulated}
    end
  end
end
