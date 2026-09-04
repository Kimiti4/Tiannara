# scripts/diagnostics_memory_ownership.exs
defmodule Tiannara.Diagnostics.MemoryOwnership do
  require Logger

  @output_file "memory_ownership_diagnostics.csv"

  def run(opts) do
    epoch_count = Keyword.get(opts, :epochs, 300)
    seed = Keyword.get(opts, :seed, 42)

    start_services()

    {:ok, _audit} = Tiannara.Runtime.AuditHooks.setup(audit_mode: :rea_4_6)
    Tiannara.Runtime.AuditHooks.init_ets()

    state = initialize_universe(seed)

    File.write!(@output_file, "epoch,system_mem_mb,proc_count,top1_name,top1_mem_mb,top1_heap,top1_q,top2_name,top2_mem_mb,top2_heap,top2_q,top3_name,top3_mem_mb,top3_heap,top3_q\n")

    Logger.info("🔍 Starting Process Heap Growth Diagnostic (#{epoch_count} epochs)")

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

      {_tick_us, new_state} = :timer.tc(fn ->
        Tiannara.REA.UniversalEvolutionEngine.tick(state)
      end)

      if rem(epoch, 50) == 0 do
        :erlang.garbage_collect()
        
        top_procs = :recon.proc_count(:memory, 3)
        proc_data = Enum.map(top_procs, fn {pid, mem, _extra} ->
          info = :erlang.process_info(pid, [:registered_name, :total_heap_size, :message_queue_len, :initial_call])
          name = case info[:registered_name] do
            [] -> 
              case info[:initial_call] do
                {m, f, a} -> "#{m}.#{f}/#{a}"
                _ -> inspect(pid)
              end
            n -> inspect(n)
          end
          
          heap = info[:total_heap_size] || 0
          q = info[:message_queue_len] || 0
          mem_mb = Float.round(mem / 1024 / 1024, 2)
          
          {name, mem_mb, heap, q}
        end)
        
        # Pad if less than 3
        padded = proc_data ++ List.duplicate({"none", 0.0, 0, 0}, max(0, 3 - length(proc_data)))
        [p1, p2, p3 | _] = padded

        sys_mem = Float.round(:erlang.memory(:total) / 1024 / 1024, 2)
        pcount = :erlang.system_info(:process_count)

        row = "#{epoch},#{sys_mem},#{pcount}," <>
              "#{elem(p1,0)},#{elem(p1,1)},#{elem(p1,2)},#{elem(p1,3)}," <>
              "#{elem(p2,0)},#{elem(p2,1)},#{elem(p2,2)},#{elem(p2,3)}," <>
              "#{elem(p3,0)},#{elem(p3,1)},#{elem(p3,2)},#{elem(p3,3)}\n"
              
        File.write!(@output_file, row, [:append])
        
        Logger.info("📊 Epoch #{epoch} | Mem: #{sys_mem}MB | Top: #{elem(p1,0)} (#{elem(p1,1)}MB) | 2nd: #{elem(p2,0)} (#{elem(p2,1)}MB) | 3rd: #{elem(p3,0)} (#{elem(p3,1)}MB)")
      end

      state = new_state
    end
    
    Logger.info("✅ Diagnostic complete. Output: #{@output_file}")
  end

  def start_services do
    Application.ensure_all_started(:tiannara)
    Application.ensure_all_started(:recon)
    
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

Tiannara.Diagnostics.MemoryOwnership.run(epochs: 300, seed: 42)
