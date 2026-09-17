# Phase 5C.7 — ASC Runtime Consolidation Test
# Verifies all ASC services can be started and remain healthy

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🧬 PHASE 5C.7 — ASC RUNTIME CONSOLIDATION TEST")
IO.puts(String.duplicate("=", 80))

# Step 1: Enable ASC feature flag
IO.puts("\n📋 Step 1: Enabling ASC feature flag...")
Application.put_env(:tiannara, :asc, enabled: true)
IO.puts("✅ ASC feature flag enabled")

# Step 2: Start Tiannara application
IO.puts("\n📋 Step 2: Starting Tiannara application...")
{:ok, _apps} = Application.ensure_all_started(:tiannara)
IO.puts("✅ Tiannara application started")

# Step 3: Bootstrap ASC runtime
IO.puts("\n📋 Step 3: Bootstrapping ASC runtime...")
case Tiannara.ASC.Runtime.bootstrap() do
  :ok ->
    IO.puts("✅ ASC runtime bootstrap successful")
  {:error, reason} ->
    IO.puts("❌ ASC runtime bootstrap failed: #{inspect(reason)}")
    System.halt(1)
end

# Step 4: Run health check
IO.puts("\n📋 Step 4: Running comprehensive health check...")
case Tiannara.ASC.Runtime.health_check() do
  :ok ->
    IO.puts("\n✅ All ASC services healthy")
  {:error, reason} ->
    IO.puts("\n❌ Health check failed: #{inspect(reason)}")
    System.halt(1)
end

# Step 5: Verify process registration
IO.puts("\n📋 Step 5: Verifying process registration...")
services_to_check = [
  "Tiannara.ASC.Crucible.KnowledgeArchive",
  "Tiannara.ASC.Crucible.Observatory",
  "Tiannara.ASC.Crucible.TransferEcology",
  "Tiannara.ASC.Crucible.RepairLibrary"
]

all_registered = Enum.all?(services_to_check, fn service_name ->
  module = String.to_atom(service_name)
  pid = Process.whereis(module)
  registered = pid != nil && Process.alive?(pid)
  
  status = if registered do
    "✅ REGISTERED (#{inspect(pid)})"
  else
    "❌ NOT REGISTERED"
  end
  
  IO.puts("   #{String.pad_trailing(service_name, 60)} #{status}")
  registered
end)

if all_registered do
  IO.puts("\n✅ All critical services registered and alive")
else
  IO.puts("\n❌ Some services not properly registered")
  System.halt(1)
end

# Step 6: Stability test - verify services survive 5 seconds
IO.puts("\n📋 Step 6: Testing service stability (5 second hold)...")
Process.sleep(5000)

still_alive = Enum.all?(services_to_check, fn service_name ->
  module = String.to_atom(service_name)
  pid = Process.whereis(module)
  alive = pid != nil && Process.alive?(pid)
  
  unless alive do
    IO.puts("   ❌ #{service_name} died during stability test")
  end
  
  alive
end)

if still_alive do
  IO.puts("✅ All services survived stability test")
else
  IO.puts("❌ Some services crashed during stability period")
  System.halt(1)
end

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🎉 PHASE 5C.7 VALIDATION SUCCESSFUL!")
IO.puts("=" <> String.duplicate("=", 79))
IO.puts("\nASC Runtime is now consolidated and stable.")
IO.puts("All crucible components bootable from single supervision tree.")
IO.puts("\nPhase 5C.6 validation campaigns can now proceed with confidence.\n")
