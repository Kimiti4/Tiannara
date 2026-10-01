defmodule TiannaraRuntime.Mathematics.InductionKernel do
  @moduledoc """
  Structural proof kernel for ordinary induction over natural-number predicates.

  A proof requires an explicit base proof and an induction-step proof schema.
  Checking several finite cases is never treated as an induction proof.
  """

  def prove(%{variable: variable, base: base, step: step, target: target})
      when is_atom(variable) do
    with {:ok, base_evidence} <- prove_base(base),
         {:ok, step_evidence} <- prove_step(variable, step) do
      {:ok, :proved, %{
        rule: :natural_induction,
        variable: variable,
        target: target,
        base: base_evidence,
        step: step_evidence
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def prove(_), do: {:error, :induction_schema_required}

  defp prove_base({:proved, evidence}), do: {:ok, evidence}
  defp prove_base(_), do: {:error, :base_case_not_proved}

  defp prove_step(variable, {:proved, %{assumption: {^variable, :n}, conclusion: conclusion} = evidence})
       when not is_nil(conclusion),
       do: {:ok, Map.put(evidence, :rule, :induction_step)}

  defp prove_step(_variable, _), do: {:error, :induction_step_not_proved}
end
