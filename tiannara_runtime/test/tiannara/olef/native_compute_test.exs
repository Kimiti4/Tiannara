defmodule Tiannara.OLEF.NativeComputeTest do
  use ExUnit.Case, async: false
  
  alias Tiannara.OLEF.ComputeBackends.Native
  
  test "Binary Tensor Serialization & Deserialization" do
    # Create a dummy field Map
    field = %{
      "node_a" => 1.5,
      "node_b" => 2.0,
      "node_c" => 0.5
    }
    
    # 1. Serialize to binary
    {binary, index_map} = Native.serialize_to_binary(field)
    
    # Verify index map has 3 elements
    assert map_size(index_map) == 3
    # 3 floats * 8 bytes (Float64) = 24 bytes
    assert byte_size(binary) == 24
    
    # 2. Deserialize back to map
    rebuilt_field = Native.deserialize_from_binary(binary, index_map)
    
    # Should perfectly match the original map
    assert rebuilt_field == field
  end
end
