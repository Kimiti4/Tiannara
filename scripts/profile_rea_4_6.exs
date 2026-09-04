# scripts/profile_rea_4_6.exs

defmodule Tiannara.Profiler do
  @populations %{
    civilization: %{size: 100, module: Tiannara.Ecology.Civilization, niche: %{fitness_weights: %{economy: 0.3, truth: 0.4, cohesion: 0.3}}},
    epistemology: %{size: 40, module: Tiannara.Sentinel.D2.EpistemologySpecies, niche: %{coherence_weight: 0.5}},
    law_species: %{size: 30, module: Tiannara.SOPL.LawSpecies, niche: %{symmetry_weight: 0.6}},
    meta_genome: %{size: 20, module: Tiannara.SOPL.MetaGenome, niche: %{diversity_weight: 0.5, resilience_weight: 0.5, topological_plasticity: 0.1}}
  }

  def run_all do
    Application.ensure_all_started(:tiannara)

    IO.puts("🔍 Running 50-epoch :eprof Profiling...")
    
    reset_state()
    u = initialize_universe(0)
    
    :eprof.start()
    :eprof.profile(fn -> run_epochs(u, 50) end)
    :eprof.analyze(:total, [{:sort, :time}])
    :eprof.stop()
  end

  def run_epochs(universe, 0), do: universe
  def run_epochs(universe, remaining) do
    # Tick the engine
    new_u = Tiannara.REA.UniversalEvolutionEngine.tick(universe)
    run_epochs(new_u, remaining - 1)
  end

  defp initialize_universe(epoch) do
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

  defp reset_state do
    if Process.whereis(Tiannara.REA.LineageRegistry) do
      GenServer.call(Tiannara.REA.LineageRegistry, :reset_state)
    end
    if Process.whereis(Tiannara.Sentinel.D2.EpistemologyGraph) do
      GenServer.call(Tiannara.Sentinel.D2.EpistemologyGraph, :reset_state)
    end
    if Process.whereis(Tiannara.Topology.ACF.LawManager) do
      GenServer.call(Tiannara.Topology.ACF.LawManager, :reset_state)
    end
  end
end

Tiannara.Profiler.run_all()
