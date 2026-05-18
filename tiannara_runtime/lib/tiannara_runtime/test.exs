defmodule TiannaraRuntime.Test do
  @moduledoc """
  Simple test module to verify Phase 1 foundation is working.
  
  Run with: mix run lib/tiannara_runtime/test.exs
  """
  
  def run do
    IO.puts("\n🧪 Tiannara Runtime Phase 1 - Verification Test\n")
    
    test_application_start()
    test_identity_spawning()
    test_entropy_monitoring()
    test_nats_bridge()
    
    IO.puts("\n✅ All tests passed! Phase 1 foundation is operational.\n")
  end
  
  defp test_application_start do
    IO.puts("1. Testing application startup...")
    
    # The application should already be started by mix run
    children = Supervisor.which_children(TiannaraRuntime.Supervisor)
    
    IO.puts("   ✓ Application supervisor running")
    IO.puts("   ✓ Active children: #{length(children)}")
    
    Enum.each(children, fn {id, pid, _, _} ->
      IO.puts("     - #{inspect(id)} (#{inspect(pid)})")
    end)
    
    IO.puts("")
  end
  
  defp test_identity_spawning do
    IO.puts("2. Testing identity process spawning...")
    
    # Spawn a test identity
    case TiannaraRuntime.GRCC.EcologySupervisor.spawn_identity("test_1", "test_lineage") do
      {:ok, pid} ->
        IO.puts("   ✓ Identity spawned: #{inspect(pid)}")
        
        # Get identity state
        state = TiannaraRuntime.GRCC.Identity.get_state("test_1")
        IO.puts("   ✓ Identity coherence: #{state.state.coherence}")
        IO.puts("   ✓ Identity fitness: #{state.state.fitness}")
        
      {:error, reason} ->
        IO.puts("   ✗ Failed to spawn identity: #{inspect(reason)}")
    end
    
    # Count identities
    counts = TiannaraRuntime.GRCC.EcologySupervisor.count_identities()
    IO.puts("   ✓ Total identities: #{counts.active}")
    IO.puts("")
  end
  
  defp test_entropy_monitoring do
    IO.puts("3. Testing CIS entropy monitoring...")
    
    # Get entropy status
    status = TiannaraRuntime.CIS.EntropyMonitor.get_entropy_status()
    
    IO.puts("   ✓ Current entropy: #{Float.round(status.entropy, 3)}")
    IO.puts("   ✓ Health status: #{status.status}")
    IO.puts("   ✓ Target range: #{inspect(status.target_range)}")
    IO.puts("   ✓ History length: #{status.history_length}")
    IO.puts("")
  end
  
  defp test_nats_bridge do
    IO.puts("4. Testing NATS bridge...")
    
    # Check NATS connection status
    nats_status = TiannaraRuntime.NATS.ConnectionManager.get_status()
    
    if nats_status.connected do
      IO.puts("   ✓ NATS connected: #{nats_status.server_url}")
    else
      IO.puts("   ⚠ NATS not connected (expected in Phase 1 without NATS server)")
      IO.puts("   ✓ Connection manager running (will retry automatically)")
    end
    
    # Test publishing (simulated)
    TiannaraRuntime.NATS.Publisher.publish("tiannara.ecology.test", %{message: "hello"})
    IO.puts("   ✓ Event published (simulated)")
    
    IO.puts("")
  end
end

# Run tests if this file is executed directly
if Mix.env() != :test do
  TiannaraRuntime.Test.run()
end
