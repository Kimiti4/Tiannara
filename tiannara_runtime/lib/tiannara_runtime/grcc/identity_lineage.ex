defmodule TiannaraRuntime.GRCC.IdentityLineage do
  @moduledoc """
  GRCC Identity Lineage Process (GenServer)
  
  Each identity lineage is an isolated actor/process with:
  - Evolving semantic genome state
  - Ecological metrics tracking (entropy, fitness, dominance)
  - Mutation and reproduction capabilities
  - Communication with other lineages via message passing
  
  This maps directly to the GRCC v10 identity specification where each lineage:
  * Has state (semantic genome, coherence, activation)
  * Evolves (mutation, selection pressure)
  * Communicates (interference patterns, hybridization)
  * Adapts (fitness-based survival)
  * Mutates (genomic variation)
  * Reproduces (offspring creation)
  * Dies independently (extinction when fitness < threshold)
  """
  
  use GenServer
  require Logger

  # Identity state structure
  defstruct [
    :id,
    :lineage_id,
    coherence: 1.0,
    activation_level: 0.5,
    birth_step: 0,
    semantic_genome: %{},
    fitness_history: [],
    mutation_rate: 0.1,
    local_physics: %{},
    ecological_metrics: %{
      entropy_contribution: 0.0,
      niche_occupancy: 0.0,
      dominance_ratio: 0.0
    },
    last_updated: nil
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    lineage_id: String.t(),
    coherence: float(),
    activation_level: float(),
    birth_step: integer(),
    semantic_genome: map(),
    fitness_history: [float()],
    mutation_rate: float(),
    local_physics: map(),
    ecological_metrics: map(),
    last_updated: DateTime.t() | nil
  }

  # Client API
  
  @doc """
  Start a new identity lineage process.
  
  ## Parameters
  - id: Unique identity identifier
  - lineage_id: Lineage grouping identifier
  - initial_genome: Semantic genome template
  """
  def start_link(id, lineage_id, initial_genome) do
    GenServer.start_link(__MODULE__, {id, lineage_id, initial_genome}, name: via_tuple(id))
  end
  
  @doc """
  Get current identity state.
  """
  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end
  
  @doc """
  Update fitness score for this identity.
  """
  def update_fitness(id, fitness_score) do
    GenServer.cast(via_tuple(id), {:update_fitness, fitness_score})
  end
  
  @doc """
  Apply mutation to semantic genome.
  """
  def apply_mutation(id, mutation_strength \\ 0.1) do
    GenServer.cast(via_tuple(id), {:apply_mutation, mutation_strength})
  end
  
  @doc """
  Calculate ecological fitness based on multiple factors.
  Formula: F_i = w1*C_i + w2*N_i + w3*A_i + w4*H_i
  """
  def calculate_ecological_fitness(id, weights \\ %{coherence: 0.30, niche_utility: 0.25, adaptation_success: 0.25, hybridization: 0.20}) do
    GenServer.call(via_tuple(id), {:calculate_fitness, weights})
  end
  
  @doc """
  Request hybridization with another identity.
  """
  def request_hybridization(id, other_identity_id) do
    GenServer.call(via_tuple(id), {:request_hybridization, other_identity_id})
  end
  
  # Server callbacks
  
  @impl true
  def init({id, lineage_id, initial_genome}) do
    state = %__MODULE__{
      id: id,
      lineage_id: lineage_id,
      semantic_genome: initial_genome,
      birth_step: current_step(),
      last_updated: DateTime.utc_now()
    }
    
    Logger.info("🧬 Identity lineage started: #{id} (lineage: #{lineage_id})")
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  
  @impl true
  def handle_call({:calculate_fitness, weights}, _from, state) do
    fitness = compute_ecological_fitness(state, weights)
    {:reply, fitness, state}
  end
  
  @impl true
  def handle_call({:request_hybridization, other_id}, _from, state) do
    # Attempt hybridization with another identity
    case attempt_hybridization(state, other_id) do
      {:ok, hybrid_offspring} ->
        Logger.info("✅ Hybridization successful: #{state.id} x #{other_id}")
        {:reply, {:ok, hybrid_offspring}, state}
      
      {:error, reason} ->
        Logger.warning("❌ Hybridization failed: #{state.id} x #{other_id} - #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
  
  @impl true
  def handle_cast({:update_fitness, fitness_score}, state) do
    updated_history = [fitness_score | Enum.take(state.fitness_history, 99)]
    
    updated_state = %{state | 
      fitness_history: updated_history,
      last_updated: DateTime.utc_now()
    }
    
    # Publish fitness update to ecological event bus
    publish_ecological_event(:fitness_update, %{
      identity_id: state.id,
      lineage_id: state.lineage_id,
      fitness: fitness_score,
      timestamp: DateTime.utc_now()
    })
    
    {:ok, updated_state}
  end
  
  @impl true
  def handle_cast({:apply_mutation, strength}, state) do
    mutated_genome = mutate_genome(state.semantic_genome, strength)
    
    updated_state = %{state |
      semantic_genome: mutated_genome,
      mutation_rate: state.mutation_rate * 1.1,  # Slight increase after mutation
      last_updated: DateTime.utc_now()
    }
    
    Logger.debug("🧬 Mutation applied to #{state.id}: rate=#{updated_state.mutation_rate}")
    
    # Publish mutation event
    publish_ecological_event(:mutation_applied, %{
      identity_id: state.id,
      lineage_id: state.lineage_id,
      mutation_strength: strength,
      timestamp: DateTime.utc_now()
    })
    
    {:ok, updated_state}
  end
  
  # Private functions
  
  defp via_tuple(id), do: {:via, Registry, {TiannaraRuntime.GRCC.Registry, id}}
  
  defp current_step(), do: System.monotonic_time(:millisecond)
  
  defp compute_ecological_fitness(state, weights) do
    # Coherence component (w1)
    coherence_score = state.coherence
    
    # Niche utility component (w2) - reward underrepresented niches
    niche_utility = 1.0 - state.ecological_metrics.niche_occupancy
    
    # Adaptation success component (w3) - recent fitness history
    adaptation_success = if length(state.fitness_history) > 0 do
      recent = Enum.take(state.fitness_history, 10)
      Enum.sum(recent) / length(recent)
    else
      0.5  # Default for new identities
    end
    
    # Hybridization contribution (w4) - simplified for now
    hybrid_contribution = 0.5  # Would track actual hybrid success rate
    
    # Weighted combination
    fitness = (
      weights.coherence * coherence_score +
      weights.niche_utility * niche_utility +
      weights.adaptation_success * adaptation_success +
      weights.hybridization * hybrid_contribution
    )
    
    max(0.0, min(1.0, fitness))
  end
  
  defp attempt_hybridization(state, other_id) do
    # In Phase 1, we'll simulate hybridization
    # In Phase 2+, this will involve actual cross-lineage communication
    
    # Check if other identity exists
    case GenServer.whereis(via_tuple(other_id)) do
      nil ->
        {:error, "Target identity not found: #{other_id}"}
      
      _pid ->
        # Get other identity's genome
        other_state = GenServer.call(via_tuple(other_id), :get_state)
        
        # Create hybrid offspring genome (simple averaging for now)
        hybrid_genome = merge_genomes(state.semantic_genome, other_state.semantic_genome)
        
        {:ok, %{
          id: "hybrid_#{state.id}_#{other_id}",
          lineage_id: "hybrid_#{state.lineage_id}_#{other_state.lineage_id}",
          semantic_genome: hybrid_genome,
          coherence: (state.coherence + other_state.coherence) / 2 * 0.8,  # Offspring start less coherent
          birth_step: current_step()
        }}
    end
  end
  
  defp mutate_genome(genome, strength) do
    # Apply Gaussian mutation to each genome dimension
    genome
    |> Enum.map(fn {key, value} ->
      mutation = :rand.normal() * strength
      mutated_value = value + mutation
      {key, max(0.0, min(1.0, mutated_value))}  # Clamp to [0, 1]
    end)
    |> Enum.into(%{})
  end
  
  defp merge_genomes(genome1, genome2) do
    # Simple averaging of genome values
    Map.merge(genome1, genome2, fn _key, v1, v2 ->
      (v1 + v2) / 2
    end)
  end
  
  defp publish_ecological_event(event_type, payload) do
    # Publish to Phoenix PubSub for real-time monitoring
    Phoenix.PubSub.broadcast(
      TiannaraRuntime.PubSub,
      "ecological_events",
      %{type: event_type, payload: payload}
    )
    
    # Also publish to NATS for Python layer integration (Phase 1)
    # This will be implemented in TiannaraRuntime.NATS.Publisher
  end
end
