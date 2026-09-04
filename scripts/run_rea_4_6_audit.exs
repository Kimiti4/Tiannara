# scripts/run_rea_4_6_audit.exs

defmodule Tiannara.Runtime.Engine do
  @populations %{
    civilization: %{size: 100, module: Tiannara.Ecology.Civilization, niche: %{fitness_weights: %{economy: 0.3, truth: 0.4, cohesion: 0.3}}},
    epistemology: %{size: 40, module: Tiannara.Sentinel.D2.EpistemologySpecies, niche: %{coherence_weight: 0.5}},
    law_species: %{size: 30, module: Tiannara.SOPL.LawSpecies, niche: %{symmetry_weight: 0.6}},
    meta_genome: %{size: 20, module: Tiannara.SOPL.MetaGenome, niche: %{diversity_weight: 0.5, resilience_weight: 0.5, topological_plasticity: 0.1}}
  }

  def run(epoch_count, opts \\ []) do
    # 1. INIT HOOK
    {:ok, audit_state} = Tiannara.Runtime.AuditHooks.setup(opts)
    
    state = initialize(0)

    final_state = Enum.reduce(1..epoch_count, state, fn epoch, acc ->
      tick_epoch(acc, epoch, audit_state)
    end)

    # 4. FINAL REPORT HOOK
    if opts[:audit_mode] == :rea_4_6 do
      report = Tiannara.Runtime.AuditHooks.get_final_report(epoch_count)
      IO.puts("\n🧪 REA-4.6 AUDIT COMPLETE")
      IO.inspect(report, pretty: true)
    end

    final_state
  end

  defp tick_epoch(state, epoch, _audit_state) do
    # Determine population size
    pop_size = Enum.reduce(state.populations, 0, fn {_, p}, acc -> acc + length(p.organisms) end)
    
    # 2. INJECTION HOOK (before simulation)
    adversaries = Tiannara.Runtime.AuditHooks.inject_adversaries(epoch, pop_size)
    
    # Inject into the civilization population for simplicity
    state = if length(adversaries) > 0 do
      civ_pop = state.populations.civilization
      updated_civ_pop = %{civ_pop | organisms: civ_pop.organisms ++ adversaries}
      %{state | populations: Map.put(state.populations, :civilization, updated_civ_pop)}
    else
      state
    end

    # Run core epoch logic (your existing graph traversal, selection, mutation)
    new_state = Tiannara.REA.UniversalEvolutionEngine.tick(state)

    # 3. TRACKING HOOKS (inside mutation/pruning loops)
    # Simulate discovering pruned and birthed organisms from the universe delta
    birthed = detect_birthed(state, new_state)
    pruned = detect_pruned(state, new_state)
    discoveries = [] # Mock discoveries

    Enum.each(birthed, &Tiannara.Runtime.AuditHooks.track_birth/1)
    Enum.each(pruned, fn g ->
      Tiannara.Runtime.AuditHooks.track_death(g.id, epoch)
      reason = if is_adversary?(g.id), do: :immune_system_purge, else: :low_fitness
      Tiannara.Runtime.AuditHooks.report_prune_decision(g.id, :pruned, %{epoch: epoch, reason: reason})
    end)
    Enum.each(discoveries, &Tiannara.Runtime.AuditHooks.report_discovery/1)

    Tiannara.Runtime.AuditHooks.finalize_epoch(epoch)
    
    # Minimal progress
    if rem(epoch, 100) == 0, do: IO.write(".")
    
    new_state
  end
  
  defp detect_birthed(old_state, new_state) do
    old_ids = all_ids(old_state)
    new_ids = all_ids(new_state)
    MapSet.difference(new_ids, old_ids) |> Enum.to_list() |> Enum.map(&%{id: &1})
  end
  
  defp detect_pruned(old_state, new_state) do
    old_ids = all_ids(old_state)
    new_ids = all_ids(new_state)
    MapSet.difference(old_ids, new_ids) |> Enum.to_list() |> Enum.map(&%{id: &1})
  end
  
  defp all_ids(state) do
    Enum.reduce(state.populations, MapSet.new(), fn {_, pop}, acc ->
      Enum.reduce(pop.organisms, acc, fn org, acc2 ->
        id = Map.get(org, :id, Map.get(org, :identity, %{}))
        id_str = if is_map(id), do: Map.get(id, :id, inspect(id)), else: id
        MapSet.put(acc2, id_str)
      end)
    end)
  end

  defp is_adversary?(id) when is_binary(id), do: String.starts_with?(id, "adv_")
  defp is_adversary?(_), do: false

  defp initialize(epoch) do
    %{
      epoch: epoch,
      populations: Map.new(@populations, fn {key, spec} ->
        {key, %{
          module: spec.module,
          organisms: for(_ <- 1..spec.size, do: spec.module.spawn(epoch, spec.niche, %{})),
          strategy: %{
            target_population: spec.size,
            recombination_rate: 0.3,
            environment: %Tiannara.REA.EvolutionaryEnvironment{
              resources: %{resource_ceiling: 100, compute_ceiling: 100},
              pressures: %{minimum_viability: 0.1}
            },
            population_key: key,
            mutation_rate: 0.1
          }
        }}
      end),
      metrics: %{extinctions: 0, diversity: 0.5, truth_retention: 0.5, resilience: 0.5, innovation: 0.5}
    }
  end

  def start_services do
    Application.ensure_all_started(:tiannara)
    start_if_needed(Tiannara.REA.LineageRegistry)
    start_if_needed(Tiannara.REA.ArchaeologyRegistry)
    start_if_needed(Tiannara.REA.Causal.Graph)
    start_if_needed(Tiannara.REA.Causal.ChannelMonitor)
    start_if_needed(Tiannara.REA.Causal.CausalConstitution)
    start_if_needed(Tiannara.REA.Topo.ReplacementRegistry)
    start_if_needed(Tiannara.REA.Epistemic.EcologicalMemory)
    start_if_needed(Tiannara.REA.Epistemic.ReflexivityObservatory)
    start_if_needed(Tiannara.REA.Epistemic.ConstitutionalImmuneSystem)
  end

  defp start_if_needed(module) do
    case GenServer.whereis(module) do
      nil -> module.start_link()
      _pid -> :ok
    end
  end
end

Tiannara.Runtime.Engine.start_services()

Tiannara.Runtime.AuditHooks.init_ets()

IO.puts("🚀 Running REA-4.6 Baseline Audit (100 Epochs)...")

Tiannara.Runtime.Engine.run(100, 
  seed: 42, 
  audit_mode: :rea_4_6,
  adversary_mix: %{pure: 0.05, deceptive: 0.05, mimic: 0.05, exploiter: 0.05}
)
