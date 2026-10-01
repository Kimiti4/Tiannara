defmodule TiannaraRuntime.Mathematics.ProofComposerTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.ProofComposer

  test "only proved fragments can be composed" do
    assert {:ok, %{status: :composed}} =
      ProofComposer.compose([%{status: :proved, evidence: %{kernel: :logic_v1}}])
  end

  test "unsupported fragments cannot enter a composed proof" do
    assert {:error, :unproved_fragment_present} =
      ProofComposer.compose([%{status: :supported, evidence: %{tests: 10}}])
  end
end
