defmodule TiannaraRuntime.Mathematics.LyapunovKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.LyapunovKernel

  test "proved positive definite and negative derivative create a stability candidate" do
    {:ok, candidate} = LyapunovKernel.candidate(:V, :origin)
    assert {:ok, result} =
      LyapunovKernel.verify(candidate, %{
        positive_definite: :proved,
        derivative_condition: :negative_definite
      })

    assert result.certificate_status == :local_asymptotic_stability_candidate
    assert result.certification_eligible == false
  end

  test "simulation evidence alone does not certify stability" do
    {:ok, candidate} = LyapunovKernel.candidate(:V, :origin)
    assert {:ok, result} =
      LyapunovKernel.verify(candidate, %{simulation_stable: true})

    assert result.certificate_status == :unproved
    assert result.certification_eligible == false
  end
end
