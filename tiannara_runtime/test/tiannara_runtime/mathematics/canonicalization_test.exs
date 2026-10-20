defmodule TiannaraRuntime.Mathematics.CanonicalizationTest do
  @moduledoc "Phase 16.X.3 — Canonicalization tests: canonicalize, canonical_hash, canonically_equivalent?, sort_commutative."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.Canonicalization
  alias TiannaraRuntime.Mathematics.SymbolicEngine

  # ---------------------------------------------------------------------------
  # sort_commutative (public)
  # ---------------------------------------------------------------------------

  describe "sort_commutative/1" do
    test "sorts operands of addition" do
      {:ok, a} = SymbolicEngine.constant(3)
      {:ok, b} = SymbolicEngine.constant(1)
      {:ok, c} = SymbolicEngine.variable("x")
      {:ok, expr} = SymbolicEngine.operator(:+, [a, b, c])

      sorted = Canonicalization.sort_commutative(expr)
      children_vals = Enum.map(sorted.children, & &1.value)
      assert children_vals == [1, 3, "x"]
    end

    test "leaves non-commutative operators unchanged" do
      {:ok, a} = SymbolicEngine.constant(3)
      {:ok, b} = SymbolicEngine.constant(1)
      {:ok, expr} = SymbolicEngine.operator(:-, [a, b])

      sorted = Canonicalization.sort_commutative(expr)
      assert sorted == expr
    end
  end

  # ---------------------------------------------------------------------------
  # canonicalize (tests internal fold_constants + eliminate_identities through
  # the public API)
  # ---------------------------------------------------------------------------

  describe "canonicalize/1" do
    test "folds 3 + 5 to 8" do
      {:ok, a} = SymbolicEngine.constant(3)
      {:ok, b} = SymbolicEngine.constant(5)
      {:ok, expr} = SymbolicEngine.operator(:+, [a, b])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :constant
      assert result.value == 8
    end

    test "folds nested addition of constants" do
      {:ok, a} = SymbolicEngine.constant(2)
      {:ok, b} = SymbolicEngine.constant(3)
      {:ok, c} = SymbolicEngine.constant(4)
      {:ok, sum} = SymbolicEngine.operator(:+, [a, b])
      {:ok, expr} = SymbolicEngine.operator(:+, [sum, c])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :constant
      assert result.value == 9
    end

    test "returns unchanged when no folding or identities apply" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y} = SymbolicEngine.variable("y")
      {:ok, expr} = SymbolicEngine.operator(:+, [x, y])

      result = Canonicalization.canonicalize(expr)
      assert result == expr
    end

    test "folds multiplication of constants" do
      {:ok, a} = SymbolicEngine.constant(6)
      {:ok, b} = SymbolicEngine.constant(7)
      {:ok, expr} = SymbolicEngine.operator(:*, [a, b])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :constant
      assert result.value == 42
    end

    test "x + 0 -> x (identity elimination via canonicalize)" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, zero} = SymbolicEngine.constant(0)
      {:ok, expr} = SymbolicEngine.operator(:+, [x, zero])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "x * 1 -> x (identity elimination via canonicalize)" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, one} = SymbolicEngine.constant(1)
      {:ok, expr} = SymbolicEngine.operator(:*, [x, one])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "x * 0 -> 0 (identity elimination via canonicalize)" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, zero} = SymbolicEngine.constant(0)
      {:ok, expr} = SymbolicEngine.operator(:*, [x, zero])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :constant
      assert result.value == 0
    end

    test "applies all canonicalization passes in sequence" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, zero} = SymbolicEngine.constant(0)
      {:ok, one} = SymbolicEngine.constant(1)
      {:ok, inner} = SymbolicEngine.operator(:+, [x, zero])
      {:ok, expr} = SymbolicEngine.operator(:*, [inner, one])

      result = Canonicalization.canonicalize(expr)
      assert result.type == :variable
      assert result.value == "x"
    end

    test "non-identity expression unchanged through canonicalize" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y} = SymbolicEngine.variable("y")
      {:ok, expr} = SymbolicEngine.operator(:+, [x, y])

      result = Canonicalization.canonicalize(expr)
      assert result == expr
    end
  end

  # ---------------------------------------------------------------------------
  # canonical_hash
  # ---------------------------------------------------------------------------

  describe "canonical_hash/1" do
    test "produces deterministic hash" do
      {:ok, x1} = SymbolicEngine.variable("x")
      {:ok, x2} = SymbolicEngine.variable("x")
      assert Canonicalization.canonical_hash(x1) == Canonicalization.canonical_hash(x2)
    end

    test "different expressions produce different hashes" do
      {:ok, x} = SymbolicEngine.variable("x")
      {:ok, y} = SymbolicEngine.variable("y")
      assert Canonicalization.canonical_hash(x) != Canonicalization.canonical_hash(y)
    end
  end

  # ---------------------------------------------------------------------------
  # canonically_equivalent?
  # ---------------------------------------------------------------------------

  describe "canonically_equivalent?/2" do
    test "3 + 5 and 5 + 3 are equivalent" do
      {:ok, a} = SymbolicEngine.constant(3)
      {:ok, b} = SymbolicEngine.constant(5)
      {:ok, c} = SymbolicEngine.constant(3)
      {:ok, d} = SymbolicEngine.constant(5)
      {:ok, e1} = SymbolicEngine.operator(:+, [a, b])
      {:ok, e2} = SymbolicEngine.operator(:+, [d, c])

      assert Canonicalization.canonically_equivalent?(e1, e2)
    end

    test "different expressions are not equivalent" do
      {:ok, a} = SymbolicEngine.constant(1)
      {:ok, b} = SymbolicEngine.constant(2)
      {:ok, e1} = SymbolicEngine.operator(:+, [a, b])
      {:ok, e2} = SymbolicEngine.operator(:*, [a, b])

      refute Canonicalization.canonically_equivalent?(e1, e2)
    end
  end
end
