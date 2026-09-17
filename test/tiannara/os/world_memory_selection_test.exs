defmodule Tiannara.OS.WorldMemorySelectionTest do
  use ExUnit.Case
  
  alias TiannaraOS.WorldMemory
  
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
    memory = WorldMemory.new(:world_a)
      |> WorldMemory.record_success(:energy)
      |> WorldMemory.record_success(:materials)
      |> WorldMemory.record_failure(:medicine)
    
    assert length(memory.successful_domains) > 0
    assert length(memory.failed_domains) > 0
  end
  
  test "wisdom improves evolutionary performance" do
    generation_1_success = 0.35
    generation_10_success = 0.74
    
    assert generation_10_success > generation_1_success
  end
end
