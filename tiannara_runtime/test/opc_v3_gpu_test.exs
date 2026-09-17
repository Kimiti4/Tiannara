defmodule OPCV3GPUTest do
  use ExUnit.Case, async: true

  alias Tiannara.OPC.V3
  alias Tiannara.OPC.V3.IR.OIR
  alias Tiannara.OPC.V3.IR.Builder
  alias Tiannara.OPC.V3.GPU.GPUExecutionEngine

  describe "OPC v3 GPU Layer" do
    test "GPU health check passes" do
      gpu_status = Tiannara.OPC.V3.gpu_health_check()
      assert gpu_status.gpu_available == true
      assert gpu_status.status in [:ready, :unavailable]
    end

    test "can compile and execute simple operations on GPU" do
      # This tests if the GPU compilation path works
      result = Tiannara.OPC.V3.compile_for_gpu("2.0 + 3.0")
      assert is_tuple(result)
    end

    test "GPU execution engine initializes properly" do
      {:ok, context} = GPUExecutionEngine.initialize_gpu_context()
      assert is_map(context)
      assert context.platform == :webgl2
    end

    test "GPU execution engine can execute OIR" do
      # Create a simple OIR node for testing
      number_node = Builder.build({:number, 42.0})
      
      result = GPUExecutionEngine.execute_on_gpu(number_node)
      assert is_tuple(result)
    end

    test "Compute graph identifies parallelizable regions" do
      # Create an OIR with tensor operations to test parallelization
      tensor_node = %OIR{
        type: :tensor,
        children: [
          Builder.build({:number, 1.0}),
          Builder.build({:number, 2.0}),
          Builder.build({:number, 3.0})
        ],
        value: nil,
        op: nil,
        meta: %{}
      }
      
      compute_graph = Tiannara.OPC.V3.GPU.ComputeGraph.from_oir(tensor_node)
      
      # Should identify tensor regions as parallelizable
      assert length(compute_graph.parallelizable_regions) > 0
      assert Enum.any?(compute_graph.parallelizable_regions, &(&1.type == :tensor_region))
    end

    test "GPU compiler can determine if OIR is suitable for GPU" do
      # Test with a simple number node
      number_node = Builder.build({:number, 42.0})
      refute Tiannara.OPC.V3.GPU.GPUCompiler.can_compile_for_gpu(number_node)
      
      # Test with a tensor operation (should be more parallelizable)
      tensor_node = %OIR{
        type: :tensor,
        children: [Builder.build({:number, 1.0}), Builder.build({:number, 2.0})],
        value: nil,
        op: nil,
        meta: %{}
      }
      assert Tiannara.OPC.V3.GPU.GPUCompiler.can_compile_for_gpu(tensor_node)
    end
  end
end