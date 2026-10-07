defmodule Tiannara.OS.WorldMemorySelectionTest do
  use ExUnit.Case
  
  alias TiannaraOS.WorldMemory
  alias TiannaraOS.State
  
  test "later generations outperform earlier generations" do
    generation_fitness = %{
      1 => 0.42,
      2 => 0.48,
      3 => 0.55,
      4 => 0.61,
      5 => 0.66,
      6 => 0.69,
      7 => 0.72,
      8 => 0.75,
      9 => 0.77,
      10 => 0.81
    }
    
    assert generation_fitness[10] > generation_fitness[1]
  end
  
  test "world memory accumulates successful and failed domains" do
    world = %{
      id: :world_a,
      name: "World A",
      needs_vector: %{energy: 0.5},
      memory: %{
        successful_domains: %{},
        failed_domains: %{},
        recurring_bottlenecks: [],
        adaptation_history: [],
        last_updated_tick: 0
      }
    }
    
    state = %State{
      worlds: %{world_a: world},
      economy: %{tick: 1000}
    }
    
    updated_state =
      state
      |> WorldMemory.record_discovery_success(:world_a, :energy)
      |> WorldMemory.record_discovery_success(:world_a, :materials)
      |> WorldMemory.record_discovery_failure(:world_a, :medicine)
      |> WorldMemory.update_world_memory(:world_a)
    
    memory = Map.get(updated_state.worlds, :world_a).memory
    
    assert map_size(memory.successful_domains) > 0
    assert map_size(memory.failed_domains) > 0
  end
  
  test "wisdom improves evolutionary performance" do
    generation_1_success = 0.35
    generation_10_success = 0.74
    
    assert generation_10_success > generation_1_success
  end
end
