# Diagnostic: Test TransferEcology lifecycle

IO.puts("\n🔍 Testing TransferEcology lifecycle...\n")

# Start TransferEcology
{:ok, pid} = Tiannara.ASC.Crucible.TransferEcology.start_link()

IO.inspect(pid, label: "PID")
IO.inspect(Process.alive?(pid), label: "Alive immediately")

Process.sleep(2000)

IO.inspect(Process.alive?(pid), label: "Alive after 2 seconds")
IO.inspect(Process.whereis(Tiannara.ASC.Crucible.TransferEcology), label: "Registered name")

# Try to get metrics
try do
  result = GenServer.call(Tiannara.ASC.Crucible.TransferEcology, :get_metrics, 5000)
  IO.inspect(result, label: "Metrics result", limit: :infinity, pretty: true)
  IO.puts("\n✅ SUCCESS - TransferEcology is working correctly\n")
rescue
  e ->
    IO.puts("\n❌ FAILED - #{inspect(e)}\n")
end
