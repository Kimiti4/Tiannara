defmodule Tiannara.OPC.V3.GPU.GPUCompiler do
  @moduledoc """
  GPU Compiler for OPC v3
  Turns OIR into parallel compute graph for WebGL2/GPGPU execution
  """

  alias Tiannara.OPC.V3.IR.OIR
  alias Tiannara.OPC.V3.GPU.ComputeGraph
  alias Tiannara.OPC.V3.GPU.ShaderGenerator

  @doc """
  Compiles OIR to GPU executable format
  """
  def compile_for_gpu(%OIR{} = oir) do
    # Generate compute graph from OIR
    compute_graph = ComputeGraph.from_oir(oir)
    
    # Generate GPU shader from compute graph
    shader_source = ShaderGenerator.generate_shader(compute_graph)
    
    # Package as GPU executable
    %{
      type: :gpu_executable,
      compute_graph: compute_graph,
      shader_source: shader_source,
      metadata: %{
        estimated_parallelism: ComputeGraph.estimate_parallelism(compute_graph),
        memory_requirements: ComputeGraph.calculate_memory_usage(compute_graph),
        execution_profile: ComputeGraph.estimate_execution_time(compute_graph)
      }
    }
  end

  @doc """
  Validates if an OIR is suitable for GPU compilation
  """
  def can_compile_for_gpu(%OIR{} = oir) do
    ComputeGraph.is_parallelizable?(oir)
  end
end
