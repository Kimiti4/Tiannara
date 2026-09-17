import os
import re

file_path = r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\capability_registry.ex"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace apply_capability_selection to return {pruned_caps, extinctions}
content = content.replace("pruned_caps = apply_capability_selection(program.capabilities || %{}, current_tick)",
                          "{pruned_caps, extinctions} = apply_capability_selection(program.capabilities || %{}, current_tick)")

content = content.replace("defp apply_capability_selection(capabilities, current_tick) do",
"""defp apply_capability_selection(capabilities, current_tick) do
    evaluated = capabilities
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
    
    survivors = evaluated
    |> Enum.filter(fn {_id, node} -> node.selection_score > @extinction_threshold end)
    |> Enum.into(%{})
    
    extinctions = map_size(capabilities) - map_size(survivors)
    {survivors, extinctions}""")

# Remove old apply_capability_selection logic
content = re.sub(r"defp apply_capability_selection\(capabilities, current_tick\) do.*?{survivors, extinctions}", 
"""defp apply_capability_selection(capabilities, current_tick) do
    evaluated = capabilities
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
    
    survivors = evaluated
    |> Enum.filter(fn {_id, node} -> node.selection_score > @extinction_threshold end)
    |> Enum.into(%{})
    
    extinctions = map_size(capabilities) - map_size(survivors)
    {survivors, extinctions}""", content, flags=re.DOTALL, count=1)


# Replace apply_discovery_mutation to return {mutated_caps, births}
content = content.replace("mutated_caps = apply_discovery_mutation(pruned_caps, discovery, current_tick)",
                          "{mutated_caps, births} = apply_discovery_mutation(pruned_caps, discovery, current_tick)")

content = re.sub(r"defp apply_discovery_mutation\(capabilities, discovery, current_tick\) do.*?end",
"""defp apply_discovery_mutation(capabilities, discovery, current_tick) do
    domain_vector = Map.get(discovery.metadata, :domain_vector, %{})
    
    valid_domains = domain_vector
      |> Enum.filter(fn {_, w} -> w >= @capability_unlock_threshold end)
      |> Enum.map(fn {d, w} -> {d, w} end)
      
    cond do
      length(valid_domains) == 0 -> {capabilities, 0}
      length(valid_domains) == 1 ->
        {domain, weight} = hd(valid_domains)
        apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick)
      true ->
        apply_synthesis_mutation(capabilities, valid_domains, discovery, current_tick)
    end
  end""", content, flags=re.DOTALL, count=1)

content = re.sub(r"defp apply_single_domain_mutation.*?defp apply_synthesis_mutation",
"""defp apply_single_domain_mutation(capabilities, domain, weight, discovery, current_tick) do
    existing_node = Map.get(capabilities, domain)
    rand = :rand.uniform()
    
    if existing_node do
      if rand < 0.05 do
        # Type 4: Paradigm Shift
        new_id = String.to_atom("#{domain}_paradigm_#{:rand.uniform(1000)}")
        new_node = create_node(new_id, [domain], weight * 0.8, discovery, current_tick)
        {Map.put(capabilities, new_id, new_node), 1}
      else
        if rand < 0.20 do
          # Type 2: Specialization
          new_id = String.to_atom("#{domain}_spec_#{:rand.uniform(1000)}")
          new_node = create_node(new_id, [domain], existing_node.efficiency + 0.1, discovery, current_tick)
          {Map.put(capabilities, new_id, new_node), 1}
        else
          # Type 1: Improvement
          updated = %{existing_node |
            version: existing_node.version + 1,
            efficiency: min(1.5, existing_node.efficiency + (weight * 0.05)),
            reliability: min(1.0, existing_node.reliability + 0.02),
            usage_count: existing_node.usage_count + 1,
            last_used_tick: current_tick,
            selection_score: min(1.0, existing_node.selection_score + 0.1)
          }
          updated = update_fitness(updated)
          {Map.put(capabilities, domain, updated), 0}
        end
      end
    else
      new_node = create_node(domain, [], weight, discovery, current_tick)
      {Map.put(capabilities, domain, new_node), 1}
    end
  end

  defp apply_synthesis_mutation""", content, flags=re.DOTALL, count=1)

content = re.sub(r"defp apply_synthesis_mutation.*?defp create_node",
"""defp apply_synthesis_mutation(capabilities, domains, discovery, current_tick) do
    parent_ids = Enum.map(domains, fn {d, _} -> d end)
    
    updated_caps = Enum.reduce(parent_ids, capabilities, fn p_id, acc ->
      if node = Map.get(acc, p_id) do
        updated = %{node | 
          usage_count: node.usage_count + 1,
          last_used_tick: current_tick,
          selection_score: min(1.0, node.selection_score + 0.1)
        }
        Map.put(acc, p_id, update_fitness(updated))
      else
        Map.put(acc, p_id, create_node(p_id, [], 0.5, discovery, current_tick))
      end
    end)
    
    syn_id = String.to_atom("syn_" <> Enum.join(parent_ids, "_") <> "_#{:rand.uniform(1000)}")
    
    avg_efficiency = updated_caps
      |> Map.take(parent_ids)
      |> Map.values()
      |> Enum.map(& &1.efficiency)
      |> Enum.sum()
      |> Kernel./(max(1, length(parent_ids)))
      
    syn_node = create_node(syn_id, parent_ids, avg_efficiency + 0.2, discovery, current_tick)
    syn_node = %{syn_node | novelty: 0.9}
    syn_node = update_fitness(syn_node)
    
    {Map.put(updated_caps, syn_id, syn_node), 1}
  end

  defp create_node""", content, flags=re.DOTALL, count=1)

# Now update the main register_discovery function to track metadata
content = content.replace("%{state | research_programs: updated_programs}",
"""meta = state.metadata || %{}
      meta = Map.update(meta, :capability_births, births, &(&1 + births))
      meta = Map.update(meta, :capability_extinctions, extinctions, &(&1 + extinctions))
      
      # Track rediscovery (if capability was birthed but it's not truly novel)
      # We just count total capability births over time as "Total Discoveries", 
      # and the unique capability size as "Unique Capabilities".
      
      %{state | research_programs: updated_programs, metadata: meta}""")

# Track promotions
content = content.replace("defp promote_program_to_world(state) do",
"""defp promote_program_to_world(state) do
    meta = state.metadata || %{}""")

content = content.replace("promoted_nodes =", "promoted_nodes =")
content = content.replace("Map.put(acc_worlds, world_id, updated_world)",
"""meta = Process.get(:tmp_meta, state.metadata || %{})
        Process.put(:tmp_meta, Map.update(meta, :capability_promotions, map_size(promoted_nodes), &(&1 + map_size(promoted_nodes))))
        Map.put(acc_worlds, world_id, updated_world)""")

content = content.replace("%{state | worlds: updated_worlds}",
"""final_meta = Process.get(:tmp_meta, meta)
    %{state | worlds: updated_worlds, metadata: final_meta}""")


with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patched capability_registry.ex for metrics")
