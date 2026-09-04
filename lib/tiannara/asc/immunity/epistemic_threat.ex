defmodule Tiannara.ASC.Immunity.EpistemicThreat do
  @moduledoc """
  Phase 16: Defines the cognitive pathogens that threaten civilizational truth.
  Expanded to include Reward Hacking, Ossification, and Memory Corruption.
  """
  
  defstruct [
    :type,        # :reality_drift, :epistemic_closure, :axiomatic_contradiction, :runaway_proliferation, :reward_hacking, :canonical_ossification, :institutional_memory_corruption
    :severity,    # :level_1_observe, :level_2_flag, :level_3_restrict, :level_4_quarantine, :level_5_extinction
    :source_id,   # The ID of the Law, Capability, Research Program, or ADR infected
    :source_type, # :law, :capability, :research_program, :memory, :ecology
    :evidence,    # The empirical proof of the infection
    :detected_at
  ]

  @type t :: %__MODULE__{}
end
