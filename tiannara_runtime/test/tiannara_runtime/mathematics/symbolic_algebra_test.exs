defmodule TiannaraRuntime.Mathematics.SymbolicAlgebraTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{SymbolicAlgebra, ConjectureKernel}

  test "normalization removes neutral algebraic elements" do
    expression = {:add, {:mul, {:constant, 1}, {:var, :x}}, {:constant, 0}}
    assert SymbolicAlgebra.normalize(expression) == {:var, :x}
  end

  test "double negation normalizes" do
    assert SymbolicAlgebra.equivalent?({:neg, {:neg, {:var, :x}}}, {:var, :x})
  end

  test "conjectures remain unproved after special-case testing" do
    {:ok, conjecture} = ConjectureKernel.propose(:identity_x, :pattern_observed)
    {:ok, result} =
      ConjectureKernel.test_special_cases(conjecture, [
        %{left: {:var, :x}, right: {:var, :x}},
        %{left: {:add, {:var, :x}, {:constant, 0}}, right: {:var, :x}}
      ])

    assert result.status == :conjecture
    assert result.proof_status == :unproved
    assert result.counterexample_status == :not_falsified
  end

  test "conjectures cannot self-promote" do
    {:ok, conjecture} = ConjectureKernel.propose(:new_theorem, :pattern)
    assert {:error, :independent_proof_required} =
      ConjectureKernel.promote_to_theorem(conjecture)
  end
end
