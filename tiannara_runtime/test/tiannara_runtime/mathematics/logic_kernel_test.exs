defmodule TiannaraRuntime.Mathematics.LogicKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.LogicKernel

  test "assumption proves implication" do
    assert {:ok, :proved, %{rule: :implication_intro}} =
      LogicKernel.prove({:implies, :p, :p})
  end

  test "conjunction requires both propositions" do
    assert {:ok, :proved, %{rule: :and_intro}} =
      LogicKernel.prove({:and, :p, :q}, [:p, :q])
  end

  test "unsupported derivation remains unestablished" do
    assert {:ok, :not_established, _} = LogicKernel.prove(:q, [:p])
  end
end
