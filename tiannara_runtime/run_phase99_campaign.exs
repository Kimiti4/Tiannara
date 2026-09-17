Application.ensure_all_started(:tiannara)

require Logger
Logger.info("Applying Thermodynamic Baseline...")
Tiannara.Ecology.ThermodynamicBaseline.apply()

Logger.info("Starting Instrumentation...")
Tiannara.Sentinel.D2.BasinTracker.start_link([])
Tiannara.Sentinel.D2.EpistemicResilienceTracker.start_link([])
Tiannara.Ecology.RegimeLadder.start_link([])

Logger.info("Running Campaign...")
Tiannara.Ecology.RegimeLadder.run_campaign(epochs: 10_000)

# Keep the script alive long enough for the async campaign to finish outputting
Process.sleep(2000)
