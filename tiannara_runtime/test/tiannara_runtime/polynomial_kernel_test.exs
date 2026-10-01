defmodule TiannaraRuntime.Mathematics.PolynomialKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{PolynomialKernel, AlgebraProofRules}

  test "polynomial addition combines like powers" do
    assert {:ok, [{0, 3}, {1, 2}]} =
      PolynomialKernel.add([{0, 1}, {1, 2}], [{0, 2}])
  end

  test "polynomial multiplication is exact over the representation" do
    assert {:ok, [{0, 1}, {1, 2}, {2, 1}]} =
      PolynomialKernel.multiply([{0, 1}, {1, 1}], [{0, 1}, {1, 1}])
  end

  test "derivative transforms coefficients and powers exactly" do
    assert {:ok, [{0, 3}, {1, 4}]} =
      PolynomialKernel.derivative([{1, 3}, {2, 2}])
  end

  test "algebra proof rule remains a generated step" do
    assert {:ok, step} =
      AlgebraProofRules.derivative([{1, 3}, {2, 2}])
    assert step.status == :generated
    assert step.evidence_class == :exact_symbolic_transformation
  end
end
