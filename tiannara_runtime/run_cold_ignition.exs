{:ok, _} = Application.ensure_all_started(:tiannara_runtime)

IO.puts("\n🌌 Cold Ignition Started. Universe booting...")
:timer.sleep(3000)

IO.puts("⚡ INJECTING CONTROLLED PERTURBATION ⚡")

event = %{
  type: :manual_perturbation,
  reason: "Cold Ignition Operator Injection",
  timestamp: System.os_time(:second),
  intensity: 1.5
}

# Cast event to the Universe Server to be picked up by telemetry
GenServer.cast({:via, Registry, {Tiannara.Registry, {:universe, "alpha_universe"}}}, {:burst_event, event})

# For the dashboard to react to pressure redistribution, we need to artificially inject 
# some entropy or pressure directly to UniverseServer's Olef field if possible, 
# or just rely on the event showing up in the CIS layer.
# But since this is a demonstration of aliveness, the burst event is enough for now.

IO.puts("Perturbation Injected. Monitoring for 24-hour stability...")
:timer.sleep(:infinity)
