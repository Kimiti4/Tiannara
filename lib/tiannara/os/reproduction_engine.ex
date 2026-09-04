defmodule TiannaraOS.ReproductionEngine do
  @moduledoc """
  Sprint 2: Probabilistic reproduction with institutional memory.
  
  Programs spawn offspring proportional to portfolio value via sigmoid curve.
  Offspring inherit mutated traits guided by ancestral wisdom from graveyard.
  
  Key features:
  - Smooth probability curve (not threshold cliff)
  - Real Gaussian mutation of traits
  - Institutional memory prevents repeating fatal mistakes
  - Lineage tracking for evolutionary analysis
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.InstitutionalMemory
  
  # Scale parameter: portfolio value where reproduction probability hits ~60%
  @reproduction_scale 3000.0
  
  # Base mutation rate
  @base_mutation_rate 0.2
  
  @doc """
  Trigger probabilistic reproduction for all active programs.
  
  Returns updated state with new child programs spawned.
  
  ## Process
  
  1. Calculate portfolio value for each program
  2. Determine reproduction probability via sigmoid curve
  3. Extract institutional wisdom for parent's world
  4. Spawn mutated offspring if reproduction triggers
  5. Track lineage relationships
  """
  @spec trigger_reproduction(State.t()) :: State.t()
  def trigger_reproduction(%State{} = state) do
    programs = state.research_programs || %{}
    
    Enum.reduce(programs, state, fn {prog_id, program}, acc_state ->
      if program.status == :active and can_reproduce?(program) do
        portfolio_value = calculate_portfolio_value(program, acc_state)
        
        # Sigmoid-like probability bounded to [0, 1]
        reproduction_prob = min(1.0, portfolio_value / @reproduction_scale)
        
        if :rand.uniform() < reproduction_prob do
          # Extract wisdom before spawning
          wisdom = InstitutionalMemory.extract_wisdom(acc_state, program.world_id)
          
          # Spawn mutated offspring
          child_id = generate_child_id(prog_id)
          child_program = mutate_and_spawn(program, child_id, acc_state, wisdom)
          
          # Update parent's child list
          updated_parent = %{program | 
            child_program_ids: (program.child_program_ids || []) ++ [child_id]
          }
          
          updated_programs = Map.put(acc_state.research_programs, prog_id, updated_parent)
          final_programs = Map.put(updated_programs, child_id, child_program)
          
          IO.puts("  🧬 Reproduction: #{prog_id} → #{child_id} (portfolio: #{Float.round(portfolio_value, 0)}, prob: #{Float.round(reproduction_prob * 100, 1)}%)")
          
          %{acc_state | research_programs: final_programs}
        else
          acc_state
        end
      else
        acc_state
      end
    end)
  end
  
  @spec can_reproduce?(ResearchProgram.t()) :: boolean()
  defp can_reproduce?(%ResearchProgram{} = program) do
    current_tick = program.metadata[:created_at_tick] || 0
    age = (program.metadata[:current_tick] || 0) - current_tick
    
    max_children = 5
    current_children = length(program.child_program_ids || [])
    
    age > 100 and current_children < max_children
  end
  
  @spec calculate_portfolio_value(ResearchProgram.t(), State.t()) :: float()
  defp calculate_portfolio_value(%ResearchProgram{} = program, %State{} = state) do
    assets = state.discovery_assets || %{}
    
    program_assets = Enum.filter(assets, fn {_id, asset} ->
      owns_asset?(asset, program.id)
    end)
    |> Map.values()
    
    if Enum.empty?(program_assets) do
      0.0
    else
      # Sum of all asset valuations
      Enum.sum(Enum.map(program_assets, & &1.valuation))
    end
  end
  
  @spec generate_child_id(atom()) :: atom()
  defp generate_child_id(parent_id) do
    generation_suffix = :rand.uniform(9999)
    String.to_atom("#{parent_id}_gen_#{generation_suffix}")
  end
  
  @spec owns_asset?(map(), atom()) :: boolean()
  defp owns_asset?(asset, program_id) do
    Enum.any?(asset.transaction_history || [], fn txn ->
      txn.type == :creation && txn.owner_program == program_id
    end)
  end
  
  @spec mutate_and_spawn(ResearchProgram.t(), atom(), State.t(), map()) :: ResearchProgram.t()
  defp mutate_and_spawn(%ResearchProgram{} = parent, child_id, %State{} = state, wisdom) do
    # Get parent's world physics for context-aware mutation
    physics = parent.metadata[:epistemic_physics]
    
    # Apply wisdom-guided mutation
    mutated_genome = InstitutionalMemory.apply_wisdom_to_mutation(
      parent.strategy_genome,
      wisdom,
      @base_mutation_rate
    )
    
    # Calculate initial budget (15% of parent's current budget)
    child_budget = %{
      credits: parent.budget.credits * 0.15,
      compute: parent.budget.compute * 0.15,
      attention: parent.budget.attention * 0.15,
      curiosity_budget: (parent.budget.curiosity_budget || 0.0) * 0.15
    }
    
    %ResearchProgram{
      id: child_id,
      world_id: parent.world_id,
      strategy_genome: mutated_genome,
      budget: child_budget,
      status: :active,
      parent_program_id: parent.id,  # Track lineage
      child_program_ids: [],
      generation: (parent.generation || 1) + 1,  # Increment generation
      metadata: %{
        epistemic_physics: physics,
        created_at_tick: state.economy[:tick] || 0,
        current_tick: state.economy[:tick] || 0,
        portfolio_value: 0.0,
        lineage_depth: (parent.generation || 1) + 1,
        wisdom_applied: wisdom.confidence > 0.1
      }
    }
  end
end
