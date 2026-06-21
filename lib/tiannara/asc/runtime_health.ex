defmodule Tiannara.ASC.RuntimeHealth do
  @moduledoc """
  Verifies the runtime integrity of the ASC crucible ecosystem.
  """

  @services [
    {:knowledge_archive, Tiannara.ASC.KnowledgeArchive},
    {:repair_library, Tiannara.ASC.Crucible.RepairLibrary},
    {:transfer_ecology, Tiannara.ASC.Crucible.TransferEcology},
    {:adaptation_velocity, Tiannara.ASC.Crucible.AdaptationVelocity},
    {:repair_reuse_engine, Tiannara.ASC.Crucible.RepairReuseEngine},
    {:observatory, Tiannara.ASC.Crucible.Observatory}
  ]

  @doc """
  Checks if all required ASC services are alive and responsive.
  Returns a health report struct.
  """
  def check do
    results = 
      Enum.map(@services, fn {name, module} ->
        pid = Process.whereis(module)
        if pid do
          responsive = is_responsive?(module)
          {name, %{registered: true, responsive: responsive, pid: pid}}
        else
          {name, %{registered: false, responsive: false, pid: nil}}
        end
      end)
      |> Map.new()

    all_services_healthy = Enum.all?(results, fn {_, status} -> status.registered and status.responsive end)
    
    # Check RepairLibrary Memory Integrity
    memory_integrity = if results[:repair_library] && results[:repair_library].responsive do
      report = Tiannara.ASC.Crucible.RepairLibrary.population_report()
      integrity_healthy = Tiannara.ASC.Crucible.RepairLibrary.verify_integrity()
      
      IO.puts("\nRepairLibrary:")
      IO.puts("  persisted_patterns: #{report.persisted_count}")
      IO.puts("  ets_patterns: #{report.ets_count}")
      IO.puts("  unique_ids: #{report.unique_ids}")
      IO.puts("  status: #{if integrity_healthy, do: "healthy", else: "CORRUPTED"}")
      
      if not integrity_healthy do
        {_, corruption_details} = Tiannara.ASC.Crucible.RepairLibrary.detect_corruption()
        IO.puts("  corruption_details: #{inspect(corruption_details)}")
        IO.puts("\n⚠️  MEMORY INTEGRITY FAILURE\n")
      end

      %{report: report, healthy: integrity_healthy}
    else
      IO.puts("\nRepairLibrary:\n  status: UNRESPONSIVE")
      %{report: nil, healthy: false}
    end

    all_healthy = all_services_healthy and memory_integrity.healthy
    
    failed_services = 
      Enum.filter(results, fn {_, status} -> not (status.registered and status.responsive) end)
      |> Enum.map(&elem(&1, 0))

    if all_healthy do
      IO.puts("\n6/6 services healthy")
      IO.puts("RepairLibrary integrity verified")
    end

    %{
      all_healthy: all_healthy,
      services: results,
      memory_integrity: memory_integrity,
      failed_services: failed_services
    }
  end

  defp is_responsive?(module) do
    try do
      # :sys.get_state is the standard OTP way to check responsiveness 
      # without needing to implement custom :health_check calls in every module.
      case :sys.get_state(module, 1000) do
        _ -> true
      end
    catch
      :exit, _ -> false
      _, _ -> false
    end
  end
end
