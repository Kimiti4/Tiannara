defmodule TiannaraRuntime.Mathematics.LimitKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.LimitKernel

  test "constant sequence has an exact limit" do
    {:ok, claim} = LimitKernel.define({:constant, 3}, :n, 3, :natural_numbers)
    assert {:ok, :proved, %{rule: :constant_sequence}} = LimitKernel.prove(claim)
  end

  test "finite observations do not prove convergence" do
    {:ok, claim} = LimitKernel.define({:samples, [1, 1, 1]}, :n, 1, :natural_numbers)
    assert {:ok, :not_established, _} = LimitKernel.prove(claim)
  end

  test "verified backend evidence can establish a limit" do
    claim = %{sequence: :s, variable: :n, target: 0,
              evidence: %{status: :proved, verifier_id: "limit-v1"}}
    assert {:ok, :proved, %{rule: :verified_limit_backend}} = LimitKernel.prove(claim)
  end
end
