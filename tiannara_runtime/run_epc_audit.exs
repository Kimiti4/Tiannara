alias Tiannara.EPC.Governor
require Logger

Logger.info("\n🌌 === STARTING EPC GOVERNOR (AUDIT DEPLOYMENT) === 🌌")

# Start the Governor GenServer
{:ok, pid} = Governor.start_link([])

Logger.info("🛡️ EPC Governor is running and auditing telemetry bounds...")

# Let the GenServer run for 4 ticks to demonstrate Lyapunov bounds and stability
Process.sleep(2100)

# Stop the Governor
GenServer.stop(pid)

Logger.info("\n==================================================")
Logger.info("🌌 EPC GOVERNOR AUDIT COMPLETE 🌌")
Logger.info("==================================================")
