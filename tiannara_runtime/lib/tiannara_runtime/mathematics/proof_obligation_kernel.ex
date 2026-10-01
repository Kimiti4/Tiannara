defmodule TiannaraRuntime.Mathematics.ProofObligationKernel do
  @moduledoc """
  Decomposes theorem claims into explicit proof obligations.

  This is an orchestration layer only: creating obligations never establishes
  their truth. Each obligation must eventually be discharged by an independent
  proof or verified theorem dependency.
  """

  def create(theorem, obligations) when is_list(obligations) do
    {:ok, %{
      theorem: theorem,
      obligations:
        Enum.with_index(obligations, 1)
        |> Enum.map(fn {claim, id} ->
          %{id: id, claim: claim, status: :open, dependencies: []}
        end),
      status: if(obligations == [], do: :invalid, else: :open),
      proof_status: :unproved,
      certification_eligible: false
    }}
  end

  def add_dependency(plan, obligation_id, dependency)
      when is_map(plan) and is_integer(obligation_id) do
    update_obligation(plan, obligation_id, fn obligation ->
      %{obligation | dependencies: obligation.dependencies ++ [dependency]}
    end)
  end

  def discharge(plan, obligation_id, evidence)
      when is_map(plan) and is_integer(obligation_id) and is_map(evidence) do
    if verified_evidence?(evidence) do
      update_obligation(plan, obligation_id, fn obligation ->
        %{obligation | status: :discharged, evidence: evidence}
      end)
    else
      {:error, :independent_verified_evidence_required}
    end
  end

  def status(plan) when is_map(plan) do
    open = Enum.count(plan.obligations, &(&1.status == :open))
    discharged = Enum.count(plan.obligations, &(&1.status == :discharged))

    {:ok, %{open: open, discharged: discharged,
            complete: open == 0 and discharged > 0,
            proof_status: if(open == 0 and discharged > 0, do: :all_obligations_discharged,
              else: :unproved)}}
  end

  defp update_obligation(plan, id, fun) do
    case Enum.any?(plan.obligations, &(&1.id == id)) do
      true ->
        {:ok, %{plan | obligations: Enum.map(plan.obligations,
          fn obligation -> if obligation.id == id, do: fun.(obligation), else: obligation end)}}
      false -> {:error, :obligation_not_found}
    end
  end

  defp verified_evidence?(%{status: :proved}), do: true
  defp verified_evidence?(%{verified: true}), do: true
  defp verified_evidence?(_), do: false
end
