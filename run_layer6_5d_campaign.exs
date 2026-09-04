defmodule Tiannara.Validation.Layer6_5DCampaign do
  @moduledoc """
  Executes the 100k-tick Phase 6.5D Technological Evolution Validation Campaign.
  Runs in steps: 10k -> 25k -> 100k, evaluating explicit failure-state gates at each stage.
  """
  alias TiannaraOS.CivilizationScheduler
  
  require Logger

  def run do
    Logger.info("🚀 [Campaign 6.5D] Bootstrapping Technological Evolution Validation...")
    
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
      metadata: %{
        capability_births: 0, 
        capability_extinctions: 0, 
        capability_promotions: 0,
        enable_capabilities: true
      }
    }
    
    # Populate initial programs
    state = Enum.reduce(world_ids, initial_state, fn world_id, acc ->
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

    # Step 1: 10k Ticks
    Logger.info("\n========================================")
    Logger.info("▶️ STAGE 1: 10,000 TICKS")
    Logger.info("========================================")
    state = run_stage(state, 10_000)
    if evaluate_gates(state, "10k") == :halt, do: exit(:shutdown)
    
    # Step 2: 25k Ticks
    Logger.info("\n========================================")
    Logger.info("▶️ STAGE 2: 25,000 TICKS")
    Logger.info("========================================")
    state = run_stage(state, 15_000) # Runs additional 15k ticks
    if evaluate_gates(state, "25k") == :halt, do: exit(:shutdown)

    # Step 3: 100k Ticks
    Logger.info("\n========================================")
    Logger.info("▶️ STAGE 3: 100,000 TICKS")
    Logger.info("========================================")
    state = run_stage(state, 75_000) # Runs additional 75k ticks
    
    Logger.info("\n🏆 [Campaign 6.5D] Complete.")
    CivilizationScheduler.print_civilization_summary(state)
  end

  defp run_stage(state, ticks) do
    # `run_simulation` already does a loop of ticks, let's use it
    # wait, run_simulation expects total final tick to be the argument usually
    # In `run_100k.exs` it uses `run_simulation(state, 100_000)`
    # Let's just use `run_simulation(state, state.economy[:tick] + ticks, enable_capabilities: true)`
    # Wait, the 3rd argument is a keyword list for run_simulation
    TiannaraOS.CivilizationScheduler.run_simulation(state, (state.economy[:tick] || 0) + ticks, enable_capabilities: true)
  end

  defp evaluate_gates(state, stage_name) do
    metrics = CivilizationScheduler.analyze_results(state)
    
    top_share = Map.get(metrics, :top_capability_share, 0.0)
    roots_ratio = Map.get(metrics, :graph_roots_ratio, 0.0)
    avg_children = Map.get(metrics, :graph_avg_children, 0.0)
    max_gen = Map.get(metrics, :max_generation, 0)
    prev_max_gen = Process.get(:global_max_gen, 0)
    Process.put(:global_max_gen, max_gen)
    
    stall_count = Map.get(metrics, :evolution_stall_count, 0)
    
    Logger.info("📊 Checkpoint [#{stage_name}] Gates:")
    Logger.info("   - Top Capability Share: #{Float.round(top_share * 100, 1)}%")
    Logger.info("   - Roots Ratio: #{Float.round(roots_ratio * 100, 1)}%")
    Logger.info("   - Avg Children: #{Float.round(avg_children, 2)}")
    Logger.info("   - Max Generation: #{max_gen} (Prev: #{prev_max_gen})")
    Logger.info("   - Stall Count: #{stall_count}/3")
    
    cond do
      top_share > 0.40 ->
        Logger.error("❌ FAILURE GATE A: Monopolization (Top Share > 40%)")
        :halt
      roots_ratio > 0.25 or avg_children < 0.5 ->
        Logger.error("❌ FAILURE GATE B: Graph Collapse (Roots > 25% OR Avg Children < 0.5)")
        :halt
      stall_count >= 3 ->
        Logger.error("❌ FAILURE GATE C: Evolution Stall (Births < Deaths for 3 checkpoints)")
        :halt
      max_gen == prev_max_gen and prev_max_gen > 0 ->
        Logger.error("❌ FAILURE GATE D: Generation Stagnation (Max Gen stalled at #{max_gen})")
        :halt
      true ->
        Logger.info("✅ All Failure Gates Passed. Continuing...")
        :continue
    end
  end
end

Tiannara.Validation.Layer6_5DCampaign.run()
