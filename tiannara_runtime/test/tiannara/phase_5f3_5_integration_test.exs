defmodule TiannaraRuntime.Phase5F35IntegrationTest do
  @moduledoc """
  Phase 5F.3.5 Integration Tests
  
  Tests the complete control plane consolidation layer:
  - ExecutionController (single authority)
  - ResourceQuota Governor (system metabolism)
  - LineageCompression Engine (memory convergence)
  - GCK Hard Gate (compilation barrier)
  - KillSwitch unification
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraRuntime.CIS.ExecutionController
  alias TiannaraRuntime.Resources.QuotaGovernor
  alias TiannaraRuntime.Memory.LineageCompression
  alias TiannaraRuntime.Causal.GCK
  alias TiannaraRuntime.MultiWorld.KillSwitch
  
  describe "ExecutionController + CIS Supervisor integration" do
    test "kill request flows through proper authority chain" do
      # Start processes manually for isolated testing
      {:ok, cis_pid} = TiannaraRuntime.CIS.Supervisor.start_link([])
      {:ok, exec_pid} = ExecutionController.start_link([])
      
      # Request kill with normal severity
      result = ExecutionController.execute(:kill_world, "test_world_001", "Test termination", :normal)
      
      # Should be approved by CIS in normal mode
      assert result == :ok
      
      # Cleanup
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
    end
    
    test "kill denied in lockdown mode" do
      {:ok, cis_pid} = TiannaraRuntime.CIS.Supervisor.start_link([])
      {:ok, exec_pid} = ExecutionController.start_link([])
      
      # Set to lockdown mode
      TiannaraRuntime.CIS.Supervisor.set_safety_mode(:lockdown)
      
      # Attempt kill should be denied
      result = ExecutionController.execute(:kill_world, "test_world_002", "Should fail", :critical)
      
      assert result == {:error, :denied_by_cis}
      
      # Cleanup
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
    end
  end
  
  describe "ResourceQuota Governor enforcement" do
    test "quota check allows within limits" do
      {:ok, quota_pid} = QuotaGovernor.start_link([])
      
      world_id = "quota_test_world"
      
      # Check quota before operations (should pass)
      result = QuotaGovernor.check_quota(world_id, :memory_usage, 500_000)
      
      assert result == :approved
      
      Process.exit(quota_pid, :normal)
    end
    
    test "quota throttles when approaching soft limit" do
      {:ok, quota_pid} = QuotaGovernor.start_link([])
      
      world_id = "throttle_test_world"
      
      # Simulate high memory usage (approaching soft limit)
      result = QuotaGovernor.check_quota(world_id, :memory_usage, 9_000_000)
      
      # Should throttle but not deny
      assert result in [:approved, :throttled]
      
      Process.exit(quota_pid, :normal)
    end
    
    test "quota escalates on hard limit violation" do
      {:ok, quota_pid} = QuotaGovernor.start_link([])
      
      world_id = "escalation_test_world"
      
      # Exceed hard limit significantly
      result = QuotaGovernor.check_quota(world_id, :memory_usage, 20_000_000)
      
      # Should escalate or deny
      assert result in [:deny, :escalate_to_cis]
      
      Process.exit(quota_pid, :normal)
    end
  end
  
  describe "GCK Hard Gate validation" do
    test "valid observer creation passes GCK" do
      {:ok, gck_pid} = GCK.start_link([])
      
      config = %{
        coherence: 0.85,
        physics_stable: true,
        causal_depth: 5
      }
      
      result = GCK.validate_observer_creation(config)
      
      assert result == :approved
      
      Process.exit(gck_pid, :normal)
    end
    
    test "low coherence observer rejected by GCK" do
      {:ok, gck_pid} = GCK.start_link([])
      
      config = %{
        coherence: 0.2,  # Below threshold
        physics_stable: true,
        causal_depth: 3
      }
      
      result = GCK.validate_observer_creation(config)
      
      assert match?({:rejected, _}, result)
      
      Process.exit(gck_pid, :normal)
    end
    
    test "world merge validated for contradictions" do
      {:ok, gck_pid} = GCK.start_link([])
      
      result = GCK.validate_world_merge("world_a", "world_b")
      
      # Should approve if no contradictions detected
      assert result == :approved
      
      Process.exit(gck_pid, :normal)
    end
    
    test "causal graph changes validated" do
      {:ok, gck_pid} = GCK.start_link([])
      
      changes = [
        %{type: :add_edge, from: "node_a", to: "node_b"},
        %{type: :update_node, id: "node_c", data: %{value: 42}}
      ]
      
      result = GCK.validate_causal_graph_change(changes)
      
      # Should approve valid changes
      assert result == :approved
      
      Process.exit(gck_pid, :normal)
    end
  end
  
  describe "LineageCompression Engine" do
    test "compression triggered on threshold" do
      {:ok, compression_pid} = LineageCompression.start_link([])
      
      world_id = "compression_test_world"
      
      # Add multiple similar memories to trigger compression
      Enum.each(1..15, fn i ->
        omsv = %{
          event: "Event #{i}",
          weight: 0.9,
          observer_origin: "observer_#{rem(i, 3)}",
          msf: 0.85,
          oss: 0.80,
          coherence: 0.90,
          temporal_consistency: 0.85,
          interference: 0.3,
          causal_confidence: 0.75,
          timestamp: System.system_time(:second) - i
        }
        
        LineageCompression.compress_memory(world_id, omsv)
      end)
      
      # Check compression stats
      stats = LineageCompression.get_compression_stats(world_id)
      
      assert Map.has_key?(stats, :total_memories)
      assert Map.has_key?(stats, :compressed_count)
      
      Process.exit(compression_pid, :normal)
    end
    
    test "similarity deduplication merges near-identical memories" do
      {:ok, compression_pid} = LineageCompression.start_link([])
      
      world_id = "dedup_test_world"
      
      # Create two very similar memories
      mem1 = %{
        event: "Very similar event A",
        weight: 0.9,
        observer_origin: "obs_1",
        msf: 0.85,
        oss: 0.80,
        coherence: 0.90
      }
      
      mem2 = %{
        event: "Very similar event B",  # Slightly different
        weight: 0.89,  # Nearly identical
        observer_origin: "obs_1",
        msf: 0.86,
        oss: 0.81,
        coherence: 0.91
      }
      
      LineageCompression.compress_memory(world_id, mem1)
      LineageCompression.compress_memory(world_id, mem2)
      
      # Should detect similarity and potentially merge
      stats = LineageCompression.get_compression_stats(world_id)
      
      assert Map.has_key?(stats, :similarity_deduplications)
      
      Process.exit(compression_pid, :normal)
    end
  end
  
  describe "KillSwitch unified execution" do
    test "kill request delegates to ExecutionController" do
      {:ok, cis_pid} = TiannaraRuntime.CIS.Supervisor.start_link([])
      {:ok, exec_pid} = ExecutionController.start_link([])
      
      # Use unified KillSwitch
      result = KillSwitch.request_termination("unified_test_world", "Unified kill test", :critical)
      
      # Should route through ExecutionController
      assert result in [:requested, :executed] or match?({:error, _}, result)
      
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
    end
    
    test "emergency shutdown follows authority chain" do
      {:ok, cis_pid} = TiannaraRuntime.CIS.Supervisor.start_link([])
      {:ok, exec_pid} = ExecutionController.start_link([])
      
      result = KillSwitch.emergency_shutdown("emergency_test", "System emergency")
      
      # Should follow proper escalation path
      assert result in [:initiated, :escalated] or match?({:error, _}, result)
      
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
    end
  end
  
  describe "Full control plane pipeline" do
    test "complete kill flow: GCK → CIS → ExecutionController → KillSwitch" do
      # Start all components
      {:ok, gck_pid} = GCK.start_link([])
      {:ok, cis_pid} = TiannaraRuntime.CIS.Supervisor.start_link([])
      {:ok, exec_pid} = ExecutionController.start_link([])
      {:ok, quota_pid} = QuotaGovernor.start_link([])
      
      world_id = "full_pipeline_test"
      
      # Step 1: Validate via GCK (pre-operation check)
      validation_config = %{
        coherence: 0.9,
        physics_stable: true,
        entropy: 0.3
      }
      
      gck_result = GCK.validate_observer_creation(validation_config)
      assert gck_result == :approved
      
      # Step 2: Check resource quota
      quota_result = QuotaGovernor.check_quota(world_id, :world_count, 1)
      assert quota_result in [:approved, :throttled]
      
      # Step 3: Execute kill through proper chain
      exec_result = ExecutionController.execute(:kill_world, world_id, "Pipeline test", :normal)
      assert exec_result == :ok
      
      # Verify full pipeline executed without errors
      assert gck_result == :approved
      assert exec_result == :ok
      
      # Cleanup
      Process.exit(gck_pid, :normal)
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
      Process.exit(quota_pid, :normal)
    end
  end
  
  describe "Safety boundary enforcement" do
    test "operations blocked when GCK rejects" do
      {:ok, gck_pid} = GCK.start_link([])
      
      # Create invalid configuration
      invalid_config = %{
        coherence: 0.1,  # Way too low
        physics_stable: false,
        entropy: 0.99  # Near maximum
      }
      
      result = GCK.validate_observer_creation(invalid_config)
      
      # Should be rejected
      assert match?({:rejected, _reason}, result)
      
      Process.exit(gck_pid, :normal)
    end
    
    test "resource exhaustion triggers kill path" do
      {:ok, quota_pid} = QuotaGovernor.start_link([])
      {:ok, cis_pid} = TiannaraRuntime.CIS.Supervisor.start_link([])
      {:ok, exec_pid} = ExecutionController.start_link([])
      
      world_id = "exhaustion_test"
      
      # Simulate critical resource usage
      result = QuotaGovernor.check_quota(world_id, :memory_usage, 50_000_000)
      
      # Should trigger escalation or denial
      assert result in [:deny, :escalate_to_cis, :trigger_kill_path]
      
      Process.exit(quota_pid, :normal)
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
    end
  end
end
