defmodule Tiannara.REA.SimulationRunner do
  @moduledoc """
  Runs the UniversalEvolutionEngine for a configured number of epochs.
  """
  
  alias Tiannara.REA.{UniversalEvolutionEngine, EvolutionaryEnvironment}
  alias Tiannara.Ecology.Civilization
  alias Tiannara.Sentinel.D2.EpistemologySpecies
  alias Tiannara.SOPL.LawSpecies
  alias Tiannara.SOPL.MetaGenome
  alias Tiannara.REA.Causal.ChannelMonitor

  def run(config) do
    epochs = Map.get(config, :epochs, 100)
    snapshot_interval = Map.get(config, :snapshot_interval, 50)
    pop_sizes = Map.get(config, :population_sizes, %{civilization: 30, epistemology: 25, law_species: 20, meta_genome: 15})
    
    civs = for _ <- 1..pop_sizes.civilization, do: Civilization.spawn(0, %{}, %{})
    epis = for _ <- 1..pop_sizes.epistemology, do: EpistemologySpecies.spawn(0, %{}, %{})
    laws = for _ <- 1..pop_sizes.law_species, do: LawSpecies.spawn(0, %{}, %{})
    metas = for _ <- 1..pop_sizes.meta_genome, do: MetaGenome.spawn(0, %{}, %{})

    universe = %{
      epoch: 0,
      populations: %{
        civilization: %{module: Civilization, organisms: civs, strategy: %{target_population: pop_sizes.civilization, population_key: :civilization, environment: %EvolutionaryEnvironment{}}},
        epistemology: %{module: EpistemologySpecies, organisms: epis, strategy: %{target_population: pop_sizes.epistemology, population_key: :epistemology, environment: %EvolutionaryEnvironment{}}},
        law_species: %{module: LawSpecies, organisms: laws, strategy: %{target_population: pop_sizes.law_species, population_key: :law_species, environment: %EvolutionaryEnvironment{}}},
        meta_genome: %{module: MetaGenome, organisms: metas, strategy: %{target_population: pop_sizes.meta_genome, population_key: :meta_genome, environment: %EvolutionaryEnvironment{}}}
      },
      metrics: %{}
    }
    
    result_universe = Enum.reduce(1..epochs, universe, fn ep, u ->
      next_u = UniversalEvolutionEngine.tick(u)
      
      if rem(ep, snapshot_interval) == 0 do
        pressures = %{}
        pop_stats = next_u.populations
                    |> Enum.map(fn {k, pop} -> 
                        # We use the previous tick's metrics or calculate them here
                        extinctions = get_in(next_u.metrics, [k, :extinctions]) || 0
                        avg_fitness = get_in(next_u.metrics, [k, :avg_fitness]) || 0.0
                        {k, %{fitness: avg_fitness, population: length(pop.organisms), extinctions: extinctions}}
                    end)
                    |> Map.new()
        ChannelMonitor.record_epoch(ep, pressures, pop_stats)
      end
      
      next_u
    end)

    report = ChannelMonitor.generate_ecology_report()
    
    %{universe: result_universe, ecology_report: report}
  end
end
