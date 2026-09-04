defmodule TiannaraOS.Governance.ProposalGenome do
  @moduledoc """
  ProposalGenome - Measurable, quantifiable representation of a proposal
  
  This is the canonical form used for simulation, comparison, and
  impact assessment. Every field is measurable and trackable.
  
  ## Owner
  Embedded within Proposal - immutable once created (part of proposal ID generation)
  
  ## Guarantees
  - All fields are measurable and quantifiable
  - Validation ensures data integrity
  - Scoring enables proposal ranking and prioritization
  - Immutable after creation (frozen at proposal submission)
  
  ## Usage
      iex> genome = %ProposalGenome{
      ...>   intent: "Improve replay determinism",
      ...>   affected_domains: [:governance],
      ...>   expected_fitness_delta: 0.15,
      ...>   risk_score: 0.2,
      ...>   safety_score: 0.9
      ...> }
      iex> {:ok, validated} = ProposalGenome.validate(genome)
      iex> score = ProposalGenome.calculate_score(validated)
      0.785
  """

  @typedoc """
  ProposalGenome structure with all measurable fields.
  """
  @type t :: %__MODULE__{
    # Intent and scope
    intent: String.t(),
    affected_domains: [atom()],
    affected_kernel: boolean(),
    affected_governance: boolean(),
    affected_science: boolean(),
    
    # Expected impacts (measurable)
    expected_fitness_delta: float(),
    expected_entropy_delta: float(),
    expected_cost: float(),
    expected_replay_impact: replay_impact(),
    expected_migration_cost: float(),
    expected_scientific_capital_change: float(),
    expected_archaeology_impact: archaeology_impact(),
    expected_complexity_score: float(),
    
    # Risk assessment
    risk_score: float(),
    safety_score: float(),
    migration_difficulty: difficulty(),
    rollback_difficulty: difficulty(),
    replay_difficulty: difficulty(),
    
    # Graph impact
    graph_impact: graph_impact(),
    
    # Dependency impact
    dependency_impact: [String.t()]
  }

  defstruct [
    # Intent and scope
    :intent,
    :affected_domains,
    :affected_kernel,
    :affected_governance,
    :affected_science,
    
    # Expected impacts (measurable)
    :expected_fitness_delta,
    :expected_entropy_delta,
    :expected_cost,
    :expected_replay_impact,
    :expected_migration_cost,
    :expected_scientific_capital_change,
    :expected_archaeology_impact,
    :expected_complexity_score,
    
    # Risk assessment
    :risk_score,
    :safety_score,
    :migration_difficulty,
    :rollback_difficulty,
    :replay_difficulty,
    
    # Graph impact
    :graph_impact,
    
    # Dependency impact
    :dependency_impact
  ]

  @type replay_impact :: :none | :minor | :major | :breaking
  @type archaeology_impact :: :none | :minor | :major
  @type difficulty :: :trivial | :easy | :moderate | :hard | :extreme

  @type graph_impact :: %{
    nodes_added: integer(),
    nodes_removed: integer(),
    edges_added: integer(),
    edges_removed: integer()
  }

  @doc """
  Validate genome has all required fields populated and within valid ranges.
  
  Returns `{:ok, genome}` if valid, or `{:error, [errors]}` with detailed messages.
  
  ## Validation Rules
  - Intent must be at least 20 characters
  - Must specify at least one affected domain
  - Fitness delta must be between -1.0 and 1.0
  - Risk score must be between 0.0 and 1.0
  - Safety score must be between 0.0 and 1.0
  - Complexity score must be between 0.0 and 1.0
  - Cost must be non-negative
  - Migration cost must be non-negative
  """
  @spec validate(t()) :: {:ok, t()} | {:error, [String.t()]}
  def validate(%__MODULE__{} = genome) do
    errors = []
    
    # Validate intent
    errors = if is_nil(genome.intent) or String.length(String.trim(genome.intent)) < 20 do
      ["Intent must be at least 20 characters"] ++ errors
    else
      errors
    end
    
    # Validate affected domains
    errors = if is_nil(genome.affected_domains) or Enum.empty?(genome.affected_domains) do
      ["Must specify at least one affected domain"] ++ errors
    else
      errors
    end
    
    # Validate fitness delta range
    errors = if is_nil(genome.expected_fitness_delta) or 
             genome.expected_fitness_delta < -1.0 or 
             genome.expected_fitness_delta > 1.0 do
      ["Fitness delta must be between -1.0 and 1.0"] ++ errors
    else
      errors
    end
    
    # Validate entropy delta range
    errors = if is_nil(genome.expected_entropy_delta) or 
             genome.expected_entropy_delta < -1.0 or 
             genome.expected_entropy_delta > 1.0 do
      ["Entropy delta must be between -1.0 and 1.0"] ++ errors
    else
      errors
    end
    
    # Validate cost (non-negative)
    errors = if is_nil(genome.expected_cost) or genome.expected_cost < 0 do
      ["Expected cost must be non-negative"] ++ errors
    else
      errors
    end
    
    # Validate risk score range
    errors = if is_nil(genome.risk_score) or 
             genome.risk_score < 0.0 or 
             genome.risk_score > 1.0 do
      ["Risk score must be between 0.0 and 1.0"] ++ errors
    else
      errors
    end
    
    # Validate safety score range
    errors = if is_nil(genome.safety_score) or 
             genome.safety_score < 0.0 or 
             genome.safety_score > 1.0 do
      ["Safety score must be between 0.0 and 1.0"] ++ errors
    else
      errors
    end
    
    # Validate complexity score range
    errors = if is_nil(genome.expected_complexity_score) or 
             genome.expected_complexity_score < 0.0 or 
             genome.expected_complexity_score > 1.0 do
      ["Complexity score must be between 0.0 and 1.0"] ++ errors
    else
      errors
    end
    
    # Validate migration cost (non-negative)
    errors = if is_nil(genome.expected_migration_cost) or genome.expected_migration_cost < 0 do
      ["Migration cost must be non-negative"] ++ errors
    else
      errors
    end
    
    # Validate graph_impact structure if present
    errors = if not is_nil(genome.graph_impact) and not is_map(genome.graph_impact) do
      ["Graph impact must be a map"] ++ errors
    else
      errors
    end
    
    if Enum.empty?(errors) do
      {:ok, genome}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Calculate overall proposal score (weighted combination of metrics).
  
  Higher is better. Used for ranking and prioritization.
  
  ## Scoring Weights
  - Fitness improvement: 30% (higher fitness delta = better)
  - Safety: 25% (higher safety score = better)
  - Low risk: 20% (lower risk score = better)
  - Low complexity: 15% (lower complexity = better)
  - Low cost: 10% (lower cost = better)
  
  ## Score Range
  Returns value between 0.0 and 1.0, where higher is better.
  
  ## Examples
      iex> genome = %ProposalGenome{
      ...>   intent: "Test proposal",
      ...>   affected_domains: [:governance],
      ...>   expected_fitness_delta: 0.5,
      ...>   safety_score: 0.9,
      ...>   risk_score: 0.2,
      ...>   expected_complexity_score: 0.3,
      ...>   expected_cost: 100.0
      ...> }
      iex> ProposalGenome.calculate_score(genome)
      0.765
  """
  @spec calculate_score(t()) :: float()
  def calculate_score(%__MODULE__{} = genome) do
    weights = %{
      fitness: 0.3,
      safety: 0.25,
      low_risk: 0.2,
      low_complexity: 0.15,
      low_cost: 0.1
    }
    
    # Normalize fitness delta to 0-1 range (delta of -1.0 → 0.0, delta of +1.0 → 1.0)
    normalized_fitness = max(0, min(1, (genome.expected_fitness_delta + 1.0) / 2.0))
    
    # Normalize cost to 0-1 range (0 cost → 1.0, 1000+ cost → 0.0)
    normalized_cost = 1.0 - min(genome.expected_cost / 1000.0, 1.0)
    
    score = 
      weights.fitness * normalized_fitness +
      weights.safety * genome.safety_score +
      weights.low_risk * (1.0 - genome.risk_score) +
      weights.low_complexity * (1.0 - genome.expected_complexity_score) +
      weights.low_cost * normalized_cost
    
    Float.round(score, 3)
  end

  @doc """
  Get difficulty numeric value for comparison.
  
  Maps difficulty atoms to numeric values:
  - :trivial → 0.0
  - :easy → 0.25
  - :moderate → 0.5
  - :hard → 0.75
  - :extreme → 1.0
  """
  @spec difficulty_to_number(difficulty()) :: float()
  def difficulty_to_number(:trivial), do: 0.0
  def difficulty_to_number(:easy), do: 0.25
  def difficulty_to_number(:moderate), do: 0.5
  def difficulty_to_number(:hard), do: 0.75
  def difficulty_to_number(:extreme), do: 1.0

  @doc """
  Get replay impact numeric value for comparison.
  
  Maps replay impact atoms to numeric values:
  - :none → 0.0
  - :minor → 0.25
  - :major → 0.75
  - :breaking → 1.0
  """
  @spec replay_impact_to_number(replay_impact()) :: float()
  def replay_impact_to_number(:none), do: 0.0
  def replay_impact_to_number(:minor), do: 0.25
  def replay_impact_to_number(:major), do: 0.75
  def replay_impact_to_number(:breaking), do: 1.0

  @doc """
  Get archaeology impact numeric value for comparison.
  
  Maps archaeology impact atoms to numeric values:
  - :none → 0.0
  - :minor → 0.5
  - :major → 1.0
  """
  @spec archaeology_impact_to_number(archaeology_impact()) :: float()
  def archaeology_impact_to_number(:none), do: 0.0
  def archaeology_impact_to_number(:minor), do: 0.5
  def archaeology_impact_to_number(:major), do: 1.0

  @doc """
  Create a minimal valid genome for testing purposes.
  
  Useful for unit tests and quick prototyping.
  """
  @spec test_genome() :: t()
  def test_genome() do
    %__MODULE__{
      intent: "This is a test proposal for validation purposes",
      affected_domains: [:governance],
      affected_kernel: false,
      affected_governance: true,
      affected_science: false,
      expected_fitness_delta: 0.1,
      expected_entropy_delta: -0.05,
      expected_cost: 50.0,
      expected_replay_impact: :minor,
      expected_migration_cost: 20.0,
      expected_scientific_capital_change: 0.0,
      expected_archaeology_impact: :none,
      expected_complexity_score: 0.3,
      risk_score: 0.2,
      safety_score: 0.9,
      migration_difficulty: :easy,
      rollback_difficulty: :trivial,
      replay_difficulty: :minor,
      graph_impact: %{
        nodes_added: 0,
        nodes_removed: 0,
        edges_added: 0,
        edges_removed: 0
      },
      dependency_impact: []
    }
  end
end
