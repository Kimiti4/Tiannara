defmodule TiannaraOS.ResearchInstitution do
  @moduledoc """
  ResearchInstitution - Permanent constitutional entity for scientific cognition.
  
  A Research Institution is a persistent cognitive operating unit that:
  - Owns its constitution and governance
  - Runs multiple campaigns concurrently
  - Maintains four-tier memory pipeline
  - Emits semantic events through Event Bus
  - Records lifecycle events through Lifecycle Registry
  - Maintains canonical Knowledge Graph
  - Accounts for resources through Economic Ledger
  - Validates every action through Governance
  - Registers itself automatically in Runtime Atlas
  
  **Constitutional Principle**: Everything is an Institution.
  Programs are temporary. Campaigns evolve. Institutions persist.
  
  ## State Ownership
  
  This struct contains ONLY state. No business logic.
  All mutations go through InstitutionKernel (Principle 5).
  
  ## Architecture
  
  ```
  ResearchInstitution
  ├── Constitution (mission, governance, ethics, economic/publication/research rules)
  ├── Identity (mission, philosophy, competencies, reputation, trust, domain vector)
  ├── Kernel PID (InstitutionKernel GenServer)
  ├── Campaigns (map of campaign_id → ResearchCampaign)
  ├── Knowledge Graph (canonical graph with multi-node types)
  ├── Four-Tier Memory (operational → research → institutional → civilizational)
  ├── Economic Ledger (income/expense/allocation/commitment/reserve + assets/liabilities)
  ├── Governance State (policies, treaties, compliance, pending approvals)
  ├── World Model (beliefs, confidence, disagreements, evidence base)
  ├── Discovery Portfolio (discoveries with lifecycle status)
  ├── Semantic Event Log (domain-specific events)
  └── Telemetry (health metrics, productivity, performance)
  ```
  """

  @derive Jason.Encoder
  defstruct [
    # ==================== Identity ====================
    :id,                        # atom() - unique institution identifier
    :world_id,                  # atom() | nil - operating world (nil if cross-world)
    :founded_tick,              # integer() - tick when institution was created
    :status,                    # atom() - :active | :dormant | :dissolved
    
    # ==================== Constitution ====================
    constitution: %{            # Institution Constitution (genome for scientific culture)
      mission: "",              # String.t() - core purpose
      governance_rules: %{      # How decisions are made
        decision_making: :democratic,  # :democratic | :hierarchical | :meritocratic
        voting_threshold: 0.5,         # float() 0.0-1.0
        quorum_requirements: 1         # integer() minimum participants
      },
      ethics_framework: %{      # Ethical boundaries
        prohibited_research: [],       # [atom()] forbidden research types
        required_approvals: [],        # [atom()] mandatory approval workflows
        ethical_principles: []         # [String.t()] guiding principles
      },
      economic_rules: %{        # Financial policies
        profit_distribution: %{},      # map() how profits distributed
        funding_priorities: %{},       # map() budget allocation priorities
        budget_allocation_strategy: :balanced  # atom() allocation strategy
      },
      publication_rules: %{     # Knowledge sharing
        open_access: true,             # boolean() public access policy
        peer_review_required: true,    # boolean() review before publication
        citation_standards: :apa       # atom() citation format
      },
      research_rules: %{        # Scientific methodology
        validation_standards: :rigorous,   # atom() validation rigor level
        replication_requirements: 2,       # integer() min replications
        evidence_thresholds: %{}           # map() evidence quality thresholds
      },
      amendment_process: %{     # How constitution changes
        proposal_threshold: 0.3,       # float() support needed to propose
        ratification_threshold: 0.67,  # float() support needed to ratify
        cooling_off_period_ticks: 1000 # integer() ticks before activation
      }
    },
    
    # ==================== Kernel ====================
    kernel_pid: nil,            # pid() | nil - InstitutionKernel GenServer process
    
    # ==================== Identity & Reputation ====================
    identity: %{                # Institution identity and standing
      mission: "",                     # String.t() - short mission statement
      research_philosophy: :empirical, # atom() - :empirical | :theoretical | :computational
      core_competencies: [],           # [atom()] - areas of expertise
      reputation: 0.5,                 # float() 0.0-1.0 - community standing
      trust_score: 0.5,                # float() 0.0-1.0 - reliability metric
      scientific_domain_vector: %{}    # %{atom() => float()} - multi-dimensional domain representation
    },
    
    # ==================== Domain Profile ====================
    domain_profile: nil,        # TiannaraOS.DomainProfile.t() | nil - loaded domain profile
    
    # ==================== Ownership ====================
    campaigns: %{},             # %{atom() => TiannaraOS.ResearchCampaign.t()} - owned campaigns
    active_program_count: 0,    # integer() - currently executing programs across all campaigns
    
    # ==================== Four-Tier Memory ====================
    operational_memory: [],     # [map()] - current tick events (auto-pruned)
    research_memory: %{         # %{hypotheses: [], experiments: [], evidence: []} - structured records
      hypotheses: [],
      experiments: [],
      evidence: []
    },
    institutional_memory: %{    # %{patterns: [], heuristics: []} - meta-knowledge
      patterns: [],
      heuristics: []
    },
    civilizational_memory: %{}, # map() - high-level abstractions (read-only interface)
    
    # ==================== Economic Ledger ====================
    economic_ledger: %{         # Double-entry bookkeeping with conservation invariant
      entries: [],                     # [map()] - income/expense/allocation/commitment/reserve entries
      assets: %{                       # Intellectual and knowledge assets
        intellectual_capital: 0.0,     # float() value of discoveries
        knowledge_assets: 0.0,         # float() value of institutional memory
        reputation_value: 0.0          # float() economic value of reputation
      },
      liabilities: %{                  # Outstanding obligations
        outstanding_commitments: 0.0,  # float() reserved but not spent
        treaty_obligations: 0.0        # float() inter-institution obligations
      },
      opportunity_costs: %{            # Foregone opportunities
        foregone_research_paths: []    # [map()] paths not taken
      },
      balance: 0.0              # float() - current available balance
    },
    
    # ==================== Governance ====================
    governance_state: %{        # Governance framework state
      policies: [],                    # [map()] active policies
      treaties: [],                    # [map()] inter-institution treaties
      compliance_status: :compliant,   # atom() - :compliant | :violation
      pending_approvals: []            # [map()] awaiting approval workflows
    },
    
    # ==================== Knowledge Graph ====================
    knowledge_graph: %{         # Canonical multi-node type graph (replaces Claim Graph)
      nodes: %{},                      # %{atom() => map()} - node_id → {type, metadata}
      edges: %{},                      # %{atom() => [map()]} - node_id → [{to_id, edge_type}]
      node_types: MapSet.new(),        # MapSet.t() - registered node types
      edge_types: MapSet.new()         # MapSet.t() - registered edge types
    },
    
    # ==================== Discovery Portfolio ====================
    discovery_portfolio: %{     # Managed discoveries with expanded lifecycle
      discoveries: %{},                # %{atom() => map()} - discovery_id → {status, citations, adoption}
      status_counts: %{                # %{atom() => integer()} - count by status
        candidate: 0,
        validated: 0,
        replicated: 0,
        published: 0,
        adopted: 0,
        standardized: 0,
        obsolete: 0,
        retracted: 0
      }
    },
    
    # ==================== World Model ====================
    world_model: %{             # Institution's separate view of reality
      beliefs: %{},                    # %{atom() => map()} - belief_id → {content, confidence}
      confidence_levels: %{},          # %{atom() => float()} - confidence per belief
      disagreements: [],               # [map()] where institution disagrees with civilization
      evidence_base: []                # [atom()] evidence supporting world model
    },
    
    # ==================== Lifecycle Integration ====================
    semantic_event_log: [],     # [map()] - domain-specific semantic events
    last_lifecycle_sync_tick: nil,  # integer() | nil - last sync with canonical registry
    
    # ==================== Telemetry ====================
    telemetry: %{               # Observability metrics
      health_metrics: %{               # %{tick_rate: 0.0, error_rate: 0.0, ...}
        tick_rate: 0.0,
        error_rate: 0.0,
        uptime_ticks: 0
      },
      research_productivity: %{        # %{discoveries_per_tick: 0.0, ...}
        discoveries_per_tick: 0.0,
        hypotheses_per_tick: 0.0,
        experiments_per_tick: 0.0
      },
      memory_performance: %{         # %{compression_ratio: 0.0, ...}
        compression_ratio: 0.0,
        retrieval_latency_ticks: 0
      },
      economic_health: %{            # %{budget_utilization: 0.0, ...}
        budget_utilization: 0.0,
        asset_growth_rate: 0.0
      },
      lifecycle_events: %{           # %{total_events: 0, ...}
        total_events: 0,
        events_per_tick: 0.0
      }
    },
    
    # ==================== Runtime Atlas Registration ====================
    runtime_registration: %{    # Auto-published to Runtime Atlas
      registered: false,               # boolean() registration status
      registered_at_tick: nil,         # integer() | nil - registration tick
      capabilities: [],                # [atom()] exposed capabilities
      services: [],                    # [atom()] available services
      trust_level: :unverified         # atom() - :unverified | :verified | :trusted
    }
  ]

  @type t :: %__MODULE__{
    id: atom(),
    world_id: atom() | nil,
    founded_tick: integer(),
    status: :active | :dormant | :dissolved,
    constitution: map(),
    kernel_pid: pid() | nil,
    identity: map(),
    campaigns: map(),
    active_program_count: integer(),
    operational_memory: [map()],
    research_memory: map(),
    institutional_memory: map(),
    civilizational_memory: map(),
    economic_ledger: map(),
    governance_state: map(),
    knowledge_graph: map(),
    discovery_portfolio: map(),
    world_model: map(),
    semantic_event_log: [map()],
    last_lifecycle_sync_tick: integer() | nil,
    telemetry: map(),
    runtime_registration: map()
  }
  
  # ==================== Helper Functions ====================
  
  @doc """
  Create a new ResearchInstitution with default constitution.
  
  ## Examples
  
      iex> institution = TiannaraOS.ResearchInstitution.new(:quantum_lab, :physics_world, 1)
      iex> institution.id
      :quantum_lab
  """
  @spec new(atom(), atom() | nil, integer()) :: t()
  def new(id, world_id, founded_tick) do
    %__MODULE__{
      id: id,
      world_id: world_id,
      founded_tick: founded_tick,
      status: :active,
      constitution: default_constitution(id),
      identity: default_identity(id),
      campaigns: %{},
      active_program_count: 0,
      operational_memory: [],
      research_memory: %{hypotheses: [], experiments: [], evidence: []},
      institutional_memory: %{patterns: [], heuristics: []},
      civilizational_memory: %{},
      economic_ledger: %{
        entries: [],
        assets: %{intellectual_capital: 0.0, knowledge_assets: 0.0, reputation_value: 0.0},
        liabilities: %{outstanding_commitments: 0.0, treaty_obligations: 0.0},
        opportunity_costs: %{foregone_research_paths: []},
        balance: 1000.0  # Initial endowment
      },
      governance_state: %{
        policies: [],
        treaties: [],
        compliance_status: :compliant,
        pending_approvals: []
      },
      knowledge_graph: %{
        nodes: %{},
        edges: %{},
        node_types: MapSet.new(),
        edge_types: MapSet.new()
      },
      discovery_portfolio: %{
        discoveries: %{},
        status_counts: %{
          candidate: 0,
          validated: 0,
          replicated: 0,
          published: 0,
          adopted: 0,
          standardized: 0,
          obsolete: 0,
          retracted: 0
        }
      },
      world_model: %{
        beliefs: %{},
        confidence_levels: %{},
        disagreements: [],
        evidence_base: []
      },
      semantic_event_log: [],
      last_lifecycle_sync_tick: nil,
      telemetry: %{
        health_metrics: %{tick_rate: 0.0, error_rate: 0.0, uptime_ticks: 0},
        research_productivity: %{discoveries_per_tick: 0.0, hypotheses_per_tick: 0.0, experiments_per_tick: 0.0},
        memory_performance: %{compression_ratio: 0.0, retrieval_latency_ticks: 0},
        economic_health: %{budget_utilization: 0.0, asset_growth_rate: 0.0},
        lifecycle_events: %{total_events: 0, events_per_tick: 0.0}
      },
      runtime_registration: %{
        registered: false,
        registered_at_tick: nil,
        capabilities: [],
        services: [],
        trust_level: :unverified
      }
    }
  end
  
  defp default_constitution(id) do
    %{
      mission: "Advance scientific knowledge in #{Atom.to_string(id)}",
      governance_rules: %{
        decision_making: :democratic,
        voting_threshold: 0.5,
        quorum_requirements: 1
      },
      ethics_framework: %{
        prohibited_research: [:human_experimentation_without_consent],
        required_approvals: [:ethics_review, :safety_review],
        ethical_principles: ["Do no harm", "Transparency", "Reproducibility"]
      },
      economic_rules: %{
        profit_distribution: %{researchers: 0.3, institution: 0.5, reserves: 0.2},
        funding_priorities: %{high_risk_high_reward: 0.4, incremental: 0.4, maintenance: 0.2},
        budget_allocation_strategy: :balanced
      },
      publication_rules: %{
        open_access: true,
        peer_review_required: true,
        citation_standards: :apa
      },
      research_rules: %{
        validation_standards: :rigorous,
        replication_requirements: 2,
        evidence_thresholds: %{minimum_confidence: 0.8, minimum_replications: 2}
      },
      amendment_process: %{
        proposal_threshold: 0.3,
        ratification_threshold: 0.67,
        cooling_off_period_ticks: 1000
      }
    }
  end
  
  defp default_identity(id) do
    %{
      mission: "Scientific advancement through #{Atom.to_string(id)}",
      research_philosophy: :empirical,
      core_competencies: [:general_research],
      reputation: 0.5,
      trust_score: 0.5,
      scientific_domain_vector: %{general: 1.0}
    }
  end
end
