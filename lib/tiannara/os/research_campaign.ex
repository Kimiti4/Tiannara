defmodule TiannaraOS.ResearchCampaign do
  @moduledoc """
  ResearchCampaign - Long-lived scientific field with evolutionary properties.
  
  Campaigns sit between Institutions (permanent) and Programs (transient).
  
  **Three Temporal Scales**:
  - Programs evolve quickly (ticks)
  - Campaigns evolve slowly (thousands of ticks)
  - Institutions evolve very slowly (tens of thousands of ticks)
  
  ## Campaign Genome
  
  Campaigns have a genome that evolves over time:
  - exploration_rate: novel vs established research
  - validation_priority: replicate vs discover
  - cross_domain_synthesis: interdisciplinary level
  - anomaly_sensitivity: focus on outliers
  - risk_tolerance: bold vs conservative
  
  ## Campaign Fitness
  
  Fitness metrics track campaign effectiveness:
  - discovery_yield: discoveries per resource unit
  - hypothesis_success_rate: validated / proposed
  - resource_efficiency: output / input
  - citation_impact: external recognition
  
  ## Architecture
  
  ```
  ResearchCampaign
  ├── Objectives (research goals)
  ├── Genome (evolutionary parameters)
  ├── Fitness (performance metrics)
  ├── Strategy (current approach)
  ├── Memory (campaign-specific knowledge)
  ├── Programs (transient processes owned by campaign)
  ├── Discoveries (findings attributed to campaign)
  ├── Economics (budget allocation)
  └── Lifecycle (campaign lifecycle state)
  ```
  """

  @derive Jason.Encoder
  defstruct [
    # ==================== Identity ====================
    :id,                        # atom() - unique campaign identifier
    :institution_id,            # atom() - owning institution
    :name,                      # String.t() - human-readable name
    :created_tick,              # integer() - tick when campaign was created
    :status,                    # atom() - :active | :archived | :completed
    
    # ==================== Objectives ====================
    objectives: [],             # [String.t()] - research goals
    
    # ==================== Campaign Genome ====================
    genome: %{                  # Evolutionary parameters (slow evolution)
      exploration_rate: 0.5,           # float() 0.0-1.0 (novel vs established)
      validation_priority: 0.5,        # float() 0.0-1.0 (replicate vs discover)
      cross_domain_synthesis: 0.3,     # float() 0.0-1.0 (interdisciplinary)
      anomaly_sensitivity: 0.4,        # float() 0.0-1.0 (focus on outliers)
      risk_tolerance: 0.6              # float() 0.0-1.0 (bold vs conservative)
    },
    
    # ==================== Campaign Fitness ====================
    fitness: %{                 # Performance metrics (updated periodically)
      discovery_yield: 0.0,            # float() discoveries per resource unit
      hypothesis_success_rate: 0.0,    # float() validated / proposed
      resource_efficiency: 0.0,        # float() output / input
      citation_impact: 0.0             # float() external recognition
    },
    
    # ==================== Strategy ====================
    strategy: %{                # Current research approach
      current_approach: :exploration,  # atom() - :exploration | :exploitation | :balanced
      adaptation_rate: 0.1,            # float() how quickly strategy adapts
      last_adaptation_tick: nil        # integer() | nil - last strategy update
    },
    
    # ==================== Memory ====================
    memory: %{                  # Campaign-specific knowledge
      hypotheses: [],                  # [atom()] hypothesis IDs
      experiments: [],                 # [atom()] experiment IDs
      evidence: [],                    # [atom()] evidence IDs
      patterns: []                     # [map()] discovered patterns
    },
    
    # ==================== Ownership ====================
    programs: %{},              # %{atom() => map()} - program_id → program metadata
    active_program_count: 0,    # integer() - currently executing programs
    
    # ==================== Discoveries ====================
    discoveries: [],            # [atom()] - discovery IDs attributed to campaign
    
    # ==================== Economics ====================
    economics: %{               # Campaign budget and spending
      allocated_budget: 0.0,           # float() total budget allocated
      spent: 0.0,                      # float() total spent
      remaining: 0.0,                  # float() available budget
      cost_per_discovery: 0.0          # float() average cost
    },
    
    # ==================== Lifecycle ====================
    lifecycle_state: %{         # Campaign lifecycle tracking
      stage: :initialized,             # atom() - lifecycle stage
      transitions: [],                 # [map()] stage transition history
      age_ticks: 0                     # integer() ticks since creation
    }
  ]

  @type t :: %__MODULE__{
    id: atom(),
    institution_id: atom(),
    name: String.t(),
    created_tick: integer(),
    status: :active | :archived | :completed,
    objectives: [String.t()],
    genome: map(),
    fitness: map(),
    strategy: map(),
    memory: map(),
    programs: map(),
    active_program_count: integer(),
    discoveries: [atom()],
    economics: map(),
    lifecycle_state: map()
  }
  
  # ==================== Helper Functions ====================
  
  @doc """
  Create a new ResearchCampaign.
  
  ## Parameters
  
  - `id`: atom() - unique campaign identifier
  - `institution_id`: atom() - owning institution
  - `created_tick`: integer() - creation tick
  - `params`: map() - optional parameters (objectives, genome, budget)
  
  ## Examples
  
      iex> params = %{objectives: ["quantum supremacy"], genome: %{exploration_rate: 0.7}}
      iex> campaign = TiannaraOS.ResearchCampaign.new(:quantum_research, :quantum_lab, 1, params)
      iex> campaign.genome.exploration_rate
      0.7
  """
  @spec new(atom(), atom(), integer(), map()) :: t()
  def new(id, institution_id, created_tick, params \\ %{}) do
    %__MODULE__{
      id: id,
      institution_id: institution_id,
      name: Map.get(params, :name, Atom.to_string(id)),
      created_tick: created_tick,
      status: :active,
      objectives: Map.get(params, :objectives, []),
      genome: merge_genome(default_genome(), Map.get(params, :genome, %{})),
      fitness: default_fitness(),
      strategy: default_strategy(created_tick),
      memory: %{hypotheses: [], experiments: [], evidence: [], patterns: []},
      programs: %{},
      active_program_count: 0,
      discoveries: [],
      economics: %{
        allocated_budget: Map.get(params, :budget, 500.0),
        spent: 0.0,
        remaining: Map.get(params, :budget, 500.0),
        cost_per_discovery: 0.0
      },
      lifecycle_state: %{
        stage: :initialized,
        transitions: [%{from: nil, to: :initialized, tick: created_tick}],
        age_ticks: 0
      }
    }
  end
  
  defp default_genome do
    %{
      exploration_rate: 0.5,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.3,
      anomaly_sensitivity: 0.4,
      risk_tolerance: 0.6
    }
  end
  
  defp default_fitness do
    %{
      discovery_yield: 0.0,
      hypothesis_success_rate: 0.0,
      resource_efficiency: 0.0,
      citation_impact: 0.0
    }
  end
  
  defp default_strategy(created_tick) do
    %{
      current_approach: :exploration,
      adaptation_rate: 0.1,
      last_adaptation_tick: created_tick
    }
  end
  
  defp merge_genome(default, custom) do
    Map.merge(default, custom)
  end
  
  @doc """
  Update campaign fitness based on performance.
  
  ## Parameters
  
  - `campaign`: ResearchCampaign.t()
  - `metrics`: map() - new performance metrics
  
  ## Returns
  
  Updated ResearchCampaign.t()
  """
  @spec update_fitness(t(), map()) :: t()
  def update_fitness(campaign, metrics) do
    updated_fitness = Map.merge(campaign.fitness, metrics)
    %{campaign | fitness: updated_fitness}
  end
  
  @doc """
  Adapt campaign strategy based on fitness.
  
  If fitness is low, increase exploration. If high, increase exploitation.
  
  ## Parameters
  
  - `campaign`: ResearchCampaign.t()
  - `current_tick`: integer()
  
  ## Returns
  
  Updated ResearchCampaign.t()
  """
  @spec adapt_strategy(t(), integer()) :: t()
  def adapt_strategy(campaign, current_tick) do
    # Simple adaptation logic (can be made more sophisticated)
    avg_fitness = (
      campaign.fitness.discovery_yield +
      campaign.fitness.hypothesis_success_rate +
      campaign.fitness.resource_efficiency
    ) / 3
    
    new_approach = if avg_fitness < 0.3 do
      :exploration  # Low fitness → explore more
    else
      :exploitation  # High fitness → exploit successes
    end
    
    updated_strategy = %{
      campaign.strategy |
      current_approach: new_approach,
      last_adaptation_tick: current_tick
    }
    
    %{campaign | strategy: updated_strategy}
  end
  
  @doc """
  Record a discovery attributed to this campaign.
  
  ## Parameters
  
  - `campaign`: ResearchCampaign.t()
  - `discovery_id`: atom()
  
  ## Returns
  
  Updated ResearchCampaign.t()
  """
  @spec record_discovery(t(), atom()) :: t()
  def record_discovery(campaign, discovery_id) do
    updated_discoveries = [discovery_id | campaign.discoveries]
    
    # Update cost per discovery
    total_spent = campaign.economics.spent
    num_discoveries = length(updated_discoveries)
    cost_per_discovery = if num_discoveries > 0, do: total_spent / num_discoveries, else: 0.0
    
    updated_economics = %{campaign.economics | cost_per_discovery: cost_per_discovery}
    
    %{campaign | discoveries: updated_discoveries, economics: updated_economics}
  end
  
  @doc """
  Update campaign economics (spend budget).
  
  ## Parameters
  
  - `campaign`: ResearchCampaign.t()
  - `amount`: float() - amount spent
  
  ## Returns
  
  Updated ResearchCampaign.t()
  """
  @spec spend_budget(t(), float()) :: t()
  def spend_budget(campaign, amount) do
    spent = campaign.economics.spent + amount
    remaining = campaign.economics.remaining - amount
    
    updated_economics = %{
      campaign.economics |
      spent: spent,
      remaining: max(0.0, remaining)
    }
    
    %{campaign | economics: updated_economics}
  end
  
  @doc """
  Advance campaign lifecycle by one tick.
  
  ## Parameters
  
  - `campaign`: ResearchCampaign.t()
  
  ## Returns
  
  Updated ResearchCampaign.t()
  """
  @spec advance_tick(t()) :: t()
  def advance_tick(campaign) do
    updated_lifecycle = %{
      campaign.lifecycle_state |
      age_ticks: campaign.lifecycle_state.age_ticks + 1
    }
    
    %{campaign | lifecycle_state: updated_lifecycle}
  end
end
