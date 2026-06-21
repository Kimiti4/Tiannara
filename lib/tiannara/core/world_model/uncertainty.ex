defmodule Tiannara.Core.WorldModel.Uncertainty do
  @moduledoc """
  Uncertainty tracking and contradiction management.

  Instead of storing certainty, the World Model explicitly tracks:
  - Ambiguities: States where multiple interpretations are possible
  - Contradictions: Conflicting beliefs
  - Confidence distribution: Where confidence is high vs low

  This is where most cognitive systems fail - they hide uncertainty.
  Tiannara makes it explicit.
  """

  defstruct [
    :ambiguities,
    :contradictions,
    :confidence_distribution,
    :uncertainty_hotspots
  ]

  @doc "Create a new uncertainty tracker."
  def new do
    %__MODULE__{
      ambiguities: [],
      contradictions: [],
      confidence_distribution: %{},
      uncertainty_hotspots: []
    }
  end

  @doc "Record an ambiguity - multiple valid interpretations."
  def record_ambiguity(tracker, entity_id, interpretations) do
    ambiguity = {entity_id, interpretations}
    %{tracker | ambiguities: [ambiguity | tracker.ambiguities]}
  end

  @doc "Record a contradiction - conflicting beliefs."
  def record_contradiction(tracker, belief1, belief2, severity \\ 0.5) do
    contradiction = {belief1, belief2, severity}
    %{tracker | contradictions: [contradiction | tracker.contradictions]}
  end

  @doc "Mark a region of uncertainty - where confidence is low."
  def mark_hotspot(tracker, region_id, confidence_level) do
    hotspot = {region_id, 1.0 - confidence_level}
    %{tracker | uncertainty_hotspots: [hotspot | tracker.uncertainty_hotspots]}
  end

  @doc "Get regions of high uncertainty."
  def high_uncertainty_regions(tracker, threshold \\ 0.3) do
    Enum.filter(tracker.uncertainty_hotspots, fn {_id, uncertainty} ->
      uncertainty >= threshold
    end)
  end
end
