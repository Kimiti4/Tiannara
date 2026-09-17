defmodule TiannaraRuntime.SharedMemoryTest do
  use ExUnit.Case, async: false
  alias TiannaraRuntime.SharedMemory
  alias Tiannara.Native.A10

  test "allocates and retrieves the state resource from ETS" do
    assert {:ok, ref} = SharedMemory.get_state_ref()
    assert is_reference(ref)
  end

  test "updates a shard and computes drift/lyapunov from shared memory" do
    {:ok, ref} = SharedMemory.get_state_ref()
    
    # Let's update shard 0 with some test data
    shard_size = 10_000
    test_data = List.duplicate(2.0, shard_size)
    
    assert :ok == A10.update_shard(ref, 0, test_data)
    
    # Read shard to verify
    retrieved_data = A10.read_shard(ref, 0)
    assert length(retrieved_data) == shard_size
    assert List.first(retrieved_data) == 2.0
    
    # Compute Lyapunov with a gain matrix of all 1.0s
    gain_matrix = List.duplicate(1.0, 100)
    
    v = A10.lyapunov_shared(ref, gain_matrix)
    # Total V = 40,000.0 (since 2.0 * 1.0 * 2.0 = 4.0, and 10k elements)
    assert v == 40_000.0
    
    # Compute Drift
    drift = A10.compute_drift_shared(ref, 5)
    assert length(drift) > 0
  end
end
