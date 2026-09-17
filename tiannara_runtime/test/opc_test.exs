defmodule Tiannara.OPCTest do
  use ExUnit.Case, async: true
  
  alias Tiannara.OPC.Parser.Lexer
  alias Tiannara.OPC.Parser.Parser
  alias Tiannara.OPC.Parser.AST
  alias Tiannara.OPC.Validator.SymbolicValidator
  alias Tiannara.OPC.AOR.Regularizer
  alias Tiannara.OPC.OIR.IRBuilder
  alias Tiannara.OPC.Compiler.GPUCompiler
  alias Tiannara.OPC.API.CompileAPI

  describe "Lexer" do
    test "tokenizes simple expression" do
      tokens = Lexer.tokenize("gravity * 9.81")
      
      assert {:identifier, :gravity} in tokens
      assert {:operator, :*} in tokens
      assert {:number, 9.81} in tokens
    end

    test "tokenizes complex expression" do
      tokens = Lexer.tokenize("velocity ^ 2 + acceleration * time")
      
      assert length(tokens) > 0
      assert {:identifier, :velocity} in tokens
      assert {:operator, :^} in tokens
      assert {:number, 2.0} in tokens
    end

    test "handles parentheses" do
      tokens = Lexer.tokenize("(a + b) * c")
      
      assert {:paren, :open} in tokens
      assert {:paren, :close} in tokens
    end
  end

  describe "Parser" do
    test "parses simple multiplication" do
      {:ok, ast} = Parser.parse("gravity * 9.81")
      
      assert {:binary_op, :*, {:identifier, :gravity}, {:number, 9.81}} = ast
    end

    test "parses addition" do
      {:ok, ast} = Parser.parse("a + b")
      
      assert {:binary_op, :+, {:identifier, :a}, {:identifier, :b}} = ast
    end

    test "parses nested expressions" do
      {:ok, ast} = Parser.parse("(a + b) * c")
      
      assert {:binary_op, :*, _, _} = ast
    end

    test "parses function calls" do
      {:ok, ast} = Parser.parse("sqrt(9.0)")
      
      assert {:function, :sqrt, [{:number, 9.0}]} = ast
    end

    test "rejects invalid syntax" do
      result = Parser.parse("gravity *")
      
      assert elem(result, 0) == :error
    end

    test "enforces AST depth limit" do
      # Create deeply nested expression
      deep_expr = String.duplicate("(1 + ", 20) <> "1" <> String.duplicate(")", 20)
      
      result = Parser.parse(deep_expr)
      
      assert elem(result, 0) == :error
    end
  end

  describe "AST" do
    test "calculates depth correctly" do
      ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
      
      assert AST.depth(ast) == 2
    end

    test "validates allowed operations" do
      valid_ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
      
      assert AST.validate_operations(valid_ast) == :ok
    end

    test "rejects invalid operations" do
      invalid_ast = {:binary_op, :invalid_op, {:number, 1.0}, {:number, 2.0}}
      
      assert {:error, _} = AST.validate_operations(invalid_ast)
    end
  end

  describe "SymbolicValidator" do
    test "validates stable expressions" do
      ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
      
      assert {:ok, :stable} = SymbolicValidator.validate(ast)
    end

    test "detects division by zero" do
      ast = {:binary_op, :/, {:number, 1.0}, {:number, 0.0}}
      
      assert {:error, :division_by_zero} = SymbolicValidator.validate(ast)
    end

    test "detects recursive instability" do
      # Manually create deeply nested AST
      deep_ast = create_deep_ast(20)
      
      assert {:error, :recursive_instability} = SymbolicValidator.validate(deep_ast)
    end

    test "validates sqrt domain" do
      ast = {:unary_op, :sqrt, {:number, -1.0}}
      
      assert {:error, :sqrt_negative_domain} = SymbolicValidator.validate(ast)
    end

    test "detects exponential blowup risk" do
      ast = {:binary_op, :^, {:number, 200.0}, {:number, 15.0}}
      
      assert {:error, :exponential_blowup_risk} = SymbolicValidator.validate(ast)
    end
  end

  describe "AOR Regularizer" do
    test "injects epsilon shim for division" do
      ast = {:binary_op, :/, {:number, 1.0}, {:number, 2.0}}
      
      regularized = Regularizer.regularize(ast)
      
      # Should wrap divisor with sqrt(x^2 + epsilon^2)
      assert {:binary_op, :/, _, {:function, :sqrt, _}} = regularized
    end

    test "preserves other operations" do
      ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
      
      regularized = Regularizer.regularize(ast)
      
      assert {:binary_op, :+, {:number, 1.0}, {:number, 2.0}} = regularized
    end
  end

  describe "OIR Builder" do
    test "builds OIR from simple AST" do
      ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
      
      oir = IRBuilder.build(ast)
      
      assert length(oir) > 0
      assert {:load_const, 1.0} in oir
      assert {:load_const, 2.0} in oir
      assert {:binary_exec, :+} in oir
    end

    test "builds OIR for identifiers" do
      ast = {:identifier, :gravity}
      
      oir = IRBuilder.build(ast)
      
      assert {:load_var, :gravity} in oir
    end
  end

  describe "GPU Compiler" do
    test "compiles OIR to GLSL" do
      oir = [
        {:load_const, 1.0},
        {:load_const, 2.0},
        {:binary_exec, :+}
      ]
      
      {:ok, shader} = GPUCompiler.compile_oir(oir)
      
      assert is_binary(shader)
      assert String.contains?(shader, "#version 310 es")
      assert String.contains?(shader, "void main()")
    end

    test "generates stack-based code" do
      oir = [{:load_const, 5.0}]
      
      {:ok, shader} = GPUCompiler.compile_oir(oir)
      
      assert String.contains?(shader, "stack[sp++]")
    end
  end

  describe "CompileAPI Integration" do
    test "compiles and executes simple physics" do
      {:ok, result} = CompileAPI.compile_physics("obs_test", "gravity * 9.81")
      
      assert result.observer_id == "obs_test"
      assert result.expression == "gravity * 9.81"
      assert result.ast_depth > 0
      assert result.oir_instructions_optimized > 0
      assert result.shader_length > 0
      assert Map.has_key?(result, :execution)
    end

    test "validates before compilation" do
      result = CompileAPI.validate_only("gravity * 9.81")
      
      assert {:ok, :valid} = result
    end

    test "rejects invalid expressions" do
      result = CompileAPI.validate_only("gravity / 0")
      
      assert elem(result, 0) == :error
    end

    test "provides compilation metrics" do
      {:ok, result} = CompileAPI.compile_physics("obs_metrics", "velocity ^ 2 + acceleration")
      
      assert is_number(result.ast_depth)
      assert is_number(result.oir_instructions_optimized)
      assert is_number(result.shader_length)
    end
  end

  # Helper functions
  defp create_deep_ast(0), do: {:number, 1.0}
  defp create_deep_ast(n), do: {:binary_op, :+, {:number, 1.0}, create_deep_ast(n - 1)}
end
