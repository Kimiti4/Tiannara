# scripts/diagnostics_rea_4_6.exs
defmodule Tiannara.Diagnostics.REA46 do
  require Logger

  @metrics_table :diag_metrics
  @ets_tables [:lineage_records, :causal_graph, :historical_snapshots, :audit_config]

  def run(opts) do
    epoch_count = Keyword.get(opts, :epochs, 400)
    seed = Keyword.get(opts, :seed, 42)

    init_ets()
    start_services()

    {:ok, _audit} = Tiannara.Runtime.AuditHooks.setup(audit_mode: :rea_4_6)
    Tiannara.Runtime.AuditHooks.init_ets()

    state = initialize_universe(seed)

    IO.puts("epoch,active_nodes,lineage_records,causal_records,historical_snapshots,tick_us,ets_mem_kb")

    for epoch <- 1..epoch_count do
      # 1. Inject adversaries
      pop_size = Enum.reduce(state.populations, 0, fn {_, p}, acc -> acc + length(p.organisms) end)
      adversaries = Tiannara.Runtime.AuditHooks.inject_adversaries(epoch, pop_size)
      
      state = if length(adversaries) > 0 do
        civ_pop = state.populations.civilization
        updated_civ_pop = %{civ_pop | organisms: civ_pop.organisms ++ adversaries}
        %{state | populations: Map.put(state.populations, :civilization, updated_civ_pop)}
      else
        state
      end

      # 2. Instrumented Tick (which includes traversal, propagation, and lineage tracking)
      {tick_us, new_state} = :timer.tc(fn ->
        Tiannara.REA.UniversalEvolutionEngine.tick(state)
      end)

      # 3. Sample every 25 epochs
      if rem(epoch, 25) == 0 do
        active_nodes = Enum.reduce(new_state.populations, 0, fn {_, p}, acc -> acc + length(p.organisms) end)
        
        # ETS Metrics
        lineage_records = if :ets.info(Tiannara.REA.LineageRegistry) != :undefined, do: :ets.info(Tiannara.REA.LineageRegistry, :size), else: 0
        causal_records = if :ets.info(Tiannara.REA.Causal.Graph) != :undefined, do: :ets.info(Tiannara.REA.Causal.Graph, :size), else: 0
        historical_snapshots = if :ets.info(Tiannara.REA.ArchaeologyRegistry) != :undefined, do: :ets.info(Tiannara.REA.ArchaeologyRegistry, :size), else: 0
        
        ets_mem = Enum.reduce([Tiannara.REA.LineageRegistry, Tiannara.REA.Causal.Graph, Tiannara.REA.ArchaeologyRegistry], 0, fn tab, acc ->
          if :ets.info(tab) != :undefined do
            acc + (:ets.info(tab, :memory) * :erlang.system_info(:wordsize) / 1024)
          else
            acc
          end
        end) |> Float.round(2)

        IO.puts("#{epoch},#{active_nodes},#{lineage_records},#{causal_records},#{historical_snapshots},#{tick_us},#{ets_mem}")
      end

      # 4. Detailed Audit Report every 1000 epochs
      if rem(epoch, 1000) == 0 do
        report = Tiannara.Runtime.AuditHooks.get_final_report(epoch)
        civ_diversity = Map.get(new_state.metrics, :civilization, %{}) |> Map.get(:diversity, 0.0)
        
        IO.puts("\n📊 [AUDIT REPORT - Epoch #{epoch}]")
        IO.puts("TPR: #{Float.round(report.true_positive_rate, 4)}")
        IO.puts("FPR: #{Float.round(report.false_positive_rate, 4)}")
        IO.puts("Novelty Survival: #{Float.round(report.novelty_survival_rate, 4)}")
        IO.puts("Diversity: #{Float.round(civ_diversity, 4)}\n")
      end

      state = new_state
    end
    
    IO.puts("\n✅ Diagnostics Complete.")
  end

  defp init_ets do
    :ets.new(@metrics_table, [:named_table, :bag, :public])
    :ok
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

Tiannara.Diagnostics.REA46.run(epochs: 10000, seed: 42)
