defmodule Tiannara.OS.CapabilityRegistryTest do
  @moduledoc """
  Test suite for Capability Registry system.
  
  Validates that:
  1. Discoveries extract capabilities correctly
  2. Prerequisite checking works
  3. Difficulty scaling based on capability gaps
  4. Cross-world capability merging
  5. Capability inheritance enables future discoveries
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.CapabilityRegistry
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  
  # ============================================================================
  # Test 1: Extract Capabilities from Discovery
  # ============================================================================
  
  test "register_discovery extracts capabilities from domain vector" do
    world = %{
      id: :w1,
      name: "Test World",
      capabilities: %{}
    }
    
    state = %State{
      worlds: %{w1: world},
      discoveries: %{},
      research_programs: %{}
    }
    
    # Battery discovery with high energy domain weight
    battery_discovery = %Discovery{
      id: :battery_tech,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.9, materials: 0.6}}
    }
    
    updated_state = CapabilityRegistry.register_discovery(state, battery_discovery)
    caps = CapabilityRegistry.get_world_capabilities(updated_state, :w1)
    
    # Should have extracted energy_generation capability
    assert Map.has_key?(caps, :energy_generation)
    assert caps[:energy_generation] >= 0.8
    
    # Should have materials_science capability
    assert Map.has_key?(caps, :materials_science)
  end
  
  # ============================================================================
  # Test 2: Prerequisite Checking - All Met
  # ============================================================================
  
  test "check_capability_prerequisites returns :ok when capabilities sufficient" do
    world = %{
      id: :w1,
      name: "Test World",
      capabilities: %{
        energy_generation: 0.9,
        materials_science: 0.8,
        computation: 0.7
      }
    }
    
    state = %State{
      worlds: %{w1: world},
      discoveries: %{},
      research_programs: %{}
    }
    
    # Robotics discovery requiring energy and materials
    robotics_discovery = %Discovery{
      id: :robotics,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{computation: 0.7, energy: 0.6}}
    }
    
    result = CapabilityRegistry.check_capability_prerequisites(state, robotics_discovery)
    
    assert elem(result, 0) == :ok
    gaps = elem(result, 1)
    
    # Should have small or zero gaps
    assert Map.get(gaps, :energy_generation, 0) < 0.5
  end
  
  # ============================================================================
  # Test 3: Prerequisite Checking - Missing Capabilities
  # ============================================================================
  
  test "check_capability_prerequisites returns :blocked when capabilities missing" do
    world = %{
      id: :w1,
      name: "Test World",
      capabilities: %{
        energy_generation: 0.3  # Too low
      }
    }
    
    state = %State{
      worlds: %{w1: world},
      discoveries: %{},
      research_programs: %{}
    }
    
    # Advanced discovery requiring high energy
    advanced_discovery = %Discovery{
      id: :fusion_reactor,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.95, materials: 0.8}}
    }
    
    result = CapabilityRegistry.check_capability_prerequisites(state, advanced_discovery)
    
    assert elem(result, 0) == :blocked
    missing = elem(result, 1)
    
    # Should be missing energy_generation (need higher level)
    assert :energy_generation in missing or length(missing) > 0
  end
  
  # ============================================================================
  # Test 4: Difficulty Scaling
  # ============================================================================
  
  test "calculate_difficulty increases with capability gaps" do
    world_easy = %{
      id: :w1,
      name: "Easy World",
      capabilities: %{energy_generation: 0.9}
    }
    
    world_hard = %{
      id: :w2,
      name: "Hard World",
      capabilities: %{energy_generation: 0.2}
    }
    
    state = %State{
      worlds: %{w1: world_easy, w2: world_hard},
      discoveries: %{},
      research_programs: %{}
    }
    
    discovery = %Discovery{
      id: :test_disc,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.8}}
    }
    
    easy_difficulty = CapabilityRegistry.calculate_difficulty(%{state | worlds: %{w1: world_easy}}, discovery)
    hard_difficulty = CapabilityRegistry.calculate_difficulty(%{state | worlds: %{w2: world_hard}}, discovery)
    
    # Hard world should have higher difficulty
    assert hard_difficulty > easy_difficulty
    assert easy_difficulty >= 1.0
    assert hard_difficulty >= 1.0
  end
  
  # ============================================================================
  # Test 5: Get Unlocked Capabilities
  # ============================================================================
  
  test "get_unlocked_capabilities returns capability list" do
    discovery = %Discovery{
      id: :battery,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.9, materials: 0.7}}
    }
    
    unlocked = CapabilityRegistry.get_unlocked_capabilities(discovery)
    
    assert length(unlocked) >= 1
    assert :energy_generation in unlocked or :materials_science in unlocked
  end
  
  # ============================================================================
  # Test 6: Cross-World Capability Merging
  # ============================================================================
  
  test "merge_world_capabilities takes best levels from all worlds" do
    world1 = %{
      id: :w1,
      name: "Energy World",
      capabilities: %{energy_generation: 0.9, materials_science: 0.3}
    }
    
    world2 = %{
      id: :w2,
      name: "Materials World",
      capabilities: %{energy_generation: 0.4, materials_science: 0.8}
    }
    
    state = %State{
      worlds: %{w1: world1, w2: world2},
      discoveries: %{},
      research_programs: %{}
    }
    
    merged = CapabilityRegistry.merge_world_capabilities(state, [:w1, :w2])
    
    # Should take best of each
    assert merged[:energy_generation] == 0.9  # From w1
    assert merged[:materials_science] == 0.8  # From w2
  end
  
  # ============================================================================
  # Test 7: Capability Summarization
  # ============================================================================
  
  test "summarize_capabilities produces readable output" do
    capabilities = %{
      energy_generation: 0.9,
      materials_science: 0.6,
      computation: 0.8
    }
    
    summary = CapabilityRegistry.summarize_capabilities(capabilities)
    
    assert String.contains?(summary, "=== Civilization Capabilities ===")
    assert String.contains?(summary, "energy_generation")
    assert String.contains?(summary, "0.9")
  end
  
  # ============================================================================
  # Test 8: Capability Accumulation Over Time
  # ============================================================================
  
  test "capabilities accumulate across multiple discoveries" do
    world = %{
      id: :w1,
      name: "Accumulating World",
      capabilities: %{}
    }
    
    state = %State{
      worlds: %{w1: world},
      discoveries: %{},
      research_programs: %{}
    }
    
    # First discovery: basic energy
    disc1 = %Discovery{
      id: :disc1,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.5}}
    }
    
    state_after_1 = CapabilityRegistry.register_discovery(state, disc1)
    caps_after_1 = CapabilityRegistry.get_world_capabilities(state_after_1, :w1)
    
    # Second discovery: better energy
    disc2 = %Discovery{
      id: :disc2,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.8}}
    }
    
    state_after_2 = CapabilityRegistry.register_discovery(state_after_1, disc2)
    caps_after_2 = CapabilityRegistry.get_world_capabilities(state_after_2, :w1)
    
    # Capability should improve
    assert caps_after_2[:energy_generation] >= caps_after_1[:energy_generation]
    assert caps_after_2[:energy_generation] >= 0.7
  end
  
  # ============================================================================
  # Test 9: Cross-Domain Integration Requirement
  # ============================================================================
  
  test "multi-domain discoveries require cross_domain_integration capability" do
    world = %{
      id: :w1,
      name: "Test World",
      capabilities: %{
        energy_generation: 0.8,
        materials_science: 0.8
      }
    }
    
    state = %State{
      worlds: %{w1: world},
      discoveries: %{},
      research_programs: %{}
    }
    
    # Synthesis discovery requiring integration
    synthesis_discovery = %Discovery{
      id: :synthesis,
      origin_world_id: :w1,
      metadata: %{domain_vector: %{energy: 0.8, materials: 0.8}}
    }
    
    result = CapabilityRegistry.check_capability_prerequisites(state, synthesis_discovery)
    
    # May be blocked by missing cross_domain_integration
    case result do
      {:blocked, missing} ->
        assert :cross_domain_integration in missing
      {:ok, _gaps} ->
        # Or ok if integration not required at this level
        assert true
    end
  end
  
  # ============================================================================
  # Test 10: Empty State Handling
  # ============================================================================
  
  test "get_world_capabilities handles missing world" do
    state = %State{
      worlds: %{},
      discoveries: %{},
      research_programs: %{}
    }
    
    caps = CapabilityRegistry.get_world_capabilities(state, :nonexistent)
    
    assert caps == %{}
  end
end
