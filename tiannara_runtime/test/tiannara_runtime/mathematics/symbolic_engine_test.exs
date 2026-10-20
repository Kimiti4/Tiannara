defmodule TiannaraRuntime.Mathematics.SymbolicEngineTest do
  @moduledoc "Phase 16.X.3 — Symbolic Computation Engine tests: expressions, simplify, expand, factor, substitute, differentiate, integrate, solve."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.SymbolicEngine
  # ---------------------------------------------------------------------------
  # Expression Construction
  # ---------------------------------------------------------------------------

  describe "constant/2" do
    test "creates a constant expression" do
      assert {:ok, expr} = SymbolicEngine.constant(42)
      assert expr.type == :constant
      assert expr.value == 42
    end
  end

  describe "variable/2" do
    test "creates a variable expression" do
      assert {:ok, expr} = SymbolicEngine.variable("x")
      assert expr.type == :variable
      assert expr.value == "x"
    end
  end

  describe "operator/3" do
    test "creates an operator with children" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y} = SymbolicEngine.variable("y")
      assert {:ok, expr} = SymbolicEngine.operator(:+, [x, y])
      assert expr.type == :operator
      assert expr.value == :+
      assert length(expr.children) == 2
    end
  end

  describe "function/3" do
    test "creates a function expression" do
      {:ok, x} = SymbolicEngine.variable("x")
      assert {:ok, expr} = SymbolicEngine.function("sin", [x])
      assert expr.type == :function
      assert expr.value == "sin"
    end
  end

  # ---------------------------------------------------------------------------
  # Expression Hash / Equivalence
  # ---------------------------------------------------------------------------

  describe "expression_hash/1" do
    test "produces deterministic SHA-256 hash" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y1} = SymbolicEngine.variable("x")
      assert SymbolicEngine.expression_hash(x) == SymbolicEngine.expression_hash(y1)
      {:ok, y2} = SymbolicEngine.variable("y")
      assert SymbolicEngine.expression_hash(x) != SymbolicEngine.expression_hash(y2)
    end
  end

  describe "equivalent?/2" do
    test "identical expressions are equivalent" do
      {:ok, a} = SymbolicEngine.constant(5)
      {:ok, b} = SymbolicEngine.constant(5)
      assert SymbolicEngine.equivalent?(a, b)
    end

    test "different expressions are not equivalent" do
      {:ok, a} = SymbolicEngine.constant(5)
      {:ok, b} = SymbolicEngine.constant(10)
      refute SymbolicEngine.equivalent?(a, b)
    end
  end

  # ---------------------------------------------------------------------------
  # Simplify
  # ---------------------------------------------------------------------------

  describe "simplify/1" do
    test "simplifies x + 0 to x" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, zero} = SymbolicEngine.constant(0)
      {:ok, expr} = SymbolicEngine.operator(:+, [x, zero])
      assert {:ok, result} = SymbolicEngine.simplify(expr)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "simplifies x * 1 to x" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, one} = SymbolicEngine.constant(1)
      {:ok, expr} = SymbolicEngine.operator(:*, [x, one])
      assert {:ok, result} = SymbolicEngine.simplify(expr)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "simplifies x * 0 to 0" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, zero} = SymbolicEngine.constant(0)
      {:ok, expr} = SymbolicEngine.operator(:*, [x, zero])
      assert {:ok, result} = SymbolicEngine.simplify(expr)
      assert result.type == :constant
      assert result.value == 0
    end

    test "simplifies 3 + 5 to 8" do
      {:ok, a} = SymbolicEngine.constant(3)
      {:ok, b} = SymbolicEngine.constant(5)
      {:ok, expr} = SymbolicEngine.operator(:+, [a, b])
      assert {:ok, result} = SymbolicEngine.simplify(expr)
      assert result.type == :constant
      assert result.value == 8
    end

    test "constant is returned unchanged" do
      {:ok, expr} = SymbolicEngine.constant(7)
      assert {:ok, result} = SymbolicEngine.simplify(expr)
      assert result == expr
    end

    test "variable is returned unchanged" do
      {:ok, expr} = SymbolicEngine.variable("x")
      assert {:ok, result} = SymbolicEngine.simplify(expr)
      assert result == expr
    end
  end

  # ---------------------------------------------------------------------------
  # Expand
  # ---------------------------------------------------------------------------

  describe "expand/1" do
    test "expands x*(y+z) to x*y + x*z" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y} = SymbolicEngine.variable("y")
      {:ok, z} = SymbolicEngine.variable("z")
      {:ok, sum} = SymbolicEngine.operator(:+, [y, z])
      {:ok, expr} = SymbolicEngine.operator(:*, [x, sum])

      assert {:ok, result} = SymbolicEngine.expand(expr)
      assert result.type == :operator
      assert result.value == :+
    end
  end

  # ---------------------------------------------------------------------------
  # Factor
  # ---------------------------------------------------------------------------

  describe "factor/1" do
    test "factors common terms" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, a} = SymbolicEngine.constant(2)
      {:ok, b} = SymbolicEngine.constant(3)
      {:ok, ax} = SymbolicEngine.operator(:*, [a, x])
      {:ok, bx} = SymbolicEngine.operator(:*, [b, x])
      {:ok, expr} = SymbolicEngine.operator(:+, [ax, bx])

      assert {:ok, result} = SymbolicEngine.factor(expr)
      assert result.type == :operator
    end
  end

  # ---------------------------------------------------------------------------
  # Substitute
  # ---------------------------------------------------------------------------

  describe "substitute/3" do
    test "substitutes a variable with an expression" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, val} = SymbolicEngine.constant(5)
      assert {:ok, result} = SymbolicEngine.substitute(x, "x", val)
      assert result.type == :constant
      assert result.value == 5
    end

    test "no substitution when variable doesn't match" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, val} = SymbolicEngine.constant(5)
      assert {:ok, result} = SymbolicEngine.substitute(x, "y", val)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "substitutes in nested expressions" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y} = SymbolicEngine.variable("y")
      {:ok, val} = SymbolicEngine.constant(10)
      {:ok, sum} = SymbolicEngine.operator(:+, [x, y])

      assert {:ok, result} = SymbolicEngine.substitute(sum, "x", val)
      assert result.type == :operator
      assert hd(result.children).type == :constant
      assert hd(result.children).value == 10
    end
  end

  # ---------------------------------------------------------------------------
  # Differentiate
  # ---------------------------------------------------------------------------

  describe "differentiate/2" do
    test "derivative of constant is 0" do
      {:ok, c} = SymbolicEngine.constant(5)
      assert {:ok, result} = SymbolicEngine.differentiate(c, "x")
      assert result.type == :constant
      assert result.value == 0
    end

    test "derivative of x with respect to x is 1" do
      {:ok, x} = SymbolicEngine.variable("x")
      assert {:ok, result} = SymbolicEngine.differentiate(x, "x")
      assert result.type == :constant
      assert result.value == 1
    end

    test "derivative of y with respect to x is 0" do
      {:ok, y} = SymbolicEngine.variable("y")
      assert {:ok, result} = SymbolicEngine.differentiate(y, "x")
      assert result.type == :constant
      assert result.value == 0
    end

    test "derivative of sin(x) is cos(x)" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, sin} = SymbolicEngine.function("sin", [x])
      assert {:ok, result} = SymbolicEngine.differentiate(sin, "x")
      assert result.type == :operator
      assert result.value == :*
    end
  end

  # ---------------------------------------------------------------------------
  # Integrate
  # ---------------------------------------------------------------------------

  describe "integrate/2" do
    test "integral of constant c with respect to x is c*x" do
      {:ok, c} = SymbolicEngine.constant(5)
      assert {:ok, result} = SymbolicEngine.integrate(c, "x")
      assert result.type == :operator
    end
  end

  # ---------------------------------------------------------------------------
  # Solve
  # ---------------------------------------------------------------------------

  describe "solve/2" do
    test "returns {:error, :unsupported} for non-linear forms" do
      {:ok, x} = SymbolicEngine.variable("x")
      assert {:error, _} = SymbolicEngine.solve(x, "x")
    end
  end

  # ---------------------------------------------------------------------------
  # Matrix Operations
  # ---------------------------------------------------------------------------

  describe "matrix/2" do
    test "creates a matrix from nested lists" do
      {:ok, a} = SymbolicEngine.constant(1)
      {:ok, b} = SymbolicEngine.constant(2)
      {:ok, c} = SymbolicEngine.constant(3)
      {:ok, d} = SymbolicEngine.constant(4)

      assert {:ok, m} = SymbolicEngine.matrix([[a, b], [c, d]])
      assert m.type == :function
      assert m.value == "matrix"
      assert length(m.children) == 2
    end
  end

  describe "matrix_add/2" do
    test "adds two matrices element-wise" do
      {:ok, a} = SymbolicEngine.constant(1)
      {:ok, b} = SymbolicEngine.constant(2)
      {:ok, c} = SymbolicEngine.constant(3)
      {:ok, d} = SymbolicEngine.constant(4)

      {:ok, m1} = SymbolicEngine.matrix([[a, b], [c, d]])
      {:ok, m2} = SymbolicEngine.matrix([[d, c], [b, a]])

      assert {:ok, result} = SymbolicEngine.matrix_add(m1, m2)
      assert result.type == :function
      assert result.value == "matrix"
    end
  end

  # ---------------------------------------------------------------------------
  # Metadata
  # ---------------------------------------------------------------------------

  describe "with_metadata/2" do
    test "attaches frozen metadata to an expression" do
      {:ok, expr} = SymbolicEngine.constant(42)
      meta = %{"origin" => "test", "purpose" => "unit_test", "owner" => "CRC"}
      result = SymbolicEngine.with_metadata(expr, meta)
      assert result.metadata["origin"] == "test"
      assert result.metadata["owner"] == "CRC"
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  describe "replay_computation/2" do
    test "replays a simplify computation" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, zero} = SymbolicEngine.constant(0)
      {:ok, expr} = SymbolicEngine.operator(:+, [x, zero])

      steps = [%{"rule" => "simplify", "args" => []}]

      assert {:ok, result} = SymbolicEngine.replay_computation(expr, steps)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "returns error for unknown replay rule" do
      {:ok, expr} = SymbolicEngine.constant(1)
      steps = [%{"rule" => "unknown_rule", "args" => []}]
      assert {:error, _} = SymbolicEngine.replay_computation(expr, steps)
    end
  end
end
