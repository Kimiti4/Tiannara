# benchmarks/diagnostics_periodic_ets.exs
defmodule Tiannara.Diagnostics.DynamicScan do
  require Logger

  @output_file "periodic_ets_diagnostics.csv"

  def run(opts) do
    epoch_count = Keyword.get(opts, :epochs, 1000)
    seed = Keyword.get(opts, :seed, 42)

    start_services()

    {:ok, _audit} = Tiannara.Runtime.AuditHooks.setup(audit_mode: :rea_4_6)
    Tiannara.Runtime.AuditHooks.init_ets()

    state = initialize_universe(seed)

    File.write!(@output_file, "epoch,tick_us,mem_mb,top_table_1,size_1,top_table_2,size_2,top_table_3,size_3,max_msg_queue,queue_pid\n")

    Logger.info("🔍 Starting Dynamic ETS/Queue Diagnostic (#{epoch_count} epochs)")

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

      if rem(epoch, 50) == 0 do
        # 1. Find largest named ETS tables
        tables = :ets.all()
        named_tables = Enum.map(tables, fn tab -> 
          try do
            info = :ets.info(tab)
            if info[:named_table] do
              {tab, info[:size] || 0}
            else
              nil
            end
          rescue
            _ -> nil
          end
        end) |> Enum.reject(&is_nil/1)
        
        top_tables = named_tables
          |> Enum.sort_by(fn {_, size} -> size end, :desc)
          |> Enum.take(3)
          
        [t1, t2, t3] = case length(top_tables) do
          3 -> top_tables
          2 -> top_tables ++ [{"none", 0}]
          1 -> top_tables ++ [{"none", 0}, {"none", 0}]
          0 -> [{"none", 0}, {"none", 0}, {"none", 0}]
        end

        # 2. Find longest message queues
        processes = Process.list()
        top_queues = Enum.map(processes, fn pid ->
          try do
            {:message_queue_len, len} = Process.info(pid, :message_queue_len)
            {pid, len}
          rescue
            _ -> {pid, 0}
          end
        end)
        |> Enum.sort_by(fn {_, len} -> len end, :desc)
        |> Enum.take(1)
        
        {max_q_pid, max_q_len} = hd(top_queues ++ [{nil, 0}])
        
        pid_name = if max_q_pid, do: inspect(Process.info(max_q_pid, :registered_name) || max_q_pid), else: "none"

        mem_mb = Float.round(:erlang.memory(:total) / 1024 / 1024, 2)

        row = "#{epoch},#{tick_us},#{mem_mb},#{elem(t1, 0)},#{elem(t1, 1)},#{elem(t2, 0)},#{elem(t2, 1)},#{elem(t3, 0)},#{elem(t3, 1)},#{max_q_len},#{pid_name}\n"
        File.write!(@output_file, row, [:append])
        
        Logger.info("📊 Epoch #{epoch} | Tick: #{div(tick_us, 1000)}ms | Top Table: #{elem(t1, 0)} (#{elem(t1, 1)}) | Max Queue: #{max_q_len} (#{pid_name})")
      end

      state = new_state
    end
    
    Logger.info("✅ Diagnostic complete. Output: #{@output_file}")
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

Tiannara.Diagnostics.DynamicScan.run(epochs: 1000, seed: 42)
