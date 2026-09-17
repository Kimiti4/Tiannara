defmodule Tiannara.OS.DiscoveryDependencyGraphTest do
  @moduledoc """
  Test suite for Discovery Dependency Graph system.
  
  Validates that:
  1. Prerequisites are correctly identified
  2. Capability registry updates properly
  3. Difficulty scaling works with missing prerequisites
  4. Domain inference creates synthesis domains
  5. Breakthrough attempts have correct probability
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.DiscoveryDependencyGraph
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  
  # ============================================================================
  # Test 1: Prerequisite Checking - All Met
  # ============================================================================
  
  test "check_prerequisites returns :ok when all capabilities exist" do
    # Create state with existing discoveries
    existing_discoveries = %{
      disc1: %Discovery{
        id: :disc1,
        world_id: :w1,
        domain_vector: %{materials: 0.9, energy: 0.3}
      },
      disc2: %Discovery{
        id: :disc2,
        world_id: :w1,
        domain_vector: %{energy: 0.85, computation: 0.4}
      }
    }
    
    state = %State{
      discoveries: existing_discoveries,
      worlds: %{},
      research_programs: %{}
    }
    
    # Proposed discovery requires materials and energy (both exist)
    proposed_discovery = %Discovery{
      id: :disc_proposed,
      world_id: :w1,
      domain_vector: %{materials: 0.8, energy: 0.7}
    }
    
    result = DiscoveryDependencyGraph.check_prerequisites(state, proposed_discovery)
    
    assert elem(result, 0) == :ok
    unlocked = elem(result, 1)
    assert :materials in unlocked
    assert :energy in unlocked
  end
  
  # ============================================================================
  # Test 2: Prerequisite Checking - Missing Capabilities
  # ============================================================================
  
  test "check_prerequisites returns :blocked when capabilities missing" do
    existing_discoveries = %{
      disc1: %Discovery{
        id: :disc1,
        world_id: :w1,
        domain_vector: %{materials: 0.9}
      }
    }
    
    state = %State{
      discoveries: existing_discoveries,
      worlds: %{},
      research_programs: %{}
    }
    
    # Proposed discovery requires quantum_computing (doesn't exist)
    proposed_discovery = %Discovery{
      id: :disc_proposed,
      world_id: :w1,
      domain_vector: %{materials: 0.6, quantum_computing: 0.8}
    }
    
    result = DiscoveryDependencyGraph.check_prerequisites(state, proposed_discovery)
    
    assert elem(result, 0) == :blocked
    missing = elem(result, 1)
    assert :quantum_computing in missing
  end
  
  # ============================================================================
  # Test 3: Difficulty Scaling
  # ============================================================================
  
  test "calculate_difficulty increases with missing prerequisites" do
    existing_discoveries = %{
      disc1: %Discovery{
        id: :disc1,
        world_id: :w1,
        domain_vector: %{materials: 0.9}
      }
    }
    
    state = %State{
      discoveries: existing_discoveries,
      worlds: %{},
      research_programs: %{}
    }
    
    # Discovery with no missing prereqs
    easy_discovery = %Discovery{
      id: :easy,
      world_id: :w1,
      domain_vector: %{materials: 0.8}
    }
    
    # Discovery with missing prereqs
    hard_discovery = %Discovery{
      id: :hard,
      world_id: :w1,
      domain_vector: %{materials: 0.6, quantum_computing: 0.8, nanotechnology: 0.7}
    }
    
    easy_difficulty = DiscoveryDependencyGraph.calculate_difficulty(state, easy_discovery)
    hard_difficulty = DiscoveryDependencyGraph.calculate_difficulty(state, hard_discovery)
    
    assert easy_difficulty == 1.0  # Base difficulty
    assert hard_difficulty > easy_difficulty  # Should be harder
    assert hard_difficulty >= 2.0  # At least 2x harder (2 missing prereqs * 0.5 penalty)
  end
  
  # ============================================================================
  # Test 4: Domain Inference - Synthesis Domains
  # ============================================================================
  
  test "infer_enabled_domains creates synthesis domains for multi-domain discoveries" do
    # Single domain discovery
    single_domain = %Discovery{
      id: :single,
      world_id: :w1,
      domain_vector: %{energy: 0.9}
    }
    
    enabled_single = DiscoveryDependencyGraph.infer_enabled_domains(single_domain)
    assert :energy in enabled_single
    assert length(enabled_single) == 1
    
    # Multi-domain discovery should create synthesis
    multi_domain = %Discovery{
      id: :multi,
      world_id: :w1,
      domain_vector: %{energy: 0.85, materials: 0.8}
    }
    
    enabled_multi = DiscoveryDependencyGraph.infer_enabled_domains(multi_domain)
    assert :energy in enabled_multi
    assert :materials in enabled_multi
    assert length(enabled_multi) >= 3  # energy + materials + synthesis domain
    
    # Check that synthesis domain exists
    synthesis_exists = Enum.any?(enabled_multi, fn domain ->
      is_atom(domain) && String.contains?(Atom.to_string(domain), "synthesis")
    end)
    assert synthesis_exists
  end
  
  # ============================================================================
  # Test 5: Breakthrough Probability
  # ============================================================================
  
  test "attempt_breakthrough has decreasing probability with more missing prereqs" do
    # Run multiple trials to get statistical average
    trials = 1000
    
    # 1 missing prerequisite
    successes_1 = Enum.count(1..trials, fn _ ->
      DiscoveryDependencyGraph.attempt_breakthrough(1)
    end)
    
    # 3 missing prerequisites
    successes_3 = Enum.count(1..trials, fn _ ->
      DiscoveryDependencyGraph.attempt_breakthrough(3)
    end)
    
    prob_1 = successes_1 / trials
    prob_3 = successes_3 / trials
    
    # Probability should decrease with more missing prereqs
    assert prob_1 > prob_3
    
    # Probabilities should be roughly in expected range (allowing for variance)
    assert prob_1 < 0.2  # Should be around 0.1
    assert prob_3 < 0.1  # Should be around 0.033
  end
  
  # ============================================================================
  # Test 6: Register Discovery Updates Capability Registry
  # ============================================================================
  
  test "register_discovery adds to world capabilities" do
    initial_world = %{
      id: :w1,
      name: "Test World",
      capabilities: []
    }
    
    state = %State{
      discoveries: %{},
      worlds: %{w1: initial_world},
      research_programs: %{},
      discovery_dependencies: %{}
    }
    
    new_discovery = %Discovery{
      id: :new_disc,
      world_id: :w1,
      domain_vector: %{energy: 0.9, efficiency: 0.8}
    }
    
    updated_state = DiscoveryDependencyGraph.register_discovery(state, new_discovery)
    updated_world = Map.get(updated_state.worlds, :w1)
    
    assert length(updated_world.capabilities) == 1
    assert hd(updated_world.capabilities) == %{energy: 0.9, efficiency: 0.8}
  end
  
  # ============================================================================
  # Test 7: Full Integration Cycle
  # ============================================================================
  
  test "full dependency cycle: register → check → infer" do
    # Start with empty state
    state = %State{
      discoveries: %{},
      worlds: %{w1: %{id: :w1, name: "Test", capabilities: []}},
      research_programs: %{},
      discovery_dependencies: %{}
    }
    
    # Step 1: Register foundational discovery
    foundational = %Discovery{
      id: :foundational,
      world_id: :w1,
      domain_vector: %{materials: 0.9}
    }
    
    state_after_register = DiscoveryDependencyGraph.register_discovery(state, foundational)
    
    # Step 2: Check if advanced discovery is now possible
    advanced = %Discovery{
      id: :advanced,
      world_id: :w1,
      domain_vector: %{materials: 0.7, manufacturing: 0.8}
    }
    
    result = DiscoveryDependencyGraph.check_prerequisites(state_after_register, advanced)
    
    # Should be blocked (manufacturing not yet discovered)
    assert elem(result, 0) == :blocked
    missing = elem(result, 1)
    assert :manufacturing in missing
  end
end
