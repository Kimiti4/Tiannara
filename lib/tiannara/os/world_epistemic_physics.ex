defmodule TiannaraOS.WorldEpistemicPhysics do
  @moduledoc """
  Defines the epistemic physics of a world environment.
  
  Instead of hardcoding domain-specific reward functions,
  worlds have measurable characteristics that determine
  which research strategies succeed or fail.
  
  This creates genuine ecological niches without manual tuning.
  """
  
  @type t :: %__MODULE__{
    uncertainty: float(),                # 0.0-1.0 (how uncertain is knowledge?)
    experiment_cost: float(),            # 0.0-1.0 (cost of testing hypotheses)
    replication_difficulty: float(),     # 0.0-1.0 (hard to reproduce results?)
    discovery_rate: float(),             # 0.0-1.0 (how often do discoveries occur?)
    failure_penalty: float(),            # 0.0-1.0 (penalty for wrong answers)
    coupling_strength: float(),          # 0.0-1.0 (how interconnected are concepts?)
    transferability: float(),            # 0.0-1.0 (can knowledge transfer elsewhere?)
    time_to_validation: float(),         # 0.0-1.0 (how long to confirm truth?)
    
    # Derived preferences (calculated from physics)
    preferred_exploration: float(),      # What exploration rate works best?
    preferred_validation: float(),       # What validation priority works best?
    preferred_synthesis: float(),        # What cross-domain synthesis works best?
    preferred_anomaly_sensitivity: float(), # What anomaly focus works best?
    
    # Importance weights (what matters most in this environment?)
    exploration_importance: float(),     # How much does exploration matter?
    validation_importance: float(),      # How much does validation matter?
    synthesis_importance: float()        # How much does synthesis matter?
  }
  
  defstruct [
    uncertainty: 0.5,
    experiment_cost: 0.5,
    replication_difficulty: 0.5,
    discovery_rate: 0.5,
    failure_penalty: 0.5,
    coupling_strength: 0.5,
    transferability: 0.5,
    time_to_validation: 0.5,
    
    preferred_exploration: 0.5,
    preferred_validation: 0.5,
    preferred_synthesis: 0.5,
    preferred_anomaly_sensitivity: 0.5,
    
    exploration_importance: 0.33,
    validation_importance: 0.33,
    synthesis_importance: 0.34
  ]
  
  @doc """
  Calculate derived preferences from raw epistemic physics.
  
  This is where the magic happens: strategy preferences emerge
  from environmental constraints, not hardcoded rules.
  """
  @spec derive_preferences(t()) :: t()
  def derive_preferences(%__MODULE__{} = physics) do
    # High uncertainty → rewards exploration
    # Low uncertainty → rewards validation
    preferred_exploration = physics.uncertainty
    
    # High experiment cost → rewards validation (don't waste resources)
    # Low experiment cost → rewards exploration (cheap to test)
    preferred_validation = 1.0 - physics.experiment_cost
    
    # High coupling strength → rewards synthesis (everything connected)
    # Low coupling strength → rewards specialization
    preferred_synthesis = physics.coupling_strength
    
    # High failure penalty → rewards caution (low anomaly sensitivity)
    # Low failure penalty → rewards boldness (high anomaly sensitivity)
    preferred_anomaly_sensitivity = 1.0 - physics.failure_penalty
    
    # Calculate importance weights based on what drives success
    total_importance = 
      physics.experiment_cost + 
      physics.time_to_validation + 
      physics.coupling_strength
    
    exploration_importance = 
      if total_importance > 0 do
        physics.experiment_cost / total_importance
      else
        0.33
      end
    
    validation_importance = 
      if total_importance > 0 do
        physics.time_to_validation / total_importance
      else
        0.33
      end
    
    synthesis_importance = 
      if total_importance > 0 do
        physics.coupling_strength / total_importance
      else
        0.34
      end
    
    %__MODULE__{
      physics |
      preferred_exploration: preferred_exploration,
      preferred_validation: preferred_validation,
      preferred_synthesis: preferred_synthesis,
      preferred_anomaly_sensitivity: preferred_anomaly_sensitivity,
      exploration_importance: exploration_importance,
      validation_importance: validation_importance,
      synthesis_importance: synthesis_importance
    }
  end
  
  @doc """
  Calculate fitness of a research strategy genome in this environment.
  
  Returns 0.0-1.0 fitness score based on how well the genome matches
  environmental demands.
  """
  @spec calculate_fitness(t(), map()) :: float()
  def calculate_fitness(%__MODULE__{} = physics, genome) do
    # Calculate trait matching (1.0 = perfect match, 0.0 = complete mismatch)
    exploration_fit = 1.0 - abs(genome.exploration_rate - physics.preferred_exploration)
    validation_fit = 1.0 - abs(genome.validation_priority - physics.preferred_validation)
    synthesis_fit = 1.0 - abs(genome.cross_domain_synthesis - physics.preferred_synthesis)
    anomaly_fit = 1.0 - abs(genome.anomaly_sensitivity - physics.preferred_anomaly_sensitivity)
    
    # Weighted fitness based on what environment rewards
    weighted_fitness = 
      (exploration_fit * physics.exploration_importance) +
      (validation_fit * physics.validation_importance) +
      (synthesis_fit * physics.synthesis_importance) +
      (anomaly_fit * 0.1)  # Anomaly sensitivity has minor weight
    
    # Normalize to 0.0-1.0 range
    min(max(weighted_fitness, 0.0), 1.0)
  end
  
  @doc """
  Create a Medicine-like epistemic environment.
  
  Characteristics:
  - High uncertainty (human biology complex)
  - Very high experiment cost (clinical trials expensive)
  - High replication difficulty (patient variability)
  - Very high failure penalty (lives at stake)
  - Low transferability (species-specific)
  """
  @spec medicine_environment() :: t()
  def medicine_environment do
    %__MODULE__{
      uncertainty: 0.7,
      experiment_cost: 0.95,
      replication_difficulty: 0.8,
      discovery_rate: 0.3,
      failure_penalty: 1.0,
      coupling_strength: 0.6,
      transferability: 0.4,
      time_to_validation: 0.9
    }
    |> derive_preferences()
  end
  
  @doc """
  Create a Cybernetics-like epistemic environment.
  
  Characteristics:
  - Moderate uncertainty (systems predictable but complex)
  - Low experiment cost (simulations cheap)
  - Low replication difficulty (deterministic systems)
  - High discovery rate (many innovations possible)
  - Low failure penalty (bugs fixable)
  - High transferability (principles apply broadly)
  """
  @spec cybernetics_environment() :: t()
  def cybernetics_environment do
    %__MODULE__{
      uncertainty: 0.6,
      experiment_cost: 0.2,
      replication_difficulty: 0.3,
      discovery_rate: 0.9,
      failure_penalty: 0.2,
      coupling_strength: 0.7,
      transferability: 0.8,
      time_to_validation: 0.3
    }
    |> derive_preferences()
  end
  
  @doc """
  Create a Mathematics-like epistemic environment.
  
  Characteristics:
  - Low uncertainty (axioms clear)
  - Very low experiment cost (proofs cheap to construct)
  - Very low replication difficulty (proofs reproducible)
  - Low discovery rate (hard problems rare)
  - Low failure penalty (wrong proofs just wrong)
  - Very high time to validation (peer review rigorous)
  """
  @spec mathematics_environment() :: t()
  def mathematics_environment do
    %__MODULE__{
      uncertainty: 0.2,
      experiment_cost: 0.1,
      replication_difficulty: 0.05,
      discovery_rate: 0.2,
      failure_penalty: 0.3,
      coupling_strength: 0.9,
      transferability: 0.95,
      time_to_validation: 1.0
    }
    |> derive_preferences()
  end
  
  @doc """
  Create a Physics-like epistemic environment.
  
  Characteristics:
  - Moderate uncertainty (quantum effects)
  - High experiment cost (particle accelerators expensive)
  - Moderate replication difficulty (equipment sensitive)
  - Moderate discovery rate (incremental progress)
  - High failure penalty (wrong theories waste years)
  - High coupling strength (unified theories)
  """
  @spec physics_environment() :: t()
  def physics_environment do
    %__MODULE__{
      uncertainty: 0.5,
      experiment_cost: 0.8,
      replication_difficulty: 0.6,
      discovery_rate: 0.4,
      failure_penalty: 0.7,
      coupling_strength: 0.8,
      transferability: 0.7,
      time_to_validation: 0.8
    }
    |> derive_preferences()
  end
  
  @doc """
  Create a Biology/Ecology-like epistemic environment.
  
  Characteristics:
  - High uncertainty (emergent complexity)
  - Moderate experiment cost (field studies moderate)
  - High replication difficulty (ecosystem variability)
  - Moderate discovery rate (patterns emerge slowly)
  - Moderate failure penalty (ecological damage reversible)
  - Very high coupling strength (everything connected)
  """
  @spec ecology_environment() :: t()
  def ecology_environment do
    %__MODULE__{
      uncertainty: 0.8,
      experiment_cost: 0.6,
      replication_difficulty: 0.7,
      discovery_rate: 0.5,
      failure_penalty: 0.5,
      coupling_strength: 0.95,
      transferability: 0.5,
      time_to_validation: 0.7
    }
    |> derive_preferences()
  end
  
  @doc """
  Create a Chemistry-like epistemic environment.
  
  Characteristics:
  - Moderate uncertainty (reaction mechanisms complex)
  - Moderate experiment cost (lab equipment moderate)
  - Low replication difficulty (reactions reproducible)
  - High discovery rate (many compounds to test)
  - Moderate failure penalty (failed experiments common)
  - Moderate coupling strength (periodic table structure)
  """
  @spec chemistry_environment() :: t()
  def chemistry_environment do
    %__MODULE__{
      uncertainty: 0.5,
      experiment_cost: 0.5,
      replication_difficulty: 0.3,
      discovery_rate: 0.7,
      failure_penalty: 0.4,
      coupling_strength: 0.6,
      transferability: 0.6,
      time_to_validation: 0.5
    }
    |> derive_preferences()
  end
  
  @doc """
  Generate random epistemic physics for evolutionary experimentation.
  
  Creates novel environments to test strategy adaptability.
  """
  @spec random_environment() :: t()
  def random_environment do
    %__MODULE__{
      uncertainty: :rand.uniform(),
      experiment_cost: :rand.uniform(),
      replication_difficulty: :rand.uniform(),
      discovery_rate: :rand.uniform(),
      failure_penalty: :rand.uniform(),
      coupling_strength: :rand.uniform(),
      transferability: :rand.uniform(),
      time_to_validation: :rand.uniform()
    }
    |> derive_preferences()
  end
end
