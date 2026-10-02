defmodule Tiannara.Sentinel.CrossWorldTheoryExperiment do
  @moduledoc """
  Executes quarantined cross-world theory transfers against explicit scenarios.

  This module is orchestration only: it never treats a simulation result as
  operational truth. A real executor must be supplied; there is deliberately no
  mock or fallback executor. Every scenario produces a child Sentinel evidence
  record linked to the source theory.
  """

  alias Tiannara.Sentinel.CrossWorldTheoryTransfer
  alias Tiannara.Sentinel.MathematicalEvidence

  @type executor ::
          (map() -> {:ok, map()} | {:error, term()})

  @spec run(map(), [map()], executor() | nil) :: {:ok, map()} | {:error, term()}
  def run(transfer, scenarios, executor)
      when is_map(transfer) and is_list(scenarios) do
    with :ok <- validate_transfer(transfer),
         :ok <- validate_scenarios(scenarios),
         :ok <- require_executor(executor),
         {:ok, results} <- execute_scenarios(transfer, scenarios, executor, []) do
      {:ok, %{
        transfer_id: transfer.transfer_id,
        source_evidence_id: transfer.source_evidence_id,
        scenarios: results,
        scenario_count: length(results),
        execution_mode: :simulation,
        evidence_class: :simulated,
        certification_eligible: false
      }}
    end
  end

  def run(_, _, _), do: {:error, :invalid_cross_world_experiment}

  defp execute_scenarios(_transfer, [], _executor, acc), do: {:ok, Enum.reverse(acc)}

  defp execute_scenarios(transfer, [scenario | rest], executor, acc) do
    bound = bind_scenario(transfer, scenario)

    case executor.(bound) do
      {:ok, outcome} when is_map(outcome) ->
        with {:ok, result} <- normalize_result(bound, outcome),
             {:ok, transfer_result} <- CrossWorldTheoryTransfer.record_result(transfer, result),
             {:ok, evidence} <- persist_evidence(transfer, bound, transfer_result) do
          execute_scenarios(
            transfer,
            rest,
            executor,
            [Map.merge(transfer_result, %{evidence_id: evidence.id, scenario: bound}) | acc]
          )
        end

      {:error, reason} ->
        {:error, {:scenario_execution_failed, bound.scenario_id, reason}}

      other ->
        {:error, {:invalid_scenario_executor_result, bound.scenario_id, other}}
    end
  end

  defp bind_scenario(transfer, scenario) do
    Map.merge(%{
      transfer_id: transfer.transfer_id,
      source_evidence_id: transfer.source_evidence_id,
      theory: transfer.theory,
      inherited_assumptions: transfer.assumptions,
      target_world_id: transfer.target_world_id,
      target_civilization_id: transfer.target_civilization_id,
      execution_mode: :simulation,
      evidence_class: :simulated
    }, scenario)
  end

  defp normalize_result(scenario, outcome) do
    with :ok <- require(outcome, :outcome),
         :ok <- validate_outcome(outcome.outcome) do
      {:ok, %{
        scenario_id: scenario.scenario_id,
        outcome: outcome.outcome,
        observations: Map.get(outcome, :observations, []),
        counterevidence: Map.get(outcome, :counterevidence, []),
        assumptions_held: Map.get(outcome, :assumptions_held, scenario.inherited_assumptions),
        assumptions_changed: Map.get(outcome, :assumptions_changed, []),
        execution_mode: :simulation,
        evidence_class: :simulated
      }}
    end
  end

  defp persist_evidence(transfer, scenario, result) do
    MathematicalEvidence.store(%{
      kind: :scientific_reasoning,
      statement: transfer.theory,
      artifact: %{
        transfer_id: transfer.transfer_id,
        scenario_id: scenario.scenario_id,
        target_world_id: scenario.target_world_id,
        target_civilization_id: Map.get(scenario, :target_civilization_id),
        controlled_variables: Map.get(scenario, :controlled_variables, %{}),
        changed_variables: Map.get(scenario, :changed_variables, %{}),
        seed: Map.get(scenario, :seed),
        outcome: result.outcome
      },
      evidence: %{
        observations: result.observations,
        counterevidence: result.counterevidence,
        evidence_class: :simulated,
        execution_mode: :simulation,
        certification_eligible: false
      },
      status: outcome_status(result.outcome),
      assumptions: result.assumptions_held ++ result.assumptions_changed,
      provenance: %{
        source_evidence_id: transfer.source_evidence_id,
        transfer_id: transfer.transfer_id,
        scenario_id: scenario.scenario_id,
        target_world_id: scenario.target_world_id,
        target_civilization_id: Map.get(scenario, :target_civilization_id)
      },
      parent_ids: [transfer.source_evidence_id]
    })
  end

  defp outcome_status(:supported), do: :supported
  defp outcome_status(:refuted), do: :refuted
  defp outcome_status(:inconclusive), do: :inconclusive
  defp outcome_status(:mixed), do: :inconclusive

  defp validate_transfer(transfer) do
    with :ok <- require(transfer, :transfer_id),
         :ok <- require(transfer, :source_evidence_id),
         :ok <- require(transfer, :target_world_id),
         :ok <- require(transfer, :theory) do
      if transfer[:certification_eligible] == false,
        do: :ok,
        else: {:error, :transfer_must_remain_non_certifying}
    end
  end

  defp validate_scenarios(scenarios) do
    if scenarios != [] and Enum.all?(scenarios, &valid_scenario?/1),
      do: :ok,
      else: {:error, :controlled_scenarios_required}
  end

  defp valid_scenario?(scenario) when is_map(scenario) do
    is_binary(Map.get(scenario, :scenario_id)) and
      is_binary(Map.get(scenario, :world_id, "")) and
      (is_map(Map.get(scenario, :controlled_variables, %{})) or
         is_list(Map.get(scenario, :controlled_variables, [])))
  end

  defp valid_scenario?(_), do: false

  defp require_executor(executor) when is_function(executor, 1), do: :ok
  defp require_executor(_), do: {:error, :cross_world_executor_unavailable}

  defp require(map, key), do: if(Map.has_key?(map, key), do: :ok, else: {:error, {:missing_field, key}})
  defp validate_outcome(value) when value in [:supported, :refuted, :inconclusive, :mixed], do: :ok
  defp validate_outcome(_), do: {:error, :invalid_transfer_outcome}
end
