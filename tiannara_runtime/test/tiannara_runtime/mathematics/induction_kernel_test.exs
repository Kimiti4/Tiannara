defmodule TiannaraRuntime.Mathematics.InductionKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.InductionKernel

  test "induction requires base and step evidence" do
    schema = %{
      variable: :n,
      base: {:proved, %{case: 0, evidence: :base}},
      step: {:proved, %{assumption: {:n, :n}, conclusion: :p_next}},
      target: :p
    }

    assert {:ok, :proved, %{rule: :natural_induction}} =
      InductionKernel.prove(schema)
  end

  test "finite examples do not constitute induction" do
    schema = %{variable: :n, base: {:examples, [0, 1, 2]}, step: {:examples, [0, 1]}}
    assert {:error, :base_case_not_proved} = InductionKernel.prove(schema)
  end

  test "missing induction step is blocked" do
    schema = %{variable: :n, base: {:proved, %{case: 0}}, step: :unknown, target: :p}
    assert {:error, :induction_step_not_proved} = InductionKernel.prove(schema)
  end
end
