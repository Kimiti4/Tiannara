defmodule Tiannara.ASC.Ecology.Capability do
  @moduledoc """
  Phase 13: A discrete unit of cognitive or organizational power.
  Can be an Agent Role, a Cognitive Tool, or a Research Instrument.
  Capabilities compete for inclusion in the Dynamic Guild pipeline.
  """
  
  defstruct [
    :id,
    :name,
    :type,               # :agent_role, :cognitive_tool, :research_instrument
    :trigger_condition,  # When should the Dynamic Orchestrator include this?
    :implementation,     # The function that executes this capability
    :lineage,            # :human_seeded | :unprompted_synthesis
    fitness_impact: 0.0
  ]

  @type t :: %__MODULE__{}
end
