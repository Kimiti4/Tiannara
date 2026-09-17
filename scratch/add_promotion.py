import os

def append_to_file():
    code_to_add = """
  @doc \"\"\"
  Promotes mature capabilities from Program -> World -> Civilization layer.
  Runs periodically to solidify knowledge.
  \"\"\"
  @spec promote_capabilities(State.t()) :: State.t()
  def promote_capabilities(%State{} = state) do
    # 1. Program -> World Promotion
    updated_state = promote_program_to_world(state)
    
    # 2. World -> Civilization Promotion
    promote_world_to_civilization(updated_state)
  end
  
  defp promote_program_to_world(state) do
    worlds = state.worlds || %{}
    programs = state.research_programs || %{}
    
    # Group programs by world
    programs_by_world = Enum.group_by(Map.values(programs), & &1.world_id)
    
    updated_worlds = Enum.reduce(worlds, worlds, fn {world_id, world}, acc_worlds ->
      world_progs = Map.get(programs_by_world, world_id, [])
      
      # Collect all capabilities across all programs in this world
      all_caps = Enum.flat_map(world_progs, fn p -> Map.values(p.capabilities || %{}) end)
      
      # Find capabilities meeting promotion criteria
      promotable = all_caps
        |> Enum.filter(fn cap -> 
             cap.fitness_score > 0.8 and 
             cap.usage_count > 5 and
             cap.version > 2
           end)
        |> Enum.group_by(& &1.id)
        
      # Only promote if adopted by multiple lineages (adoption count > 1 isn't enough, we need multiple instances)
      promoted_nodes = promotable
        |> Enum.filter(fn {_id, instances} -> length(instances) >= 3 end)
        |> Enum.map(fn {id, instances} -> 
             # Take best instance
             best_node = Enum.max_by(instances, & &1.fitness_score)
             {id, %{best_node | promoted: true}}
           end)
        |> Enum.into(%{})
        
      if map_size(promoted_nodes) > 0 do
        world_caps = world.capabilities || %{}
        merged_world_caps = Map.merge(world_caps, promoted_nodes, fn _k, v1, v2 -> 
          if v1.fitness_score > v2.fitness_score, do: v1, else: v2 
        end)
        
        updated_world = %{world | capabilities: merged_world_caps}
        Map.put(acc_worlds, world_id, updated_world)
      else
        acc_worlds
      end
    end)
    
    %{state | worlds: updated_worlds}
  end
  
  defp promote_world_to_civilization(state) do
    civ_caps = Map.get(state, :capabilities, %{})
    worlds = state.worlds || %{}
    
    all_world_caps = worlds
      |> Map.values()
      |> Enum.flat_map(fn w -> Map.values(w.capabilities || %{}) end)
      |> Enum.group_by(& &1.id)
      
    # Promote to civ level if present in 20% of worlds
    threshold = max(1, map_size(worlds) * 0.2 |> round())
    
    promoted_nodes = all_world_caps
      |> Enum.filter(fn {_id, instances} -> length(instances) >= threshold end)
      |> Enum.map(fn {id, instances} -> 
             best_node = Enum.max_by(instances, & &1.fitness_score)
             {id, %{best_node | promoted: true}}
           end)
      |> Enum.into(%{})
      
    merged_civ_caps = Map.merge(civ_caps, promoted_nodes, fn _k, v1, v2 -> 
      if v1.fitness_score > v2.fitness_score, do: v1, else: v2 
    end)
    
    # Using Map.put because state struct might not have `capabilities` explicitly defined
    # Actually, TiannaraOS.State needs to be updated in Phase F to have `:capabilities`.
    Map.put(state, :capabilities, merged_civ_caps)
  end
"""
    # Insert code before the final "end" of the module
    with open(r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\capability_registry.ex", "r", encoding="utf-8") as f:
        content = f.read()
    
    if "def promote_capabilities" not in content:
        # Find last end
        last_end_idx = content.rfind("end")
        new_content = content[:last_end_idx] + code_to_add + "\nend\n"
        
        with open(r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\capability_registry.ex", "w", encoding="utf-8") as f:
            f.write(new_content)
        print("Capability promotion added.")
    else:
        print("Already added.")

append_to_file()
