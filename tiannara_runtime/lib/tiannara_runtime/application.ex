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
    
    children = [
      # Start all systems through the unified startup supervisor
      {TiannaraRuntime.StartupSupervisor, []}
    ]
    
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
