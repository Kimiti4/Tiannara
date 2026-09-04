defmodule Tiannara.World.WorldQueryEngine do
  alias Tiannara.World.{UnifiedWorldModel, UnifiedRealityGraph, ProvenanceEngine}

  def find(opts \\ []) do
    type = Keyword.get(opts, :type); subtype = Keyword.get(opts, :subtype)
    min_conf = Keyword.get(opts, :min_confidence, 0.0)
    status = Keyword.get(opts, :status, :active)
    limit = Keyword.get(opts, :limit, 100); offset = Keyword.get(opts, :offset, 0)

    pred = fn e ->
      (type == nil or e.type == type) and
      (subtype == nil or e.subtype == subtype) and
      (e.confidence || 0.0) >= min_conf and
      e.status == status
    end

    case UnifiedRealityGraph.query_entities(predicate: pred, limit: limit + offset) do
      {:ok, ids} ->
        ents = ids |> Enum.drop(offset) |> Enum.take(limit)
               |> Enum.map(fn id -> case UnifiedWorldModel.get_entity(id) do {:ok, e} -> e; _ -> nil end end)
               |> Enum.reject(&is_nil/1)
        {:ok, %{results: ents, total: length(ids), returned: length(ents), query: %{type: type, subtype: subtype, min_confidence: min_conf, status: status, limit: limit, offset: offset}}}
      err -> err
    end
  end

  def search(query_text, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    {:ok, result} = find(Keyword.put(opts, :limit, 1000))
    matches = Enum.filter(result.results, fn e ->
      txt = inspect(e.attributes)
      String.contains?(String.downcase(txt), String.downcase(query_text))
    end) |> Enum.take(limit)
    {:ok, %{results: matches, query: query_text, total_matches: length(matches)}}
  end

  def trace(entity_id) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} ->
        case ProvenanceEngine.reconstruct_lineage(entity_id, entity) do
          {:ok, lineage} -> {:ok, %{entity_id: entity_id, lineage: lineage, depth: lineage_depth(lineage), evidence_count: count_ev(lineage)}}
          err -> err
        end
      err -> err
    end
  end

  def predict(entity_id, change_type \\ :refute) do
    case UnifiedRealityGraph.blast_radius(entity_id) do
      {:ok, %{affected_entities: affected}} ->
        preds = Enum.map(affected, fn aid ->
          case UnifiedWorldModel.get_entity(aid) do
            {:ok, e} -> %{entity_id: aid, entity_type: e.type, predicted_impact: estimate_impact(e, change_type), confidence: e.confidence * 0.7}
            _ -> nil
          end
        end) |> Enum.reject(&is_nil/1)
        {:ok, %{source_entity_id: entity_id, change_type: change_type, affected_count: length(affected), predictions: preds}}
      err -> err
    end
  end

  def explain(entity_id) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} ->
        case ProvenanceEngine.confidence_path(entity_id) do
          {:ok, path} ->
            {:ok, %{entity_id: entity_id, status: entity.status, confidence: entity.confidence,
              uncertainty: entity.uncertainty, evidence_chain: path.confidence_sources,
              evidence_count: path.evidence_count, contributor_count: path.contributor_count,
              explanation_text: explain_text(entity, path)}}
          {:error, :no_provenance_record} ->
            {:ok, %{entity_id: entity_id, status: entity.status, confidence: entity.confidence,
              explanation_text: "No provenance record. Confidence based on default prior."}}
          err -> err
        end
      err -> err
    end
  end

  def blast(entity_id) do
    case UnifiedRealityGraph.blast_radius(entity_id) do
      {:ok, %{affected_entities: affected}} ->
        cat = Enum.map(affected, fn aid ->
          case UnifiedWorldModel.get_entity(aid) do {:ok, e} -> {e.type, aid}; _ -> {:unknown, aid} end
        end) |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        {:ok, %{source_entity_id: entity_id, total_affected: length(affected), categorized: cat}}
      err -> err
    end
  end

  def causal(entity_ids) do
    case UnifiedRealityGraph.causal_analysis(entity_ids) do
      {:ok, %{downstream_effects: effects}} ->
        {:ok, %{input_entities: entity_ids, downstream_effects: effects, effect_count: length(effects)}}
      err -> err
    end
  end

  def temporal(timestamp) do
    case UnifiedRealityGraph.historical_state(timestamp) do
      {:ok, state} -> {:ok, %{timestamp: timestamp, state: state}}
      err -> err
    end
  end

  defp lineage_depth(%{contributors: []}), do: 0
  defp lineage_depth(%{contributors: cs}), do: 1 + (cs |> Enum.map(&lineage_depth/1) |> Enum.max(fn -> 0 end))

  defp count_ev(%{evidence: e, contributors: cs}), do: length(e) + Enum.sum(Enum.map(cs, &count_ev/1))
  defp count_ev(_), do: 0

  defp estimate_impact(entity, _change_type) do
    base = case entity.type do
      :scientific_entity -> 0.9; :knowledge_entity -> 0.8
      :engineering_entity -> 0.7; :mission_entity -> 0.6
      :resource_entity -> 0.5; _ -> 0.4
    end
    base * (entity.confidence || 0.5)
  end

  defp explain_text(entity, path) do
    cond do
      entity.status == :refuted -> "Entity is refuted. Original confidence was #{entity.confidence}."
      path.evidence_count == 0 -> "Entity has confidence #{entity.confidence} but no explicit evidence."
      path.evidence_count == 1 -> "Entity has confidence #{entity.confidence} supported by 1 piece of evidence."
      true -> "Entity has confidence #{entity.confidence} supported by #{path.evidence_count} pieces of evidence from #{path.contributor_count} contributors."
    end
  end
end
