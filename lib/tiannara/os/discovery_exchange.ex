defmodule TiannaraOS.DiscoveryExchange do
  @moduledoc """
  Facilitates knowledge sharing between Research Programs.
  
  Enables cross-pollination of discoveries, preventing siloed knowledge
  and accelerating innovation through import/export mechanisms.
  """
  
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  
  @doc """
  Share a discovery from one program to another.
  
  Returns updated state with shared discovery added to recipient's discoveries.
  """
  @spec share_discovery(State.t(), atom(), atom()) :: {:ok, State.t()} | {:error, any()}
  def share_discovery(%State{} = state, from_program_id, to_program_id) do
    case {Map.get(state.research_programs, from_program_id), Map.get(state.research_programs, to_program_id)} do
      {nil, _} -> {:error, :source_program_not_found}
      {_, nil} -> {:error, :target_program_not_found}
      {%ResearchProgram{} = from_prog, %ResearchProgram{} = to_prog} ->
        # Find validated discoveries from source program
        validated_discoveries = get_validated_discoveries(from_prog, state)
        
        if length(validated_discoveries) == 0 do
          {:error, :no_validated_discoveries}
        else
          # Select a discovery to share (could be weighted by quality)
          discovery_to_share = Enum.random(validated_discoveries)
          
          # Add to recipient's discoveries
          updated_to_prog = %{
            to_prog |
            discoveries: [discovery_to_share.id | to_prog.discoveries]
          }
          
          new_programs = Map.put(state.research_programs, to_program_id, updated_to_prog)
          {:ok, %{state | research_programs: new_programs}}
        end
    end
  end
  
  @doc """
  Cross-pollinate discoveries between all programs in a world.
  
  Each program shares one discovery with a random peer.
  """
  @spec cross_pollinate_world(State.t(), atom()) :: State.t()
  def cross_pollinate_world(%State{} = state, world_id) do
    programs_in_world = 
      state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.world_id == world_id)
    
    if length(programs_in_world) < 2 do
      state  # Need at least 2 programs to share
    else
      # Each program shares with a random peer
      Enum.reduce(programs_in_world, state, fn prog, acc_state ->
        peers = Enum.reject(programs_in_world, & &1.id == prog.id)
        
        if length(peers) > 0 and length(prog.discoveries) > 0 do
          target = Enum.random(peers)
          
          case share_discovery(acc_state, prog.id, target.id) do
            {:ok, new_state} -> new_state
            {:error, _} -> acc_state  # Skip if can't share
          end
        else
          acc_state
        end
      end)
    end
  end
  
  @doc """
  Import discoveries from other worlds (cross-world exchange).
  
  Programs can import validated discoveries from different worlds,
  enabling knowledge migration across the civilization.
  """
  @spec import_from_other_worlds(State.t(), atom()) :: State.t()
  def import_from_other_worlds(%State{} = state, target_world_id) do
    # Find programs in other worlds with validated discoveries
    external_programs = 
      state.research_programs
      |> Map.values()
      |> Enum.filter(fn prog ->
        prog.world_id != target_world_id and length(prog.discoveries) > 0
      end)
    
    target_programs = 
      state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.world_id == target_world_id)
    
    if length(external_programs) == 0 or length(target_programs) == 0 do
      state
    else
      # Each target program imports from a random external program
      Enum.reduce(target_programs, state, fn target_prog, acc_state ->
        source_prog = Enum.random(external_programs)
        
        case share_discovery(acc_state, source_prog.id, target_prog.id) do
          {:ok, new_state} -> new_state
          {:error, _} -> acc_state
        end
      end)
    end
  end
  
  @doc """
  Calculate knowledge diversity for a program.
  
  Measures how many unique discovery sources a program has accessed.
  Higher diversity indicates better cross-pollination.
  """
  @spec calculate_knowledge_diversity(ResearchProgram.t(), State.t()) :: float()
  def calculate_knowledge_diversity(%ResearchProgram{} = program, %State{} = state) do
    if length(program.discoveries) == 0 do
      0.0
    else
      # Count unique origin programs of discoveries
      unique_sources = 
        program.discoveries
        |> Enum.map(fn disc_id ->
          case Map.get(state.discoveries, disc_id) do
            %Discovery{origin_program_id: origin_id} -> origin_id
            _ -> nil
          end
        end)
        |> Enum.filter(& &1 != nil)
        |> Enum.uniq()
      
      diversity_ratio = length(unique_sources) / length(program.discoveries)
      min(diversity_ratio, 1.0)
    end
  end
  
  @doc """
  Perform global discovery exchange across all worlds.
  
  Called periodically to ensure knowledge flows throughout the system.
  """
  @spec perform_global_exchange(State.t()) :: State.t()
  def perform_global_exchange(%State{} = state) do
    world_ids = 
      state.research_programs
      |> Map.values()
      |> Enum.map(& &1.world_id)
      |> Enum.uniq()
    
    Enum.reduce(world_ids, state, fn world_id, acc_state ->
      # First: cross-pollinate within world
      acc_state = cross_pollinate_world(acc_state, world_id)
      
      # Second: import from other worlds
      acc_state = import_from_other_worlds(acc_state, world_id)
      
      acc_state
    end)
  end
  
  # --- PRIVATE HELPERS ---
  
  defp get_validated_discoveries(%ResearchProgram{} = program, %State{} = state) do
    program.discoveries
    |> Enum.map(fn disc_id -> Map.get(state.discoveries, disc_id) end)
    |> Enum.filter(fn
      %Discovery{status: :validated} -> true
      %Discovery{validation_level: level} when level in [:l2, :l3, :l4] -> true
      _ -> false
    end)
    |> Enum.filter(& &1 != nil)
  end
end
