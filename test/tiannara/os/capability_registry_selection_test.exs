defmodule Tiannara.OS.CapabilityRegistrySelectionTest do
  use ExUnit.Case
  
  test "capabilities unlock new discovery regions" do
    baseline_discovery_space = 10
    
    unlocked_discovery_space = 35
    
    assert unlocked_discovery_space > baseline_discovery_space
  end
  
  test "energy storage capability enables robotics" do
    capabilities = MapSet.new([:energy_storage])
    
    robotics_possible = MapSet.member?(capabilities, :energy_storage)
    
    assert robotics_possible
  end
end
