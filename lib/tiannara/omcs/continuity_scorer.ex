defmodule Tiannara.OMCS.ContinuityScorer do
  @moduledoc """
  Calculates the ContinuityVector between an original IdentitySeed and a restored IdentitySeed.
  """

  alias Tiannara.OMCS.ContinuityVector
  alias Tiannara.OMCS.IdentitySeed

  @doc """
  Scores continuity between the original and restored IdentitySeeds.
  Returns a %ContinuityVector{}.
  """
  def score(%IdentitySeed{} = original, %IdentitySeed{} = restored) do
    lineage_score = score_lineage(original.lineage_graph, restored.lineage_graph)
    ontology_score = score_ontology(original.ontology_fingerprint, restored.ontology_fingerprint)
    causal_score = score_causal(original.causal_graph, restored.causal_graph)
    
    narrative_score = score_narrative(
      original.narrative_graph, restored.narrative_graph,
      original.causal_graph, restored.causal_graph,
      original.ontology_fingerprint, restored.ontology_fingerprint
    )

    vector = %ContinuityVector{
      lineage_continuity: lineage_score,
      ontology_continuity: ontology_score,
      causal_continuity: causal_score,
      narrative_continuity: narrative_score
    }

    ContinuityVector.calculate_overall(vector)
  end

  defp score_lineage(original_graph, restored_graph) do
    # Perfect lineage match returns 1.0. Any deviation drops it significantly.
    if original_graph == restored_graph do
      1.0
    else
      # Check if it's a migration/restoration edge
      if restored_graph && original_graph && 
         restored_graph.parent == {original_graph.id, :migrated_from} do
        1.0
      else
        # Simplified comparison for this version
        0.5
      end
    end
  end

  defp score_ontology(original_fp, restored_fp) do
    # Simple similarity based on intersecting elements
    # Assuming fingerprints are lists or maps
    orig_set = MapSet.new(original_fp || [])
    rest_set = MapSet.new(restored_fp || [])
    
    intersection_size = MapSet.intersection(orig_set, rest_set) |> MapSet.size()
    union_size = MapSet.union(orig_set, rest_set) |> MapSet.size()
    
    if union_size == 0 do
      1.0
    else
      intersection_size / union_size
    end
  end

  defp score_causal(original_graph, restored_graph) do
    orig_set = MapSet.new(original_graph || [])
    rest_set = MapSet.new(restored_graph || [])
    
    if MapSet.size(orig_set) == 0 do
      1.0
    else
      retained = MapSet.intersection(orig_set, rest_set) |> MapSet.size()
      retained / MapSet.size(orig_set)
    end
  end

  defp score_narrative(orig_narrative, rest_narrative, orig_causal, rest_causal, orig_fp, rest_fp) do
    # Milestone Retention (0.40)
    milestone_retention = calculate_retention(orig_narrative, rest_narrative)
    
    # Causal Story Retention (0.35)
    causal_story_retention = score_causal(orig_causal, rest_causal)
    
    # Identity Theme Retention (0.25)
    identity_theme_retention = score_ontology(orig_fp, rest_fp)
    
    (0.40 * milestone_retention) +
    (0.35 * causal_story_retention) +
    (0.25 * identity_theme_retention)
  end

  defp calculate_retention(original_list, restored_list) do
    orig_count = length(original_list || [])
    if orig_count == 0 do
      1.0
    else
      # Compare based on Milestone ID
      orig_ids = Enum.map(original_list, & &1.id) |> MapSet.new()
      rest_ids = Enum.map(restored_list, & &1.id) |> MapSet.new()
      
      retained = MapSet.intersection(orig_ids, rest_ids) |> MapSet.size()
      retained / orig_count
    end
  end
end
