defmodule Tiannara.Validation.LifecycleInvariantTest do
  @moduledoc """
  Automated verification of lifecycle registry invariants.
  
  These tests validate that the canonical invariant holds:
    UniqueCreated - Removed = ActiveUnique
  
  Run after every architectural change to ensure constitutional compliance.
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.LifecycleRegistry
  
  setup do
    LifecycleRegistry.init_tables()
    :ets.delete_all_objects(:lifecycle_events)
    :ets.delete_all_objects(:lifecycle_state)
    :ets.delete_all_objects(:lifecycle_stats)
    :ok
  end
  
  describe "Entity Conservation Law" do
    test "invariant holds with single creation" do
      LifecycleRegistry.record_created(:capability, "cap_1", 100, %{})
      
      assert_invariant_holds(:capability, 1)
    end
    
    test "invariant holds with multiple creations" do
      Enum.each(1..10, fn i ->
        LifecycleRegistry.record_created(:capability, "cap_#{i}", 100 + i, %{})
      end)
      
      assert_invariant_holds(:capability, 10)
    end
    
    test "invariant holds after removal" do
      LifecycleRegistry.record_created(:capability, "cap_1", 100, %{})
      LifecycleRegistry.record_created(:capability, "cap_2", 200, %{})
      LifecycleRegistry.record_removed(:capability, "cap_1", 300, :selection, %{})
      
      assert_invariant_holds(:capability, 1)
    end
    
    test "invariant holds with mixed operations" do
      # Create 5 entities
      Enum.each(1..5, fn i ->
        LifecycleRegistry.record_created(:capability, "cap_#{i}", i * 100, %{})
      end)
      
      # Remove 2
      LifecycleRegistry.record_removed(:capability, "cap_1", 600, :selection, %{})
      LifecycleRegistry.record_removed(:capability, "cap_3", 700, :replacement, %{})
      
      # Expected: 5 - 2 = 3
      assert_invariant_holds(:capability, 3)
    end
    
    test "invariant holds across entity types" do
      # Create capabilities
      LifecycleRegistry.record_created(:capability, "cap_1", 100, %{})
      LifecycleRegistry.record_created(:capability, "cap_2", 200, %{})
      
      # Create theories
      LifecycleRegistry.record_created(:theory, "theory_1", 150, %{})
      
      # Verify independently
      assert_invariant_holds(:capability, 2)
      assert_invariant_holds(:theory, 1)
    end
  end
  
  describe "Rediscovery Detection" do
    test "rediscovery does not increment created counter" do
      # First creation
      LifecycleRegistry.record_created(:capability, "mathematics", 100, %{})
      
      # Attempted second creation (should be rediscovery)
      result = LifecycleRegistry.record_created(:capability, "mathematics", 200, %{})
      
      assert result == {:error, :already_exists}
      
      stats = LifecycleRegistry.get_stats(:capability)
      assert stats.created == 1
      assert stats.rediscovered == 1
      
      # Invariant should still show 1 active
      assert_invariant_holds(:capability, 1)
    end
    
    test "multiple rediscoveries tracked correctly" do
      LifecycleRegistry.record_created(:capability, "physics", 100, %{})
      
      # Three rediscoveries
      Enum.each(1..3, fn _ ->
        LifecycleRegistry.record_created(:capability, "physics", 200, %{})
      end)
      
      stats = LifecycleRegistry.get_stats(:capability)
      assert stats.created == 1
      assert stats.rediscovered == 3
      
      assert_invariant_holds(:capability, 1)
    end
    
    test "event conservation law holds" do
      LifecycleRegistry.record_created(:capability, "chem", 100, %{})
      LifecycleRegistry.record_created(:capability, "chem", 200, %{})
      LifecycleRegistry.record_created(:capability, "chem", 300, %{})
      
      stats = LifecycleRegistry.get_stats(:capability)
      
      # Created + Rediscovered = Total events for this entity
      total_events = stats.created + stats.rediscovered
      assert total_events == 4  # 1 created + 3 rediscovered (including first)
    end
  end
  
  describe "Removal Reasons" do
    test "selection removal tracked correctly" do
      LifecycleRegistry.record_created(:capability, "weak_cap", 100, %{})
      LifecycleRegistry.record_removed(:capability, "weak_cap", 200, :selection, %{
        fitness: 0.01
      })
      
      assert_invariant_holds(:capability, 0)
      
      history = LifecycleRegistry.get_history(:capability, "weak_cap")
      removal_event = Enum.find(history, fn {type, _, _} -> type == :removed end)
      
      assert removal_event != nil
      {_type, _tick, metadata} = removal_event
      assert metadata.removal_reason == :selection
    end
    
    test "promotion removal tracked correctly" do
      LifecycleRegistry.record_created(:capability, "adv_math", 100, %{})
      LifecycleRegistry.record_promoted(:capability, "adv_math", 200, :theory, %{
        theory_name: "advanced_theory"
      })
      
      # Original capability should be removed
      assert_invariant_holds(:capability, 0)
      
      # New theory should exist
      assert_invariant_holds(:theory, 1)
    end
    
    test "merge removal tracked correctly" do
      LifecycleRegistry.record_created(:capability, "cap_a", 100, %{})
      LifecycleRegistry.record_created(:capability, "cap_b", 200, %{})
      LifecycleRegistry.record_removed(:capability, "cap_a", 300, :merge, %{
        merged_into: "cap_b"
      })
      
      assert_invariant_holds(:capability, 1)
    end
  end
  
  describe "Promotion Handling" do
    test "promotion creates new entity and removes old" do
      LifecycleRegistry.record_created(:capability, "proto_theory", 100, %{})
      LifecycleRegistry.record_promoted(:capability, "proto_theory", 200, :theory, %{
        theory_id: "formal_theory"
      })
      
      # Capability removed
      cap_stats = LifecycleRegistry.get_stats(:capability)
      assert cap_stats.removed == 1
      
      # Theory created
      theory_stats = LifecycleRegistry.get_stats(:theory)
      assert theory_stats.created == 1
      
      # Both invariants hold independently
      assert_invariant_holds(:capability, 0)
      assert_invariant_holds(:theory, 1)
    end
    
    test "promotion increments promoted counter" do
      LifecycleRegistry.record_created(:capability, "promotable", 100, %{})
      LifecycleRegistry.record_promoted(:capability, "promotable", 200, :theory, %{})
      
      stats = LifecycleRegistry.get_stats(:capability)
      assert stats.promoted == 1
    end
  end
  
  describe "Query API" do
    test "get_history returns complete event log" do
      LifecycleRegistry.record_created(:capability, "tracked", 100, %{})
      LifecycleRegistry.record_created(:capability, "tracked", 200, %{})
      LifecycleRegistry.record_mutated(:capability, "tracked", 300, :update, %{})
      
      history = LifecycleRegistry.get_history(:capability, "tracked")
      
      assert length(history) == 3
      
      event_types = Enum.map(history, fn {type, _, _} -> type end)
      assert event_types == [:created, :rediscovered, :mutated]
    end
    
    test "get_lineage returns ancestry chain" do
      metadata = %{
        lineage: ["root", "parent", "child"]
      }
      
      LifecycleRegistry.record_created(:capability, "child", 100, metadata)
      
      lineage = LifecycleRegistry.get_lineage(:capability, "child")
      assert lineage == ["root", "parent", "child"]
    end
    
    test "get_survival_curve tracks cohort survival" do
      # Create cohort at tick 100
      Enum.each(1..5, fn i ->
        LifecycleRegistry.record_created(:capability, "cohort_#{i}", 100, %{})
      end)
      
      # Remove 2 at tick 200
      LifecycleRegistry.record_removed(:capability, "cohort_1", 200, :selection, %{})
      LifecycleRegistry.record_removed(:capability, "cohort_2", 200, :selection, %{})
      
      curve = LifecycleRegistry.get_survival_curve(:capability, 100)
      
      assert Map.get(curve, 100) == 5  # All alive at creation
      assert Map.get(curve, 200) == 3  # 2 removed
    end
    
    test "innovation_efficiency calculates correctly" do
      LifecycleRegistry.record_created(:capability, "novel_1", 100, %{})
      LifecycleRegistry.record_created(:capability, "novel_2", 200, %{})
      LifecycleRegistry.record_created(:capability, "novel_1", 300, %{})
      LifecycleRegistry.record_created(:capability, "novel_1", 400, %{})
      
      efficiency = LifecycleRegistry.innovation_efficiency(:capability)
      
      # 2 created / (2 created + 2 rediscovered) = 0.5
      assert_in_delta efficiency, 0.5, 0.01
    end
  end
  
  describe "Invariant Violation Detection" do
    test "raises error when invariant violated" do
      LifecycleRegistry.record_created(:capability, "cap_1", 100, %{})
      
      # Manually corrupt state (simulate bug)
      :ets.delete(:lifecycle_state, {:capability, "cap_1"})
      
      assert_raise LifecycleRegistry.LifecycleInvariantError, fn ->
        LifecycleRegistry.verify!(:capability, fn -> MapSet.new() end)
      end
    end
    
    test "provides detailed error information" do
      LifecycleRegistry.record_created(:capability, "cap_1", 100, %{})
      LifecycleRegistry.record_created(:capability, "cap_2", 200, %{})
      
      # Corrupt by removing one from lifecycle state
      :ets.delete(:lifecycle_state, {:capability, "cap_2"})
      
      try do
        LifecycleRegistry.verify!(:capability, fn ->
          MapSet.new(["cap_1", "cap_2"])
        end)
      rescue
        e ->
          assert e.entity_type == :capability
          assert e.created == 2
          assert e.expected_active == 2
          assert e.actual_active == 1
          assert "cap_2" in e.missing_from_lifecycle
      end
    end
  end
  
  describe "Edge Cases" do
    test "handles zero entities gracefully" do
      assert_invariant_holds(:capability, 0)
    end
    
    test "handles large numbers" do
      Enum.each(1..1000, fn i ->
        LifecycleRegistry.record_created(:capability, "bulk_#{i}", i, %{})
      end)
      
      assert_invariant_holds(:capability, 1000)
    end
    
    test "handles rapid creation-removal cycles" do
      Enum.each(1..100, fn i ->
        cap_id = "cycle_#{i}"
        LifecycleRegistry.record_created(:capability, cap_id, i * 10, %{})
        LifecycleRegistry.record_removed(:capability, cap_id, i * 10 + 5, :selection, %{})
      end)
      
      assert_invariant_holds(:capability, 0)
    end
    
    test "entity IDs can be any term" do
      LifecycleRegistry.record_created(:capability, :atom_id, 100, %{})
      LifecycleRegistry.record_created(:capability, {"tuple", "id"}, 200, %{})
      LifecycleRegistry.record_created(:capability, 12345, 300, %{})
      
      assert_invariant_holds(:capability, 3)
    end
  end
  
  describe "Cross-Entity-Type Isolation" do
    test "operations on one type don't affect others" do
      LifecycleRegistry.record_created(:capability, "cap_1", 100, %{})
      LifecycleRegistry.record_created(:theory, "theory_1", 200, %{})
      LifecycleRegistry.record_created(:ontology, "ont_1", 300, %{})
      
      # Remove capability
      LifecycleRegistry.record_removed(:capability, "cap_1", 400, :selection, %{})
      
      # Other types unaffected
      assert_invariant_holds(:capability, 0)
      assert_invariant_holds(:theory, 1)
      assert_invariant_holds(:ontology, 1)
    end
    
    test "stats are isolated per type" do
      LifecycleRegistry.record_created(:capability, "c1", 100, %{})
      LifecycleRegistry.record_created(:theory, "t1", 200, %{})
      LifecycleRegistry.record_removed(:capability, "c1", 300, :selection, %{})
      
      cap_stats = LifecycleRegistry.get_stats(:capability)
      theory_stats = LifecycleRegistry.get_stats(:theory)
      
      assert cap_stats.created == 1
      assert cap_stats.removed == 1
      
      assert theory_stats.created == 1
      assert theory_stats.removed == 0
    end
  end
  
  describe "Event Payload Enrichment" do
    test "metadata preserved in events" do
      rich_metadata = %{
        world_id: "world_1",
        program_id: "prog_42",
        parent_id: "parent_cap",
        discovery_id: "disc_99",
        generation: 5,
        lineage: ["root", "parent", "current"],
        fitness: 0.85,
        depth: 3
      }
      
      LifecycleRegistry.record_created(:capability, "rich_cap", 100, rich_metadata)
      
      history = LifecycleRegistry.get_history(:capability, "rich_cap")
      {_type, _tick, metadata} = List.first(history)
      
      assert metadata.world_id == "world_1"
      assert metadata.program_id == "prog_42"
      assert metadata.generation == 5
      assert metadata.fitness == 0.85
    end
    
    test "lineage tracking works across generations" do
      # Root
      LifecycleRegistry.record_created(:capability, "root", 100, %{
        lineage: ["root"]
      })
      
      # Child
      LifecycleRegistry.record_created(:capability, "child", 200, %{
        parent_id: "root",
        lineage: ["root", "child"]
      })
      
      # Grandchild
      LifecycleRegistry.record_created(:capability, "grandchild", 300, %{
        parent_id: "child",
        lineage: ["root", "child", "grandchild"]
      })
      
      child_lineage = LifecycleRegistry.get_lineage(:capability, "grandchild")
      assert child_lineage == ["root", "child", "grandchild"]
    end
  end
  
  # Helper function to verify invariant holds
  defp assert_invariant_holds(entity_type, expected_active) do
    # Mock graph size function returning expected count
    mock_graph_fn = fn -> expected_active end
    
    # Should not raise
    assert :ok = LifecycleRegistry.verify!(entity_type, mock_graph_fn)
    
    # Also verify stats match
    stats = LifecycleRegistry.get_stats(entity_type)
    calculated_active = stats.created - stats.removed - stats.promoted - stats.merged
    
    assert calculated_active == expected_active,
      "Expected #{expected_active} active, but calculated #{calculated_active} " <>
      "(created=#{stats.created}, removed=#{stats.removed}, " <>
      "promoted=#{stats.promoted}, merged=#{stats.merged})"
  end
end
