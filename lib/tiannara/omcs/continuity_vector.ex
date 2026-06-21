defmodule Tiannara.OMCS.ContinuityVector do
  @moduledoc """
  The canonical metric for tracking a civilization's identity persistence across
  evolution, collapse, restoration, and merger.
  """

  @enforce_keys [
    :lineage_continuity,
    :ontology_continuity,
    :causal_continuity,
    :narrative_continuity
  ]
  
  defstruct [
    :lineage_continuity,   # Float 0.0 - 1.0
    :ontology_continuity,  # Float 0.0 - 1.0
    :causal_continuity,    # Float 0.0 - 1.0
    :narrative_continuity, # Float 0.0 - 1.0
    :overall_continuity,   # Float 0.0 - 1.0
    :measured_at           # DateTime
  ]

  @doc """
  Calculates the overall continuity score based on the 4 vectors.
  """
  def calculate_overall(%__MODULE__{} = vector) do
    # Simple unweighted average for now, could be adjusted
    overall = (vector.lineage_continuity + vector.ontology_continuity + 
               vector.causal_continuity + vector.narrative_continuity) / 4.0
               
    %{vector | overall_continuity: overall, measured_at: DateTime.utc_now()}
  end
end
