defmodule Tiannara.Sentinel.CrossWorldTheoryTransfer do
  @moduledoc """
  Transfers a historical theory as an explicitly quarantined research candidate.

  A failed or superseded theory can be re-tested in another world/civilization.
  The source result is never changed and the transferred theory is never
  promoted automatically. Results are linked back to the source evidence.
  """

  @spec prepare(map(), map()) :: {:ok, map()} | {:error, term()}
  def prepare(source_record, target) when is_map(source_record) and is_map(target) do
    with :ok <- validate_source(source_record),
         :ok <- validate_target(target) do
      {:ok, %{
        transfer_id: "theory-transfer-#{System.unique_integer([:positive])}",
        source_evidence_id: source_record.id,
        source_status: source_record.status,
        target_world_id: target.world_id,
        target_civilization_id: Map.get(target, :civilization_id),
        theory: source_record.statement,
        assumptions: Map.get(source_record, :assumptions, []),
        transfer_mode: :quarantined_research_candidate,
        source_truth_status: :unchanged,
        target_truth_status: :unknown,
        certification_eligible: false
      }}
    end
  end

  def prepare(_, _), do: {:error, :invalid_theory_transfer}

  @spec record_result(map(), map()) :: {:ok, map()} | {:error, term()}
  def record_result(transfer, result) when is_map(transfer) and is_map(result) do
    with :ok <- require_key(transfer, :transfer_id),
         :ok <- require_key(transfer, :source_evidence_id),
         :ok <- require_key(result, :scenario_id),
         :ok <- require_key(result, :outcome),
         :ok <- validate_outcome(result.outcome) do
      {:ok, %{
        transfer_id: transfer.transfer_id,
        source_evidence_id: transfer.source_evidence_id,
        target_world_id: transfer.target_world_id,
        target_civilization_id: transfer.target_civilization_id,
        scenario_id: result.scenario_id,
        outcome: result.outcome,
        observations: Map.get(result, :observations, []),
        counterevidence: Map.get(result, :counterevidence, []),
        assumptions_held: Map.get(result, :assumptions_held, []),
        assumptions_changed: Map.get(result, :assumptions_changed, []),
        execution_mode: Map.get(result, :execution_mode, :simulation),
        evidence_class: Map.get(result, :evidence_class, :simulated),
        certification_eligible: false
      }}
    end
  end

  defp validate_source(record) do
    if Map.has_key?(record, :id) and Map.has_key?(record, :statement) and
         Map.get(record, :status) in [:refuted, :superseded, :rejected, :inconclusive, :candidate],
      do: :ok,
      else: {:error, :source_theory_not_transferable}
  end

  defp validate_target(target) do
    if is_binary(Map.get(target, :world_id)), do: :ok, else: {:error, :target_world_required}
  end

  defp require_key(map, key), do: if(Map.has_key?(map, key), do: :ok, else: {:error, {:missing_field, key}})
  defp validate_outcome(value) when value in [:supported, :refuted, :inconclusive, :mixed], do: :ok
  defp validate_outcome(_), do: {:error, :invalid_transfer_outcome}
end
