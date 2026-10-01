defmodule TiannaraRuntime.Mathematics.QuantifiedLogicKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.QuantifiedLogicKernel

  test "finite forall requires every domain member" do
    proposition = {:eq, {:var, :x}, {:var, :x}}
    assert {:ok, :proved, %{rule: :finite_forall_intro}} =
      QuantifiedLogicKernel.prove({:forall, :x, [1, 2, 3], proposition})
  end

  test "finite forall is not generalized beyond its declared domain" do
    proposition = {:eq, {:var, :x}, 1}
    assert {:ok, :not_established, _} =
      QuantifiedLogicKernel.prove({:forall, :x, [1, 2, 3], proposition})
  end

  test "finite exists records a witness" do
    proposition = {:eq, {:var, :x}, 2}
    assert {:ok, :proved, %{rule: :finite_exists_intro, witness: 2}} =
      QuantifiedLogicKernel.prove({:exists, :x, [1, 2, 3], proposition})
  end
end
