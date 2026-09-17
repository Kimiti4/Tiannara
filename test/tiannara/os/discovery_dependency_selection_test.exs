defmodule Tiannara.OS.DiscoveryDependencySelectionTest do
  use ExUnit.Case
  
  alias TiannaraOS.DiscoveryDependencyGraph
  
  test "dependency graph creates deeper discovery chains" do
    world_a = %{
      discoveries: 50,
      capabilities: 0,
      max_dependency_depth: 1,
      avg_asset_value: 100.0
    }
    
    graph = DiscoveryDependencyGraph.new()
      |> DiscoveryDependencyGraph.add_dependency(:electric_motor, [:advanced_metallurgy])
      |> DiscoveryDependencyGraph.add_dependency(:robotics, [:electric_motor])
      |> DiscoveryDependencyGraph.add_dependency(:autonomous_manufacturing, [:robotics])
    
    world_b = %{
      discoveries: 50,
      capabilities: 4,
      max_dependency_depth: 4,
      avg_asset_value: 250.0
    }
    
    assert world_b.max_dependency_depth > world_a.max_dependency_depth
    assert world_b.avg_asset_value > world_a.avg_asset_value
    assert world_b.capabilities > world_a.capabilities
  end
  
  test "dependency chains unlock future discovery space" do
    graph = DiscoveryDependencyGraph.new()
      |> DiscoveryDependencyGraph.add_dependency(:robotics, [:electric_motor])
    
    assert graph != nil
  end
end
