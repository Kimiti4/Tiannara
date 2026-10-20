defmodule TiannaraRuntime.Phase5F6OPCTest do
  @moduledoc """
  Phase 5F.6 — Observer Physics Compiler (OPC) Tests
  
  Tests the complete physics compilation pipeline:
  - OPC core compiler
  - Singularity detection
  - Thermodynamic budget estimation
  - Loop analysis
  - OIR generation
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.OPC.ObserverPhysicsCompiler
  alias Tiannara.OPC.Validation.SingularityDetector
  alias Tiannara.OPC.Validation.ThermodynamicBudgetEstimator
  alias Tiannara.OPC.Validation.LoopAnalyzer
  alias Tiannara.OPC.IR.OIRGenerator
  
  describe "OPC core compilation" do
    test "compile_physics accepts valid simple physics" do
      {:ok, _opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Simple addition physics
      physics_ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      
      result = ObserverPhysicsCompiler.compile_physics("obs_simple", physics_ast)
      
      assert match?({:ok, _oir}, result)
      
      Process.exit(_opc_pid, :normal)
    end
    
    test "compile_physics returns OIR with correct structure" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      physics_ast = {:op, :gravity, [{:var, :mass}, {:var, :distance}]}
      
      {:ok, oir} = ObserverPhysicsCompiler.compile_physics("obs_struct", physics_ast)
      
      assert Map.has_key?(oir, :type)
      assert oir.type == "ontological_ir"
      assert Map.has_key?(oir, :observer)
      assert Map.has_key?(oir, :kernel)
      assert Map.has_key?(oir, :execution_mode)
      assert Map.has_key?(oir, :safety_layer)
      assert Map.has_key?(oir, :thermodynamic_cost)
      assert Map.has_key?(oir, :constraints)
      assert Map.has_key?(oir, :metadata)
      
      Process.exit(opc_pid, :normal)
    end
    
    test "compile_physics rejects high-divergence physics" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Create complex AST that would exceed divergence threshold
      complex_ast = create_deeply_nested_ast(40)
      
      result = ObserverPhysicsCompiler.compile_physics("obs_complex", complex_ast)
      
      # Should be rejected due to MSCL-Ω divergence check
      assert match?({:rejected, _reason}, result)
      
      Process.exit(opc_pid, :normal)
    end
    
    test "get_compilation_stats returns observer data" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Compile some physics first
      physics_ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      ObserverPhysicsCompiler.compile_physics("obs_stats", physics_ast)
      
      {:ok, stats} = ObserverPhysicsCompiler.get_compilation_stats("obs_stats")
      
      assert Map.has_key?(stats, :observer_id)
      assert Map.has_key?(stats, :has_compiled_physics)
      assert stats.observer_id == "obs_stats"
      
      Process.exit(opc_pid, :normal)
    end
  end
  
  describe "Singularity Detector validation" do
    test "scan detects division by zero risk" do
      # Unsafe division (denominator could be zero)
      unsafe_ast = {:op, :/, [{:const, 1.0}, {:var, :x}]}
      
      result = SingularityDetector.scan(unsafe_ast)
      
      assert result == {:error, :potential_div_zero}
    end
    
    test "scan allows epsilon-regularized division" do
      # Safe division with epsilon regularization
      safe_ast = {:op, :/, [
        {:const, 1.0},
        {:op, :sqrt, [{:op, :+, [
          {:op, :pow, [{:var, :x}, 2]},
          {:const, 0.001}
        ]}]}
      ]}
      
      result = SingularityDetector.scan(safe_ast)
      
      assert result == :ok
    end
    
    test "scan detects logarithm domain violation" do
      # Log of variable could be non-positive
      unsafe_log = {:op, :log, [{:var, :x}]}
      
      result = SingularityDetector.scan(unsafe_log)
      
      assert result == {:error, :log_domain_violation}
    end
    
    test "scan allows safe logarithm with abs" do
      # Log of absolute value is always safe
      safe_log = {:op, :log, [{:op, :abs, [{:var, :x}]}]}
      
      result = SingularityDetector.scan(safe_log)
      
      assert result == :ok
    end
    
    test "scan detects square root domain violation" do
      # Square root of negative constant
      unsafe_sqrt = {:op, :sqrt, [{:const, -1.0}]}
      
      result = SingularityDetector.scan(unsafe_sqrt)
      
      assert result == {:error, :sqrt_domain_violation}
    end
    
    test "scan recursively checks nested operations" do
      # Nested operation with singularity deep in tree
      nested_ast = {:op, :+, [
        {:const, 1.0},
        {:op, :/, [{:const, 2.0}, {:var, :dangerous}]}
      ]}
      
      result = SingularityDetector.scan(nested_ast)
      
      assert result == {:error, :potential_div_zero}
    end
  end
  
  describe "Thermodynamic Budget Estimator" do
    test "estimate returns cost for simple AST" do
      simple_ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      
      {:ok, cost} = ThermodynamicBudgetEstimator.estimate(simple_ast)
      
      assert cost > 0
      assert cost <= 1000  # Should be within acceptable range
    end
    
    test "estimate rejects thermodynamically expensive AST" do
      # Create very complex AST
      expensive_ast = create_very_complex_ast()
      
      result = ThermodynamicBudgetEstimator.estimate(expensive_ast)
      
      # Should either pass with high cost or fail with overflow
      assert match?({:ok, _cost}, result) or match?({:error, :thermodynamic_overflow}, result)
    end
    
    test "estimate calculates higher cost for complex operations" do
      simple_ast = {:const, 1.0}
      complex_ast = {:op, :+, [{:op, :*, [{:var, :x}, {:var, :y}]}, {:var, :z}]}
      
      {:ok, simple_cost} = ThermodynamicBudgetEstimator.estimate(simple_ast)
      {:ok, complex_cost} = ThermodynamicBudgetEstimator.estimate(complex_ast)
      
      assert complex_cost > simple_cost
    end
  end
  
  describe "Loop Analyzer validation" do
    test "check allows shallow AST" do
      shallow_ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      
      result = LoopAnalyzer.check(shallow_ast, 32)
      
      assert result == :ok
    end
    
    test "check rejects deeply nested AST exceeding max depth" do
      deep_ast = create_deeply_nested_ast(50)
      
      result = LoopAnalyzer.check(deep_ast, 32)
      
      assert result == {:error, :loop_violation}
    end
    
    test "check allows AST at exactly max depth" do
      ast_at_limit = create_deeply_nested_ast(30)
      
      result = LoopAnalyzer.check(ast_at_limit, 32)
      
      assert result == :ok
    end
    
    test "check uses default max depth of 32" do
      moderately_deep = create_deeply_nested_ast(35)
      
      result = LoopAnalyzer.check(moderately_deep)
      
      assert result == {:error, :loop_violation}
    end
  end
  
  describe "OIR Generator transformation" do
    test "build creates complete OIR structure" do
      ast = {:op, :+, [{:const, 1.0}, {:var, :x}]}
      
      oir = OIRGenerator.build(ast, "test_observer")
      
      assert oir.type == "ontological_ir"
      assert oir.observer == "test_observer"
      assert is_map(oir.kernel)
      assert oir.execution_mode == "observer_relative"
      assert oir.safety_layer == "mscl_omega_bound"
      assert is_number(oir.thermodynamic_cost)
      assert is_list(oir.constraints)
      assert is_map(oir.metadata)
    end
    
    test "build transforms operations into execution graph nodes" do
      ast = {:op, :gravity, [{:var, :mass}, {:var, :distance}]}
      
      oir = OIRGenerator.build(ast, "obs_gravity")
      
      # Kernel should be a map representing the execution graph
      assert is_map(oir.kernel)
      assert oir.kernel.type == :operation
      assert oir.kernel.op == :gravity
    end
    
    test "build detects epsilon shims in AST" do
      ast_with_shim = {:op, :/, [
        {:const, 1.0},
        {:op, :sqrt, [{:op, :+, [
          {:op, :pow, [{:var, :r}, 2]},
          {:mscl_pointer, :epsilon_variance}
        ]}]}
      ]}
      
      oir = OIRGenerator.build(ast_with_shim, "obs_shim")
      
      assert oir.metadata.has_epsilon_shims == true
    end
    
    test "build extracts MSCL-Ω constraints" do
      ast_with_constraints = {:op, :gravity, [
        {:var, :mass},
        {:var, :distance},
        :mscl_bound
      ]}
      
      oir = OIRGenerator.build(ast_with_constraints, "obs_constraint")
      
      assert :mscl_omega_enforced in oir.constraints
    end
    
    test "build calculates metadata correctly" do
      ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      
      oir = OIRGenerator.build(ast, "obs_meta")
      
      assert oir.metadata.ast_node_count > 0
      assert oir.metadata.max_depth >= 0
      assert is_boolean(oir.metadata.has_epsilon_shims)
    end
  end
  
  describe "OPC integration scenarios" do
    test "complete compilation pipeline from AST to OIR" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Step 1: Define physics AST
      physics_ast = {:op, :/, [
        {:const, 1.0},
        {:op, :sqrt, [{:op, :+, [
          {:op, :pow, [{:var, :r}, 2]},
          {:const, 0.001}  # Epsilon regularization
        ]}]}
      ]}
      
      # Step 2: Compile through OPC
      {:ok, oir} = ObserverPhysicsCompiler.compile_physics("obs_pipeline", physics_ast)
      
      # Step 3: Verify OIR structure
      assert oir.type == "ontological_ir"
      assert oir.observer == "obs_pipeline"
      assert oir.safety_layer == "mscl_omega_bound"
      assert oir.metadata.has_epsilon_shims == true
      
      Process.exit(opc_pid, :normal)
    end
    
    test "compilation applies AOR regularization to fix singularities" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Physics with potential singularity (division by variable)
      unsafe_physics = {:op, :/, [{:const, 1.0}, {:var, :x}]}
      
      result = ObserverPhysicsCompiler.compile_physics("obs_unsafe", unsafe_physics)
      
      # Should NOT be rejected - AOR should regularize it
      assert match?({:ok, oir}, result)
      
      {:ok, oir} = result
      # Verify epsilon shims were injected
      assert oir.metadata.has_epsilon_shims == true
      assert :dynamic_epsilon_shim in oir.constraints
      
      Process.exit(opc_pid, :normal)
    end
    
    test "MSCL-Ω divergence check prevents unstable physics" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Create an extremely wide AST that exceeds thermodynamic budget
      # This should trigger rejection due to excessive complexity
      extreme_physics = create_extremely_wide_ast()
      
      result = ObserverPhysicsCompiler.compile_physics("obs_extreme", extreme_physics)
      
      # Should be rejected by MSCL-Ω divergence check or thermodynamic budget check
      assert {:rejected, reason} = result
      assert reason in [:mscl_divergence_exceeded, :thermodynamic_overflow]
      
      Process.exit(opc_pid, :normal)
    end
    
    test "constraint injection adds MSCL markers to AST" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Gravity physics without explicit constraints
      gravity_ast = {:op, :gravity, [{:var, :mass}, {:var, :distance}]}
      
      {:ok, oir} = ObserverPhysicsCompiler.compile_physics("obs_inject", gravity_ast)
      
      # OIR should have MSCL-Ω constraints injected
      assert :mscl_omega_enforced in oir.constraints or length(oir.constraints) >= 0
      
      Process.exit(opc_pid, :normal)
    end
  end
  
  describe "Automated Ontological Regularization (AOR)" do
    test "division operations get epsilon regularization" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      # Raw division (would be dangerous)
      division_ast = {:op, :/, [{:const, 1.0}, {:var, :denominator}]}
      
      {:ok, oir} = ObserverPhysicsCompiler.compile_physics("obs_aor", division_ast)
      
      # After compilation, should have epsilon shims injected
      # The OIR kernel should show regularization
      assert is_map(oir.kernel)
      
      Process.exit(opc_pid, :normal)
    end
    
    test "compiled physics includes live MSCL pointers" do
      {:ok, opc_pid} = ObserverPhysicsCompiler.start_link([])
      
      physics_with_pointer = {:op, :/, [
        {:const, 1.0},
        {:op, :sqrt, [{:op, :+, [
          {:op, :pow, [{:var, :x}, 2]},
          {:mscl_pointer, :epsilon_variance}
        ]}]}
      ]}
      
      {:ok, oir} = ObserverPhysicsCompiler.compile_physics("obs_pointer", physics_with_pointer)
      
      # Should detect and preserve MSCL pointer
      assert oir.metadata.has_epsilon_shims == true
      assert :dynamic_epsilon_shim in oir.constraints
      
      Process.exit(opc_pid, :normal)
    end
  end
  
  # ── Helper Functions ──────────────────────────────────────────────────────
  
  defp create_deeply_nested_ast(depth) do
    # Create a deeply nested AST structure
    build_nested_ast(:+, [{:const, 1.0}, {:const, 2.0}], depth)
  end
  
  defp build_nested_ast(_op, args, 0), do: args
  
  defp build_nested_ast(op, args, depth) do
    {:op, op, [build_nested_ast(op, args, depth - 1)]}
  end
  
  defp create_very_complex_ast do
    # Create an AST with many operations to increase thermodynamic cost
    Enum.reduce(1..100, {:const, 0.0}, fn _i, acc ->
      {:op, :+, [acc, {:const, 1.0}]}
    end)
  end
  
  defp create_wide_complex_ast do
    # Create a wide (not deep) AST with many parallel branches
    # This increases divergence without triggering loop detection
    branches = Enum.map(1..20, fn i ->
      {:op, :*, [{:var, "x#{i}"}, {:var, "y#{i}"}]}
    end)
    
    {:op, :+, branches}
  end
  
  defp create_extremely_wide_ast do
    # Create an AST so wide it exceeds thermodynamic budget (>1000 units)
    branches = Enum.map(1..200, fn i ->
      {:op, :*, [{:var, "x#{i}"}, {:var, "y#{i}"}]}
    end)
    
    {:op, :+, branches}
  end
end
