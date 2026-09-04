# scripts/diagnostics_rea_4_6_lineage.exs
defmodule Tiannara.Diagnostics.Lineage do
  require Logger

  def run(opts) do
    epoch_count = Keyword.get(opts, :epochs, 400)
    seed = Keyword.get(opts, :seed, 42)

    start_services()

    {:ok, _audit} = Tiannara.Runtime.AuditHooks.setup(audit_mode: :rea_4_6)
    Tiannara.Runtime.AuditHooks.init_ets()

    state = initialize_universe(seed)

    IO.puts("epoch,active_nodes,lineage_records,avg_depth,max_depth,lineage_query_us,tick_us")

    for epoch <- 1..epoch_count do
      pop_size = Enum.reduce(state.populations, 0, fn {_, p}, acc -> acc + length(p.organisms) end)
      adversaries = Tiannara.Runtime.AuditHooks.inject_adversaries(epoch, pop_size)
      
      state = if length(adversaries) > 0 do
        civ_pop = state.populations.civilization
        updated_civ_pop = %{civ_pop | organisms: civ_pop.organisms ++ adversaries}
        %{state | populations: Map.put(state.populations, :civilization, updated_civ_pop)}
      else
        state
      end

      {tick_us, new_state} = :timer.tc(fn ->
        Tiannara.REA.UniversalEvolutionEngine.tick(state)
      end)

      if rem(epoch, 25) == 0 do
        active_orgs = Enum.flat_map(new_state.populations, fn {_, p} -> p.organisms end)
        active_nodes = length(active_orgs)
        
        {query_us, depths} = :timer.tc(fn ->
          Enum.map(active_orgs, fn org ->
            id = case org.identity do
              %{id: id} -> id
              id when is_binary(id) -> id
              _ -> nil
            end
            
            if id do
              ancestors = Tiannara.REA.LineageRegistry.ancestors(id)
              length(ancestors)
            else
              0
            end
          end)
        end)
        
        max_depth = if depths == [], do: 0, else: Enum.max(depths)
        avg_depth = if depths == [], do: 0.0, else: Enum.sum(depths) / length(depths)
        
        lineage_records = if :ets.info(Tiannara.REA.LineageRegistry) != :undefined, do: :ets.info(Tiannara.REA.LineageRegistry, :size), else: 0

        IO.puts("#{epoch},#{active_nodes},#{lineage_records},#{Float.round(avg_depth, 2)},#{max_depth},#{query_us},#{tick_us}")
      end

      state = new_state
    end
    
    IO.puts("\n✅ Lineage Diagnostics Complete.")
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

  defp initialize_universe(_seed) do
    if GenServer.whereis(Tiannara.REA.Causal.Graph) do
      Tiannara.REA.Causal.Graph.flush()
      Tiannara.REA.Causal.Topology.default() |> Tiannara.REA.Causal.Graph.load_topology()
    end
    
    epoch = 0
    %{
      epoch: epoch,
      populations: %{
        civilization: make_pop(:civilization, 100, epoch),
        epistemology: make_pop(:epistemology, 40, epoch),
        law_species: make_pop(:law_species, 30, epoch),
        meta_genome: make_pop(:meta_genome, 20, epoch)
      },
      metrics: %{extinctions: 0, diversity: 0.5, truth_retention: 0.5, resilience: 0.5, innovation: 0.5}
    }
  end

  defp make_pop(type, size, epoch) do
    {mod, niche} = case type do
      :civilization -> {Tiannara.Ecology.Civilization, %{fitness_weights: %{economy: 0.3, truth: 0.4, cohesion: 0.3}}}
      :epistemology -> {Tiannara.Sentinel.D2.EpistemologySpecies, %{coherence_weight: 0.5}}
      :law_species -> {Tiannara.SOPL.LawSpecies, %{symmetry_weight: 0.6}}
      :meta_genome -> {Tiannara.SOPL.MetaGenome, %{diversity_weight: 0.5, resilience_weight: 0.5, topological_plasticity: 0.1}}
    end
    
    %{
      module: mod,
      organisms: for(_ <- 1..size, do: mod.spawn(epoch, niche, %{})),
      strategy: %{
        target_population: size,
        recombination_rate: 0.3,
        environment: %Tiannara.REA.EvolutionaryEnvironment{
          resources: %{resource_ceiling: 100, compute_ceiling: 100},
          pressures: %{minimum_viability: 0.1}
        },
        population_key: type,
        mutation_rate: 0.1
      }
    }
  end
end

Tiannara.Diagnostics.Lineage.run(epochs: 400, seed: 42)
