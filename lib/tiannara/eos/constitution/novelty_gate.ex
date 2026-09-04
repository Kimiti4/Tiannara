defmodule Tiannara.EOS.Constitution.NoveltyGate do
  @moduledoc """
  Prevents artifact inflation. If a candidate artifact is closer than
  `merge_threshold` to an existing artifact, the evidence is folded
  into the existing artifact's revision history instead of minting a
  duplicate.

  Constitutional mandate: Clause 21 — never merely increase artifact count.
  """

  @merge_threshold 0.15

  @doc """
  Route a candidate artifact based on semantic distance to existing artifacts.
  Returns `{:fold_into_existing, artifact_id, evidence}` or `{:mint_new, candidate}`.
  """
  def route_candidate(candidate, existing_artifacts) do
    nearest = Tiannara.NearestNeighbor.find(candidate.embedding, existing_artifacts)

    if nearest && nearest.distance < @merge_threshold do
      {:fold_into_existing, nearest.artifact_id, candidate.evidence}
    else
      {:mint_new, candidate}
    end
  end

  def merge_threshold, do: @merge_threshold
end
