defmodule TiannaraRuntime.WorldModel.Prediction.PredictionArchaeology do
  @moduledoc """
  Phase 17.4.7 — PredictionArchaeology: records every prediction's evidence
  lineage, assumption hashes, equation roots, and replay attempts for full
  audit trail.
  """
  alias TiannaraRuntime.WorldModel.Prediction.{Prediction, PredictionEvidence}

  @archaeology_table :prediction_archaeology

  @spec record_prediction(Prediction.t()) :: {:ok, PredictionEvidence.t()}
  def record_prediction(%Prediction{} = prediction) do
    init_table()

    evidence = %PredictionEvidence{
      prediction_id: prediction.prediction_id,
      model_evidence: prediction.evidence_roots,
      metadata: %{
        world_model_id: prediction.world_model_id,
        horizon: prediction.horizon,
        created_at: prediction.created_at
      }
    }

    {:ok, ev} = PredictionEvidence.new(
      prediction_id: prediction.prediction_id,
      model_evidence: prediction.evidence_roots,
      assumption_hashes: extract_assumption_hashes(prediction),
      equation_hashes: [],
      causal_roots: [],
      metadata: %{
        world_model_id: prediction.world_model_id,
        horizon: prediction.horizon,
        created_at: prediction.created_at
      }
    )

    :ets.insert(@archaeology_table, {ev.evidence_id, ev})
    :ets.insert(@archaeology_table, {{:by_prediction, prediction.prediction_id}, ev.evidence_id})
    {:ok, ev}
  end

  @spec get_prediction_lineage(String.t()) :: {:ok, PredictionEvidence.t()} | {:error, :not_found}
  def get_prediction_lineage(prediction_id) do
    init_table()

    case :ets.lookup(@archaeology_table, {:by_prediction, prediction_id}) do
      [{{:by_prediction, _}, ev_id}] ->
        case :ets.lookup(@archaeology_table, ev_id) do
          [{^ev_id, evidence}] -> {:ok, evidence}
          [] -> {:error, :not_found}
        end
      [] ->
        {:error, :not_found}
    end
  end

  @spec record_replay(String.t(), String.t(), String.t(), boolean()) :: :ok
  def record_replay(prediction_id, fingerprint, result, verified) do
    init_table()

    replay_record = %{
      prediction_id: prediction_id,
      fingerprint: fingerprint,
      result: result,
      verified: verified,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    :ets.insert(@archaeology_table, {{:replay, prediction_id, fingerprint}, replay_record})
    :ok
  end

  @spec list_all() :: {:ok, [map()]}
  def list_all do
    init_table()

    entries =
      @archaeology_table
      |> :ets.tab2list()
      |> Enum.filter(fn {key, _} -> is_evidence_key?(key) end)
      |> Enum.map(fn {_, v} -> v end)

    {:ok, entries}
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

  defp extract_assumption_hashes(%Prediction{assumptions: assumptions}) when is_map(assumptions) do
    assumptions
    |> Enum.map(fn {k, v} -> :crypto.hash(:sha256, "#{k}#{v}") |> Base.encode16(case: :lower) end)
  end

  defp extract_assumption_hashes(_), do: []

  defp is_evidence_key?(key) when is_binary(key), do: String.starts_with?(key, "pe_")
  defp is_evidence_key?(_), do: false
end
