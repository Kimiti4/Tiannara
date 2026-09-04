patched = File.read!("lib/tiannara/application.ex") |> String.replace("      Tiannara.Sentinel.Supervisor,", "      Tiannara.Sentinel.Supervisor,\n\n      # Cognitive Immune System — F11 residency (AE-007)\n      Tiannara.CIS.Supervisor,")
Code.compile_string(patched)
{:ok, _} = Application.ensure_all_started(:tiannara)
Process.sleep(1500)
IO.puts("CIS present: #{Process.whereis(Tiannara.CIS.Supervisor) != nil}")
IO.inspect(Tiannara.CEL.Kernel.boot_report(), label: :boot_report)
IO.puts("EventStore healthy?: #{inspect(try do Tiannara.CEL.Services.EventStore.healthy?() catch _, e -> e end)}")
IO.puts("ExecutiveMemory health: #{inspect(try do Tiannara.CEL.Services.ExecutiveMemory.health() catch _, e -> e end)}")
IO.puts("Kernel runtime: #{inspect(try do Tiannara.CEL.Kernel.runtime_state() catch _, e -> e end)}")
# try lineage
corr = "verify_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
Tiannara.CEL.Services.ExecutiveMemory.record_event(:test_event, %{data: "x"}, %{correlation_id: corr})
Process.sleep(300)
IO.puts("Lineage: #{inspect(Tiannara.CEL.Services.ExecutiveMemory.get_lineage(corr))}")
