defmodule Tiannara.OPC.API.CompileAPI do
  @moduledoc """
  Phase 5F.6 — OPC Compile API
  
  High-level API for compiling observer-defined physics into executable kernels.
  
  ## Pipeline
  
  1. Parse expression → AST
  2. Validate AST → Stability check
  3. Regularize AST → AOR injection
  4. Build OIR → Intermediate representation
  5. Compile to GPU → GLSL shader
  6. Execute → Runtime deployment
  
  ## Example
  
      iex> CompileAPI.compile_physics("obs_001", "gravity * 9.81")
      {:ok, %{shader: "...", execution_id: 123}}
  """
  
  require Logger
  alias Tiannara.OPC.Parser.Parser
  alias Tiannara.OPC.Validator.SymbolicValidator
  alias Tiannara.OPC.Validation.TensorConstraintSolver
  alias Tiannara.OPC.Validation.SingularityDetector
  alias Tiannara.OPC.Validation.LoopAnalyzer
  alias Tiannara.OPC.Validation.SymbolicSimplifier
  alias Tiannara.OPC.Validation.EpsilonShimEngine
  alias Tiannara.OPC.OIR.IRBuilder
  alias Tiannara.OPC.Compiler.GPUCompiler
  alias Tiannara.OPC.Compiler.ShaderCache
  alias Tiannara.OPC.Compiler.KernelOptimizer
  alias Tiannara.OPC.Runtime.ExecutionRuntime
  alias Tiannara.OPC.Runtime.SandboxInjector
  alias Tiannara.OPC.Runtime.ChronogramBridge
  alias Tiannara.NATS.OPCBus

  @doc """
  Compile and execute observer physics expression.
  
  ## Parameters
  
  - `observer_id`: Unique observer identifier
  - `expression`: Physics expression string (e.g., "gravity * 9.81")
  
  ## Returns
  
  - `{:ok, result}` with execution details
  - `{:error, reason}` if compilation fails
  """
  def compile_physics(observer_id, expression) when is_binary(expression) do
    Logger.info("🔧 OPC: Compiling physics for observer #{observer_id}")
    
    with {:ok, ast} <- parse_expression(expression),
         :ok <- validate_ast(ast),
         simplified_ast <- simplify_ast(ast),
         regularized_ast <- regularize_ast(simplified_ast),
         oir <- build_oir(regularized_ast),
         optimized_oir <- optimize_oir(oir),
         {:ok, shader} <- compile_to_gpu(optimized_oir),
         sandboxed_shader <- inject_sandbox(shader, observer_id),
         :ok <- cache_shader(optimized_oir, sandboxed_shader),
         {:ok, execution_result} <- execute_kernel(observer_id, sandboxed_shader),
         {:ok, chronogram_result} <- update_chronogram(observer_id, execution_result) do
      
      # Publish execution result via NATS
      OPCBus.publish_execution_result(observer_id, execution_result.execution_id, execution_result)
      
      Logger.info("✅ OPC: Compilation successful for #{observer_id}")
      
      {:ok, %{
        observer_id: observer_id,
        expression: expression,
        ast_depth: Tiannara.OPC.Parser.AST.depth(ast),
        simplification_metrics: SymbolicSimplifier.complexity_reduction(ast, simplified_ast),
        oir_instructions_original: length(oir),
        oir_instructions_optimized: length(optimized_oir),
        optimization_reduction: ((length(oir) - length(optimized_oir)) / max(length(oir), 1)) * 100,
        shader_length: byte_size(sandboxed_shader),
        execution: execution_result,
        chronogram: chronogram_result
      }}
    else
      {:error, reason} ->
        Logger.error("❌ OPC: Compilation failed for #{observer_id}: #{inspect(reason)}")
        # Publish rollback if needed
        OPCBus.publish_rollback(observer_id, inspect(reason))
        {:error, reason}
    end
  end

  defp parse_expression(expression) do
    Logger.debug("OPC: Parsing expression")
    Parser.parse(expression)
  end

  defp validate_ast(ast) do
    Logger.debug("OPC: Validating AST stability")
    
    with {:ok, :stable} <- SymbolicValidator.validate(ast),
         :ok <- SingularityDetector.scan(ast),
         :ok <- LoopAnalyzer.check(ast, 32),
         {:ok, _constrained} <- TensorConstraintSolver.solve(ast) do
      :ok
    else
      {:error, reason} -> {:error, {:validation_failed, reason}}
    end
  end

  defp simplify_ast(ast) do
    Logger.debug("OPC: Applying symbolic simplification")
    SymbolicSimplifier.simplify(ast)
  end

  defp regularize_ast(ast) do
    Logger.debug("OPC: Applying AOR regularization")
    budget = get_mscl_budget()

    {:ok, regularized_ast} = EpsilonShimEngine.apply(ast, budget)
    regularized_ast
  end

  defp get_mscl_budget do
    if Process.whereis(Tiannara.MSCL.Supervisor) do
      case Tiannara.MSCL.Supervisor.get_state() do
        {:ok, state} ->
          max(0.01, 1.0 - Map.get(state, :collapse_risk, 0.0))
        _ ->
          0.5
      end
    else
      0.5
    end
  end

  defp build_oir(ast) do
    Logger.debug("OPC: Building OIR")
    IRBuilder.build(ast)
  end

  defp compile_to_gpu(oir) do
    Logger.debug("OPC: Compiling to GPU shader")
    GPUCompiler.compile_oir(oir)
  end

  defp execute_kernel(observer_id, shader) do
    Logger.debug("OPC: Executing kernel")
    ExecutionRuntime.execute(observer_id, shader)
  end

  defp optimize_oir(oir) do
    Logger.debug("OPC: Optimizing OIR instructions")
    KernelOptimizer.optimize(oir)
  end

  defp inject_sandbox(shader, observer_id) do
    Logger.debug("OPC: Injecting sandbox constraints")
    limits = SandboxInjector.default_limits(:standard)
    SandboxInjector.inject(shader, observer_id, limits)
  end

  defp cache_shader(oir, shader) do
    Logger.debug("OPC: Caching compiled shader")
    ShaderCache.store(oir, shader)
    :ok
  end

  defp update_chronogram(observer_id, execution_result) do
    Logger.debug("OPC: Updating chronogram with execution results")
    
    # Create mock texture data (in production, this would come from GPU)
    texture_data = %{
      width: 64,
      height: 64,
      channels: 4,
      pixel_data: <<>>  # Placeholder
    }
    
    ChronogramBridge.mutate_observer_reality(observer_id, texture_data, %{
      execution_id: execution_result.execution_id,
      execution_time_ms: 100
    })
  end

  @doc """
  Quick validation without full compilation.
  
  Checks if an expression is syntactically valid and stable.
  """
  def validate_only(expression) do
    with {:ok, ast} <- Parser.parse(expression),
         {:ok, :stable} <- SymbolicValidator.validate(ast) do
      {:ok, :valid}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
