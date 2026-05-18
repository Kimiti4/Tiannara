defmodule TiannaraRuntime.GRCC.Identity do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: GRCC Identity Lineage Process
  
  Each identity lineage becomes a GenServer process with:
  - Evolving state (coherence, fitness, specialization)
  - Mutation logic (genetic variation)
  - Ecological metrics (entropy contribution, dominance)
  - Inter-identity communication via message passing
  
  This maps directly to the BEAM actor model where each identity is an
  autonomous, isolated process that can fail independently without
  collapsing the entire ecosystem.
  """
  
  use GenServer
  
  # Client API
  
  @doc """
  Start a new identity lineage process.
  
  ## Parameters
  - id: Unique identity identifier
  - lineage_id: Evolutionary genealogy tracker
  - initial_state: Initial cognitive state map
  """
  def start_link(id, lineage_id, initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, %{
      id: id,
      lineage_id: lineage_id,
      state: Map.merge(default_state(), initial_state),
      birth_time: System.system_time(:millisecond),
      mutation_count: 0,
      fitness_history: [],
      message_log: []
    }, name: via_tuple(id))
  end
  
  @doc """
  Send ecological signal to identity (environmental feedback).
  """
  def receive_signal(id, signal_type, payload) do
    GenServer.cast(via_tuple(id), {:receive_signal, signal_type, payload})
  end
  
  @doc """
  Request identity to mutate (evolutionary pressure).
  """
  def mutate(id, mutation_rate \\ 0.1) do
    GenServer.cast(via_tuple(id), {:mutate, mutation_rate})
  end
  
  @doc """
  Get current identity state and metrics.
  """
  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end
  
  @doc """
  Compute fitness score based on ecological compatibility.
  """
  def compute_fitness(id, environment_state) do
    GenServer.call(via_tuple(id), {:compute_fitness, environment_state})
  end
  
  @doc """
  Reproduce - create offspring identity with inherited genome.
  """
  def reproduce(id, parent_genome, ecosystem_memory) do
    GenServer.call(via_tuple(id), {:reproduce, parent_genome, ecosystem_memory})
  end
  
  # Server Callbacks
  
  @impl true
  def init(state) do
    IO.puts("🧬 Identity #{state.id} born in lineage #{state.lineage_id}")
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:receive_signal, signal_type, payload}, state) do
    updated_state = process_signal(state, signal_type, payload)
    {:ok, updated_state}
  end
  
  @impl true
  def handle_cast({:mutate, mutation_rate}, state) do
    mutated_state = apply_mutation(state, mutation_rate)
    IO.puts("🔄 Identity #{state.id} mutated (count: #{mutated_state.mutation_count})")
    {:ok, mutated_state}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  
  @impl true
  def handle_call({:compute_fitness, env_state}, _from, state) do
    fitness = calculate_fitness(state.state, env_state)
    updated_state = update_fitness_history(state, fitness)
    {:reply, fitness, updated_state}
  end
  
  @impl true
  def handle_call({:reproduce, parent_genome, ecosystem_memory}, _from, state) do
    child_genome = recombine_genome(parent_genome, ecosystem_memory)
    child_state = create_offspring_state(state, child_genome)
    {:reply, child_state, state}
  end
  
  # Private Functions
  
  defp default_state do
    %{
      coherence: 1.0,
      activation_level: 0.5,
      fitness: 0.5,
      specialization_vector: %{
        exploratory: 0.5,
        conservative: 0.5,
        bridge_building: 0.5,
        contradiction_harvesting: 0.5
      },
      semantic_genome: %{
        merge_bias: 0.5,
        contradiction_tolerance: 0.5,
        novelty_affinity: 0.5,
        topology_preference: 0.5,
        exploration_exploitation_balance: 0.5,
        stability_sensitivity: 0.5
      },
      entropy_contribution: 0.0,
      ecological_fitness: 0.5
    }
  end
  
  defp via_tuple(id) do
    {:via, Registry, {TiannaraRuntime.IdentityRegistry, id}}
  end
  
  defp process_signal(state, signal_type, payload) do
    # Process environmental feedback signals
    updated_state = case signal_type do
      :environmental_pressure ->
        adjust_to_pressure(state, payload)
      :immune_intervention ->
        apply_immune_response(state, payload)
      :niche_opportunity ->
        explore_niche(state, payload)
      _ ->
        state
    end
    
    log_message(updated_state, "Received signal: #{signal_type}")
  end
  
  defp apply_mutation(state, mutation_rate) do
    # Apply genetic mutation to semantic genome
    mutated_genome = Enum.reduce(state.state.semantic_genome, %{}, fn {key, value}, acc ->
      if :rand.uniform() < mutation_rate do
        mutation = :rand.normal() * 0.1
        Map.put(acc, key, max(0.0, min(1.0, value + mutation)))
      else
        Map.put(acc, key, value)
      end
    end)
    
    updated_state = put_in(state.state.semantic_genome, mutated_genome)
    %{updated_state | mutation_count: state.mutation_count + 1}
  end
  
  defp calculate_fitness(identity_state, env_state) do
    # Fitness function from GRCC v10 specification:
    # F_i = w1*C_i + w2*N_i + w3*A_i + w4*H_i
    w1 = 0.30  # Coherence weight
    w2 = 0.25  # Niche utility weight
    w3 = 0.25  # Adaptation success weight
    w4 = 0.20  # Hybridization contribution weight
    
    coherence_score = identity_state.coherence
    niche_utility = calculate_niche_utility(identity_state, env_state)
    adaptation_success = identity_state.fitness  # Historical fitness as proxy
    hybridization_bonus = calculate_hybridization_bonus(identity_state)
    
    w1 * coherence_score + w2 * niche_utility + w3 * adaptation_success + w4 * hybridization_bonus
  end
  
  defp calculate_niche_utility(_identity_state, _env_state) do
    # Placeholder - would integrate with actual niche occupancy data
    0.5
  end
  
  defp calculate_hybridization_bonus(_identity_state) do
    # Placeholder - would track cross-lineage synthesis events
    0.5
  end
  
  defp update_fitness_history(state, fitness) do
    history = [fitness | state.fitness_history] |> Enum.take(100)  # Keep last 100
    %{state | fitness_history: history, state: Map.put(state.state, :fitness, fitness)}
  end
  
  defp recombine_genome(parent_genome, ecosystem_memory) do
    # Genome recombination biased by ecosystem memory (GRCC v8/v9)
    genome_inheritance_weight = 0.6
    
    Enum.reduce(parent_genome, %{}, fn {key, parent_value}, acc ->
      memory_value = Map.get(ecosystem_memory, key, 0.5)
      
      child_value = genome_inheritance_weight * parent_value + 
                    (1.0 - genome_inheritance_weight) * memory_value
      
      # Apply mutation
      mutation = :rand.normal() * 0.1
      final_value = max(0.0, min(1.0, child_value + mutation))
      
      Map.put(acc, key, final_value)
    end)
  end
  
  defp create_offspring_state(parent_state, child_genome) do
    # Create offspring with inherited genome
    offspring_state = parent_state.state
      |> Map.put(:semantic_genome, child_genome)
      |> Map.put(:coherence, parent_state.state.coherence * 0.7)
      |> Map.put(:activation_level, parent_state.state.activation_level * 0.4)
    
    %{
      id: "identity_offspring_#{System.system_time(:millisecond)}",
      lineage_id: parent_state.lineage_id,
      state: offspring_state,
      birth_time: System.system_time(:millisecond),
      mutation_count: 0,
      fitness_history: [],
      message_log: []
    }
  end
  
  defp adjust_to_pressure(state, _payload) do
    # Adjust identity parameters in response to environmental pressure
    state
  end
  
  defp apply_immune_response(state, _payload) do
    # Apply CIS immune interventions (mutation boost, suppression, etc.)
    state
  end
  
  defp explore_niche(state, _payload) do
    # Explore new semantic niche opportunities
    state
  end
  
  defp log_message(state, message) do
    messages = [message | state.message_log] |> Enum.take(50)
    %{state | message_log: messages}
  end
end
