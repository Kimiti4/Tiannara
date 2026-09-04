defmodule Tiannara.Validation.Run16EcologyCampaign do
  @moduledoc """
  Run 16 — Technological Ecology Instrumentation Campaign
  
  Objective: Characterize ecological laws governing technological species in Tiannara
  Duration: 100,000 ticks
  Focus: Instrumentation, profiling, ecological measurement
  Constraint: NO architectural refactors — measurement only
  
  Scientific Question:
    > What are the ecological laws governing technological species inside Tiannara?
  
  Run 15 proved: Technological evolution exists
  Run 16 must prove: Technological ecology exists
  """
  
  alias TiannaraOS.CivilizationScheduler
  require Logger
  
  defp count_capabilities(state) do
    state.research_programs
    |> Map.values()
    |> Enum.flat_map(fn prog -> (prog.capabilities || %{}) |> Map.keys() end)
    |> length()
  end

  def run do
    Logger.info("🚀 [Run 16] Bootstrapping Technological Ecology Instrumentation...")
    
    # Initialize lock-free ecology tracker and profiler
    Tiannara.Ecology.init_tables()
    
    # PHASE 1 DUAL-WRITE: Initialize new event-sourced lifecycle registry
    Tiannara.LifecycleRegistry.init_tables()
    
    Tiannara.Profiling.init_profiler()
    
    # Standard 50 world setup (same as Run 15)
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
    
    # Populate initial programs (40 per world = 2000 total)
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

    # Execute 100k-tick simulation with ecology instrumentation
    Logger.info("\n========================================")
    Logger.info("▶️ RUN 16: 100,000 TICKS WITH ECOLOGY TRACKING")
    Logger.info("========================================")
    
    final_state = run_instrumented_simulation(state, 100_000)
    
    # Print final comprehensive report
    print_final_report(final_state)
    
    Logger.info("\n🏆 [Run 16] Complete — Technological Ecology Characterized")
  end

  defp run_instrumented_simulation(initial_state, max_ticks) do
    start_time = System.monotonic_time(:millisecond)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("RUN 16 — TECHNOLOGICAL ECOLOGY INSTRUMENTATION")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Duration: #{max_ticks} ticks")
    IO.puts("Worlds: #{map_size(initial_state.worlds)}")
    IO.puts("Programs: #{map_size(initial_state.research_programs)}")
    IO.puts("Instrumentation: Lock-free ETS + Telemetry")
    IO.puts(String.duplicate("=", 80) <> "\n")

    final_state =
      Enum.reduce(1..max_ticks, {initial_state, 0}, fn tick, {acc_state, prev_graph_size} ->
        # GRAPH DELTA AUDITING: Track graph size changes
        current_graph_size = 
          acc_state.research_programs
          |> Map.values()
          |> Enum.flat_map(fn prog -> (prog.capabilities || %{}) |> Map.keys() end)
          |> length()
        
        if tick > 1 and current_graph_size != prev_graph_size do
          delta = current_graph_size - prev_graph_size
          if rem(tick, 1000) == 0 or delta < -10 do
            Logger.info("📊 [Tick #{tick}] Graph Delta: #{delta} (Previous: #{prev_graph_size}, Current: #{current_graph_size})")
          end
        end
        
        # Increment ecology tick counter
        Tiannara.Ecology.tick()
        
        # PHASE 1 DUAL-WRITE: Verify lifecycle invariant every 10k ticks
        if rem(tick, 10_000) == 0 do
          try do
            Logger.info("🔍 [Tick #{tick}] Starting invariant check...")
            
            # COMPREHENSIVE GRAPH AUDIT: Count all four metrics
            programs = acc_state.research_programs |> Map.values()
            num_programs = length(programs)
            
            # Total capability entries (sum across all programs)
            total_entries = 
              Enum.sum(
                Enum.map(programs, fn prog ->
                  map_size(prog.capabilities || %{})
                end)
              )
            
            # Unique capability IDs across all programs
            unique_ids_set = 
              programs
              |> Enum.flat_map(fn prog ->
                (prog.capabilities || %{}) |> Map.keys()
              end)
              |> MapSet.new()
            
            unique_ids_count = MapSet.size(unique_ids_set)
            
            # Lifecycle active count
            lifecycle_active = 
              :ets.select(:lifecycle_state, [
                {{{:capability, :'$1'}, :_}, [], [:'$1']}
              ])
              |> length()
            
            Logger.info("📊 [Tick #{tick}] GRAPH AUDIT:")
            Logger.info("   Programs: #{num_programs}")
            Logger.info("   Total Capability Entries (all programs): #{total_entries}")
            Logger.info("   Unique Capability IDs: #{unique_ids_count}")
            Logger.info("   Lifecycle Active State: #{lifecycle_active}")
            
            if total_entries != unique_ids_count do
              Logger.info("   ⚠️  DUPLICATION DETECTED: #{total_entries - unique_ids_count} duplicate capability entries")
            end
            
            graph_capability_ids = unique_ids_set
            
            Logger.info("🔍 [Tick #{tick}] Calling verify!...")
            # Pass a function that returns the set of IDs
            Tiannara.LifecycleRegistry.verify!(:capability, fn -> graph_capability_ids end)
            Logger.info("✅ [Tick #{tick}] Lifecycle invariant verified: #{unique_ids_count} unique active capabilities")
          rescue
            e ->
              Logger.error("🚨 [Tick #{tick}] Lifecycle invariant FAILED: #{inspect(e)}")
              raise e  # Re-enabled after Run 18 validation
          end
        end
        
        # === PHASE 1: Economic & Scarcity Loop (with profiling) ===
        t0 = System.monotonic_time(:microsecond)
        acc_state = update_program_ticks(acc_state, tick)
        t1 = System.monotonic_time(:microsecond)
        
        # Profile economic phases
        acc_state = profile_economic_phases(acc_state, tick)
        
        # Kill exhausted programs
        pre_kill_size = count_capabilities(acc_state)
        acc_state = kill_exhausted_programs(acc_state, tick)
        post_kill_size = count_capabilities(acc_state)
        if rem(tick, 5000) == 0 and pre_kill_size != post_kill_size do
          Logger.info("📊 [Tick #{tick}] Program Death Delta: #{post_kill_size - pre_kill_size} (#{pre_kill_size} → #{post_kill_size})")
        end
        t2 = System.monotonic_time(:microsecond)

        # === PHASE 2: Reproduction Loop ===
        acc_state = rebuild_global_adoption_cache(acc_state, tick)
        
        # Skip reproduction for Run 15.5 validation (module not available)
        t3 = System.monotonic_time(:microsecond)

        # === PHASE 3: Discovery & Capability Loop (with profiling + ecology) ===
        pre_cap_size = count_capabilities(acc_state)
        acc_state = register_new_discoveries_with_ecology(acc_state, tick)
        post_cap_size = count_capabilities(acc_state)
        if rem(tick, 5000) == 0 and pre_cap_size != post_cap_size do
          Logger.info("📊 [Tick #{tick}] Capability Evolution Delta: #{post_cap_size - pre_cap_size} (#{pre_cap_size} → #{post_cap_size})")
        end
        t4 = System.monotonic_time(:microsecond)
        
        acc_state =
          if rem(tick, 10) == 0 do
            apply_capability_decay(acc_state)
          else
            acc_state
          end
        t5 = System.monotonic_time(:microsecond)

        acc_state =
          if rem(tick, 500) == 0 do
            apply_discovery_relevance_decay(acc_state)
          else
            acc_state
          end
        t6 = System.monotonic_time(:microsecond)

        # Skip capability promotion for Run 15.5 validation (module not available)
        t7 = System.monotonic_time(:microsecond)

        # === PHASE 4: Sparse Telemetry & World Evolution ===
        acc_state = evolve_all_world_needs(acc_state, tick)
        acc_state = update_all_world_memories(acc_state, tick)
        
        # Periodic reporting
        acc_state =
          if rem(tick, 20_000) == 0 do
            report_progress(acc_state, tick, start_time)
          else
            acc_state
          end
        
        # Ecology report every 5k ticks
        acc_state =
          if rem(tick, 5_000) == 0 do
            Tiannara.Ecology.print_ecology_report()
            # Skip economic/registration profiling for Run 15.5 validation
            track_lineage_composition(acc_state, tick)
          else
            acc_state
          end
        
        # Skip registration profiling for Run 15.5 validation
        
        t8 = System.monotonic_time(:microsecond)

        # Record runtime performance metrics
        meta = acc_state.metadata || %{}
        meta =
          meta
          |> Map.update(:time_sched, 0, &(&1 + (t1 - t0)))
          |> Map.update(:time_econ, 0, &(&1 + (t2 - t1)))
          |> Map.update(:time_repro, 0, &(&1 + (t3 - t2)))
          |> Map.update(:time_disc, 0, &(&1 + (t4 - t3)))
          |> Map.update(:time_cap_decay, 0, &(&1 + (t5 - t4)))
          |> Map.update(:time_disc_rel, 0, &(&1 + (t6 - t5)))
          |> Map.update(:time_cap_promo, 0, &(&1 + (t7 - t6)))
          |> Map.update(:time_tele, 0, &(&1 + (t8 - t7)))

        updated_economy = Map.put(acc_state.economy, :tick, tick)
        new_state = %{acc_state | economy: updated_economy, metadata: meta}
        
        # Update graph size for next iteration
        new_graph_size = 
          new_state.research_programs
          |> Map.values()
          |> Enum.flat_map(fn prog -> (prog.capabilities || %{}) |> Map.keys() end)
          |> length()
        
        {new_state, new_graph_size}
      end)

    # Extract state from {state, graph_size} tuple
    {final_state, _final_graph_size} = final_state
    
    elapsed = System.monotonic_time(:millisecond) - start_time
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("SIMULATION COMPLETE")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Ticks completed: #{max_ticks}")
    IO.puts("Elapsed time: #{Float.round(elapsed / 1000, 2)} seconds")
    IO.puts("Tick rate: #{Float.round(max_ticks / (elapsed / 1000), 0)} ticks/sec")
    IO.puts(String.duplicate("=", 80) <> "\n")

    final_state
  end

  # ==================== Instrumented Phase Wrappers ====================

  defp profile_economic_phases(state, tick) do
    # For Run 15.5 validation, skip detailed economic profiling
    # The core ecology tracking (births/deaths) is already instrumented
    state
  end

  defp register_new_discoveries_with_ecology(state, tick) do
    # Call existing registration function (already instrumented with ecology tracking)
    register_new_discoveries(state, tick)
  end

  # ==================== Stub Functions (replace with actual implementations) ====================
  
  defp update_program_ticks(state, _tick), do: state
  defp valuate_portfolios(state), do: state
  defp allocate_resources(state), do: state
  defp match_needs(state), do: state
  defp kill_exhausted_programs(state, _tick), do: state
  defp rebuild_global_adoption_cache(state, tick) do
    if rem(tick, 500) == 0 do
      cap_adoption_map =
        Enum.reduce(Map.values(state.research_programs || %{}), %{}, fn p, acc ->
          if p.status == :active do
            Enum.reduce(Map.keys(p.capabilities || %{}), acc, fn cap_id, inner_acc ->
              Map.update(inner_acc, cap_id, 1, &(&1 + 1))
            end)
          else
            acc
          end
        end)

      active_count =
        map_size(
          Enum.filter(state.research_programs || %{}, fn {_, p} ->
            p.status == :active
          end)
          |> Map.new()
        )

      new_meta =
        (state.metadata || %{})
        |> Map.put(:global_adoption, cap_adoption_map)
        |> Map.put(:active_programs_count, active_count)

      %{state | metadata: new_meta}
    else
      state
    end
  end
  defp apply_capability_decay(state), do: state
  defp apply_discovery_relevance_decay(state), do: state
  defp evolve_all_world_needs(state, tick) do
    if rem(tick, 5000) == 0 do
      # Evolve needs logic
      state
    else
      state
    end
  end
  defp update_all_world_memories(state, tick) do
    if rem(tick, 5000) == 0 do
      # Update memories logic
      state
    else
      state
    end
  end
  defp register_new_discoveries(state, tick) do
    # Generate synthetic discoveries for active programs to trigger capability evolution
    active_programs = 
      state.research_programs
      |> Map.values()
      |> Enum.filter(fn prog -> prog.status == :active end)
    
    # Generate 1 discovery per random active program every 100 ticks (sparse to avoid atom exhaustion)
    if rem(tick, 100) == 0 and length(active_programs) > 0 do
      # Pick 10 random programs instead of all 2000
      sample_size = min(10, length(active_programs))
      sampled_programs = Enum.take_random(active_programs, sample_size)
      
      Enum.reduce(sampled_programs, state, fn program, acc_state ->
        # Create a synthetic discovery (use string ID to avoid atom exhaustion)
        # Include domain_vector so capability mutations can occur
        domains = [:mathematics, :physics, :chemistry, :biology, :computer_science, :engineering]
        primary_domain = Enum.random(domains)
        domain_vector = %{primary_domain => 0.7 + :rand.uniform() * 0.3}
        
        discovery = %TiannaraOS.Discovery{
          id: "disc_#{program.id}_#{tick}",  # String, not atom!
          source_world: program.world_id,
          origin_program_id: program.id,
          origin_world_id: program.world_id,
          validation_level: :l1,
          status: :validated,
          evidence_score: 0.8 + :rand.uniform() * 0.2,
          novelty_score: 0.5 + :rand.uniform() * 0.5,
          impact_score: 0.3 + :rand.uniform() * 0.7,
          confidence: 0.9,
          utility: 0.7 + :rand.uniform() * 0.3,
          relevance: 1.0,
          metadata: %{synthetic: true, tick: tick, domain_vector: domain_vector}
        }
        
        # Register the discovery to trigger capability mutations
        new_state = TiannaraOS.CapabilityRegistry.register_discovery(acc_state, discovery)
        
        # Debug: Print first discovery at tick 100
        if tick == 100 and program.id == hd(sampled_programs).id do
          IO.puts("\n🔬 [DEBUG] First discovery generated at tick #{tick}:")
          IO.puts("   Program: #{program.id}")
          IO.puts("   Domain: #{primary_domain}")
          IO.puts("   Domain vector: #{inspect(domain_vector)}")
          IO.puts("   State programs before: #{map_size(acc_state.research_programs)}")
          IO.puts("   State programs after: #{map_size(new_state.research_programs)}")
          prog_before = Map.get(acc_state.research_programs, program.id)
          prog_after = Map.get(new_state.research_programs, program.id)
          IO.puts("   Capabilities before: #{map_size(prog_before.capabilities || %{})}")
          IO.puts("   Capabilities after: #{map_size(prog_after.capabilities || %{})}")
        end
        
        new_state
      end)
    else
      state
    end
  end
  defp calculate_carrying_capacity(state), do: state
  defp track_lineage_composition(state, _tick), do: state
  defp report_progress(state, tick, start_time) do
    elapsed = System.monotonic_time(:millisecond) - start_time
    tick_rate = tick / (elapsed / 1000)
    
    IO.puts("\n📊 Progress @ Tick #{tick}:")
    IO.puts("   Elapsed: #{Float.round(elapsed / 1000, 2)}s")
    IO.puts("   Rate: #{Float.round(tick_rate, 1)} ticks/sec")
    IO.puts("   Programs: #{map_size(state.research_programs || %{})}")
    
    state
  end

  defp print_final_report(state) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🎯 RUN 15.6 INSTRUMENTATION AUDIT — ECOLOGY VISIBILITY DIAGNOSTIC")
    IO.puts(String.duplicate("=", 80))
    
    # Run 15.6: Direct ETS inspection
    Tiannara.Debug.Audit.inspect_ecology_state()
    
    # Run 15.6: Compare actual graph vs ecology tracking
    Tiannara.Debug.Audit.compare_graph_vs_ecology(state)
    
    # Print final ecology snapshot (for comparison)
    Tiannara.Ecology.print_ecology_report()
    
    # Summary statistics
    IO.puts("\n📈 Summary Statistics:")
    IO.puts("   Total Programs: #{map_size(state.research_programs || %{})}")
    IO.puts("   Active Programs: #{get_in(state, [:metadata, :active_programs_count]) || 0}")
    IO.puts("   Final Tick: #{state.economy[:tick]}")
    
    IO.puts("\n" <> String.duplicate("=", 80))
  end
end

# Execute Run 16
Tiannara.Validation.Run16EcologyCampaign.run()
