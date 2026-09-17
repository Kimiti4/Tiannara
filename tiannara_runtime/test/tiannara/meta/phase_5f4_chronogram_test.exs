defmodule TiannaraRuntime.Phase5F4ChronogramTest do
  @moduledoc """
  Phase 5F.4 — Holographic Chronogram Memory System Tests
  
  Tests the complete holographic memory implementation:
  - ChronogramMatrix (frequency-encoded memory substrate)
  - GCK ChronogramGate (validation layer)
  - ExecutionController memory pipeline integration
  - Observer-relative truth (different observers see different memories)
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.Meta.ChronogramMatrix
  alias Tiannara.GCK.ChronogramGate
  alias TiannaraRuntime.CIS.ExecutionController
  
  describe "ChronogramMatrix core operations" do
    test "observer registration assigns unique MEI frequencies" do
      {:ok, matrix_pid} = start_matrix()
      
      # Register root observer
      {:ok, mei_root} = ChronogramMatrix.register_observer("obs_root")
      assert mei_root > 1.618 and mei_root < 1.718  # Base frequency + random offset
      
      # Register child observer (should have different frequency)
      {:ok, mei_child} = ChronogramMatrix.register_observer("obs_child", "obs_root")
      assert mei_child != mei_root
      assert mei_child > mei_root  # Child frequency is parent + phase shift
      
      # Verify both are registered
      {:ok, retrieved_mei} = ChronogramMatrix.get_observer_mei("obs_root")
      assert retrieved_mei == mei_root
      
      {:ok, retrieved_child_mei} = ChronogramMatrix.get_observer_mei("obs_child")
      assert retrieved_child_mei == mei_child
      
      Process.exit(matrix_pid, :normal)
    end
    
    test "write and read memory through observer filter" do
      {:ok, matrix_pid} = start_matrix()
      
      # Register observer
      {:ok, _mei} = ChronogramMatrix.register_observer("obs_001")
      
      # Write memory
      state = %{
        coordinate: "event_001",
        data: "Important observation",
        entropy: 0.3,
        timestamp: System.system_time(:second)
      }
      
      :ok = ChronogramMatrix.write("obs_001", state)
      Process.sleep(50)  # Allow async write to complete
      
      # Read memory back
      {payload, amplitude} = ChronogramMatrix.read("obs_001", "event_001")
      
      assert payload.coordinate == "event_001"
      assert payload.data == "Important observation"
      assert amplitude > 0  # Should have some confidence
      
      Process.exit(matrix_pid, :normal)
    end
    
    test "unregistered observer cannot write" do
      {:ok, matrix_pid} = start_matrix()
      
      # Attempt write without registration
      state = %{coordinate: "event_002", data: "test"}
      
      :ok = ChronogramMatrix.write("unregistered_obs", state)
      Process.sleep(50)
      
      # Should not be stored (check returns empty)
      result = ChronogramMatrix.read("unregistered_obs", "event_002")
      assert result == {:empty, 0.0}
      
      Process.exit(matrix_pid, :normal)
    end
    
    test "different observers get different results for same coordinate" do
      {:ok, matrix_pid} = start_matrix()
      
      # Register two observers with different frequencies
      {:ok, _mei_a} = ChronogramMatrix.register_observer("obs_A")
      {:ok, _mei_b} = ChronogramMatrix.register_observer("obs_B")
      
      # Both write to same coordinate
      state_common = %{
        coordinate: "shared_event",
        data: "Common observation",
        entropy: 0.4
      }
      
      :ok = ChronogramMatrix.write("obs_A", state_common)
      :ok = ChronogramMatrix.write("obs_B", state_common)
      Process.sleep(50)
      
      # Read from same coordinate - should get different amplitudes due to MEI filtering
      {_payload_a, amplitude_a} = ChronogramMatrix.read("obs_A", "shared_event")
      {_payload_b, amplitude_b} = ChronogramMatrix.read("obs_B", "shared_event")
      
      # Amplitudes should differ because of different MEI frequencies
      assert amplitude_a != amplitude_b
      
      Process.exit(matrix_pid, :normal)
    end
    
    test "reading non-existent coordinate returns empty" do
      {:ok, matrix_pid} = start_matrix()
      
      {:ok, _mei} = ChronogramMatrix.register_observer("obs_test")
      
      result = ChronogramMatrix.read("obs_test", "non_existent_event")
      assert result == {:empty, 0.0}
      
      Process.exit(matrix_pid, :normal)
    end
    
    test "get_stats returns matrix information" do
      {:ok, matrix_pid} = start_matrix()
      
      # Register some observers
      ChronogramMatrix.register_observer("obs_stat_1")
      ChronogramMatrix.register_observer("obs_stat_2")
      
      stats = ChronogramMatrix.get_stats()
      
      assert stats.total_registered_observers >= 2
      assert Map.has_key?(stats, :total_memory_entries)
      assert Map.has_key?(stats, :table_name)
      
      Process.exit(matrix_pid, :normal)
    end
  end
  
  describe "GCK ChronogramGate validation" do
    test "valid memory write passes GCK" do
      state = %{
        coordinate: "event_valid",
        entropy: 0.3,
        drift: 0.2,
        data: "stable memory"
      }
      
      result = ChronogramGate.validate_write("obs_001", state)
      assert result == {:allow, :ok}
    end
    
    test "high entropy memory rejected by GCK" do
      state = %{
        coordinate: "event_unstable",
        entropy: 0.95,  # Above threshold (0.92)
        drift: 0.2
      }
      
      result = ChronogramGate.validate_write("obs_001", state)
      assert result == {:reject, :entropy_overflow}
    end
    
    test "high drift memory rejected by GCK" do
      state = %{
        coordinate: "event_drifted",
        entropy: 0.3,
        drift: 0.80  # Above threshold (0.75)
      }
      
      result = ChronogramGate.validate_write("obs_001", state)
      assert result == {:reject, :causal_drift}
    end
    
    test "missing required fields rejected by GCK" do
      state = %{
        data: "missing coordinate field"
        # Missing :coordinate and :entropy
      }
      
      result = ChronogramGate.validate_write("obs_001", state)
      assert result == {:reject, :missing_fields}
    end
    
    test "read validation always allows (light check)" do
      result = ChronogramGate.validate_read("obs_001", "any_coordinate")
      assert result == {:allow, :ok}
    end
    
    test "get_thresholds returns current limits" do
      thresholds = ChronogramGate.get_thresholds()
      
      assert thresholds.entropy_limit == 0.92
      assert thresholds.observer_drift_limit == 0.75
    end
  end
  
  describe "ExecutionController memory pipeline integration" do
    test "execute_memory_write validates and stores" do
      {:ok, cis_pid} = start_cis()
      {:ok, exec_pid} = start_exec()
      {:ok, matrix_pid} = start_matrix()
      
      # Register observer first
      {:ok, _mei} = ExecutionController.register_chronogram_observer("obs_exec_001")
      
      # Write memory through ExecutionController
      state = %{
        coordinate: "exec_event_001",
        data: "Memory via ExecutionController",
        entropy: 0.3,
        drift: 0.2
      }
      
      result = ExecutionController.execute_memory_write("obs_exec_001", state)
      assert result == {:ok, :written}
      
      # Verify it was stored
      Process.sleep(50)
      {payload, _amplitude} = ChronogramMatrix.read("obs_exec_001", "exec_event_001")
      assert payload.data == "Memory via ExecutionController"
      
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
      Process.exit(matrix_pid, :normal)
    end
    
    test "execute_memory_write rejects high entropy via GCK" do
      {:ok, cis_pid} = start_cis()
      {:ok, exec_pid} = start_exec()
      {:ok, matrix_pid} = start_matrix()
      
      {:ok, _mei} = ExecutionController.register_chronogram_observer("obs_reject")
      
      # Try to write unstable memory
      unstable_state = %{
        coordinate: "unstable_event",
        data: "Too chaotic",
        entropy: 0.95,  # Above GCK threshold
        drift: 0.2
      }
      
      result = ExecutionController.execute_memory_write("obs_reject", unstable_state)
      assert result == {:error, :gck_rejected, :entropy_overflow}
      
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
      Process.exit(matrix_pid, :normal)
    end
    
    test "execute_memory_read retrieves validated memory" do
      {:ok, cis_pid} = start_cis()
      {:ok, exec_pid} = start_exec()
      {:ok, matrix_pid} = start_matrix()
      
      {:ok, _mei} = ExecutionController.register_chronogram_observer("obs_reader")
      
      # Write first
      state = %{
        coordinate: "readable_event",
        data: "Readable content",
        entropy: 0.3,
        drift: 0.1
      }
      
      result = ExecutionController.execute_memory_write("obs_reader", state)
      assert match?({:ok, :written}, result)
      Process.sleep(50)
      
      # Read through ExecutionController
      result = ExecutionController.execute_memory_read("obs_reader", "readable_event")
      assert match?({_payload, _amplitude}, result)
      
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
      Process.exit(matrix_pid, :normal)
    end
    
    test "register_chronogram_observer assigns MEI frequency" do
      {:ok, cis_pid} = start_cis()
      {:ok, exec_pid} = start_exec()
      {:ok, matrix_pid} = start_matrix()
      
      # Register root observer
      {:ok, mei_root} = ExecutionController.register_chronogram_observer("obs_root_exec")
      assert mei_root > 1.618 and mei_root < 1.718
      
      # Register child observer
      {:ok, mei_child} = ExecutionController.register_chronogram_observer("obs_child_exec", "obs_root_exec")
      assert mei_child != mei_root
      
      Process.exit(cis_pid, :normal)
      Process.exit(exec_pid, :normal)
      Process.exit(matrix_pid, :normal)
    end
  end
  
  describe "Observer-relative truth property" do
    test "same coordinate returns different amplitudes per observer" do
      {:ok, matrix_pid} = start_matrix()
      
      # Register observers with very different frequencies
      {:ok, _mei_1} = ChronogramMatrix.register_observer("obs_freq_1")
      {:ok, _mei_2} = ChronogramMatrix.register_observer("obs_freq_2")
      
      # Write identical state from both observers
      identical_state = %{
        coordinate: "identical_event",
        data: "Same content",
        entropy: 0.5
      }
      
      :ok = ChronogramMatrix.write("obs_freq_1", identical_state)
      :ok = ChronogramMatrix.write("obs_freq_2", identical_state)
      Process.sleep(50)
      
      # Read from both - payloads should be same, amplitudes different
      {payload_1, amp_1} = ChronogramMatrix.read("obs_freq_1", "identical_event")
      {payload_2, amp_2} = ChronogramMatrix.read("obs_freq_2", "identical_event")
      
      # Payloads are identical (same underlying data)
      assert payload_1.data == payload_2.data
      
      # But amplitudes differ (filtered through different MEI frequencies)
      assert amp_1 != amp_2
      
      Process.exit(matrix_pid, :normal)
    end
    
    test "observer sees only their own memories at coordinate" do
      {:ok, matrix_pid} = start_matrix()
      
      {:ok, _mei_a} = ChronogramMatrix.register_observer("obs_isolated_a")
      {:ok, _mei_b} = ChronogramMatrix.register_observer("obs_isolated_b")
      
      # Observer A writes to coordinate
      state_a = %{
        coordinate: "private_event",
        data: "A's memory",
        entropy: 0.3
      }
      
      :ok = ChronogramMatrix.write("obs_isolated_a", state_a)
      Process.sleep(50)
      
      # Observer B reads same coordinate - should get empty (no B memory there)
      result_b = ChronogramMatrix.read("obs_isolated_b", "private_event")
      assert result_b == {:empty, 0.0}
      
      # Observer A reads - should get their memory
      {payload_a, _amp} = ChronogramMatrix.read("obs_isolated_a", "private_event")
      assert payload_a.data == "A's memory"
      
      Process.exit(matrix_pid, :normal)
    end
  end
  
  describe "Phase encoding/decoding mechanics" do
    test "encode_state creates phase based on MEI" do
      state = %{coordinate: "test", entropy: 0.4}
      mei = 1.618
      
      encoded = ChronogramMatrix.encode_state(state, mei)
      
      assert Map.has_key?(encoded, :payload)
      assert Map.has_key?(encoded, :amplitude)
      assert Map.has_key?(encoded, :phase)
      assert encoded.phase == mei * 0.1
      assert encoded.amplitude > 0
    end
    
    test "decode_state applies cosine filter" do
      encoded = %{
        payload: %{data: "test"},
        amplitude: 0.8,
        phase: 0.1618
      }
      
      mei = 1.618
      {decoded_payload, filtered_amplitude} = ChronogramMatrix.decode_state(encoded, mei)
      
      assert decoded_payload.data == "test"
      # Filtered amplitude = original * cos(mei * 0.1)
      expected_filter = :math.cos(mei * 0.1)
      assert_in_delta filtered_amplitude, 0.8 * expected_filter, 0.0001
    end
  end

  defp start_matrix do
    case ChronogramMatrix.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp start_cis do
    case TiannaraRuntime.CIS.Supervisor.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp start_exec do
    case ExecutionController.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end
end

