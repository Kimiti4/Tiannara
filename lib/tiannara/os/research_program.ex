defmodule TiannaraOS.ResearchProgram do
  @moduledoc """
  Represents a structured research initiative executing inside a twin world.
  """

  @derive Jason.Encoder
  defstruct [
    :id,                     # atom() - unique identifier
    :world_id,               # atom() - target world ID
    :institution_id,         # atom() - executing institution ID
    goals: [],               # list(string()) - target objective goals
    hypotheses: [],           # list(atom()) - hypothesis node IDs in Evidence Graph
    active_experiments: [],  # list(atom()) - experiment node IDs under execution
    evidence_ids: [],        # list(atom()) - evidence node IDs collected
    discoveries: [],         # list(atom()) - discovery reference IDs generated and owned
    capabilities: %{},       # map() - %{atom() => %TiannaraOS.CapabilityNode{}} - Inherited/mutated tech tree
    stage: :initialized,     # atom() - lifecycle stage
    expected_information_gain: 0.0, # float() - projected info gain
    budget: %{
      credits: 0.0,
      compute: 0.0,
      attention: 0.0
    },
    metrics: %{
      success_rate: 0.0,
      replication_rate: 0.0,
      discovery_yield: 0.0,
      
      # KNOWLEDGE CONVERSION METRICS ⭐ NEW FOR 6.5B
      candidates_produced: 0,     # Total candidate discoveries
      candidates_validated: 0,    # Successfully validated
      conversion_rate: 0.0,       # validated / candidates
      retention_rate: 0.0,        # surviving_shocks / total_validated
      recovery_time_ticks: 0,     # Ticks to recover from last shock
      strategy_effectiveness: 0.0 # How well this genome performs
    },
    parent_program_id: nil,  # atom() | nil - parent ancestry mapping
    child_program_ids: [],   # list(atom()) - child lineage branches
    generation: 1,           # integer() - evolutionary generation (1 = founding, 2+ = descendants)
    portfolio_weight: 0.0,   # float() - dynamic portfolio allocation
    status: :active,         # atom() - :active | :completed | :suspended
    outcome: nil,            # atom() | nil - :success | :partial_success | :failure | :inconclusive
    risk_score: 0.0,         # float() - stress/risk indicator (0.0 to 1.0)
    funding_score: 1.0,      # float() - funding factor (0.0 to 1.0)
    metadata: %{},           # map() - domain-specific metadata (e.g., %{domain: :physics})
    started_at: nil,         # integer() | nil - system time milliseconds
    completed_at: nil,       # integer() | nil - system time milliseconds
    
    # RESEARCH STRATEGY GENOME ⭐ NEW FOR 6.5B
    strategy_genome: %{
      exploration_rate: 0.5,        # 0.0-1.0 (novel vs established)
      validation_priority: 0.5,     # 0.0-1.0 (replicate vs discover)
      cross_domain_synthesis: 0.0,  # 0.0-1.0 (interdisciplinary)
      anomaly_sensitivity: 0.0,     # 0.0-1.0 (focus on outliers)
      risk_tolerance: 0.5           # 0.0-1.0 (bold vs conservative)
    },
    
    # REPRODUCTION TRACKING ⭐ NEW FOR POPULATION CONTROL
    last_reproduction_tick: nil,    # integer() | nil - tick of last reproduction
    reproduction_cooldown: 500,     # integer() - ticks between reproductions
    
    # DEVELOPMENTAL LIFECYCLE ⭐ FOUR-STAGE EVOLUTION
    # Stages:
    #   :newborn    (0-1000 ticks)    → survive, fully immune from all selection
    #   :juvenile   (1000-5000 ticks) → acquire capabilities, immune from resource death
    #   :apprentice (5000-8000 ticks) → convert capabilities to discoveries, mild credit pressure
    #   :adult      (8000+ ticks)     → full selection, full reproduction rights
    born_at_tick: nil,              # integer() | nil - tick when program was created
    juvenile_period: 8000,          # integer() - ticks before becoming adult (full maturation)
    life_stage: :newborn            # atom() - :newborn | :juvenile | :apprentice | :adult
  ]

  @type t :: %__MODULE__{
    id: atom(),
    world_id: atom(),
    institution_id: atom(),
    goals: [String.t()],
    hypotheses: [atom()],
    active_experiments: [atom()],
    evidence_ids: [atom()],
    discoveries: [atom()],
    capabilities: map(),
    stage: :goal_generation | :hypothesis_generation | :experimentation | :evidence_synthesis | :discovery_candidate,
    expected_information_gain: float(),
    budget: %{credits: float(), compute: float(), attention: float()},
    metrics: %{
      success_rate: float(),
      replication_rate: float(),
      discovery_yield: float(),
      candidates_produced: integer(),
      candidates_validated: integer(),
      conversion_rate: float(),
      retention_rate: float(),
      recovery_time_ticks: integer(),
      strategy_effectiveness: float()
    },
    parent_program_id: atom() | nil,
    child_program_ids: [atom()],
    generation: integer(),
    portfolio_weight: float(),
    status: :active | :completed | :suspended,
    outcome: :success | :partial_success | :failure | :inconclusive | nil,
    risk_score: float(),
    funding_score: float(),
    started_at: integer() | nil,
    completed_at: integer() | nil,
    strategy_genome: %{
      exploration_rate: float(),
      validation_priority: float(),
      cross_domain_synthesis: float(),
      anomaly_sensitivity: float(),
      risk_tolerance: float()
    },
    last_reproduction_tick: integer() | nil,
    reproduction_cooldown: integer(),
    born_at_tick: integer() | nil,
    juvenile_period: integer(),
    life_stage: :newborn | :juvenile | :apprentice | :adult
  }
end
