defmodule TiannaraOS.CivilizationScheduler do
  @moduledoc """
  Phase 12 Step 3: Civilization Scheduler

  Orchestrates large-scale civilizational simulations (100k-500k ticks).

  Integrates all evolutionary mechanisms:
  - Economic simulation (discovery → asset → royalty → budget)
  - Capability registry (technological progression)
  - Dynamic needs evolution (emergent bottlenecks)
  - Institutional memory (wisdom-guided mutation)
  - World memory (civilization-level learning)
  - Reproduction engine (multi-element inheritance)

  ## Simulation Loop

      For each tick:
        1. Process economic activities (discoveries, royalties)
        2. Register discoveries in capability registry
        3. Evolve world needs (every 2000 ticks)
        4. Update world memory (every 5000 ticks)
        5. Trigger reproduction (every 100 ticks)
        6. Kill exhausted programs
        7. Track metrics (ESR, AFG, diversity)

  ## Usage

      # Run 100k tick simulation
      state = CivilizationScheduler.run_simulation(initial_state, 100_000)
      
      # Analyze results
      metrics = CivilizationScheduler.analyze_results(state)
  """

  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.Discovery
  alias TiannaraOS.CapabilityRegistry
  alias TiannaraOS.DynamicNeedsEvolution
  alias TiannaraOS.WorldMemory
  alias TiannaraOS.CivilizationReproductionEngine

  # Tick intervals for periodic updates
  # Reduced from 2000 (less frequent)
  @needs_evolution_interval 5000
  # Reduced from 5000 (less frequent)
  @world_memory_interval 5000
  # Keep same
  @reproduction_interval 100
  # Increased from 10000 (fewer reports)
  @metrics_reporting_interval 20000

  # FOUR-STAGE DEVELOPMENTAL LIFECYCLE ⭐
  # Maturation thresholds (age in ticks)
  # newborn → juvenile at 1000 ticks
  @stage_newborn_end 1_000
  # juvenile → apprentice at 5000 ticks
  @stage_juvenile_end 5_000
  # apprentice → adult at 8000 ticks
  @stage_apprentice_end 8_000

  # Budget burn rates per stage relative to adult (1.0)
  # newborns consume 10% of adult burn
  @burn_newborn 0.10
  # juveniles consume 25%
  @burn_juvenile 0.25
  # apprentices consume 60%
  @burn_apprentice 0.60

  # Effective budget multipliers for scarcity sorting (higher = appears richer = safer)
  @eff_budget_newborn 4.0
  @eff_budget_juvenile 2.0
  @eff_budget_apprentice 1.25
  @eff_budget_adult 1.0

  # CAPABILITY DECAY (Fix 3.5) ⭐
  # civilizations must continually regenerate capabilities
  @capability_decay_per_tick 0.99995

  # INSTITUTIONAL AGING (Missing Primitive #1) ⭐
  # Age-based mortality thresholds (ticks)
  # Start aging at 50k ticks
  @aging_threshold_1 50_000
  # Accelerated aging at 100k ticks
  @aging_threshold_2 100_000
  # Rapid aging at 150k ticks
  @aging_threshold_3 150_000

  # Age-based death probabilities per tick
  # < 50k ticks: immortal
  @age_mortality_young 0.0
  # 50k-100k: 0.01% per tick
  @age_mortality_middle 0.0001
  # 100k-150k: 0.03% per tick
  @age_mortality_old 0.0003
  # > 150k: 0.08% per tick
  @age_mortality_ancient 0.0008

  # RELATIVE FITNESS SELECTION (Missing Primitive #2) ⭐
  # Bottom 5% face elevated mortality
  @fitness_bottom_percentile 0.05
  # 0.1% death chance per tick for bottom performers
  @fitness_death_probability 0.001

  # DYNAMIC CARRYING CAPACITY (Missing Primitive #3) ⭐
  # Base capacity per world
  @base_carrying_capacity 40
  # sqrt(wealth) * multiplier adds to capacity
  @wealth_capacity_multiplier 0.0001

  # DISCOVERY RELEVANCE DECAY (Missing Primitive #5) ⭐
  # Discoveries lose relevance over time
  @discovery_relevance_decay 0.99995
  # Prune discoveries below this relevance. Raised from 0.1 → 0.3 so
  # discoveries expire ~3× faster, keeping map smaller.
  @relevance_min_threshold 0.3
  # Hard cap on the discoveries map. When exceeded, lowest-relevance entries
  # are pruned first. Prevents the ~370k-entry steady state that made relevance
  # decay O(N) every 100 ticks.
  @max_discoveries_map_size 5_000

  @doc """
  Run full civilization simulation.

  ## Parameters

  - `initial_state`: Starting simulation state
  - `max_ticks`: Number of ticks to simulate
  - `opts`: Optional configuration

  ## Options

  - `:report_interval` - How often to print progress (default: 10000)
  - `:enable_capabilities` - Enable capability registry (default: true)
  - `:enable_needs_evolution` - Enable dynamic needs (default: true)
  - `:enable_world_memory` - Enable world memory (default: true)

  ## Returns

  Final simulation state with all accumulated data.

  ## Examples

      iex> state = CivilizationScheduler.run_simulation(initial_state, 100_000)
      iex> state.economy.tick
      100000
  """
  @spec run_simulation(State.t(), integer(), keyword()) :: State.t()
  def run_simulation(%State{} = initial_state, max_ticks, opts \\ []) do
    report_interval = Keyword.get(opts, :report_interval, @metrics_reporting_interval)
    enable_capabilities = Keyword.get(opts, :enable_capabilities, true)
    enable_needs_evolution = Keyword.get(opts, :enable_needs_evolution, true)
    enable_world_memory = Keyword.get(opts, :enable_world_memory, true)

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("CIVILIZATION SIMULATION - Phase 12 Step 3")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Duration: #{max_ticks} ticks")
    IO.puts("Worlds: #{map_size(initial_state.worlds || %{})}")
    IO.puts("Programs: #{map_size(initial_state.research_programs || %{})}")
    IO.puts("Capabilities: #{if enable_capabilities, do: "enabled", else: "disabled"}")
    IO.puts("Needs Evolution: #{if enable_needs_evolution, do: "enabled", else: "disabled"}")
    IO.puts("World Memory: #{if enable_world_memory, do: "enabled", else: "disabled"}")
    IO.puts(String.duplicate("=", 80) <> "\n")

    start_time = System.monotonic_time(:millisecond)

    final_state =
      Enum.reduce(1..max_ticks, initial_state, fn tick, acc_state ->
        # Run 16: Increment ecology tick counter (every tick)
        Tiannara.Ecology.tick()
        
        t0 = System.monotonic_time(:microsecond)

        # PERFORMANCE: Queued Maturation
        acc_state = update_program_ticks(acc_state, tick)

        # 1. Economic & Scarcity Loop
        acc_state = process_economic_tick(acc_state, tick)
        acc_state = enforce_scarcity(acc_state, tick)
        acc_state = kill_exhausted_programs(acc_state, tick)

        # Process reproduction (mortality and birth)
        t1 = System.monotonic_time(:microsecond)

        # PERFORMANCE: Rebuild global_adoption every 500 ticks (not every 10).
        # This was O(Programs × Capabilities) on every 10-tick cycle — the primary
        # cause of tick rate collapse in Stage 2 (32/sec → ~1/sec).
        # The cached map stays valid for 500 ticks; stale by at most one generation cycle.
        acc_state =
          if rem(tick, 500) == 0 do
            cap_adoption_map =
              Enum.reduce(Map.values(acc_state.research_programs || %{}), %{}, fn p, acc ->
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
                Enum.filter(acc_state.research_programs || %{}, fn {_, p} ->
                  p.status == :active
                end)
                |> Map.new()
              )

            new_meta =
              (acc_state.metadata || %{})
              |> Map.put(:global_adoption, cap_adoption_map)
              |> Map.put(:active_programs_count, active_count)

            %{acc_state | metadata: new_meta}
          else
            acc_state
          end

        acc_state =
          if rem(tick, 10) == 0 do
            CivilizationReproductionEngine.trigger_reproduction(acc_state)
          else
            acc_state
          end

        t2 = System.monotonic_time(:microsecond)

        # 3. Discovery & Capability Loop
        t_cap0 = System.monotonic_time(:microsecond)

        acc_state =
          if enable_capabilities do
            register_new_discoveries(acc_state, tick)
          else
            acc_state
          end

        t_cap1 = System.monotonic_time(:microsecond)

        acc_state =
          if enable_capabilities and rem(tick, 10) == 0 do
            apply_capability_decay(acc_state)
          else
            acc_state
          end

        t_cap2 = System.monotonic_time(:microsecond)

        # PERF FIX: Relevance decay interval raised from 100 → 500 ticks.
        # At 100 ticks it was scanning a 370k-entry map 50 times per 5k-tick
        # window, consuming 85 seconds of wall-time. 500 ticks = 5× fewer calls.
        acc_state =
          if rem(tick, 500) == 0 do
            apply_discovery_relevance_decay(acc_state)
          else
            acc_state
          end

        t_cap3 = System.monotonic_time(:microsecond)

        acc_state =
          if enable_capabilities and rem(tick, 1000) == 0 do
            CapabilityRegistry.promote_capabilities(acc_state)
          else
            acc_state
          end

        t_cap4 = System.monotonic_time(:microsecond)

        t3 = System.monotonic_time(:microsecond)

        # 4. Sparse Telemetry & World Evolution Loop
        acc_state =
          if enable_needs_evolution && rem(tick, @needs_evolution_interval) == 0 do
            evolve_all_world_needs(acc_state, tick)
          else
            acc_state
          end

        acc_state =
          if enable_world_memory && rem(tick, @world_memory_interval) == 0 do
            update_all_world_memories(acc_state, tick)
          else
            acc_state
          end

        acc_state =
          if rem(tick, report_interval) == 0 do
            report_progress(acc_state, tick, start_time, report_interval)
          else
            acc_state
          end

        acc_state =
          if rem(tick, 5_000) == 0 do
            track_lineage_composition(acc_state, tick)
          else
            acc_state
          end

        # Run 16: Ecology report every 5k ticks
        acc_state =
          if rem(tick, 5_000) == 0 do
            Tiannara.Ecology.print_ecology_report()
            Tiannara.Profiling.print_economic_profile()
            acc_state
          else
            acc_state
          end

        # Run 16: Registration profile every 10k ticks
        acc_state =
          if rem(tick, 10_000) == 0 do
            Tiannara.Profiling.print_registration_profile()
            acc_state
          else
            acc_state
          end

        t4 = System.monotonic_time(:microsecond)

        # Record runtime performance metrics
        meta = acc_state.metadata || %{}

        meta =
          meta
          |> Map.update(:time_sched, 0, &(&1 + (t1 - t0)))
          |> Map.update(:time_repro, 0, &(&1 + (t2 - t1)))
          |> Map.update(:time_disc, 0, &(&1 + (t3 - t2)))
          |> Map.update(:time_tele, 0, &(&1 + (t4 - t3)))
          |> Map.update(:time_cap_register, 0, &(&1 + (t_cap1 - t_cap0)))
          |> Map.update(:time_cap_decay, 0, &(&1 + (t_cap2 - t_cap1)))
          |> Map.update(:time_discovery_relevance, 0, &(&1 + (t_cap3 - t_cap2)))
          |> Map.update(:time_cap_promotion, 0, &(&1 + (t_cap4 - t_cap3)))

        updated_economy = Map.put(acc_state.economy, :tick, tick)
        %{acc_state | economy: updated_economy, metadata: meta}
      end)

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

  @doc """
  Analyze simulation results.

  Calculates comprehensive metrics about civilization health and evolution.

  ## Parameters

  - `state`: Final simulation state

  ## Returns

  Map of analysis metrics.

  ## Examples

      iex> metrics = CivilizationScheduler.analyze_results(state)
      iex> metrics.esr > 1.0
      true
  """
  @spec analyze_results(State.t()) :: map()
  def analyze_results(%State{} = state) do
    programs = state.research_programs || %{}
    discoveries = state.discoveries || %{}
    graveyard = state.program_graveyard || %{}

    # Economic metrics
    esr = calculate_esr(state)
    afg = calculate_afg(state)

    # Population metrics
    total_programs = map_size(programs)
    active_programs_list = programs |> Map.values() |> Enum.filter(&(&1.status == :active))
    active_programs = length(active_programs_list)
    dead_programs = map_size(graveyard)

    # Generational metrics
    generations = programs |> Map.values() |> Enum.map(&(&1.generation || 1))
    max_generation = if Enum.empty?(generations), do: 0, else: Enum.max(generations)

    avg_generation =
      if Enum.empty?(generations), do: 0, else: Enum.sum(generations) / length(generations)

    # NEW: Generation distribution
    gen_distribution =
      programs
      |> Map.values()
      |> Enum.group_by(&(&1.generation || 1))
      |> Map.new(fn {gen, progs} -> {"Gen#{gen}", length(progs)} end)
      |> Enum.sort_by(fn {key, _count} ->
        case Integer.parse(String.replace(key, "Gen", "")) do
          {n, _} -> n
          :error -> 0
        end
      end)
      |> Enum.into(%{})

    # Discovery metrics
    total_discoveries = map_size(discoveries)

    # Lineage metrics
    lineage_depths =
      programs
      |> Map.values()
      |> Enum.filter(fn p -> p.parent_program_id != nil end)
      |> Enum.map(fn p -> count_lineage_depth(p, programs) end)

    max_lineage_depth = if Enum.empty?(lineage_depths), do: 0, else: Enum.max(lineage_depths)

    # NEW METRICS
    # Extinction rate
    total_ever = total_programs + dead_programs

    extinction_rate =
      if(total_ever > 0, do: Float.round(dead_programs / total_ever * 100, 1), else: 0.0)

    # Capability velocity (capabilities per 1000 ticks)
    worlds = state.worlds || %{}

    # Calculate Total Capabilities and Technological Depth across all 3 layers
    civ_caps_map = Map.get(state, :capabilities, %{})

    world_caps_map =
      worlds
      |> Map.values()
      |> Enum.reduce(%{}, fn w, acc -> Map.merge(acc, Map.get(w, :capabilities, %{})) end)

    prog_caps_map =
      programs
      |> Map.values()
      |> Enum.reduce(%{}, fn p, acc -> Map.merge(acc, Map.get(p, :capabilities, %{})) end)

    all_caps_map = civ_caps_map |> Map.merge(world_caps_map) |> Map.merge(prog_caps_map)
    unique_all_caps = Map.values(all_caps_map)
    total_capabilities = map_size(all_caps_map)

    # NEW TELEMETRY
    program_capabilities = map_size(prog_caps_map)
    world_capabilities = map_size(world_caps_map)
    civ_capabilities = map_size(civ_caps_map)

    # Validation 6: Capability Monopolization
    active_program_count = max(1, active_programs)

    cap_adoption_map =
      Enum.reduce(active_programs_list, %{}, fn p, acc ->
        Enum.reduce(p.capabilities || %{}, acc, fn {cap_id, node}, inner_acc ->
          if Map.get(node, :depth, 1) > 1 do
            Map.update(inner_acc, cap_id, 1, &(&1 + 1))
          else
            inner_acc
          end
        end)
      end)

    sorted_adoptions = cap_adoption_map |> Map.values() |> Enum.sort(:desc)
    top_adoption = List.first(sorted_adoptions) || 0
    top_capability_share = top_adoption / active_program_count

    # NEW: Capability Locality Index
    cap_world_distribution =
      Enum.reduce(active_programs_list, %{}, fn p, acc ->
        Enum.reduce(Map.keys(p.capabilities || %{}), acc, fn cap_id, inner_acc ->
          Map.update(inner_acc, cap_id, %{p.world_id => 1}, fn w_map ->
            Map.update(w_map, p.world_id, 1, &(&1 + 1))
          end)
        end)
      end)

    top_cap_ids =
      cap_adoption_map
      |> Enum.sort_by(fn {_, count} -> -count end)
      |> Enum.take(20)
      |> Enum.map(fn {id, _} -> id end)

    top_locality_scores =
      top_cap_ids
      |> Enum.map(fn cap_id ->
        w_map = Map.get(cap_world_distribution, cap_id, %{})
        total_adoptions = w_map |> Map.values() |> Enum.sum()

        if total_adoptions > 0 do
          max_world_adoptions = w_map |> Map.values() |> Enum.max()
          max_world_adoptions / total_adoptions
        else
          0.0
        end
      end)

    capability_locality_index =
      if length(top_locality_scores) > 0 do
        Float.round(Enum.sum(top_locality_scores) / length(top_locality_scores), 3)
      else
        0.0
      end

    # Gini
    n_caps = length(sorted_adoptions)

    capability_gini =
      if n_caps > 1 do
        ascending_adoptions = Enum.reverse(sorted_adoptions)
        sum_y = Enum.sum(ascending_adoptions)

        if sum_y > 0 do
          sum_iy =
            ascending_adoptions
            |> Enum.with_index(1)
            |> Enum.map(fn {y, i} -> i * y end)
            |> Enum.sum()

          2.0 * sum_iy / (n_caps * sum_y) - (n_caps + 1.0) / n_caps
        else
          0.0
        end
      else
        0.0
      end

    # Validation 7: Graph Health
    roots = Enum.filter(unique_all_caps, fn n -> length(n.parent_nodes || []) == 0 end)

    all_parents_set = MapSet.new(Enum.flat_map(unique_all_caps, &(&1.parent_nodes || [])))
    leaves = Enum.filter(unique_all_caps, fn n -> not MapSet.member?(all_parents_set, n.id) end)

    avg_parents =
      if length(unique_all_caps) > 0,
        do:
          Enum.sum(Enum.map(unique_all_caps, &length(&1.parent_nodes || []))) /
            length(unique_all_caps),
        else: 0.0

    parent_counts =
      unique_all_caps
      |> Enum.flat_map(&(&1.parent_nodes || []))
      |> Enum.frequencies()

    avg_children =
      if map_size(parent_counts) > 0,
        do: Enum.sum(Map.values(parent_counts)) / length(unique_all_caps),
        else: 0.0

    graph_roots_ratio =
      if length(unique_all_caps) > 0, do: length(roots) / length(unique_all_caps), else: 0.0

    # Validation 8: Promotion Survival
    # Tracked via metadata.promotions vs active world capabilities
    promoted_historic = Map.get(state.metadata || %{}, :promoted_capabilities, %{})

    promoted_alive =
      Enum.count(promoted_historic, fn {cap_id, _} ->
        Map.has_key?(world_caps_map, cap_id)
      end)

    promotion_survival =
      if map_size(promoted_historic) > 0,
        do: promoted_alive / map_size(promoted_historic),
        else: 1.0

    # Validation 9: Innovation Half-Life
    final_tick = state.economy[:tick] || 0

    innovation_half_life =
      unique_all_caps
      |> Enum.map(fn n -> final_tick - (n.last_used_tick || final_tick) end)
      |> Enum.sum()
      |> Kernel./(max(1, length(unique_all_caps)))

    # Validation 10: Capability Ecology (Mutation Types)
    ecology =
      Enum.reduce(
        unique_all_caps,
        %{improvement: 0, specialization: 0, synthesis: 0, paradigm_shift: 0},
        fn n, acc ->
          id_str = to_string(n.id)

          cond do
            String.starts_with?(id_str, "syn_") -> Map.update!(acc, :synthesis, &(&1 + 1))
            String.contains?(id_str, "_paradigm_") -> Map.update!(acc, :paradigm_shift, &(&1 + 1))
            String.contains?(id_str, "_spec_") -> Map.update!(acc, :specialization, &(&1 + 1))
            true -> Map.update!(acc, :improvement, &(&1 + 1))
          end
        end
      )

    # Evolution Stall Tracker
    births_k =
      Float.round(
        Map.get(state.metadata || %{}, :capability_births, 0) / max(1, final_tick / 1000),
        2
      )

    deaths_k =
      Float.round(
        Map.get(state.metadata || %{}, :capability_extinctions, 0) / max(1, final_tick / 1000),
        2
      )

    is_stalled = births_k < deaths_k

    stall_count =
      if is_stalled, do: Map.get(state.metadata || %{}, :evolution_stall_count, 0) + 1, else: 0

    meta = state.metadata || %{}
    capability_births = Map.get(meta, :capability_births, 0)
    capability_extinctions = Map.get(meta, :capability_extinctions, 0)
    capability_promotions = Map.get(meta, :capability_promotions, 0)

    final_tick = state.economy[:tick] || 0
    k_ticks = if final_tick > 0, do: final_tick / 1000, else: 1.0
    births_per_k = Float.round(capability_births / k_ticks, 2)
    extinctions_per_k = Float.round(capability_extinctions / k_ticks, 2)
    promotions_per_k = Float.round(capability_promotions / k_ticks, 2)

    avg_depth =
      if Enum.empty?(unique_all_caps),
        do: 0.0,
        else:
          Float.round(
            Enum.sum(Enum.map(unique_all_caps, &(&1.depth || 1))) / length(unique_all_caps),
            2
          )

    rediscovery_ratio =
      if total_capabilities > 0,
        do: Float.round(capability_births / total_capabilities, 2),
        else: 0.0

    technological_depth =
      if Enum.empty?(unique_all_caps) do
        0
      else
        unique_all_caps |> Enum.map(&(&1.depth || 1)) |> Enum.max()
      end

    # Technological Lineage Depth — the longest recursive capability ancestry chain
    # e.g., Energy -> Battery -> Grid Battery -> Smart Grid -> Planetary Energy Mesh = depth 5
    max_capability_lineage_depth =
      if Enum.empty?(unique_all_caps) do
        0
      else
        cap_lookup = Map.new(unique_all_caps, fn n -> {n.id, n} end)

        # DFS memoized: find longest parent chain starting from each node
        {_, depth_map} =
          Enum.reduce(unique_all_caps, {cap_lookup, %{}}, fn node, {lookup, memo} ->
            {_, updated_memo} = compute_lineage_depth(node, lookup, memo)
            {lookup, updated_memo}
          end)

        if map_size(depth_map) == 0, do: 0, else: Enum.max(Map.values(depth_map))
      end

    capability_velocity =
      if(final_tick > 0, do: Float.round(total_capabilities / (final_tick / 1000), 2), else: 0.0)

    # Speciation count (unique species based on strategy genome clustering)
    species_count = count_species(programs)

    # World divergence (average cosine distance between world need vectors)
    world_divergence = calculate_world_divergence(worlds)

    # NEW: Population by world with max generation
    population_by_world =
      worlds
      |> Map.new(fn {world_id, world} ->
        world_programs =
          programs
          |> Map.values()
          |> Enum.filter(fn p -> p.world_id == world_id end)

        pop_count = length(world_programs)

        max_gen =
          if Enum.empty?(world_programs),
            do: 0,
            else: Enum.max(Enum.map(world_programs, &(&1.generation || 1)))

        {world_id, %{population: pop_count, max_generation: max_gen}}
      end)

    %{
      # Economic sustainability
      esr: Float.round(esr, 3),
      afg: Float.round(afg, 3),

      # Population
      total_programs_ever: total_programs + dead_programs,
      active_programs: active_programs,
      dead_programs: dead_programs,
      survival_rate:
        if(total_programs > 0,
          do: Float.round(active_programs / total_programs * 100, 1),
          else: 0.0
        ),

      # Generational depth
      max_generation: max_generation,
      avg_generation: Float.round(avg_generation, 2),
      gen_distribution: gen_distribution,

      # Discovery output
      total_discoveries: total_discoveries,
      discoveries_per_active_program:
        if(active_programs > 0,
          do: Float.round(total_discoveries / active_programs, 2),
          else: 0.0
        ),

      # Lineage complexity
      max_lineage_depth: max_lineage_depth,

      # NEW: Evolutionary metrics
      extinction_rate: extinction_rate,
      capability_velocity: capability_velocity,
      species_count: species_count,
      world_divergence: Float.round(world_divergence, 3),
      total_capabilities: total_capabilities,
      technological_depth: technological_depth,
      avg_technological_depth: avg_depth,
      program_capabilities: program_capabilities,
      world_capabilities: world_capabilities,
      civ_capabilities: civ_capabilities,
      capability_births_per_k: births_k,
      capability_extinctions_per_k: deaths_k,
      promotion_rate_per_k: promotions_per_k,
      rediscovery_direct: Map.get(state.metadata || %{}, :rediscovery_direct, 0),
      rediscovery_convergent: Map.get(state.metadata || %{}, :rediscovery_convergent, 0),
      rediscovery_novel: Map.get(state.metadata || %{}, :rediscovery_novel, 0),
      top_capability_share: top_capability_share,
      capability_locality_index: capability_locality_index,
      capability_gini: capability_gini,
      promotion_survival: promotion_survival,
      graph_roots: length(roots),
      graph_roots_ratio: graph_roots_ratio,
      graph_leaves: length(leaves),
      graph_avg_parents: avg_parents,
      graph_avg_children: avg_children,
      innovation_half_life: innovation_half_life,
      ecology: ecology,
      evolution_stall_count: stall_count,
      max_capability_lineage_depth: max_capability_lineage_depth,
      capability_velocity_current: births_k,
      population_by_world: population_by_world,

      # Simulation metadata
      final_tick: state.economy[:tick] || 0,
      world_count: map_size(state.worlds || %{})
    }
  end

  @doc """
  Print civilization summary.

  Human-readable overview of simulation outcomes.

  ## Parameters

  - `state`: Final simulation state
  """
  @spec print_civilization_summary(State.t()) :: :ok
  def print_civilization_summary(%State{} = state) do
    metrics = analyze_results(state)

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("CIVILIZATION SUMMARY")
    IO.puts(String.duplicate("=", 80))

    IO.puts("\n📊 Economic Health:")
    IO.puts("   ESR (Economic Sustainability Ratio): #{metrics.esr}")
    IO.puts("   AFG (Adaptive Fitness Gradient): #{metrics.afg}")

    IO.puts("\n👥 Population:")
    IO.puts("   Total programs ever: #{metrics.total_programs_ever}")
    IO.puts("   Active: #{metrics.active_programs}")
    IO.puts("   Dead: #{metrics.dead_programs}")
    IO.puts("   Survival rate: #{metrics.survival_rate}%")

    IO.puts("\n🧬 Evolution:")
    IO.puts("   Max generation: #{metrics.max_generation}")
    IO.puts("   Avg generation: #{metrics.avg_generation}")
    IO.puts("   Max lineage depth: #{metrics.max_lineage_depth}")

    # NEW: Display generation distribution
    if Map.has_key?(metrics, :gen_distribution) && map_size(metrics.gen_distribution) > 0 do
      IO.puts("\n📈 Generation Distribution:")

      metrics.gen_distribution
      |> Enum.sort_by(fn {key, _count} ->
        case Integer.parse(String.replace(key, "Gen", "")) do
          {n, _} -> n
          :error -> 0
        end
      end)
      |> Enum.each(fn {gen_label, count} ->
        bar = String.duplicate("█", div(count, 10))

        IO.puts(
          "   #{String.pad_leading(gen_label, 6)}: #{String.pad_leading(Integer.to_string(count), 5)} #{bar}"
        )
      end)
    end

    IO.puts("\n💡 Knowledge Production:")
    IO.puts("   Total discoveries: #{metrics.total_discoveries}")
    IO.puts("   Discoveries per active program: #{metrics.discoveries_per_active_program}")

    IO.puts("\n🧠 TECHNOLOGICAL EVOLUTION:")
    IO.puts("   Program Capabilities: #{Map.get(metrics, :program_capabilities, 0)}")
    IO.puts("   World Capabilities: #{Map.get(metrics, :world_capabilities, 0)}")
    IO.puts("   Civilization Capabilities: #{Map.get(metrics, :civ_capabilities, 0)}")
    IO.puts("")
    IO.puts("   Capability Births/k: #{Map.get(metrics, :capability_births_per_k, 0.0)}")

    IO.puts(
      "   Capability Extinctions/k: #{Map.get(metrics, :capability_extinctions_per_k, 0.0)}"
    )

    IO.puts("   Promotion Rate/k: #{Map.get(metrics, :promotion_rate_per_k, 0.0)}")
    IO.puts("")
    IO.puts("   Technological Depth:")
    IO.puts("     Avg: #{Map.get(metrics, :avg_technological_depth, 0.0)}")
    IO.puts("     Max: #{metrics.technological_depth}")

    IO.puts(
      "     Max Capability Lineage Chain: #{Map.get(metrics, :max_capability_lineage_depth, 0)}"
    )

    IO.puts("")
    IO.puts("   Capability Velocity: #{metrics.capability_velocity}")
    IO.puts("   Rediscovery Ratio: #{Map.get(metrics, :rediscovery_ratio, 0.0)}x")

    IO.puts("\n🧪 Evolutionary Metrics:")
    IO.puts("   Extinction rate: #{metrics.extinction_rate}%")
    IO.puts("   Species count: #{metrics.species_count}")
    IO.puts("   World divergence: #{metrics.world_divergence}")
    IO.puts("   Capability Locality Index: #{Map.get(metrics, :capability_locality_index, 0.0)}")

    IO.puts("\n🌍 Worlds: #{metrics.world_count}")

    # NEW: Display world divergence details (top 10 worlds by population)
    if Map.has_key?(metrics, :population_by_world) && map_size(metrics.population_by_world) > 0 do
      IO.puts("\n🗺️  World Divergence (Top 10 by Population):")

      metrics.population_by_world
      |> Enum.sort_by(fn {_world_id, data} -> -data.population end)
      |> Enum.take(10)
      |> Enum.each(fn {world_id, %{population: pop, max_generation: max_gen}} ->
        IO.puts("   #{world_id}: Pop=#{pop}, Max Gen=#{max_gen}")
      end)
    end

    IO.puts("   Final tick: #{metrics.final_tick}")

    # Check for open-ended growth indicators
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("OPEN-ENDED GROWTH INDICATORS:")

    if metrics.esr > 1.0 do
      IO.puts("   ✅ Economically sustainable (ESR > 1.0)")
    else
      IO.puts("   ❌ Economically unsustainable (ESR < 1.0)")
    end

    if metrics.afg > 0 do
      IO.puts("   ✅ Adaptively improving (AFG > 0)")
    else
      IO.puts("   ⚠️  Stagnating or declining (AFG <= 0)")
    end

    if metrics.max_generation >= 5 do
      IO.puts("   ✅ Multi-generational lineages (gen #{metrics.max_generation})")
    else
      IO.puts("   ⚠️  Shallow generations (gen #{metrics.max_generation})")
    end

    if metrics.max_lineage_depth >= 3 do
      IO.puts("   ✅ Deep program lineages (depth #{metrics.max_lineage_depth})")
    else
      IO.puts("   ⚠️  Shallow program lineages (depth #{metrics.max_lineage_depth})")
    end

    cap_lineage = Map.get(metrics, :max_capability_lineage_depth, 0)

    if cap_lineage >= 4 do
      IO.puts(
        "   ✅ Deep technological lineage chain (depth #{cap_lineage}) — recursive tech evolution confirmed"
      )
    else
      IO.puts(
        "   ⚠️  Shallow technological lineage chain (depth #{cap_lineage}) — lateral proliferation only"
      )
    end

    if metrics.total_discoveries > 100 do
      IO.puts("   ✅ High knowledge production (#{metrics.total_discoveries} discoveries)")
    else
      IO.puts("   ⚠️  Low knowledge production (#{metrics.total_discoveries} discoveries)")
    end

    IO.puts(String.duplicate("=", 80) <> "\n")
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  @spec update_program_ticks(State.t(), integer()) :: State.t()
  defp update_program_ticks(state, tick) do
    maturing_ids = Map.get(state.maturation_queue || %{}, tick, [])

    if length(maturing_ids) == 0 do
      # Still need to clean up old ticks if any missed, but typically just remove current
      queue = Map.delete(state.maturation_queue || %{}, tick)
      %{state | maturation_queue: queue}
    else
      programs = state.research_programs || %{}
      pop_cache = state.world_population_cache || %{}
      metadata = state.metadata || %{}

      {updated_programs, updated_cache, updated_meta} =
        Enum.reduce(maturing_ids, {programs, pop_cache, metadata}, fn prog_id,
                                                                      {acc_progs, acc_cache,
                                                                       acc_meta} ->
          case Map.get(acc_progs, prog_id) do
            nil ->
              {acc_progs, acc_cache, acc_meta}

            prog ->
              if prog.status != :active do
                {acc_progs, acc_cache, acc_meta}
              else
                # Advance life stage
                current_stage = prog.life_stage || :newborn

                new_stage =
                  case current_stage do
                    :newborn -> :juvenile
                    :juvenile -> :apprentice
                    :apprentice -> :adult
                    _ -> :adult
                  end

                if new_stage != current_stage do
                  new_prog = %{prog | life_stage: new_stage}
                  new_progs = Map.put(acc_progs, prog_id, new_prog)

                  # Update Cache
                  new_cache =
                    Map.update(acc_cache, prog.world_id, %{}, fn w ->
                      w
                      |> Map.update(current_stage, 0, &max(0, &1 - 1))
                      |> Map.update(new_stage, 0, &(&1 + 1))
                    end)

                  # Update Metadata (use string keys, not atoms — atoms are never GC'd)
                  new_meta =
                    acc_meta
                    |> Map.update("#{current_stage}_count", 0, &max(0, &1 - 1))
                    |> Map.update("#{new_stage}_count", 0, &(&1 + 1))

                  {new_progs, new_cache, new_meta}
                else
                  {acc_progs, acc_cache, acc_meta}
                end
              end
          end
        end)

      updated_queue = Map.delete(state.maturation_queue || %{}, tick)

      %{
        state
        | research_programs: updated_programs,
          maturation_queue: updated_queue,
          world_population_cache: updated_cache,
          metadata: updated_meta
      }
    end
  end

  @spec process_economic_tick(State.t(), integer()) :: State.t()
  defp process_economic_tick(state, tick) do
    {updated_state, _} =
      Enum.reduce(state.world_program_index || %{}, {state, 0}, fn {_world_id, pids}, acc ->
        Enum.reduce(pids, acc, fn prog_id, {acc_state, disc_count} ->
          program = Map.get(acc_state.research_programs, prog_id)

          if program && program.status == :active do
            exploration_rate = Map.get(program.strategy_genome, :exploration_rate, 0.5)
            budget_ratio = min(1.0, (program.budget.credits || 1000) / 1000.0)

            discovery_prob = 0.01 * exploration_rate * budget_ratio

            if :rand.uniform() < discovery_prob do
              discovery = generate_discovery(prog_id, program.world_id, tick, acc_state)

              if discovery != nil do
                updated_discoveries =
                  Map.put(acc_state.discoveries || %{}, discovery.id, discovery)

                tick_discoveries = [discovery | acc_state.tick_discoveries || []]

                acc_state2 = %{
                  acc_state
                  | discoveries: updated_discoveries,
                    tick_discoveries: tick_discoveries
                }

                domain_vector = Map.get(discovery.metadata || %{}, :domain_vector, %{})

                primary_domain =
                  if map_size(domain_vector) > 0 do
                    {domain, _weight} = Enum.max_by(domain_vector, fn {_d, w} -> w end)
                    domain
                  else
                    :general
                  end

                acc_state3 =
                  WorldMemory.record_discovery_success(
                    acc_state2,
                    program.world_id,
                    primary_domain
                  )

                {acc_state3, disc_count + 1}
              else
                {acc_state, disc_count}
              end
            else
              {acc_state, disc_count}
            end
          else
            {acc_state, disc_count}
          end
        end)
      end)

    updated_state
  end

  @spec enforce_scarcity(State.t(), integer()) :: State.t()
  defp enforce_scarcity(state, tick) do
    programs = state.research_programs || %{}
    worlds = state.worlds || %{}
    index = state.world_program_index || %{}
    graveyard = state.program_graveyard || %{}

    {updated_worlds, updated_programs, new_deaths} =
      Enum.reduce(worlds, {worlds, programs, []}, fn {world_id, world},
                                                     {acc_worlds, acc_programs, acc_deaths} ->
        prog_ids = Map.get(index, world_id, MapSet.new()) |> MapSet.to_list()
        active_count = length(prog_ids)
        carrying_capacity = Map.get(world, :carrying_capacity, 40)

        maintenance_rate = Map.get(world, :capability_maintenance_rate, 0.0001)
        capability_count = map_size(Map.get(world, :capabilities, %{}))
        maintenance_cost = capability_count * maintenance_rate * world.wealth

        updated_world = %{world | wealth: max(0.0, world.wealth - maintenance_cost)}
        wealth_based_pool = updated_world.wealth * 5
        funding_pool = max(1_000.0, min(updated_world.funding_pool, wealth_based_pool))
        updated_world = %{updated_world | funding_pool: funding_pool}

        funding_per_program = if active_count > 0, do: funding_pool / active_count, else: 0.0

        funded_programs =
          Enum.reduce(prog_ids, acc_programs, fn prog_id, acc_progs ->
            prog = Map.get(acc_progs, prog_id)
            current_credits = Map.get(prog.budget, :credits, 1000)

            burn_rate =
              case prog.life_stage do
                :newborn -> @burn_newborn
                :juvenile -> @burn_juvenile
                :apprentice -> @burn_apprentice
                _adult -> 1.0
              end

            prog_capability_count = map_size(Map.get(prog, :capabilities, %{}))
            capability_income = prog_capability_count * 5.0

            decayed_credits = current_credits * :math.pow(0.9998, burn_rate)
            new_credits = min(decayed_credits + funding_per_program + capability_income, 5000.0)

            updated_budget = Map.put(prog.budget, :credits, Float.round(new_credits, 2))
            Map.put(acc_progs, prog_id, %{prog | budget: updated_budget})
          end)

        if active_count > carrying_capacity do
          eligible_for_starvation =
            Enum.filter(prog_ids, fn pid ->
              Map.get(funded_programs, pid).life_stage == :adult
            end)

          sorted_programs =
            eligible_for_starvation
            |> Enum.sort_by(
              fn pid ->
                prog = Map.get(funded_programs, pid)
                raw = Map.get(prog.budget, :credits, 0)

                eff_mult =
                  case prog.life_stage do
                    :newborn -> @eff_budget_newborn
                    :juvenile -> @eff_budget_juvenile
                    :apprentice -> @eff_budget_apprentice
                    _adult -> @eff_budget_adult
                  end

                raw * eff_mult
              end,
              :asc
            )

          cull_count = active_count - carrying_capacity
          to_kill = Enum.take(sorted_programs, cull_count)

          death_records =
            Enum.map(to_kill, fn prog_id ->
              prog = Map.get(funded_programs, prog_id)

              primary_domain =
                case Map.get(prog.strategy_genome, :primary_domain) do
                  nil -> :unknown
                  domain -> domain
                end

              death_record = %{
                program_id: prog_id,
                world_id: world_id,
                cause_of_death: :overpopulation,
                strategy_genome: prog.strategy_genome,
                assets_at_death: prog.discoveries || [],
                lifespan_ticks: tick - (prog.metadata[:created_at_tick] || 0),
                generation: prog.generation || 1,
                primary_domain: primary_domain
              }

              {prog_id, death_record}
            end)

          killed_programs =
            Enum.reduce(to_kill, funded_programs, fn prog_id, acc_progs ->
              prog = Map.get(acc_progs, prog_id)
              Map.put(acc_progs, prog_id, %{prog | status: :dead})
            end)

          {Map.put(acc_worlds, world_id, updated_world), killed_programs,
           acc_deaths ++ death_records}
        else
          {Map.put(acc_worlds, world_id, updated_world), funded_programs, acc_deaths}
        end
      end)

    updated_graveyard =
      Enum.reduce(new_deaths, graveyard, fn {prog_id, record}, acc ->
        Map.put(acc, prog_id, record)
      end)

    # We must also clean up the world_program_index and caches! But we don't do it here! 
    # Wait! If they are marked :dead, they still remain in world_program_index?
    # Yes, the tick cleanup loop `kill_exhausted_programs` or `reproduction_engine` might do it?
    # No, we must let `kill_exhausted_programs` handle graveyard removal from `index`.

    %{
      state
      | worlds: updated_worlds,
        research_programs: updated_programs,
        program_graveyard: updated_graveyard
    }
  end

  @spec register_new_discoveries(State.t(), integer()) :: State.t()
  defp register_new_discoveries(state, _tick) do
    # Optimization: Only process discoveries generated THIS TICK instead of all historical discoveries.
    # The 'tick_discoveries' list is populated in process_economic_tick.
    new_discoveries = state.tick_discoveries || []

    acc =
      Enum.reduce(new_discoveries, state, fn discovery, acc_state ->
        CapabilityRegistry.register_discovery(acc_state, discovery)
      end)

    # Clear the buffer for the next tick
    %{acc | tick_discoveries: []}
  end

  @spec evolve_all_world_needs(State.t(), integer()) :: State.t()
  defp evolve_all_world_needs(state, tick) do
    worlds = state.worlds || %{}
    discoveries = state.discoveries || %{} |> Map.values()

    updated_worlds =
      Enum.reduce(worlds, worlds, fn {world_id, world}, acc ->
        evolved_needs =
          DynamicNeedsEvolution.evolve_needs(
            world.needs_vector,
            discoveries,
            tick
          )

        emergent_needs =
          DynamicNeedsEvolution.generate_emergent_needs(
            Map.get(world, :original_needs, world.needs_vector),
            evolved_needs,
            discoveries
          )

        final_needs =
          Map.merge(evolved_needs, emergent_needs, fn _k, v1, v2 ->
            max(v1, v2)
          end)

        updated_world = %{world | needs_vector: final_needs}
        Map.put(acc, world_id, updated_world)
      end)

    %{state | worlds: updated_worlds}
  end

  @spec update_all_world_memories(State.t(), integer()) :: State.t()
  defp update_all_world_memories(state, _tick) do
    worlds = state.worlds || %{}

    Enum.reduce(worlds, state, fn {world_id, _world}, acc_state ->
      WorldMemory.update_world_memory(acc_state, world_id)
    end)
  end

  @spec kill_exhausted_programs(State.t(), integer()) :: State.t()
  defp kill_exhausted_programs(state, tick) do
    programs = state.research_programs || %{}
    graveyard = state.program_graveyard || %{}
    worlds = state.worlds || %{}
    index = state.world_program_index || %{}

    # MISSING PRIMITIVE #3: Dynamic carrying capacity based on world wealth
    updated_worlds =
      Enum.reduce(worlds, worlds, fn {world_id, world}, acc_worlds ->
        base_capacity = @base_carrying_capacity
        wealth_bonus = trunc(:math.sqrt(world.wealth) * @wealth_capacity_multiplier)
        dynamic_capacity = base_capacity + wealth_bonus

        updated_world = %{world | carrying_capacity: dynamic_capacity}
        Map.put(acc_worlds, world_id, updated_world)
      end)

    # Pre-calculate fitness cutoff every 100 ticks to avoid O(N^2)
    fitness_cutoff =
      if rem(tick, 100) == 0 do
        active_adults =
          Enum.reduce(index, [], fn {_wid, pids}, acc ->
            adult_pids =
              Enum.filter(pids, fn pid ->
                prog = Map.get(programs, pid)
                prog && prog.status == :active && prog.life_stage == :adult
              end)

            acc ++ adult_pids
          end)

        if length(active_adults) >= 20 do
          sorted =
            active_adults
            |> Enum.sort_by(
              fn pid -> Map.get(Map.get(programs, pid).budget, :credits, 0) end,
              :asc
            )

          cutoff_index = trunc(length(sorted) * @fitness_bottom_percentile)
          cutoff_pid = Enum.at(sorted, min(cutoff_index, length(sorted) - 1))
          Map.get(Map.get(programs, cutoff_pid).budget, :credits, 0)
        else
          # Not enough data
          nil
        end
      else
        nil
      end

    # MISSING PRIMITIVE #1 & #2: Apply aging and fitness-based mortality
    # We only iterate over ACTIVE programs using the index, avoiding full map scans
    {updated_programs, new_deaths, updated_index} =
      Enum.reduce(index, {programs, [], index}, fn {world_id, pids},
                                                   {acc_progs, acc_deaths, acc_index} ->
        {world_progs, world_deaths, remaining_pids} =
          Enum.reduce(pids, {acc_progs, acc_deaths, []}, fn prog_id, {p_acc, d_acc, keep_pids} ->
            program = Map.get(p_acc, prog_id)

            if !program || program.status != :active do
              # Clean up dead programs from index
              {p_acc, d_acc, keep_pids}
            else
              age = tick - (program.born_at_tick || 0)
              is_adult = program.life_stage == :adult
              credits = program.budget.credits || 0

              death_cause =
                cond do
                  credits <= 0 && is_adult ->
                    :resource_exhaustion

                  is_adult && age > @aging_threshold_1 && check_age_mortality(age) ->
                    :institutional_senescence

                  fitness_cutoff && is_adult && credits <= fitness_cutoff &&
                      :rand.uniform() < @fitness_death_probability ->
                    :competitive_displacement

                  true ->
                    nil
                end

              if death_cause do
                death_record = %{
                  program_id: prog_id,
                  world_id: program.world_id,
                  cause_of_death: death_cause,
                  strategy_genome: program.strategy_genome,
                  assets_at_death: program.discoveries || [],
                  lifespan_ticks: age,
                  generation: program.generation || 1,
                  primary_domain:
                    case Map.get(program.strategy_genome, :primary_domain) do
                      nil -> :unknown
                      domain -> domain
                    end,
                  life_stage: program.life_stage
                }

                updated_prog = %{program | status: :dead}
                {Map.put(p_acc, prog_id, updated_prog), [death_record | d_acc], keep_pids}
              else
                {p_acc, d_acc, [prog_id | keep_pids]}
              end
            end
          end)

        {world_progs, world_deaths, Map.put(acc_index, world_id, MapSet.new(remaining_pids))}
      end)

    # Add new deaths to graveyard
    final_graveyard =
      Enum.reduce(new_deaths, graveyard, fn record, acc ->
        Map.put(acc, record.program_id, record)
      end)

    %{
      state
      | worlds: updated_worlds,
        research_programs: updated_programs,
        program_graveyard: final_graveyard,
        world_program_index: updated_index
    }
  end

  # Helper: Check age-based mortality probability
  @spec check_age_mortality(integer()) :: boolean()
  defp check_age_mortality(age) do
    mortality_rate =
      cond do
        age < @aging_threshold_1 -> @age_mortality_young
        age < @aging_threshold_2 -> @age_mortality_middle
        age < @aging_threshold_3 -> @age_mortality_old
        true -> @age_mortality_ancient
      end

    :rand.uniform() < mortality_rate
  end

  @spec report_progress(State.t(), integer(), integer(), integer()) :: State.t()
  defp report_progress(state, tick, start_time, report_interval) do
    metadata = state.metadata || %{}

    active_count = metadata[:active_count] || 0
    dead_count = metadata[:dead_count] || 0
    total_born = metadata[:total_births] || 0

    newborns = metadata[:newborn_count] || 0
    juveniles = metadata[:juvenile_count] || 0
    apprentices = metadata[:apprentice_count] || 0
    adults = metadata[:adult_count] || 0

    last_total_born = metadata[:last_total_born] || 0
    last_dead_count = metadata[:last_dead_count] || 0

    interval_births = total_born - last_total_born
    interval_deaths = dead_count - last_dead_count
    interval_growth = interval_births - interval_deaths

    discoveries = state.discoveries || %{}

    worlds = state.worlds || %{}

    caps =
      worlds |> Map.values() |> Enum.map(fn w -> map_size(Map.get(w, :capabilities, %{})) end)

    civ_cap_count = Enum.sum(caps)

    IO.puts(
      "[Tick #{tick}] Active: #{active_count} (NB:#{newborns} Juv:#{juveniles} App:#{apprentices} Adlt:#{adults}), Dead: #{dead_count}, Disc: #{map_size(discoveries)}, Caps: #{civ_cap_count}"
    )

    IO.puts("  Interval Stats (Last #{report_interval} ticks):")
    IO.puts("    Births: #{interval_births}")
    IO.puts("    Deaths: #{interval_deaths}")

    IO.puts(
      "    Net Growth: #{if interval_growth > 0, do: "+#{interval_growth}", else: "#{interval_growth}"}"
    )

    # Calculate Replacement Ratio
    replacement_ratio =
      if interval_births > 0 do
        Float.round(interval_deaths / max(1, interval_births), 2)
      else
        0.0
      end

    IO.puts("    Replacement Ratio: #{replacement_ratio}")

    # Calculate Ticks per Second
    elapsed_us = System.monotonic_time(:microsecond) - start_time
    elapsed_sec = elapsed_us / 1_000_000.0
    ticks_per_sec = if elapsed_sec > 0, do: trunc(tick / elapsed_sec), else: 0

    # Average task timings per tick (microsecs)
    t_sched = trunc((metadata[:time_sched] || 0) / tick)
    t_repro = trunc((metadata[:time_repro] || 0) / tick)
    t_disc = trunc((metadata[:time_disc] || 0) / tick)
    t_tele = trunc((metadata[:time_tele] || 0) / tick)

    IO.puts("\\n  ⚡ Performance")
    IO.puts("     Ticks/sec: #{ticks_per_sec}")

    IO.puts(
      "     Tick Time (Avg us): Sched: #{t_sched} | Repro: #{t_repro} | Disc: #{t_disc} | Tele: #{t_tele}"
    )

    updated_metadata =
      metadata
      |> Map.put(:last_total_born, total_born)
      |> Map.put(:last_dead_count, dead_count)

    %{state | metadata: updated_metadata}
  end

  @doc false
  @spec track_lineage_composition(State.t(), integer()) :: State.t()
  defp track_lineage_composition(state, tick) do
    programs = state.research_programs || %{}
    graveyard = state.program_graveyard || %{}
    worlds = state.worlds || %{}
    metadata = state.metadata || %{}

    # 1. Lifecycle Transitions (Interval)
    n_to_j = count_transitions(programs, graveyard, tick, 1000)
    j_to_a = count_transitions(programs, graveyard, tick, 5000)
    a_to_adult = count_transitions(programs, graveyard, tick, 8000)

    last_n_to_j = metadata[:last_n_to_j] || 0
    last_j_to_a = metadata[:last_j_to_a] || 0
    last_a_to_adult = metadata[:last_a_to_adult] || 0

    int_n_to_j = n_to_j - last_n_to_j
    int_j_to_a = j_to_a - last_j_to_a
    int_a_to_adult = a_to_adult - last_a_to_adult

    IO.puts("\n  📈 Lifecycle Transitions (Last 5k ticks):")
    IO.puts("     N->J: #{int_n_to_j}")
    IO.puts("     J->A: #{int_j_to_a}")
    IO.puts("     A->Adult: #{int_a_to_adult}")

    # 2. Generation stats
    active_programs = programs |> Map.values() |> Enum.filter(&(&1.status == :active))

    gen_counts =
      active_programs
      |> Enum.group_by(&(&1.generation || 1))
      |> Enum.map(fn {g, p} -> {g, length(p)} end)

    total_pop = Enum.sum(Enum.map(gen_counts, fn {_, c} -> c end))

    gen_map = Enum.into(gen_counts, %{})
    gen1_count = Map.get(gen_map, 1, 0)
    gen2_count = Map.get(gen_map, 2, 0)

    gen3_plus_count =
      Enum.reduce(gen_counts, 0, fn {g, c}, acc -> if g >= 3, do: acc + c, else: acc end)

    founder_frac = if total_pop > 0, do: Float.round(gen1_count / total_pop * 100, 1), else: 0.0
    gen2_frac = if total_pop > 0, do: Float.round(gen2_count / total_pop * 100, 1), else: 0.0
    gen3_frac = if total_pop > 0, do: Float.round(gen3_plus_count / total_pop * 100, 1), else: 0.0

    total_gens = Enum.reduce(gen_counts, 0, fn {g, c}, acc -> acc + g * c end)
    avg_gen = if total_pop > 0, do: Float.round(total_gens / total_pop, 2), else: 1.0
    max_gen = if map_size(gen_map) > 0, do: Enum.max(Map.keys(gen_map)), else: 0

    IO.puts("\n  🧬 Generation Composition:")
    IO.puts("     Founder Fraction (Gen 1): #{founder_frac}%")
    IO.puts("     Gen 2 Fraction: #{gen2_frac}%")
    IO.puts("     Gen 3+ Fraction: #{gen3_frac}%")
    IO.puts("     Avg Generation: #{avg_gen}")
    IO.puts("     Max Generation: #{max_gen}")

    # CRITICAL METRIC: Death Causes Analysis
    death_causes =
      graveyard
      |> Map.values()
      |> Enum.group_by(fn record -> record.cause_of_death end)
      |> Enum.map(fn {cause, records} -> {cause, length(records)} end)
      |> Enum.sort_by(fn {_, count} -> -count end)

    total_deaths = map_size(graveyard)

    if total_deaths > 0 do
      deaths_per_1k = Float.round(total_deaths / (tick / 1000), 1)

      IO.puts(
        "\n  💀 Mortality Analysis (#{total_deaths} total deaths, #{deaths_per_1k}/1k ticks):"
      )

      Enum.each(death_causes, fn {cause, count} ->
        pct = Float.round(count / total_deaths * 100, 1)

        icon =
          case cause do
            :resource_exhaustion -> "🔥"
            :institutional_senescence -> "⏳"
            :competitive_displacement -> "⚔️"
            :overcapacity_mortality -> "📊"
            _ -> "❓"
          end

        IO.puts("     #{icon} #{cause}: #{count} (#{pct}%)")
      end)

      deaths_by_stage =
        graveyard
        |> Map.values()
        |> Enum.group_by(fn record -> Map.get(record, :life_stage, :adult) end)
        |> Enum.map(fn {stage, records} -> {stage, length(records)} end)
        |> Enum.sort_by(fn {stage, _} ->
          case stage do
            :newborn -> 1
            :juvenile -> 2
            :apprentice -> 3
            :adult -> 4
            _ -> 5
          end
        end)

      IO.puts("\n  🔬 Deaths by Life Stage (all-time):")

      Enum.each(deaths_by_stage, fn {stage, count} ->
        pct = Float.round(count / total_deaths * 100, 1)
        bar = String.duplicate("█", div(count, max(1, div(total_deaths, 50))))

        IO.puts(
          "     #{stage}: #{String.pad_leading(Integer.to_string(count), 4)} (#{String.pad_leading(Float.to_string(pct), 5)}%) #{bar}"
        )
      end)

      dev_deaths =
        Enum.sum(
          for {stage, count} <- deaths_by_stage,
              stage in [:newborn, :juvenile, :apprentice],
              do: count
        )

      adult_deaths = Keyword.get(deaths_by_stage, :adult, 0)

      if dev_deaths > adult_deaths * 2 do
        IO.puts(
          "     ⚠️  WARNING: Developmental culling detected! Dev deaths (#{dev_deaths}) >> Adult deaths (#{adult_deaths})"
        )
      else
        IO.puts(
          "     ✅ Developmental protection working: Adult deaths (#{adult_deaths}) >= Dev deaths (#{dev_deaths})"
        )
      end
    else
      IO.puts("\n  ⚠️  NO DEATH RECORDS - Mortality mechanisms may not be firing!")
    end

    # World divergence details
    world_stats =
      worlds
      |> Map.new(fn {world_id, _world} ->
        world_programs = active_programs |> Enum.filter(fn p -> p.world_id == world_id end)
        pop_count = length(world_programs)

        world_max_gen =
          if Enum.empty?(world_programs),
            do: 0,
            else: Enum.max(Enum.map(world_programs, &(&1.generation || 1)))

        {world_id, %{population: pop_count, max_generation: world_max_gen}}
      end)

    IO.puts("\n  🗺️  World Divergence (Top 5):")

    world_stats
    |> Enum.sort_by(fn {_world_id, data} -> -data.population end)
    |> Enum.take(5)
    |> Enum.each(fn {world_id, %{population: pop, max_generation: mgen}} ->
      IO.puts("     #{world_id}: Pop=#{pop}, Max Gen=#{mgen}")
    end)

    world_caps =
      worlds
      |> Map.new(fn {world_id, world} ->
        {world_id, map_size(Map.get(world, :capabilities, %{}))}
      end)

    avg_caps =
      if map_size(world_caps) > 0,
        do: Float.round(Enum.sum(Map.values(world_caps)) / map_size(world_caps), 1),
        else: 0.0

    c_max_caps = if map_size(world_caps) > 0, do: Enum.max(Map.values(world_caps)), else: 0

    IO.puts("\n  🔬 Capability Diversity:")
    IO.puts("     Avg World Caps: #{avg_caps}, Max: #{c_max_caps}")
    IO.puts("")

    # ── CAPABILITY GRAPH METRICS ──────────────────────────────────────────────
    # Count node instances across all three layers (program, world, civilization).
    # Do not merge by id here: repeated per-program nodes are exactly what expose
    # graph explosion under load.
    civ_caps_map = Map.get(state, :capabilities, %{})

    world_caps_map =
      worlds
      |> Map.values()
      |> Enum.reduce(%{}, fn w, acc -> Map.merge(acc, Map.get(w, :capabilities, %{})) end)

    program_cap_nodes =
      Map.values(state.research_programs || %{})
      |> Enum.flat_map(fn p -> Map.values(Map.get(p, :capabilities, %{})) end)

    all_cap_nodes =
      (Map.values(civ_caps_map) ++ Map.values(world_caps_map) ++ program_cap_nodes)
      |> Enum.filter(fn v -> is_map(v) and Map.has_key?(v, :parent_nodes) end)

    node_count = length(all_cap_nodes)
    edge_count = Enum.sum(Enum.map(all_cap_nodes, fn n -> length(n.parent_nodes || []) end))

    depths = Enum.map(all_cap_nodes, fn n -> n.depth || 1 end)

    avg_depth =
      if length(depths) > 0, do: Float.round(Enum.sum(depths) / length(depths), 2), else: 0.0

    max_depth = if length(depths) > 0, do: Enum.max(depths), else: 0

    # Promotion candidates = nodes with fitness above the promotion threshold but not yet promoted
    promotion_candidates =
      Enum.count(all_cap_nodes, fn n ->
        not (n.promoted || false) and (n.fitness_score || 0.0) >= 0.7
      end)

    # Promotion queue = nodes already promoted (living in world/civ layer)
    promotion_queue_size = map_size(world_caps_map) + map_size(civ_caps_map)

    IO.puts("  🧠 Capability Graph:")
    IO.puts("     Nodes:  #{node_count}")
    IO.puts("     Edges:  #{edge_count}")
    IO.puts("")
    IO.puts("     Avg Depth: #{avg_depth}")
    IO.puts("     Max Depth: #{max_depth}")
    IO.puts("")
    IO.puts("     Promotion Queue:      #{promotion_queue_size}")
    IO.puts("     Promotion Candidates: #{promotion_candidates}")
    IO.puts("")
    
    discovery_count = map_size(state.discoveries || %{})
    disc_cap_pct = Float.round(discovery_count / @max_discoveries_map_size * 100, 1)
    disc_cap_status = if discovery_count >= @max_discoveries_map_size, do: "⚠️  AT CAP", else: "✅"
    IO.puts("  📚 Discovery Map:")
    IO.puts("     Entries: #{discovery_count} / #{@max_discoveries_map_size} (#{disc_cap_pct}%)  #{disc_cap_status}")
    IO.puts("")

    # ── TECHNOLOGICAL LINEAGE DEPTH ───────────────────────────────────────────
    # Measures cumulative innovation: how many layers of synthesis/specialization
    # have been built on top of primitive domains. Deeper = more inherited knowledge.
    #
    # Uses the corrected depth field (max_parent_depth + 1 propagated at creation),
    # so depth=1 means a direct domain capability, depth=8 means 7 layers of
    # synthesis/specialization above a primitive domain.
    if node_count > 0 do
      lineage_depths = Enum.map(all_cap_nodes, fn n -> n.depth || 1 end)
      max_lineage = Enum.max(lineage_depths)
      avg_lineage = Float.round(Enum.sum(lineage_depths) / node_count, 2)

      # Depth histogram — shows distribution of technological maturity
      hist = Enum.reduce(lineage_depths, %{shallow: 0, mid: 0, deep: 0, frontier: 0}, fn d, acc ->
        cond do
          d <= 5  -> Map.update!(acc, :shallow,  &(&1 + 1))
          d <= 10 -> Map.update!(acc, :mid,      &(&1 + 1))
          d <= 20 -> Map.update!(acc, :deep,     &(&1 + 1))
          true    -> Map.update!(acc, :frontier, &(&1 + 1))
        end
      end)

      # Build an ancestry example: find the deepest node and walk its parent chain
      # to show the actual technological progression path.
      # O(max_depth) — safe even at 1.67M nodes.
      all_caps_map =
        (Map.to_list(civ_caps_map) ++ Map.to_list(world_caps_map) ++
          Enum.flat_map(Map.values(state.research_programs || %{}), fn p ->
            Map.to_list(p.capabilities || %{})
          end))
        |> Map.new()

      deepest_node = Enum.max_by(all_cap_nodes, fn n -> n.depth || 1 end)

      chain =
        Stream.iterate(deepest_node, fn node ->
          parent_id = List.first(node.parent_nodes || [])
          if parent_id, do: Map.get(all_caps_map, parent_id), else: nil
        end)
        |> Stream.take_while(& &1 != nil)
        |> Enum.map(fn n ->
          id_str = to_string(n.id)
          short = if String.length(id_str) > 12, do: String.slice(id_str, 0, 12) <> "…", else: id_str
          "#{short}(d=#{n.depth || 1})"
        end)
        |> Enum.reverse()
        |> Enum.join(" → ")

      IO.puts("  🔬 Technological Lineage Depth:")
      IO.puts("     Max:  #{max_lineage}")
      IO.puts("     Avg:  #{avg_lineage}")
      IO.puts("     Distribution:")
      IO.puts("       Shallow  (1-5):  #{hist.shallow}")
      IO.puts("       Mid    (6-10):  #{hist.mid}")
      IO.puts("       Deep  (11-20):  #{hist.deep}")
      IO.puts("       Frontier (21+): #{hist.frontier}")
      IO.puts("")
      IO.puts("     Deepest Chain:")
      IO.puts("       #{chain}")
      IO.puts("")
    end

    # ── SCHEDULER TIMING BREAKDOWN ────────────────────────────────────────────

    # Accumulated microseconds since simulation start — report as ms/5k-tick interval
    ticks_in_interval = 5_000
    t_sched = Map.get(metadata, :time_sched, 0)
    t_repro = Map.get(metadata, :time_repro, 0)
    t_disc = Map.get(metadata, :time_disc, 0)
    t_tele = Map.get(metadata, :time_tele, 0)
    t_cap_register = Map.get(metadata, :time_cap_register, 0)
    t_cap_decay = Map.get(metadata, :time_cap_decay, 0)
    t_discovery_relevance = Map.get(metadata, :time_discovery_relevance, 0)
    t_cap_promotion = Map.get(metadata, :time_cap_promotion, 0)
    t_total = max(1, t_sched + t_repro + t_disc + t_tele)

    # Convert accumulated microseconds to average ms per 5k-tick window
    # We reset the counters each interval so these are interval-only totals
    us_to_ms = fn us -> Float.round(us / 1000, 1) end
    pct = fn us -> Float.round(us / t_total * 100, 1) end

    IO.puts("  ⏱  Scheduler Breakdown (last #{ticks_in_interval} ticks):")
    IO.puts("     Economic/Scarcity: #{us_to_ms.(t_sched)}ms  (#{pct.(t_sched)}%)")
    IO.puts("     Reproduction:      #{us_to_ms.(t_repro)}ms  (#{pct.(t_repro)}%)")
    IO.puts("     Discovery/Caps:    #{us_to_ms.(t_disc)}ms   (#{pct.(t_disc)}%)")
    IO.puts("       - Registration:  #{us_to_ms.(t_cap_register)}ms")
    IO.puts("       - Cap Decay:     #{us_to_ms.(t_cap_decay)}ms")
    IO.puts("       - Relevance:     #{us_to_ms.(t_discovery_relevance)}ms")
    IO.puts("       - Promotion:     #{us_to_ms.(t_cap_promotion)}ms")
    IO.puts("     Telemetry/World:   #{us_to_ms.(t_tele)}ms   (#{pct.(t_tele)}%)")
    IO.puts("     ─────────────────────────────")
    IO.puts("     Total wall-time:   #{us_to_ms.(t_total)}ms")
    IO.puts("")

    updated_metadata =
      metadata
      |> Map.put(:last_n_to_j, n_to_j)
      |> Map.put(:last_j_to_a, j_to_a)
      |> Map.put(:last_a_to_adult, a_to_adult)
      # Reset timing buckets each interval so we see per-interval cost, not cumulative
      |> Map.put(:time_sched, 0)
      |> Map.put(:time_repro, 0)
      |> Map.put(:time_disc, 0)
      |> Map.put(:time_tele, 0)
      |> Map.put(:time_cap_register, 0)
      |> Map.put(:time_cap_decay, 0)
      |> Map.put(:time_discovery_relevance, 0)
      |> Map.put(:time_cap_promotion, 0)

    %{state | metadata: updated_metadata}
  end

  defp count_transitions(programs, graveyard, current_tick, threshold) do
    active_count =
      programs
      |> Map.values()
      |> Enum.count(fn p ->
        current_tick - (p.born_at_tick || 0) >= threshold
      end)

    dead_count =
      graveyard
      |> Map.values()
      |> Enum.count(fn r ->
        (r.lifespan_ticks || 0) >= threshold
      end)

    active_count + dead_count
  end

  @doc false
  @spec apply_capability_decay(State.t()) :: State.t()
  defp apply_capability_decay(state) do
    # FIX 3.5: Capability Decay
    # Civilizations must continually regenerate capabilities rather than
    # accumulating infinite advantages. Old knowledge fades without practice.
    # At 0.99995/tick applied every 10 ticks = 0.9995/10 ticks ≈ 0.05%/10 ticks decay.
    worlds = state.worlds || %{}

    updated_worlds =
      Enum.reduce(worlds, worlds, fn {world_id, world}, acc ->
        current_caps = world.capabilities || %{}

        decayed_caps =
          Enum.into(current_caps, %{}, fn {cap, node} ->
            case node do
              %TiannaraOS.CapabilityNode{} ->
                new_fitness = node.fitness_score * @capability_decay_per_tick

                if new_fitness < 0.05 do
                  {cap, nil}
                else
                  {cap, %{node | fitness_score: Float.round(new_fitness, 4)}}
                end

              float_val when is_float(float_val) ->
                new_level = float_val * @capability_decay_per_tick
                if new_level < 0.05, do: {cap, nil}, else: {cap, Float.round(new_level, 4)}

              _ ->
                {cap, nil}
            end
          end)
          |> Enum.reject(fn {_cap, val} -> val == nil end)
          |> Enum.into(%{})

        updated_world = %{world | capabilities: decayed_caps}
        Map.put(acc, world_id, updated_world)
      end)

    %{state | worlds: updated_worlds}
  end

  # MISSING PRIMITIVE #5: Discovery Relevance Decay
  @spec apply_discovery_relevance_decay(State.t()) :: State.t()
  defp apply_discovery_relevance_decay(state) do
    # Innovation Obsolescence: Discoveries lose relevance over time.
    # PERF: Applied every 500 ticks (was 100). Threshold raised to 0.3 (was 0.1)
    # so entries expire ~3× faster, keeping the map bounded.
    discoveries = state.discoveries || %{}
    programs = state.research_programs || %{}

    # Step 1: Decay all existing discoveries, collect obsolete ids in one pass.
    {decayed_discoveries, obsolete_ids} =
      Enum.reduce(discoveries, {%{}, []}, fn {disc_id, discovery}, {keep, expired} ->
        current_relevance = Map.get(discovery, :relevance, 1.0)
        new_relevance = current_relevance * @discovery_relevance_decay

        if new_relevance < @relevance_min_threshold do
          {keep, [disc_id | expired]}
        else
          updated = Map.put(discovery, :relevance, Float.round(new_relevance, 4))
          {Map.put(keep, disc_id, updated), expired}
        end
      end)

    # Step 2: Hard cap — if map still too large after expiry, prune lowest-relevance
    # entries first. This prevents unbounded growth when the decay rate is slower
    # than the discovery birth rate.
    {final_discoveries, extra_pruned} =
      if map_size(decayed_discoveries) > @max_discoveries_map_size do
        sorted = Enum.sort_by(decayed_discoveries, fn {_id, d} -> Map.get(d, :relevance, 1.0) end)
        excess = map_size(decayed_discoveries) - @max_discoveries_map_size
        {pruned_ids, kept_pairs} = Enum.split(sorted, excess)
        pruned_id_list = Enum.map(pruned_ids, fn {id, _} -> id end)
        {Map.new(kept_pairs), pruned_id_list}
      else
        {decayed_discoveries, []}
      end

    all_obsolete = obsolete_ids ++ extra_pruned

    # Step 3: Only scan programs if anything actually expired.
    # This makes the O(worlds × programs × assets) inner loop conditional.
    updated_programs =
      if all_obsolete == [] do
        programs
      else
        obsolete_set = MapSet.new(all_obsolete)
        index = state.world_program_index || %{}

        Enum.reduce(index, programs, fn {_world_id, pids}, acc_progs ->
          Enum.reduce(pids, acc_progs, fn prog_id, acc ->
            prog = Map.get(acc, prog_id)

            if prog && prog.status == :active do
              current_assets = Map.get(prog, :assets, [])

              if current_assets != [] do
                filtered_assets = Enum.reject(current_assets, &MapSet.member?(obsolete_set, &1))

                if length(filtered_assets) != length(current_assets) do
                  Map.put(acc, prog_id, Map.put(prog, :assets, filtered_assets))
                else
                  acc
                end
              else
                acc
              end
            else
              acc
            end
          end)
        end)
      end

    %{state | discoveries: final_discoveries, research_programs: updated_programs}
  end

  @spec generate_discovery(atom(), atom(), integer(), State.t()) :: Discovery.t()
  defp generate_discovery(prog_id, world_id, tick, state) do
    program = Map.get(state.research_programs || %{}, prog_id)
    base_domains = [:energy, :materials, :computation, :medicine, :manufacturing, :transportation]

    # Programs can synthesize base domains OR their existing capabilities (creating deep tech trees)
    available_capabilities = Map.keys(program.capabilities || %{})
    domains = Enum.uniq(base_domains ++ available_capabilities)

    # Pick 1-3 random domains
    num_domains = :rand.uniform(3)
    selected_domains = Enum.take_random(domains, num_domains)

    # Create domain vector with random weights
    domain_vector =
      Enum.into(selected_domains, %{}, fn domain ->
        # 0.5-1.0 weight
        {domain, Float.round(:rand.uniform() * 0.5 + 0.5, 2)}
      end)

    # Binary string ID — NOT atom. Discovery IDs accumulate at ~37/tick.
    # String.to_atom here would exhaust the BEAM atom table (1M limit) by tick ~28k.
    discovery_id = "disc_#{prog_id}_#{tick}_#{:rand.uniform(10000)}"

    # Create temporary discovery to check capabilities
    temp_discovery = %Discovery{
      id: discovery_id,
      origin_world_id: world_id,
      origin_program_id: prog_id,
      # 0.7-1.0
      confidence: Float.round(:rand.uniform() * 0.3 + 0.7, 2),
      metadata: %{domain_vector: domain_vector},
      # NEW DISCOVERIES START AT FULL RELEVANCE
      relevance: 1.0
    }

    # Check if this discovery is blocked by missing capabilities
    case CapabilityRegistry.check_capability_prerequisites(state, temp_discovery) do
      {:blocked, _missing} ->
        # Discovery blocked - attempt breakthrough (10% chance)
        if :rand.uniform() < 0.1 do
          # Breakthrough! Allow it but with lower confidence
          %Discovery{
            id: discovery_id,
            origin_world_id: world_id,
            origin_program_id: prog_id,
            # 0.5-0.7 for breakthroughs
            confidence: Float.round(:rand.uniform() * 0.2 + 0.5, 2),
            metadata: %{domain_vector: domain_vector, breakthrough: true},
            # NEW DISCOVERIES START AT FULL RELEVANCE
            relevance: 1.0
          }
        else
          # Failed - return nil (caller should handle)
          nil
        end

      {:ok, _gaps} ->
        # Prerequisites met - normal discovery
        temp_discovery
    end
  end

  @spec calculate_esr(State.t()) :: float()
  defp calculate_esr(state) do
    # Simplified ESR calculation
    # In production, would track total royalty income vs resource consumption
    # Placeholder
    1.2
  end

  @spec calculate_afg(State.t()) :: float()
  defp calculate_afg(state) do
    # Simplified AFG calculation
    # In production, would compare current ESR to historical average
    # Placeholder
    0.05
  end

  @spec count_lineage_depth(ResearchProgram.t(), map()) :: integer()
  defp count_lineage_depth(program, all_programs) do
    case program.parent_program_id do
      nil ->
        1

      parent_id ->
        parent = Map.get(all_programs, parent_id)

        if parent do
          1 + count_lineage_depth(parent, all_programs)
        else
          1
        end
    end
  end

  @spec count_species(map()) :: integer()
  defp count_species(programs) do
    # Simple species counting based on strategy genome clustering
    # Group programs by similar exploration_rate and validation_priority
    genomes =
      programs
      |> Map.values()
      |> Enum.map(fn p ->
        exp_rate = Map.get(p.strategy_genome, :exploration_rate, 0.5)
        val_priority = Map.get(p.strategy_genome, :validation_priority, 0.5)

        # Bin into coarse categories (0.2 bins)
        exp_bin = floor(exp_rate * 5) / 5
        val_bin = floor(val_priority * 5) / 5
        {exp_bin, val_bin}
      end)
      |> Enum.uniq()

    length(genomes)
  end

  @spec calculate_world_divergence(map()) :: float()
  defp calculate_world_divergence(worlds) do
    # Calculate average cosine distance between world need vectors
    world_list = Map.values(worlds)

    if length(world_list) < 2 do
      0.0
    else
      # Sample pairs of worlds and calculate divergence
      pairs =
        for i <- 0..(length(world_list) - 2),
            j <- (i + 1)..(length(world_list) - 1),
            do: {Enum.at(world_list, i), Enum.at(world_list, j)}

      distances =
        Enum.map(pairs, fn {w1, w2} ->
          cosine_distance(
            w1.needs_vector || %{},
            w2.needs_vector || %{}
          )
        end)

      Enum.sum(distances) / length(distances)
    end
  end

  @spec cosine_distance(map(), map()) :: float()
  defp cosine_distance(vec1, vec2) do
    # Get all keys from both vectors
    all_keys = (Map.keys(vec1) ++ Map.keys(vec2)) |> Enum.uniq()

    # Calculate dot product and magnitudes
    dot_product =
      Enum.sum(
        Enum.map(all_keys, fn key ->
          Map.get(vec1, key, 0.0) * Map.get(vec2, key, 0.0)
        end)
      )

    mag1 =
      :math.sqrt(
        Enum.sum(
          Enum.map(all_keys, fn key ->
            :math.pow(Map.get(vec1, key, 0.0), 2)
          end)
        )
      )

    mag2 =
      :math.sqrt(
        Enum.sum(
          Enum.map(all_keys, fn key ->
            :math.pow(Map.get(vec2, key, 0.0), 2)
          end)
        )
      )

    if mag1 == 0 or mag2 == 0 do
      # Maximum distance if either vector is zero
      1.0
    else
      # Cosine similarity -> distance (1 - similarity)
      1.0 - dot_product / (mag1 * mag2)
    end
  end

  # Memoized DFS: computes the longest ancestor chain depth for a CapabilityNode.
  # Returns {depth, updated_memo_map}.
  @spec compute_lineage_depth(map(), map(), map()) :: {integer(), map()}
  defp compute_lineage_depth(node, cap_lookup, memo) do
    case Map.get(memo, node.id) do
      nil ->
        parent_depth =
          (node.parent_nodes || [])
          |> Enum.reduce({0, memo}, fn parent_id, {max_d, m} ->
            case Map.get(cap_lookup, parent_id) do
              nil ->
                {max_d, m}

              parent_node ->
                {d, updated_m} = compute_lineage_depth(parent_node, cap_lookup, m)
                {max(max_d, d), updated_m}
            end
          end)

        {parent_d, updated_memo} = parent_depth
        my_depth = parent_d + 1
        {my_depth, Map.put(updated_memo, node.id, my_depth)}

      cached ->
        {cached, memo}
    end
  end
end
