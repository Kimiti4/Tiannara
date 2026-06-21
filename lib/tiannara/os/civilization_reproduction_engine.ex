defmodule TiannaraOS.CivilizationReproductionEngine do
  @moduledoc """
  Civilization-Level Reproduction Engine
  
  Integrates all evolutionary inheritance mechanisms:
  1. Genetics (strategy genome mutation)
  2. Wisdom (institutional memory guidance)
  3. Capabilities (civilization tech tree)
  
  This is what separates blind evolution from civilizational learning.
  
  ## Inheritance Flow
  
      Parent Program Dies/Reproduces
      ↓
      Extract Institutional Wisdom (from graveyard)
      ↓
      Get Available Capabilities (from world registry)
      ↓
      Apply Wisdom-Guided Mutation (genetics)
      ↓
      Spawn Child with:
        - Mutated strategy genome
        - Institutional wisdom context
        - Available civilization capabilities
      ↓
      Child inherits civilization's accumulated knowledge
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.InstitutionalMemory
  alias TiannaraOS.InstitutionalMemoryEnhancements
  alias TiannaraOS.WorldMemory
  alias TiannaraOS.CapabilityRegistry
  
  # Reproduction probability scale (portfolio value where prob ~60%)
  # Lowered from 3000 to 1500 to make reproduction easier
  @reproduction_scale 1500.0
  
  # Base mutation rate
  @base_mutation_rate 0.2
  
  # Contrarian mutation probability (5%)
  @contrarian_probability 0.05
  
  # Budget inheritance fraction (child gets percentage of parent's wealth)
  # Increased from 0.15 to 0.25 to ensure child survival
  @budget_inheritance_fraction 0.25
  
  # Parent budget cost after reproduction (parent loses 30%)
  @reproduction_cost_to_parent 0.30
  
  # Maximum births per world per tick
  @max_births_per_world_per_tick 5
  
  # Minimum budget for reproduction (prevent zombie reproduction)
  @minimum_reproduction_budget 50.0
  
  # Minimum portfolio value for reproduction
  @minimum_portfolio_value 25.0
  
  # FOUR-STAGE DEVELOPMENTAL LIFECYCLE ⭐
  @juvenile_protection_period 8000  # full maturation window: newborn(1k) + juvenile(4k) + apprentice(3k)
  @juvenile_burn_rate_fraction 0.10  # newborns consume 10% of adult burn rate
  
  @doc """
  Trigger reproduction for all eligible programs.
  
  Called periodically (every 100 ticks) to allow successful programs
  to spawn mutated offspring.
  
  ## Parameters
  
  - `state`: Current simulation state
  
  ## Returns
  
  Updated state with new child programs added.
  
  ## Examples
  
      iex> state = CivilizationReproductionEngine.trigger_reproduction(state)
      iex> length(Map.keys(state.research_programs)) > initial_count
      true
  """
  @spec trigger_reproduction(State.t()) :: State.t()
  def trigger_reproduction(%State{} = state) do
    programs = state.research_programs || %{}
    index = state.world_program_index || %{}
    current_tick = state.economy[:tick] || 0
    
    # We only want to trigger reproduction every 10 ticks (or using shards)
    # But instead of iterating ALL programs (including dead ones), we iterate active index
    
    {final_state, _birth_counts} = Enum.reduce(index, {state, %{}}, fn {world_id, pids}, {acc_state, birth_counts} ->
      world_births = Map.get(birth_counts, world_id, 0)
      
      # Stop if world already hit birth limit
      if world_births >= @max_births_per_world_per_tick do
        {acc_state, birth_counts}
      else
        {updated_state, updated_births} = Enum.reduce(pids, {acc_state, birth_counts}, fn prog_id, {s_acc, b_acc} ->
          prog_world_births = Map.get(b_acc, world_id, 0)
          
          if prog_world_births >= @max_births_per_world_per_tick do
            {s_acc, b_acc}
          else
            # TICK SHARDING: Only process 10% of active programs per tick
            if rem(:erlang.phash2(prog_id), 10) != rem(current_tick, 10) do
              {s_acc, b_acc}
            else
              program = Map.get(s_acc.research_programs || %{}, prog_id)
              
              if program && program.status == :active and can_reproduce?(program, current_tick) do
                portfolio_value = calculate_portfolio_value(program, s_acc)
                
                # Check minimum portfolio value threshold
                if portfolio_value < @minimum_portfolio_value do
                  {s_acc, b_acc}
                else
                  # Crowding factor reduces reproduction probability
                  world = Map.get(s_acc.worlds, program.world_id)
                  carrying_capacity = if world, do: Map.get(world, :carrying_capacity, 40), else: 40
                  active_in_world = MapSet.size(Map.get(s_acc.world_program_index || %{}, program.world_id, MapSet.new()))
                  crowding_factor = active_in_world / carrying_capacity
                  
                  # Fitness-based reproduction probability (portfolio * capabilities)
                  capability_count = map_size(Map.get(program, :capabilities, %{}))
                  fitness = portfolio_value * max(1, capability_count)
                  
                  # Sigmoid-like reproduction probability with crowding suppression
                  base_prob = min(1.0, fitness / @reproduction_scale)
                  reproduction_prob = base_prob / (1 + crowding_factor)
                  
                  if :rand.uniform() < reproduction_prob do
                    # Extract institutional wisdom
                    wisdom = InstitutionalMemory.extract_wisdom(s_acc, program.world_id)
                    
                    # Apply temporal decay to wisdom
                    decayed_wisdom = InstitutionalMemoryEnhancements.apply_temporal_decay(wisdom, current_tick)
                    
                    # Get available capabilities
                    available_caps = CapabilityRegistry.get_world_capabilities(s_acc, program.world_id)
                    
                    # Apply institutional wisdom (80/15/5 split: wisdom/exploration/contrarian)
                    mutated_genome = InstitutionalMemory.mutate_from_wisdom(
                      program.strategy_genome,
                      decayed_wisdom
                    )
                    
                    # Apply world memory bias
                    world_memory = if world, do: world.memory || %{}, else: %{}
                    final_genome = WorldMemory.bias_genome_toward_success(mutated_genome, world_memory)
                    
                    # Spawn child
                    child_id = generate_child_id(prog_id)
                    child_budget = inherit_budget(program.budget)
                    
                    child_program = %ResearchProgram{
                      id: child_id,
                      world_id: program.world_id,
                      institution_id: program.institution_id,
                      status: :active,
                      generation: (program.generation || 1) + 1,
                      parent_program_id: prog_id,
                      budget: child_budget,
                      strategy_genome: final_genome,
                      capabilities: program.capabilities || %{},  # Inherit parent's tech tree
                      last_reproduction_tick: nil,  # Newborn hasn't reproduced yet
                      reproduction_cooldown: 500,
                      born_at_tick: current_tick,        # Track birth tick
                      juvenile_period: @juvenile_protection_period,  # Full 8000-tick maturation
                      life_stage: :newborn,               # DEVELOPMENTAL LIFECYCLE: Start as newborn
                      metadata: Map.merge(program.metadata || %{}, %{
                        created_at_tick: current_tick,
                        inherited_capabilities: available_caps,
                        wisdom_confidence: decayed_wisdom.confidence,
                        reproduction_type: if(:rand.uniform() < @contrarian_probability, do: :contrarian, else: :conventional)
                      })
                    }
                    
                    # REPRODUCTION COST: Parent loses 30% of budget
                    parent_budget_after = %{program.budget | credits: program.budget.credits * (1 - @reproduction_cost_to_parent)}
                    
                    # Update parent's child list and set last_reproduction_tick
                    updated_parent = %{program |
                      child_program_ids: (program.child_program_ids || []) ++ [child_id],
                      budget: parent_budget_after,
                      last_reproduction_tick: current_tick
                    }
                    
                    # Add both parent and child to state
                    updated_programs = Map.put(s_acc.research_programs, prog_id, updated_parent)
                    final_programs = Map.put(updated_programs, child_id, child_program)
                    
                    # Update world_program_index and maturation_queue
                    # Add child to maturation queue at all three transition points
                    tick_juv = current_tick + 1000
                    tick_app = current_tick + 5000
                    tick_adu = current_tick + 8000
                    
                    queue = s_acc.maturation_queue || %{}
                    queue = Map.update(queue, tick_juv, [child_id], fn list -> [child_id | list] end)
                    queue = Map.update(queue, tick_app, [child_id], fn list -> [child_id | list] end)
                    queue = Map.update(queue, tick_adu, [child_id], fn list -> [child_id | list] end)
                    
                    # Add to index
                    updated_index = Map.update(s_acc.world_program_index || %{}, child_program.world_id, MapSet.new([child_id]), fn set ->
                      MapSet.put(set, child_id)
                    end)
                    
                    # Update pop cache and metadata
                    new_cache = Map.update(s_acc.world_population_cache || %{}, child_program.world_id, %{newborn: 1}, fn w ->
                      Map.update(w, :newborn, 1, &(&1 + 1))
                    end)
                    new_meta = (s_acc.metadata || %{})
                      |> Map.update(:total_births, 1, &(&1 + 1))
                      |> Map.update(:active_count, 1, &(&1 + 1))
                      |> Map.update(:newborn_count, 1, &(&1 + 1))
                    
                    new_state = %{s_acc | 
                      research_programs: final_programs, 
                      world_program_index: updated_index,
                      maturation_queue: queue,
                      world_population_cache: new_cache,
                      metadata: new_meta
                    }
                    
                    new_birth_counts = Map.put(b_acc, world_id, prog_world_births + 1)
                    
                    {new_state, new_birth_counts}
                  else
                    {s_acc, b_acc}
                  end
                end
              else
                {s_acc, b_acc}
              end
            end
          end
        end)
        {updated_state, updated_births}
      end
    end)
    
    final_state
  end
  
  @doc """
  Check if a program can reproduce.
  
  Programs must be active and have sufficient lifespan to reproduce.
  
  ## Parameters
  
  - `program`: Research program to check
  
  ## Returns
  
  Boolean indicating if program can reproduce.
  """
  @spec can_reproduce?(ResearchProgram.t(), integer()) :: boolean()
  def can_reproduce?(%ResearchProgram{} = program, current_tick) do
    # Must be a fully matured adult — no reproduction during developmental stages
    is_adult = program.life_stage == :adult

    # Check basic eligibility
    base_eligible = program.status == :active &&
                    program.generation >= 1 &&
                    (program.metadata[:created_at_tick] || 0) < (current_tick - 100)
    
    # Check reproduction cooldown
    last_repro = program.last_reproduction_tick || 0
    cooldown = program.reproduction_cooldown || 500
    cooldown_elapsed = (current_tick - last_repro) >= cooldown
    
    # Check minimum budget threshold (prevent zombie reproduction)
    has_budget = Map.get(program.budget, :credits, 0) >= @minimum_reproduction_budget
    
    is_adult && base_eligible && cooldown_elapsed && has_budget
  end
  
  @doc """
  Calculate portfolio value for reproduction probability.
  
  Portfolio value combines:
  - Discovery royalties
  - Asset valuations
  - Institutional prestige
  
  ## Parameters
  
  - `program`: Research program
  - `state`: Current simulation state
  
  ## Returns
  
  Float representing total portfolio value.
  """
  @spec calculate_portfolio_value(ResearchProgram.t(), State.t()) :: float()
  def calculate_portfolio_value(%ResearchProgram{} = program, %State{} = _state) do
    # Sum the fitness score of all capabilities owned by this program
    capability_fitness_sum = 
      (program.capabilities || %{})
      |> Map.values()
      |> Enum.map(&Map.get(&1, :fitness_score, 0.0))
      |> Enum.sum()
      
    # Base value from budget
    base_value = program.budget.credits || 0.0
    
    # Total value driven primarily by capability fitness
    # Scale up to match the previous discovery bonus weighting
    total_royalty = base_value + (capability_fitness_sum * 100.0)
    
    # Power law scaling prevents single-jackpot dominance
    :math.pow(total_royalty, 0.7)
  end
  
  @doc false
  @spec count_active_in_world(State.t(), atom()) :: integer()
  defp count_active_in_world(%State{} = state, world_id) do
    if state.world_population_cache do
      get_in(state.world_population_cache, [world_id, :active]) || 0
    else
      MapSet.size(Map.get(state.world_program_index || %{}, world_id, MapSet.new()))
    end
  end
  
  @doc """
  Generate unique child program ID.
  
  ## Parameters
  
  - `parent_id`: Parent program ID
  
  ## Returns
  
  Unique atom for child program.
  """
  @spec generate_child_id(atom()) :: atom()
  def generate_child_id(parent_id) do
    String.to_atom("#{parent_id}_child_#{:rand.uniform(100000)}")
  end
  
  @doc """
  Calculate inherited budget for child program.
  
  Child receives fraction of parent's wealth to prevent exponential growth.
  
  ## Parameters
  
  - `parent_budget`: Parent's budget map
  
  ## Returns
  
  Child's starting budget.
  """
  @spec inherit_budget(map()) :: map()
  def inherit_budget(%{credits: credits, compute: compute, attention: attention}) do
    # Ensure child has survivable starting budget (well above typical program levels)
    inherited_credits = max(credits * @budget_inheritance_fraction, 300.0)
    inherited_compute = max(compute * @budget_inheritance_fraction, 300.0)
    inherited_attention = max(attention * @budget_inheritance_fraction, 150.0)
    
    %{
      credits: inherited_credits,
      compute: inherited_compute,
      attention: inherited_attention
    }
  end
  
  def inherit_budget(_), do: %{credits: 100.0, compute: 100.0, attention: 50.0}
  
  @doc """
  Summarize reproduction event for logging.
  
  ## Parameters
  
  - `parent`: Parent program
  - `child`: Child program
  - `wisdom`: Applied institutional wisdom
  - `capabilities`: Available civilization capabilities
  
  ## Returns
  
  Formatted string summary.
  """
  @spec summarize_reproduction(ResearchProgram.t(), ResearchProgram.t(), map(), map()) :: String.t()
  def summarize_reproduction(parent, child, wisdom, capabilities) do
    lines = [
      "=== Reproduction Event ===",
      "Parent: #{parent.id} (gen #{parent.generation})",
      "Child:  #{child.id} (gen #{child.generation})",
      "",
      "Wisdom Applied:",
      "  Confidence: #{Float.round(wisdom.confidence * 100, 1)}%",
      "  Lessons: #{wisdom.lesson_count || 0}",
      "",
      "Capabilities Inherited: #{map_size(capabilities)}",
      "  Top capabilities:",
      format_top_capabilities(capabilities, 3)
    ]
    
    Enum.join(lines, "\n")
  end
  
  @spec format_top_capabilities(map(), integer()) :: String.t()
  defp format_top_capabilities(capabilities, count) do
    capabilities
      |> Enum.sort_by(fn {_cap, level} -> -level end)
      |> Enum.take(count)
      |> Enum.map_join("\n", fn {cap, level} ->
        "    - #{cap}: #{Float.round(level, 2)}"
      end)
  end
end
