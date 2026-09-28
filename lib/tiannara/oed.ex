defmodule Tiannara.OED do
  @moduledoc """
  Ontological Emergence/Executive Doctrine validation gate.

  OED does not grant authority merely because a plan exists. It validates
  structure, bounded execution budgets, evidence requirements and explicit
  human gates before a plan may cross into privileged runtime layers.
  """

  @required_keys [:objective, :steps]
  @max_steps 32

  def validate_constitution(plan) when is_map(plan) do
    missing = Enum.filter(@required_keys, &(not Map.has_key?(plan, &1)))
    steps = Map.get(plan, :steps, [])

    cond do
      missing != [] -> {:error, {:missing_fields, missing}}
      not is_list(steps) or steps == [] -> {:error, :empty_execution_plan}
      length(steps) > @max_steps -> {:error, :execution_budget_exceeded}
      Enum.any?(steps, &(&1 in [:self_modify, :constitution_write, :unreviewed_deploy])) ->
        {:error, :privileged_action_requires_human_gate}
      true ->
        {:ok, Map.put(plan, :oed_validation, %{status: :approved, evidence_required: true})}
    end
  end
  def validate_constitution(_), do: {:error, :invalid_execution_plan}

  def cross_validate_conclusion(output) when is_map(output) do
    evidence = Map.get(output, :evidence, Map.get(output, "evidence"))
    provenance = Map.get(output, :provenance, Map.get(output, "provenance"))

    cond do
      is_nil(evidence) -> {:error, :missing_evidence}
      is_nil(provenance) -> {:error, :missing_provenance}
      true -> {:ok, Map.put(output, :oed_cross_validation, :evidence_and_provenance_present)}
    end
  end
  def cross_validate_conclusion(_), do: {:error, :invalid_domain_output}
end
