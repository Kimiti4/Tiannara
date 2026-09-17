import os

NEW_CODE = """defmodule TiannaraOS.CapabilityRegistry do
  @moduledoc \"\"\"
  Three-Layer Capability Graph Architecture
  
  Manages the evolution of capabilities at the Program layer.
  Discoveries drive mutations (Improvement, Specialization, Synthesis, Paradigm Shift).
  \"\"\"
  
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  alias TiannaraOS.CapabilityNode
  alias TiannaraOS.ResearchProgram

  @capability_unlock_threshold 0.4
  
  # Selection and Extinction Parameters
  @selection_decay_rate 0.05
  @extinction_threshold 0.1

  @doc \"\"\"
  Register a discovery, mutating the program's capability graph.
  \"\"\"
  @spec register_discovery(State.t(), Discovery.t()) :: State.t()
  def register_discovery(%State{} = state, %Discovery{} = discovery) do
    prog_id = discovery.origin_program_id
    program = Map.get(state.research_programs || %{}, prog_id)
    
    if program do
      current_tick = state.economy[:tick] || 0
      
      # 1. Decay and prune old capabilities (Selection Layer)
      pruned_caps = apply_capability_selection(program.capabilities || %{}, current_tick)
      
      # 2. Mutate based on discovery
      mutated_caps = apply_discovery_mutation(pruned_caps, discovery, current_tick)
      
      # Update program
      updated_program = %{program | capabilities: mutated_caps}
      updated_programs = Map.put(state.research_programs, prog_id, updated_program)
      
      %{state | research_programs: updated_programs}
    else
      state
    end
  end

  @doc \"\"\"
  Check if a discovery's capability prerequisites are satisfied by the program.
  \"\"\"
  @spec check_capability_prerequisites(State.t(), Discovery.t()) :: {:ok, map()} | {:blocked, [atom()]}
  def check_capability_prerequisites(%State{} = state, %Discovery{} = discovery) do
    prog_id = discovery.origin_program_id
    program = Map.get(state.research_programs || %{}, prog_id)
    
    if program do
      program_caps = program.capabilities || %{}
      required = infer_required_capabilities(discovery)
      
      # Check if program has nodes that satisfy requirements
      missing = Enum.filter(required, fn {req_domain, req_level} ->
        # Find best node matching this domain or descended from it
        best_efficiency = program_caps
          |> Map.values()
          |> Enum.filter(fn node -> 
               node.id == req_domain || req_domain in (node.parent_nodes || [])
             end)
          |> Enum.map(& &1.efficiency)
          |> Enum.max(fn -> 0.0 end)
          
        best_efficiency < req_level
      end)
      
      if Enum.empty?(missing) do
        {:ok, %{}}
      else
        {:blocked, Enum.map(missing, fn {cap, _} -> cap end)}
      end
    else
      {:blocked, [:no_program]}
    end
  end

  # ============================================================================
  # Internal Engine
  # ============================================================================

  defp apply_capability_selection(capabilities, current_tick) do
    # Decay selection score over time if unused. Extinct if < threshold.
    capabilities
    |> Enum.map(fn {id, node} ->
      ticks_since_use = current_tick - (node.last_used_tick || 0)
      decay = if ticks_since_use > 500, do: @selection_decay_rate, else: 0.0
      
      new_selection = max(0.0, node.selection_score - decay)
      extinction_risk = if new_selection < 0.2, do: 1.0 - (new_selection * 5), else: 0.0
      
      updated_node = %{node | 
        selection_score: new_selection,
        extinction_risk: extinction_risk
      }
      {id, updated_node}
    end)
    |> Enum.filter(fn {_id, node} -> node.selection_score > @extinction_threshold end)
    |> Enum.into(%{})
  end

  defp apply_discovery_mutation(capabilities, discovery, current_tick) do
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    
    # Filter valid domains
    valid_domains = domain_vector
      |> Enum.filter(fn {_, w} -> w >= @capability_unlock_threshold end)
      |> Enum.map(fn {d, w} -> {d, w} end)
      
    cond do
      length(valid_domains) == 0 -> capabilities
      length(valid_domains) == 1 ->
        {domain, weight} = hd(valid_domains)
        apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick)
      true ->
        apply_synthesis_mutation(capabilities, valid_domains, discovery, current_tick)
    end
  end

  defp apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick) do
    existing_node = Map.get(capabilities, domain)
    
    rand = :rand.uniform()
    
    if existing_node do
      if rand < 0.05 do
        # Type 4: Paradigm Shift (Create completely new parallel branch)
        new_id = String.to_atom("#{domain}_paradigm_#{:rand.uniform(1000)}")
        new_node = create_node(new_id, [domain], weight * 0.8, discovery, current_tick)
        Map.put(capabilities, new_id, new_node)
      else
        if rand < 0.20 do
          # Type 2: Specialization
          new_id = String.to_atom("#{domain}_spec_#{:rand.uniform(1000)}")
          new_node = create_node(new_id, [domain], existing_node.efficiency + 0.1, discovery, current_tick)
          Map.put(capabilities, new_id, new_node)
        else
          # Type 1: Improvement (Mutate existing)
          updated = %{existing_node |
            version: existing_node.version + 1,
            efficiency: min(1.5, existing_node.efficiency + (weight * 0.05)),
            reliability: min(1.0, existing_node.reliability + 0.02),
            usage_count: existing_node.usage_count + 1,
            last_used_tick: current_tick,
            selection_score: min(1.0, existing_node.selection_score + 0.1)
          }
          updated = update_fitness(updated)
          Map.put(capabilities, domain, updated)
        end
      end
    else
      # Create initial base node
      new_node = create_node(domain, [], weight, discovery, current_tick)
      Map.put(capabilities, domain, new_node)
    end
  end

  defp apply_synthesis_mutation(capabilities, domains, discovery, current_tick) do
    # Type 3: Synthesis
    # Create a brand new node integrating multiple parents
    parent_ids = Enum.map(domains, fn {d, _} -> d end)
    
    # Update parents usage
    updated_caps = Enum.reduce(parent_ids, capabilities, fn p_id, acc ->
      if node = Map.get(acc, p_id) do
        updated = %{node | 
          usage_count: node.usage_count + 1,
          last_used_tick: current_tick,
          selection_score: min(1.0, node.selection_score + 0.1)
        }
        Map.put(acc, p_id, update_fitness(updated))
      else
        # If parent doesn't exist, create it as base
        Map.put(acc, p_id, create_node(p_id, [], 0.5, discovery, current_tick))
      end
    end)
    
    # Generate Synthesis ID
    syn_id = String.to_atom("syn_" <> Enum.join(parent_ids, "_") <> "_#{:rand.uniform(1000)}")
    
    # Base stats derived from parents
    avg_efficiency = updated_caps
      |> Map.take(parent_ids)
      |> Map.values()
      |> Enum.map(& &1.efficiency)
      |> Enum.sum()
      |> Kernel./(max(1, length(parent_ids)))
      
    syn_node = create_node(syn_id, parent_ids, avg_efficiency + 0.2, discovery, current_tick)
    syn_node = %{syn_node | novelty: 0.9} # High novelty for synthesis
    syn_node = update_fitness(syn_node)
    
    Map.put(updated_caps, syn_id, syn_node)
  end

  defp create_node(id, parents, base_efficiency, discovery, current_tick) do
    depth = 1 + (length(parents) * 1) # Simplified depth calc
    
    node = %CapabilityNode{
      id: id,
      domain_vector: Map.get(discovery.metadata, :domain_vector, %{}),
      version: 1,
      efficiency: min(1.5, base_efficiency),
      reliability: 0.5,
      novelty: 0.8,
      maturity: 0.1,
      parent_nodes: parents,
      child_nodes: [],
      depth: depth,
      discovered_by: discovery.origin_program_id,
      usage_count: 1,
      adoption_count: 1,
      selection_score: 1.0, # Starts fully selected
      last_used_tick: current_tick,
      extinction_risk: 0.0,
      promoted: false
    }
    update_fitness(node)
  end

  defp update_fitness(node) do
    fitness = node.efficiency * node.reliability * max(1, node.adoption_count) * node.novelty
    %{node | fitness_score: fitness}
  end

  defp infer_required_capabilities(%Discovery{} = discovery) do
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    
    domain_vector
      |> Enum.filter(fn {_, w} -> w > 0.4 end)
      |> Enum.map(fn {d, w} -> {d, Float.round(w * 0.5, 2)} end)
      |> Enum.into(%{})
  end
  
  def get_unlocked_capabilities(%Discovery{} = discovery) do
    # Fallback for old tests if needed
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    domain_vector |> Map.keys()
  end
end
"""

with open(r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\capability_registry.ex", "w", encoding="utf-8") as f:
    f.write(NEW_CODE)

print("CapabilityRegistry rewritten successfully.")
