# Phase 5C.6 Validation Sprint - Wrapper Script
# Uses ASC Runtime bootstrap for reliable service startup

IO.puts("\n🔧 Starting Tiannara application with ASC enabled...")

# Enable ASC feature flag BEFORE starting the application
Application.put_env(:tiannara, :asc, enabled: true)

# Start the entire Tiannara application
{:ok, _apps} = Application.ensure_all_started(:tiannara)
IO.puts("✅ Tiannara application started\n")

# Bootstrap ASC runtime (starts all crucible GenServers)
IO.puts("🔧 Bootstrapping ASC runtime...")
case Tiannara.ASC.Runtime.bootstrap() do
  :ok -> IO.puts("✅ ASC runtime ready\n")
  {:error, reason} ->
    IO.puts("❌ ASC runtime bootstrap failed: #{inspect(reason)}")
    System.halt(1)
end

# Load and execute validation
Code.require_file("scripts/validation_phase5c6_sprint.exs")
Tiannara.ASC.Campaign.Phase5C6Validation.run_validation()
