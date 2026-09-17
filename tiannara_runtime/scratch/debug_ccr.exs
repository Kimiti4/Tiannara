IO.puts("--- DEBUG CCR ---")
alias TiannaraRuntime.CCR.Tracker
IO.inspect(Tracker, label: "Tracker Module")
IO.inspect(Process.whereis(Tracker), label: "whereis Tracker")
try do
  if not Process.whereis(Tracker) do
    IO.puts("Tracker not running, starting it...")
    # let's try to start it manually
    Tracker.start_link()
  else
    IO.puts("Tracker is already running!")
  end
rescue
  e -> IO.inspect(e, label: "Error starting Tracker")
end
