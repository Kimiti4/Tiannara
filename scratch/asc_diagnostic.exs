defmodule AscDiagnostic do
  def check do
    IO.puts("Starting ASC Diagnostic...")
    
    Application.put_env(:tiannara, :asc, enabled: true)
    
    {:ok, _} = Application.ensure_all_started(:tiannara)
    
    # Wait for supervisor tree to settle
    Process.sleep(1000)
    
    services = [
      {"Observatory", Tiannara.ASC.Crucible.Observatory},
      {"TransferEcology", Tiannara.ASC.Crucible.TransferEcology},
      {"RepairLibrary", Tiannara.ASC.Crucible.RepairLibrary},
      {"KnowledgeArchive", Tiannara.ASC.KnowledgeArchive},
      {"AdaptationVelocity", Tiannara.ASC.Crucible.AdaptationVelocity},
      {"RepairReuseEngine", Tiannara.ASC.Crucible.RepairReuseEngine}
    ]
    
    IO.puts("\n=== ASC Runtime Diagnostic ===")
    
    results = Enum.map(services, fn {name, module} ->
      pid = Process.whereis(module)
      status = if pid, do: "ALIVE (#{inspect(pid)})", else: "DEAD/NOT REGISTERED"
      IO.puts("#{String.pad_trailing(name, 20)} : #{status}")
      {name, pid}
    end)
    
    alive_count = Enum.count(results, fn {_, pid} -> pid != nil end)
    
    IO.puts("------------------------------")
    IO.puts("#{alive_count}/#{length(services)} services healthy")
    IO.puts("==============================\n")
  end
end

AscDiagnostic.check()
