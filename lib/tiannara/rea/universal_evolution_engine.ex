defmodule Tiannara.REA.UniversalEvolutionEngine do
  @moduledoc """
  Orchestration layer for all evolutionary populations.
  
  This does NOT replace specialized engines. It coordinates them
  through a uniform contract, ensuring every population receives
  the same macro-loop:
  
    fitness → extinct? → archive → select → mutate/recombine → next_gen
  
  Specialized engines remain in place for domain-specific mutation
  operators, pressure schedules, and recombination semantics.
  
  The orchestrator provides:
    * Cross-level synchronization (epochs tick together)
    * Universal pressure injection
    * Evolutionary debt tracking (diversity loss across all levels)
    * Niche-aware selection (prevents Goodhart convergence)
  """
  
  alias Tiannara.REA.ArchaeologyRegistry
  
  @type population :: %{
    module: module(),
    organisms: [term()],
    strategy: map()
  }
  
  @type universe :: %{
    epoch: non_neg_integer(),
    populations: %{atom() => population()},
    metrics: map()
  }
  
  alias Tiannara.REA.Epistemic.ReflexivityObservatory
  alias Tiannara.REA.Epistemic.ConstitutionalImmuneSystem

  @doc """
  Execute one epoch of evolution across all populations.
  Returns the updated universe with new populations and metrics.
  """
  @spec tick(universe()) :: universe()
  def tick(%{epoch: epoch, populations: pops} = universe) do
    # 1. Tier 2 Immune Check: Evaluate global integrity BEFORE evolution proceeds
    snapshot = build_universe_snapshot(universe, epoch)
    
    if Code.ensure_loaded?(Tiannara.REA.Epistemic.UnifiedImmuneSystem) and Process.whereis(Tiannara.REA.Epistemic.UnifiedImmuneSystem) do
      # Fetch active portfolio metrics if available, otherwise blank
      Tiannara.REA.Epistemic.UnifiedImmuneSystem.evaluate_threats(snapshot, %{
        security_pressure: get_environmental_coordinate(universe, :security_pressure, 0.5)
      })
    end

    immune_status = if Code.ensure_loaded?(ConstitutionalImmuneSystem) and Process.whereis(ConstitutionalImmuneSystem) do
      case ConstitutionalImmuneSystem.evaluate(snapshot, epoch) do
        {:ok, status} -> status
        _ -> :healthy
      end
    else
      :healthy
    end

    if immune_status == :rollback_triggered do
      # If rollback occurred, the Graph was reset. We must rebuild the universe
      # to match the restored topology, effectively skipping normal evolution this tick.
      IO.puts("   ⏸️  Evolution paused for topological rollback.")
      universe # Return unmodified or rebuilt universe
    else
      # 2. Normal Evolution with Second-Order Selection
      {new_pops, metrics_deltas} =
        Enum.reduce(pops, {%{}, %{}}, fn {key, pop}, {pops_acc, met_acc} ->
          # Apply second-order fitness constraint to MetaGenomes
          pop_with_reflexivity = apply_second_order_selection(pop, epoch)
          {new_pop, delta} = tick_population(pop_with_reflexivity, epoch)
          {Map.put(pops_acc, key, new_pop), Map.put(met_acc, key, delta)}
        end)

      # 3. Evolve causal graph every 100 epochs
      if rem(epoch, 100) == 0 and epoch > 0 do
        case new_pops[:meta_genome] do
          nil -> :ok
          mg_pop ->
            # Pass reflexivity data to the evolution engine so it can record events
            record_reflexivity_events(mg_pop.organisms, epoch)
            if Code.ensure_loaded?(Tiannara.REA.Topo.ChannelEvolutionEngine) do
              Tiannara.REA.Topo.ChannelEvolutionEngine.evolve(epoch, mg_pop.organisms)
            end
        end
      end

      # --- ARC Hook ---
      tick_arc(epoch, universe)

      # Calculate CDI and TMI
      cdi = calculate_live_cdi()
      tmi = calculate_live_tmi()

      # Add CDI, TMI, and security_pressure to universe metrics
      enriched_metrics =
        universe.metrics
        |> Map.put(:cdi, cdi)
        |> Map.put(:tmi, tmi)
        |> Map.put(:security_pressure, get_environmental_coordinate(universe, :security_pressure, 0.5))

      %{universe |
        epoch: epoch + 1,
        populations: new_pops,
        metrics: merge_metrics(enriched_metrics, metrics_deltas)
      }
    end
  end

  defp apply_second_order_selection(%{module: mod, organisms: orgs} = pop, _epoch) do
    # Only applies to MetaGenomes for now, as they are the topology proposers
    if mod == Tiannara.SOPL.MetaGenome do
      updated_orgs =
        Enum.map(orgs, fn org ->
          lineage_id = Map.get(org.identity, :lineage_id, org.identity.id)
          profile = ReflexivityObservatory.classify(lineage_id)
          
          # Apply fitness multiplier based on classification
          multiplier = case profile && profile.classification do
            :pure_gamer -> 0.5      # Severe penalty: actively selected against
            :innovator -> 1.2       # Bonus: rewarded for system-wide integrity
            :conservator -> 1.05    # Slight bonus: stability is valuable
            _ -> 1.0                # Neutral
          end
          
          # Modify the organism's effective fitness or survival probability
          apply_fitness_modifier(org, multiplier)
        end)
      
      %{pop | organisms: updated_orgs}
    else
      pop
    end
  end

  defp apply_fitness_modifier(org, multiplier_base) do
    # If the organism is already marked with an effective_fitness, compound it
    current_fitness = Map.get(org, :effective_fitness, 1.0)
    
    # Escalate pure gamer penalty to 0.3x to ensure rapid culling
    final_multiplier = case multiplier_base do
      0.5 -> 0.3  # Pure gamer escalation
      _ -> multiplier_base
    end
    
    Map.put(org, :effective_fitness, current_fitness * final_multiplier)
  end

  defp record_reflexivity_events(meta_genomes, epoch) do
    Enum.each(meta_genomes, fn mg ->
      lineage_id = Map.get(mg.identity, :lineage_id, mg.identity.id)
      # Record parametric tuning or proposal events based on genome state
      ReflexivityObservatory.record_event(%{
        lineage_id: lineage_id,
        event_type: :parametric_tune,
        epoch: epoch,
        details: %{plasticity: mg.causal_genome.topological_plasticity}
      })
    end)
  end

  defp build_universe_snapshot(universe, epoch) do
    %{
      epoch: epoch,
      populations: universe.populations,
      metrics: universe.metrics,
      causal_pressures: collect_causal_pressures(universe),
      predictions: [],
      perturbations: [],
      adversarial_windows: [],
      mutation_log: [],
      volatility: get_environmental_coordinate(universe, :volatility, 0.5),
      complexity: get_environmental_coordinate(universe, :complexity, 0.5),
      adversariality: get_environmental_coordinate(universe, :adversariality, 0.5),
      security_pressure: get_environmental_coordinate(universe, :security_pressure, 0.5)
    }
  end

  defp collect_causal_pressures(universe) do
    universe.populations
    |> Enum.map(fn {k, _} ->
      pressures = Tiannara.REA.Causal.Graph.collect_pressures(k, universe.epoch)
      {k, pressures}
    end)
    |> Map.new()
  end
  
  @doc """
  Run one generation for a single population.
  Delegates to the organism module's contract.
  """
  @spec tick_population(population(), non_neg_integer()) :: {population(), map()}
  def tick_population(%{module: mod, organisms: orgs, strategy: strat}, epoch) do
    base_env = Map.get(strat, :environment, %Tiannara.REA.EvolutionaryEnvironment{})
    population_key = Map.get(strat, :population_key, :unknown)
    
    # --- REA-2 ADDITION: Compute causal pressure field ---
    alias Tiannara.REA.Causal.{Graph, PressureField, PressureInjector, Attribution}
    env = PressureInjector.prepare_environment(population_key, epoch, base_env)
    
    # --- REA-2 ADDITION: Apply pressure to each organism ---
    orgs = Enum.map(orgs, &PressureInjector.apply_to_organism(&1, env))
    
    # 1. Fitness (now contextual)
    scored = Enum.map(orgs, fn o -> {o, mod.fitness(o, env)} end)
    
    # 2. Extinction check + archive WITH ATTRIBUTION
    {survivors, dead} = Enum.split_with(scored, fn {o, _} -> 
      threshold = PressureInjector.adjusted_extinction_threshold(o, env, 0.05)
      # Some environments define their own extinction threshold, we merge it
      not mod.extinct?(o, Map.put(env, :extinction_threshold, threshold)) 
    end)
    
    ruins = Enum.map(dead, fn {o, fitness} ->
      ruin = mod.archive(o, reason: infer_collapse_reason(o, fitness, env), epoch: epoch, environment: env)
      # --- REA-2 ADDITION: Attach causal attribution ---
      attribution = Attribution.attribute(ruin)
      %{ruin | metadata: Map.put(Map.get(ruin, :metadata, %{}), :causal_attribution, attribution)}
    end)
    Enum.each(ruins, &ArchaeologyRegistry.inter/1)
    
    # 3. Niche-aware selection
    survivors_only = Enum.map(survivors, &elem(&1, 0))
    selected = niche_aware_select(survivors_only, mod, env, strat)
    
    # 4. Reproduction (mutate + recombine mix)
    next_gen = reproduce_population(selected, mod, env, strat)
    
    # --- REA-2 ADDITION: Emit signals from survivors ---
    if function_exported?(mod, :emit_signals, 1) do
      survivors_only
      |> Enum.flat_map(&mod.emit_signals/1)
      |> Enum.each(&Graph.emit/1)
    end
    
    metrics = %{
      population_size: length(next_gen),
      extinctions: length(dead),
      avg_fitness: avg_fitness(survivors),
      diversity: shannon_diversity(next_gen, mod),
      causal_pressure_magnitude: PressureField.magnitude(Map.get(env, :causal_pressure, %{}))
    }
    
    {%{module: mod, organisms: next_gen, strategy: strat}, metrics}
  end
  
  # --- Selection: Niche-Aware ---
  
  defp niche_aware_select(orgs, mod, environment, strat) do
    target = Map.get(strat, :target_population, 100)
    if length(orgs) <= target do
      orgs
    else
      # Group by niche to maintain diversity
      by_niche = Enum.group_by(orgs, &mod.niche/1)
      per_niche = max(1, div(target, max(map_size(by_niche), 1)))
      selected =
        by_niche
        |> Enum.flat_map(fn {_niche, members} ->
          members
          |> Enum.map(&{&1, mod.fitness(&1, environment)})
          |> Enum.sort_by(&elem(&1, 1), :desc)
          |> Enum.take(per_niche)
          |> Enum.map(&elem(&1, 0))
        end)
      Enum.take(shuffle(selected), target)
    end
  end
  
  # --- Reproduction ---
  
  defp reproduce_population([], _mod, _environment, _strat), do: []
  defp reproduce_population(orgs, mod, environment, strat) do
    recomb_rate = Map.get(strat, :recombination_rate, 0.3)
    target = Map.get(strat, :target_population, 100)
    
    {recombinants, asexuals} = Enum.split(shuffle(orgs), trunc(length(orgs) * recomb_rate))
    
    recombinant_children =
      recombinants
      |> Enum.chunk_every(2, 2, :discard)
      |> Enum.map(fn [a, b] -> mod.recombine(a, [b], environment) end)
    
    asexual_children = Enum.map(asexuals, &mod.mutate(&1, environment))
    
    combined = recombinant_children ++ asexual_children
    
    # Pad if under target (clone top fitness)
    if length(combined) < target do
      top = Enum.max_by(orgs, &mod.fitness(&1, environment), fn -> hd(orgs) end)
      padding = for _ <- 1..(target - length(combined)), do: mod.mutate(top, environment)
      combined ++ padding
    else
      Enum.take(combined, target)
    end
  end
  
  # --- Metrics ---
  
  defp merge_metrics(existing, deltas) do
    Map.merge(existing, deltas, fn _k, old, new ->
      Map.merge(old, new, fn
        _, o, n when is_number(o) and is_number(n) -> (o + n) / 2  # moving average
        _, _, n -> n
      end)
    end)
  end
  
  defp avg_fitness([]), do: 0.0
  defp avg_fitness(pairs), do: Enum.map(pairs, &elem(&1, 1)) |> Enum.sum() |> Kernel./(length(pairs))
  
  defp shannon_diversity(orgs, mod) do
    niches = Enum.map(orgs, &mod.niche/1)
    total = length(niches)
    if total == 0, do: 0.0, else:
      niches
      |> Enum.frequencies()
      |> Enum.map(fn {_, c} -> p = c / total; -p * :math.log2(p) end)
      |> Enum.sum()
  end
  
  defp infer_collapse_reason(_org, fitness, env) do
    cond do
      fitness < 0.1 -> :fitness_collapse
      Map.get(env.pressures, :resource_pressure, 0) > 0.8 -> :resource_exhaustion
      true -> :stagnation
    end
  end
  
  defp shuffle(list), do: Enum.shuffle(list)

  # --- ARC Private Helpers ---

  defp tick_arc(epoch, universe) do
    env_context = %{
      volatility: get_environmental_coordinate(universe, :volatility, 0.5),
      complexity: get_environmental_coordinate(universe, :complexity, 0.5),
      adversariality: get_environmental_coordinate(universe, :adversariality, 0.5),
      security_pressure: get_environmental_coordinate(universe, :security_pressure, 0.5)
    }

    # 1. Tick Research Economy
    if Code.ensure_loaded?(Tiannara.REA.ResearchEconomy) and Process.whereis(Tiannara.REA.ResearchEconomy) do
      Tiannara.REA.ResearchEconomy.tick()
    end

    # 2. Tick Goal Ecology
    if Code.ensure_loaded?(Tiannara.REA.Epistemic.GoalEcology) and Process.whereis(Tiannara.REA.Epistemic.GoalRegistry) do
      Tiannara.REA.Epistemic.GoalEcology.tick(epoch, env_context)
    end

    # 3. Tick Institution Ecology
    if Code.ensure_loaded?(Tiannara.REA.Epistemic.InstitutionEcology) and Process.whereis(Tiannara.REA.Epistemic.InstitutionRegistry) do
      Tiannara.REA.Epistemic.InstitutionEcology.tick(epoch, env_context)
    end

    # 4. Log milestones to Civilization Memory
    if Code.ensure_loaded?(Tiannara.REA.Epistemic.CivilizationMemory) and Process.whereis(Tiannara.REA.Epistemic.CivilizationMemory) do
      log_arc_milestones(epoch)
    end
  end

  defp get_environmental_coordinate(universe, key, default) do
    cond do
      Map.has_key?(universe, key) -> Map.get(universe, key)
      Map.has_key?(universe.metrics, key) -> Map.get(universe.metrics, key)
      true ->
        # Try to find in one of the population environments
        universe.populations
        |> Map.values()
        |> Enum.find_value(default, fn pop ->
          env = get_in(pop, [:strategy, :environment])
          if env do
            Map.get(env.pressures, key) || Map.get(env.resources, key)
          end
        end)
    end
  end

  defp calculate_live_cdi do
    theories =
      if Code.ensure_loaded?(Tiannara.REA.TheorySelection) do
        Tiannara.REA.TheorySelection.load_theories()
      else
        []
      end

    total_pop = Enum.sum(Enum.map(theories, & &1.population))
    weights =
      if total_pop > 0 do
        Map.new(theories, & {&1.theory_id, &1.population / total_pop})
      else
        %{}
      end

    institutions =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.InstitutionRegistry) and Process.whereis(Tiannara.REA.Epistemic.InstitutionRegistry) do
        Tiannara.REA.Epistemic.InstitutionRegistry.get_institutions()
      else
        []
      end

    goals =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.GoalRegistry) and Process.whereis(Tiannara.REA.Epistemic.GoalRegistry) do
        Tiannara.REA.Epistemic.GoalRegistry.get_goals()
      else
        []
      end

    if Code.ensure_loaded?(Tiannara.REA.PortfolioRiskAnalyzer) do
      Tiannara.REA.PortfolioRiskAnalyzer.calculate_cdi(weights, institutions, goals)
    else
      0.5
    end
  end

  defp calculate_live_tmi do
    if Code.ensure_loaded?(Tiannara.REA.PortfolioRiskAnalyzer) do
      Tiannara.REA.PortfolioRiskAnalyzer.calculate_tmi([], 0.85, 0.05)
    else
      0.8
    end
  end

  defp log_arc_milestones(epoch) do
    if rem(epoch, 10) == 0 do
      goals_count =
        if Code.ensure_loaded?(Tiannara.REA.Epistemic.GoalRegistry) and Process.whereis(Tiannara.REA.Epistemic.GoalRegistry) do
          length(Tiannara.REA.Epistemic.GoalRegistry.active_goals())
        else
          0
        end

      insts_count =
        if Code.ensure_loaded?(Tiannara.REA.Epistemic.InstitutionRegistry) and Process.whereis(Tiannara.REA.Epistemic.InstitutionRegistry) do
          length(Tiannara.REA.Epistemic.InstitutionRegistry.active_institutions())
        else
          0
        end

      Tiannara.REA.Epistemic.CivilizationMemory.log_event(
        :scientific_revolution,
        epoch,
        "ARC Civilization Milestone",
        "Epoch #{epoch}: civilization operating with #{goals_count} goals and #{insts_count} institutions.",
        %{goals_count: goals_count, insts_count: insts_count}
      )
    end
  end
end
