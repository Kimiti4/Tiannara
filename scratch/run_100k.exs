defmodule Run100k do
  def execute do
    IO.puts("Starting 100k validation run...")
    
    # Standard 50 world setup
    world_ids = Enum.map(1..50, &String.to_atom("world_#{&1}"))
    worlds = Enum.into(world_ids, %{}, fn id ->
      {id, %TiannaraOS.World{
        id: id,
        name: "World #{id}",
        template_id: :standard,
        labs: [],
        institutions: [],
        theories: [],
        discovery_registry: [],
        economy: %{budget: 1000.0, credits_allocated: %{}},
        tenant_id: "system"
      }}
    end)
    
    # Initialize state
    initial_state = %TiannaraOS.State{
      worlds: worlds,
      economy: %{tick: 0},
      metadata: %{capability_births: 0, capability_extinctions: 0, capability_promotions: 0}
    }
    
    # Populate initial programs
    state_with_programs = Enum.reduce(world_ids, initial_state, fn world_id, acc ->
      Enum.reduce(1..40, acc, fn i, inner_acc ->
        prog_id = String.to_atom("prog_#{world_id}_#{i}")
        program = %TiannaraOS.ResearchProgram{
          id: prog_id,
          world_id: world_id,
          status: :active,
          budget: %{credits: 100.0, energy: 100.0, compute: 10.0, attention: 10.0},
          generation: 1,
          life_stage: :adult,
          born_at_tick: 0
        }
        
        index = inner_acc.world_program_index || %{}
        updated_index = Map.update(index, world_id, MapSet.new([prog_id]), &MapSet.put(&1, prog_id))
        
        %{inner_acc | 
          research_programs: Map.put(inner_acc.research_programs || %{}, prog_id, program),
          world_program_index: updated_index
        }
      end)
    end)

    TiannaraOS.CivilizationScheduler.run_simulation(state_with_programs, 100_000, enable_capabilities: true)
  end
end

Run100k.execute()
