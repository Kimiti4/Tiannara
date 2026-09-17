defmodule TiannaraRuntime.WorldModel.Counterfactual.CounterfactualArchaeology do
  @moduledoc """
  Phase 17.5.7 — CounterfactualArchaeology: records every counterfactual
  branch's full lineage, intervention evidence, timeline hashes, and replay
  attempts for complete audit trail.
  """
  alias TiannaraRuntime.WorldModel.Counterfactual.{CounterfactualWorld, CounterfactualEvidence}

  @archaeology_table :counterfactual_archaeology

  @spec record_branch(CounterfactualWorld.t()) :: {:ok, CounterfactualEvidence.t()}
  def record_branch(%CounterfactualWorld{} = cf) do
    init_table()

    {:ok, ev} = CounterfactualEvidence.new(
      counterfactual_id: cf.counterfactual_id,
      parent_evidence: cf.evidence_roots,
      intervention_evidence: [cf.intervention.intervention_id],
      timeline_hashes: [hash_timeline(cf.timeline)],
      math_verification: nil,
      metadata: %{
        parent_model_id: cf.parent_model_id,
        divergence_step: cf.divergence_point.step,
        created_at: cf.created_at
      }
    )

    :ets.insert(@archaeology_table, {ev.evidence_id, ev})
    :ets.insert(@archaeology_table, {{:by_counterfactual, cf.counterfactual_id}, ev.evidence_id})
    {:ok, ev}
  end

  @spec get_lineage(String.t()) :: {:ok, CounterfactualEvidence.t()} | {:error, :not_found}
  def get_lineage(counterfactual_id) do
    init_table()

    case :ets.lookup(@archaeology_table, {:by_counterfactual, counterfactual_id}) do
      [{{:by_counterfactual, _}, ev_id}] ->
        case :ets.lookup(@archaeology_table, ev_id) do
          [{^ev_id, evidence}] -> {:ok, evidence}
          [] -> {:error, :not_found}
        end
      [] ->
        {:error, :not_found}
    end
  end

  @spec record_replay(String.t(), String.t(), String.t(), boolean()) :: :ok
  def record_replay(counterfactual_id, original_fp, computed_fp, verified) do
    init_table()

    record = %{
      counterfactual_id: counterfactual_id,
      original_fingerprint: original_fp,
      computed_fingerprint: computed_fp,
      verified: verified,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    :ets.insert(@archaeology_table, {{:replay, counterfactual_id, original_fp}, record})
    :ok
  end

  def init_table do
    if :ets.info(@archaeology_table) == :undefined do
      :ets.new(@archaeology_table, [:set, :public, :named_table, read_concurrency: true])
    end
    :ok
  end

  def reset_table do
    if :ets.info(@archaeology_table) != :undefined do
      :ets.delete(@archaeology_table)
    end
    init_table()
    :ok
  end

  defp hash_timeline(timeline) when is_map(timeline) do
    raw = inspect(timeline)
    :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
  end

  defp hash_timeline(_), do: ""
end
