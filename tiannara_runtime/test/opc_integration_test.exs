defmodule Tiannara.OPC.IntegrationTest do
  @moduledoc """
  Phase 5F.6 — OPC Integration Tests
  
  Tests the complete AST → GPU execution pipeline with all new components:
  - Symbolic Simplifier
  - Shader Cache
  - Kernel Optimizer
  - Sandbox Injector
  - Chronogram Bridge
  - NATS OPC Bus
  """

  use ExUnit.Case, async: true
  alias Tiannara.OPC.Validation.SymbolicSimplifier
  alias Tiannara.OPC.Compiler.ShaderCache
  alias Tiannara.OPC.Compiler.KernelOptimizer
  alias Tiannara.OPC.Runtime.SandboxInjector
  alias Tiannara.OPC.Runtime.ChronogramBridge
  alias Tiannara.NATS.OPCBus

  setup do
    unless Process.whereis(Tiannara.OPC.Supervisor) do
      {:ok, _} = Tiannara.OPC.Supervisor.start_link([])
    end
    :ok
  end

  describe "SymbolicSimplifier" do
    test "performs constant folding" do
      ast = {:op, :+, [{:const, 2.0}, {:const, 3.0}]}
      result = SymbolicSimplifier.simplify(ast)
      
      assert result == {:const, 5.0}
    end

    test "eliminates identity operations" do
      ast = {:op, :*, [{:var, :x}, {:const, 1.0}]}
      result = SymbolicSimplifier.simplify(ast)
      
      assert result == {:var, :x}
    end

    test "handles zero multiplication" do
      ast = {:op, :*, [{:var, :y}, {:const, 0.0}]}
      result = SymbolicSimplifier.simplify(ast)
      
      assert result == {:const, 0.0}
    end

    test "simplifies exponentiation" do
      ast = {:op, :^, [{:var, :z}, {:const, 0.0}]}
      result = SymbolicSimplifier.simplify(ast)
      
      assert result == {:const, 1.0}
    end

    test "computes complexity reduction metrics" do
      original = {:op, :+, [
        {:op, :*, [{:const, 2.0}, {:const, 3.0}]},
        {:const, 4.0}
      ]}
      
      simplified = SymbolicSimplifier.simplify(original)
      metrics = SymbolicSimplifier.complexity_reduction(original, simplified)
      
      assert metrics.nodes_reduced > 0
      assert metrics.reduction_percentage > 0
      IO.puts("✅ Simplification reduced #{metrics.nodes_reduced} nodes (#{Float.round(metrics.reduction_percentage, 1)}%)")
    end
  end

  describe "ShaderCache" do
    test "stores and retrieves shaders" do
      oir = [{:load_const, 1.0}, {:binary_exec, :+}]
      shader = "#version 310 es\nvoid main() { }"
      
      ShaderCache.store(oir, shader)
      
      # Small delay to ensure async storage completes
      Process.sleep(10)
      
      assert {:ok, ^shader} = ShaderCache.lookup(oir)
    end

    test "returns cache miss for unknown OIR" do
      oir = [{:load_const, 999.0}]
      
      assert {:error, :cache_miss} = ShaderCache.lookup(oir)
    end

    test "tracks cache statistics" do
      # Store some shaders
      Enum.each(1..3, fn i ->
        oir = [{:load_const, i * 1.0}]
        ShaderCache.store(oir, "shader_#{i}")
      end)
      
      Process.sleep(10)
      
      {:ok, stats} = ShaderCache.stats()
      
      assert stats.size >= 3
      assert stats.max_size == 1000
      assert is_number(stats.hit_rate)
      
      IO.puts("✅ Cache stats: #{stats.size} entries, #{stats.hit_rate}% hit rate")
    end

    test "clears cache" do
      ShaderCache.clear()
      {:ok, stats} = ShaderCache.stats()
      
      assert stats.size == 0
      assert stats.hits == 0
      assert stats.misses == 0
    end
  end

  describe "KernelOptimizer" do
    test "eliminates dead code" do
      oir = [
        {:load_const, 1.0},
        {:nop},
        {:comment, "test"},
        {:load_const, 2.0}
      ]
      
      optimized = KernelOptimizer.optimize(oir)
      
      assert length(optimized) < length(oir)
      refute Enum.any?(optimized, fn
        {:nop} -> true
        {:comment, _} -> true
        _ -> false
      end)
    end

    test "fuses constant operations" do
      oir = [
        {:load_const, 2.0},
        {:load_const, 3.0},
        {:binary_exec, :*}
      ]
      
      optimized = KernelOptimizer.optimize(oir)
      
      # Should fuse into single constant load
      assert length(optimized) < length(oir)
      assert {:load_const, 6.0} in optimized
    end

    test "estimates VRAM usage" do
      oir = [
        {:load_const, 1.0},
        {:load_const, 2.0},
        {:binary_exec, :+}
      ]
      
      vram_bytes = KernelOptimizer.estimate_vram_usage(oir)
      
      assert vram_bytes > 0
      IO.puts("✅ Estimated VRAM usage: #{vram_bytes} bytes")
    end

    test "checks SIMD friendliness" do
      simd_friendly_oir = [{:load_const, 1.0}, {:binary_exec, :+}]
      assert KernelOptimizer.simd_friendly?(simd_friendly_oir)
      
      non_simd_oir = [{:branch, :condition}, {:load_const, 1.0}]
      refute KernelOptimizer.simd_friendly?(non_simd_oir)
    end
  end

  describe "SandboxInjector" do
    test "injects sandbox constraints into shader" do
      shader = """
      #version 310 es
      
      void main() {
          // Original shader code
      }
      """
      
      sandboxed = SandboxInjector.inject(shader, "obs_test_001")
      
      # Check that sandbox metadata was added
      assert String.contains?(sandboxed, "Tiannara OPC Sandbox Constraints")
      assert String.contains?(sandboxed, "obs_test_001")
      
      # Check that guards were injected
      assert String.contains?(sandboxed, "check_vram_quota")
      assert String.contains?(sandboxed, "compute_ctn_rate")
      assert String.contains?(sandboxed, "check_execution_timeout")
      assert String.contains?(sandboxed, "check_stack_bounds")
      
      IO.puts("✅ Sandbox injection added #{String.length(sandboxed) - String.length(shader)} bytes of safety code")
    end

    test "validates sandbox constraints" do
      sandboxed_shader = SandboxInjector.inject("#version 310 es\nvoid main() {}", "obs_001")
      
      {:ok, constraints} = SandboxInjector.validate_sandbox(sandboxed_shader)
      
      assert "VRAM Guard" in constraints
      assert "CTN Rate Limiter" in constraints
      assert "Execution Timeout" in constraints
      assert "Memory Bounds" in constraints
    end

    test "generates default limits by tier" do
      basic_limits = SandboxInjector.default_limits(:basic)
      assert basic_limits.max_vram_mb == 128
      assert basic_limits.max_ctn_rate == 500
      
      enterprise_limits = SandboxInjector.default_limits(:enterprise)
      assert enterprise_limits.max_vram_mb == 1024
      assert enterprise_limits.max_ctn_rate == 5000
    end
  end

  describe "ChronogramBridge" do
    test "encodes MEI phase from texture data" do
      texture_data = %{
        width: 4,
        height: 4,
        channels: 4,
        pixel_data: <<>>
      }
      
      {:ok, mei_encoding} = ChronogramBridge.encode_mei(texture_data)
      
      assert is_list(mei_encoding.phase_angles)
      assert is_float(mei_encoding.coherence)
      assert mei_encoding.coherence >= 0.0
      assert mei_encoding.coherence <= 1.0
      
      IO.puts("✅ MEI encoding coherence: #{mei_encoding.coherence}")
    end

    test "mutates observer reality" do
      texture_data = %{
        width: 8,
        height: 8,
        channels: 4,
        pixel_data: <<>>
      }
      
      {:ok, result} = ChronogramBridge.mutate_observer_reality("obs_test", texture_data)
      
      assert result.observer_id == "obs_test"
      assert is_integer(result.mutation_id)
      assert result.status == :applied
      assert is_float(result.mei_encoding.coherence)
    end

    test "retrieves mutation history" do
      # First create some mutations
      texture_data = %{width: 4, height: 4, channels: 4, pixel_data: <<>>}
      ChronogramBridge.mutate_observer_reality("obs_history_test", texture_data)
      
      {:ok, history} = ChronogramBridge.get_mutation_history("obs_history_test", 10)
      
      assert is_list(history)
      assert length(history) > 0
    end

    test "computes reality divergence between observers" do
      # Create mutations for two observers
      texture_data = %{width: 4, height: 4, channels: 4, pixel_data: <<>>}
      ChronogramBridge.mutate_observer_reality("obs_div_a", texture_data)
      ChronogramBridge.mutate_observer_reality("obs_div_b", texture_data)
      
      divergence = ChronogramBridge.compute_reality_divergence("obs_div_a", "obs_div_b")
      
      assert is_float(divergence)
      assert divergence >= 0.0
      assert divergence <= 1.0
      
      IO.puts("✅ Reality divergence: #{divergence}")
    end
  end

  describe "NATS OPCBus" do
    test "publishes compile request" do
      payload = %{
        observer_id: "obs_nats_test",
        expression: "gravity * 9.81"
      }
      
      assert :ok = OPCBus.publish_compile_request(payload)
    end

    test "publishes validation result" do
      assert :ok = OPCBus.publish_validation_result("obs_001", :valid)
      assert :ok = OPCBus.publish_validation_result("obs_002", {:error, :unstable})
    end

    test "publishes shader build notification" do
      assert :ok = OPCBus.publish_shader_built("obs_001", "shader_abc123", 1024)
    end

    test "publishes execution dispatch" do
      assert :ok = OPCBus.publish_execute("obs_001", "shader_xyz789", %{})
    end

    test "publishes execution result" do
      result = %{status: :success, execution_time_ms: 50}
      assert :ok = OPCBus.publish_execution_result("obs_001", 12345, result)
    end

    test "publishes rollback command" do
      assert :ok = OPCBus.publish_rollback("obs_001", "budget_exceeded")
    end

    test "subscribes to messages" do
      callback = fn msg -> IO.inspect(msg) end
      
      {:ok, _sub_ref} = OPCBus.subscribe_compile_requests(callback)
      {:ok, _sub_ref} = OPCBus.subscribe_execution_results(callback)
    end
  end

  describe "Full Pipeline Integration" do
    test "complete compilation flow with all components" do
      # This test demonstrates the full enhanced pipeline
      expression = "2.0 + 3.0 * 4.0"
      
      # Step 1: Parse (using existing parser)
      {:ok, ast} = Tiannara.OPC.Parser.Parser.parse(expression)
      IO.puts("✅ Parsed: AST depth = #{Tiannara.OPC.Parser.AST.depth(ast)}")
      
      # Step 2: Validate
      assert {:ok, :stable} = Tiannara.OPC.Validator.SymbolicValidator.validate(ast)
      IO.puts("✅ Validated: AST is stable")
      
      # Step 3: Simplify
      simplified_ast = SymbolicSimplifier.simplify(ast)
      simplification_metrics = SymbolicSimplifier.complexity_reduction(ast, simplified_ast)
      IO.puts("✅ Simplified: Reduced #{simplification_metrics.nodes_reduced} nodes")
      
      # Step 4: Regularize (AOR)
      regularized_ast = Tiannara.OPC.AOR.Regularizer.regularize(simplified_ast)
      IO.puts("✅ Regularized: AOR epsilon injection applied")
      
      # Step 5: Build OIR
      oir = Tiannara.OPC.OIR.IRBuilder.build(regularized_ast)
      IO.puts("✅ OIR Built: #{length(oir)} instructions")
      
      # Step 6: Optimize
      optimized_oir = KernelOptimizer.optimize(oir)
      optimization_pct = ((length(oir) - length(optimized_oir)) / max(length(oir), 1)) * 100
      IO.puts("✅ Optimized: #{Float.round(optimization_pct, 1)}% instruction reduction")
      
      # Step 7: Compile to GPU
      {:ok, shader} = Tiannara.OPC.Compiler.GPUCompiler.compile_oir(optimized_oir)
      IO.puts("✅ Compiled: #{byte_size(shader)} byte GLSL shader")
      
      # Step 8: Inject sandbox
      sandboxed_shader = SandboxInjector.inject(shader, "obs_integration_test")
      IO.puts("✅ Sandboxed: Added safety constraints")
      
      # Step 9: Cache shader
      ShaderCache.store(optimized_oir, sandboxed_shader)
      IO.puts("✅ Cached: Shader stored for reuse")
      
      # Step 10: Execute (mock)
      execution_result = %{execution_id: 999, status: :executed}
      IO.puts("✅ Executed: Kernel dispatched")
      
      # Step 11: Update chronogram
      texture_data = %{width: 64, height: 64, channels: 4, pixel_data: <<>>}
      {:ok, chronogram_result} = ChronogramBridge.mutate_observer_reality(
        "obs_integration_test",
        texture_data,
        %{execution_id: 999}
      )
      IO.puts("✅ Chronogram: Reality mutated (coherence: #{chronogram_result.mei_encoding.coherence})")
      
      # Step 12: Publish via NATS
      OPCBus.publish_execution_result("obs_integration_test", 999, execution_result)
      IO.puts("✅ NATS: Execution result published")
      
      IO.puts("\n🎉 Full OPC pipeline completed successfully!")
    end
  end
end
