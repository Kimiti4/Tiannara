defmodule TiannaraRuntime.Mathematics.InequalityKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.InequalityKernel

  test "reflexive bound is proved" do
    assert {:ok, :proved, %{rule: :reflexivity}} = InequalityKernel.prove({:le, :x, :x})
  end

  test "declared inequality can establish an interval bound" do
    assumptions = [{:le, 0, :x}, {:le, :x, 10}]
    assert {:ok, :proved, %{rule: :interval_assumption}} =
      InequalityKernel.bound(:x, {:interval, 0, 10}, assumptions)
  end

  test "sampling is not a proof" do
    assert {:ok, :not_established, _} =
      InequalityKernel.prove({:le, {:f, :x}, 10}, [{:sample, :x, 1, :f, 2}])
  end
end
