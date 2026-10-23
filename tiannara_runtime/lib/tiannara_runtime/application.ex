defmodule TiannaraRuntime.Application do
  @moduledoc """
  Tiannara Runtime Application
  
  Main OTP Application that starts all Tiannara systems and the Constitutional
  Observatory Platform together in a unified initialization sequence.
  
  Startup Order:
  1. Constitutional Persistence Layer (CPL) - Event journal and checkpointing
  2. Constitutional Observatory Platform (COP) - Scientific instrumentation
  3. Core Runtime Systems - Existing Tiannara subsystems
  4. Integration Verification - Confirm all systems operational
  """
  
  use Application
  require Logger
  
  def start(_type, _args) do
    Logger.info("🧠 Tiannara Runtime - Constitutional Scientific Organism Starting...")
    
    # 5F wiring W1 (operator-approved 2026-10-19): the Phase 5F.3.5 Control
    # Plane Consolidation Layer removed in 8610c558 is restored as optional
    # children, in dependency order. ChronogramMatrix boots earlier inside
    # the Meta layer (runtime_layers/supervisors.ex); the CIS arbitration
    # kernel must precede its ExecutionController/QuotaGovernor callers.
    # optional_child only skips missing modules — a failing start still
    # fails the boot. Fail-closed :noproc semantics are unchanged.
    cpl_opts =
      case Application.get_env(:tiannara_runtime, :cpl_storage_path) do
        path when is_binary(path) -> [storage_path: path]
        _ -> []
      end

    omega_opts =
      case Application.get_env(:tiannara_runtime, :omega_storage_path) do
        path when is_binary(path) -> [executive_memory: [storage_path: path]]
        _ -> []
      end

    startup_opts = cpl_opts ++ [omega_opts: omega_opts]

    children =
      [
        # Start all systems through the unified startup supervisor
        {TiannaraRuntime.StartupSupervisor, startup_opts}
      ] ++
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.CIS.Supervisor) ++
        # The unified KillSwitch (5F.3.5) is the execution layer of the kill
        # chain and must be running before the ExecutionController it calls.
        # It was never started (F-GOV-013), so the whole safety chain was
        # unreachable.
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.MultiWorld.KillSwitch) ++
        # The world supervisor is the delivery target of the kill chain. It is
        # started so an authorized termination can reach a supervised world;
        # starting the supervisor does not spawn a world (F-ARC-240).
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.MultiWorld.WorldSupervisor) ++
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.CIS.ExecutionController) ++
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.Resources.QuotaGovernor) ++
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.Memory.LineageCompression) ++
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.Causal.GCK)

    opts = [strategy: :one_for_one, name: TiannaraRuntime.Supervisor]
    
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("✅ Tiannara Runtime Started Successfully")
        {:ok, pid}
      
      {:error, reason} ->
        Logger.error("❌ Tiannara Runtime Startup Failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
