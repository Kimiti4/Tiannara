defmodule Tiannara.ASC.Runtime do
  @moduledoc """
  ASC Runtime Bootstrap & Health Check
  
  Ensures all ASC crucible components are properly started and healthy
  before any validation campaign begins.
  
  This module consolidates the ASC supervision tree so that:
  - All GenServers are registered with proper names
  - Dependencies start in correct order via the Supervisor
  - Health checks verify ecosystem integrity
  - Campaigns can assume a stable runtime environment
  """

  require Logger

  alias Tiannara.ASC.RuntimeHealth

  @doc """
  Bootstrap the entire ASC runtime ecosystem.
  
  Starts all required GenServers in dependency order via Supervisor and verifies
  they remain alive after initialization.
  
  Raises if the runtime cannot be fully initialized.
  """
  def bootstrap do
    Logger.info("[ASC Runtime] Bootstrapping ASC civilization runtime...")
    
    # 1. Enable ASC flag
    Application.put_env(:tiannara, :asc, true)
    
    # 2. Ensure application and supervisor tree are started
    {:ok, _} = Application.ensure_all_started(:tiannara)
    
    # 3. Wait for supervisor tree to settle
    Process.sleep(500)
    
    # 4. Enforce strict health check
    health = RuntimeHealth.check()
    
    case health.all_healthy do
      true ->
        Logger.info("[ASC Runtime] ✅ ASC runtime bootstrap successful")
        IO.puts("\n✅ ASC Runtime Bootstrap Complete\n")
        display_runtime_status()
        :ok
        
      false ->
        error_details = if health.memory_integrity && not health.memory_integrity.healthy do
          "Memory integrity failure in RepairLibrary."
        else
          "Missing or unresponsive services: #{inspect(health.failed_services)}"
        end
        
        error_msg = """
        ASC runtime unhealthy.
        
        #{error_details}
        """
        Logger.error("[ASC Runtime] ❌ Bootstrap failed:\n#{error_msg}")
        raise error_msg
    end
  end

  @doc """
  Perform comprehensive health check on all ASC services.
  """
  def health_check do
    RuntimeHealth.check()
  end

  @doc """
  Returns a snapshot string of the current runtime state.
  """
  def snapshot do
    health = RuntimeHealth.check()
    
    output = ["ASC Runtime Snapshot", "--------------------"]
    
    lines = Enum.map(health.services, fn {service, status} ->
      service_name = String.pad_trailing(format_service_name(service), 22)
      state_str = if status.registered and status.responsive, do: "UP", else: "DOWN"
      "#{service_name} #{state_str}"
    end)
    
    output = output ++ lines
    output = output ++ [""]
    
    healthy_count = Enum.count(health.services, fn {_, s} -> s.registered and s.responsive end)
    total_count = map_size(health.services)
    
    output = output ++ ["#{healthy_count}/#{total_count} services healthy"]
    
    Enum.join(output, "\n")
  end

  @doc """
  Display current runtime status for debugging.
  """
  def display_runtime_status do
    IO.puts(snapshot())
  end
  
  defp format_service_name(atom) do
    atom
    |> Atom.to_string()
    |> Macro.camelize()
  end
end
