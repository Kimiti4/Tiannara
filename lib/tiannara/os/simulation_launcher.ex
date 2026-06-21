defmodule TiannaraOS.SimulationLauncher do
  @moduledoc """
  Launches large-scale civilization simulations.
  
  Creates initial state with multiple worlds and diverse programs,
  then runs the CivilizationScheduler for 100k ticks.
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.CivilizationScheduler
  
  @doc """
  Create initial simulation state with 50 worlds and 2000 programs.
  
  ## Returns
  
  Initialized State ready for simulation.
  """
  @spec create_initial_state() :: State.t()
  def create_initial_state() do
    IO.puts("Creating initial state...")
    
    # Create 50 worlds with diverse initial needs
    worlds = create_worlds(50)
    
    # Create 2000 programs distributed across worlds (40 per world average)
    programs = create_programs(2000, worlds)
    
    world_program_index = Enum.reduce(programs, %{}, fn {prog_id, prog}, acc ->
      Map.update(acc, prog.world_id, MapSet.new([prog_id]), &MapSet.put(&1, prog_id))
    end)
    
    world_population_cache = Enum.reduce(worlds, %{}, fn {world_id, _}, acc ->
      prog_count = MapSet.size(Map.get(world_program_index, world_id, MapSet.new()))
      Map.put(acc, world_id, %{active: prog_count, newborn: 0, juvenile: 0, apprentice: 0, adult: prog_count})
    end)
    
    reproduction_candidates = Map.new(programs, fn {id, _} -> {id, true} end)
    
    metadata = %{
      total_births: 0,
      total_deaths: 0,
      active_count: 2000,
      dead_count: 0,
      newborn_count: 0,
      juvenile_count: 0,
      apprentice_count: 0,
      adult_count: 2000,
      generation_counts: %{1 => 2000},
      last_total_born: 0,
      last_dead_count: 0,
      last_n_to_j: 0,
      last_j_to_a: 0,
      last_a_to_adult: 0,
      last_founder_fraction: 100.0
    }
    
    %State{
      worlds: worlds,
      research_programs: programs,
      discoveries: %{},
      program_graveyard: %{},
      economy: %{tick: 0, total_resources: 1_000_000.0},
      world_program_index: world_program_index,
      world_population_cache: world_population_cache,
      maturation_queue: %{},
      reproduction_candidates: reproduction_candidates,
      tick_discoveries: [],
      metadata: metadata
    }
  end
  @doc """
  Run 100k tick civilization simulation.
  
  ## Returns
  
  Final state after simulation completes.
  """
  @spec run_full_simulation() :: State.t()
  def run_full_simulation() do
    initial_state = create_initial_state()
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAUNCHING CIVILIZATION SIMULATION")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Worlds: #{map_size(initial_state.worlds)}")
    IO.puts("Programs: #{map_size(initial_state.research_programs)}")
    IO.puts("Duration: 100,000 ticks")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    # Run simulation with all features enabled
    final_state = CivilizationScheduler.run_simulation(
      initial_state,
      100_000,
      enable_capabilities: true,
      enable_needs_evolution: true,
      enable_world_memory: true,
      report_interval: 5_000
    )
    
    # Print comprehensive summary
    CivilizationScheduler.print_civilization_summary(final_state)
    
    # Analyze results in detail
    metrics = CivilizationScheduler.analyze_results(final_state)
    
    IO.puts("\nDetailed Metrics:")
    IO.inspect(metrics, pretty: true, limit: :infinity)
    
    final_state
  end
  
  # ============================================================================
  # Private Helper Functions
  # ============================================================================
  
  @spec create_worlds(integer()) :: map()
  defp create_worlds(count) do
    base_needs_options = [
      %{energy: 0.9, materials: 0.5, computation: 0.3},
      %{materials: 0.9, energy: 0.4, manufacturing: 0.5},
      %{computation: 0.9, energy: 0.6, algorithms: 0.4},
      %{medicine: 0.9, biology: 0.7, chemistry: 0.5},
      %{manufacturing: 0.9, materials: 0.6, automation: 0.4}
    ]
    
    Enum.reduce(1..count, %{}, fn i, acc ->
      world_id = String.to_atom("w#{i}")
      
      # Pick random base needs
      base_needs = Enum.random(base_needs_options)
      
      # Add slight variation
      varied_needs = Map.new(base_needs, fn {domain, value} ->
        variation = (:rand.uniform() - 0.5) * 0.2  # ±0.1
        {domain, Float.round(max(0.1, min(1.0, value + variation)), 2)}
      end)
      
      world = %{
        id: world_id,
        name: "World #{i}",
        original_needs: varied_needs,
        needs_vector: varied_needs,
        capabilities: %{},
        memory: %{
          successful_domains: %{},
          failed_domains: %{},
          recurring_bottlenecks: [],
          adaptation_history: [],
          last_updated_tick: 0
        },
        wealth: 100_000.0,        # Increased 10x: prevents rapid funding pool depletion
        # Carrying capacity: max programs this world can support
        carrying_capacity: :rand.uniform(20) + 30,  # 30-50 programs
        # Funding pool for active programs
        funding_pool: 500_000.0,  # Increased 10x: initial budget
        # Capability maintenance cost per tick
        capability_maintenance_rate: 0.0001  # 0.01% of wealth per tick (reduced 10x to slow wealth drain)
      }
      
      Map.put(acc, world_id, world)
    end)
  end
  
  @spec create_programs(integer(), map()) :: map()
  defp create_programs(count, worlds) do
    world_ids = Map.keys(worlds)
    
    # Diverse strategy archetypes
    strategy_archetypes = [
      # Explorer: high exploration, low validation
      %{
        exploration_rate: 0.85,
        validation_priority: 0.2,
        cross_domain_synthesis: 0.4,
        anomaly_sensitivity: 0.5,
        risk_tolerance: 0.7
      },
      # Validator: high validation, conservative
      %{
        exploration_rate: 0.3,
        validation_priority: 0.85,
        cross_domain_synthesis: 0.3,
        anomaly_sensitivity: 0.4,
        risk_tolerance: 0.3
      },
      # Synthesizer: high cross-domain synthesis
      %{
        exploration_rate: 0.6,
        validation_priority: 0.5,
        cross_domain_synthesis: 0.85,
        anomaly_sensitivity: 0.6,
        risk_tolerance: 0.5
      },
      # Anomaly Detector: high anomaly sensitivity
      %{
        exploration_rate: 0.5,
        validation_priority: 0.4,
        cross_domain_synthesis: 0.5,
        anomaly_sensitivity: 0.85,
        risk_tolerance: 0.6
      },
      # Risk-Taker: high risk tolerance
      %{
        exploration_rate: 0.7,
        validation_priority: 0.3,
        cross_domain_synthesis: 0.6,
        anomaly_sensitivity: 0.5,
        risk_tolerance: 0.85
      },
      # Balanced: moderate everything
      %{
        exploration_rate: 0.5,
        validation_priority: 0.5,
        cross_domain_synthesis: 0.5,
        anomaly_sensitivity: 0.5,
        risk_tolerance: 0.5
      }
    ]
    
    Enum.reduce(1..count, %{}, fn i, acc ->
      prog_id = String.to_atom("prog_#{i}")
      
      # Assign to random world
      world_id = Enum.random(world_ids)
      
      # Pick random archetype and add mutation
      base_strategy = Enum.random(strategy_archetypes)
      mutated_strategy = mutate_strategy(base_strategy, 0.15)
      
      program = %ResearchProgram{
        id: prog_id,
        world_id: world_id,
        institution_id: String.to_atom("inst_#{rem(i, 10) + 1}"),
        status: :active,
        generation: 1,
        budget: %{
          credits: 3000.0 + (:rand.uniform() * 1000),   # Increased 3x: more runway for reproduction
          compute: 300.0 + (:rand.uniform() * 100),
          attention: 150.0 + (:rand.uniform() * 50)
        },
        strategy_genome: mutated_strategy,
        discoveries: [],
        born_at_tick: -8000,    # Founding programs are fully mature from tick 0
        juvenile_period: 8000,  # Matches the four-stage maturation window
        life_stage: :adult,     # Mature from start — they are the founders
        metadata: %{
          created_at_tick: 0,
          current_tick: 0,
          archetype: identify_archetype(base_strategy)
        }
      }
      
      Map.put(acc, prog_id, program)
    end)
  end
  
  @spec mutate_strategy(map(), float()) :: map()
  defp mutate_strategy(strategy, mutation_rate) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, strategy, fn trait, acc ->
      value = Map.get(acc, trait, 0.5)
      perturbation = (:rand.uniform() - 0.5) * 2 * mutation_rate
      new_value = max(0.0, min(1.0, value + perturbation))
      Map.put(acc, trait, Float.round(new_value, 3))
    end)
  end
  
  @spec identify_archetype(map()) :: atom()
  defp identify_archetype(strategy) do
    cond do
      strategy.exploration_rate > 0.7 -> :explorer
      strategy.validation_priority > 0.7 -> :validator
      strategy.cross_domain_synthesis > 0.7 -> :synthesizer
      strategy.anomaly_sensitivity > 0.7 -> :anomaly_detector
      strategy.risk_tolerance > 0.7 -> :risk_taker
      true -> :balanced
    end
  end
end
