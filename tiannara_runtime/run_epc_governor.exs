alias Tiannara.EPC.Governor
require Logger

Logger.info("\n🌌 === STARTING EPC GOVERNOR (DISCRETE-TIME CONTROL) === 🌌")

# Start the Governor GenServer
{:ok, pid} = Governor.start_link([])

Logger.info("🛡️ EPC Governor is running and polling telemetry...")
Logger.info("-> Ticks 0-2 will simulate normal 'Balance Mode'.")
Logger.info("-> Tick 3 will simulate a massive dominance spike, forcing 'Containment Mode'.")

# Let the GenServer run for a few ticks to demonstrate stability and mode switching
Process.sleep(5000)

# Stop the Governor
GenServer.stop(pid)

Logger.info("\n==================================================")
Logger.info("🌌 EPC GOVERNOR SIMULATION COMPLETE 🌌")
Logger.info("==================================================")
