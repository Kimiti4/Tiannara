IO.puts("Checkpointer module loaded: #{Code.ensure_loaded?(Tiannara.CRAV.SoakCheckpointer)}")
IO.puts("Checkpointer alive: #{Process.whereis(Tiannara.CRAV.SoakCheckpointer) != nil}")
IO.puts("SoakTest module loaded: #{Code.ensure_loaded?(Tiannara.CRAV.SoakTest)}")
IO.puts("SoakTest alive: #{Process.whereis(Tiannara.CRAV.SoakTest) != nil}")
IO.puts("Test save...")
case Tiannara.CRAV.SoakCheckpointer.save(%{test: true, ts: DateTime.utc_now()}) do
  :ok -> IO.puts("Save OK")
  err -> IO.puts("Save failed: #{inspect(err)}")
end
IO.puts("Test load...")
case Tiannara.CRAV.SoakCheckpointer.load() do
  {:ok, data} -> IO.puts("Load OK: #{inspect(data)}")
  err -> IO.puts("Load failed: #{inspect(err)}")
end
IO.puts("Done")
