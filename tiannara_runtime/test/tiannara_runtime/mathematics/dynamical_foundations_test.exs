defmodule TiannaraRuntime.Mathematics.DynamicalFoundationsTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{WellPosednessKernel, InvariantKernel}

  test "numerical success does not establish well-posedness" do
    {:ok, problem} = WellPosednessKernel.define(%{equation: :ode})
    {:ok, result} = WellPosednessKernel.verify(problem, %{numerical_run: :successful})
    assert result.well_posed_status == :unproved
    assert result.certification_eligible == false
  end

  test "explicit existence and uniqueness evidence establishes a candidate" do
    {:ok, problem} = WellPosednessKernel.define(%{equation: :ode})
    {:ok, result} =
      WellPosednessKernel.verify(problem, %{existence: :proved, uniqueness: :proved})

    assert result.well_posed_status == :locally_well_posed_candidate
  end

  test "a proven zero derivative establishes a mathematical invariant" do
    {:ok, candidate} = InvariantKernel.candidate(:energy, :dynamics)
    {:ok, result} =
      InvariantKernel.verify(candidate, %{derivative_along_flow: :zero_proved})

    assert result.invariant_status == :mathematically_proved
    assert result.certification_eligible == false
  end
end
