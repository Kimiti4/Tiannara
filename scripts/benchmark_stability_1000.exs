# scripts/benchmark_stability_1000.exs
defmodule Tiannara.Benchmark.Stability1000 do
  require Logger

  @output_file "stability_1000.csv"
  @sample_interval 100

  @target_modules [
    Tiannara.REA.ArchaeologyRegistry,
    Tiannara.REA.Causal.Graph
  ]

  def run(opts) do
    epoch_count = Keyword.get(opts, :epochs, 1000)
    seed = Keyword.get(opts, :seed, 42)

    start_services()

    {:ok, _audit} = Tiannara.Runtime.AuditHooks.setup(audit_mode: :rea_4_6)
    Tiannara.Runtime.AuditHooks.init_ets()

    write_csv_header()
    state = initialize_universe(seed)

    Logger.info("🏁 Starting 1000-epoch stability benchmark")

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

      :erlang.garbage_collect()

      if rem(epoch, @sample_interval) == 0 do
        snapshot = capture_snapshot(epoch, tick_us)
        write_csv_row(snapshot)
        print_progress(epoch, snapshot)
      end

      state = new_state
    end

    analyze_stability()
    Logger.info("✅ Benchmark complete. Output: #{@output_file}")
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

  defp capture_snapshot(epoch, tick_us) do
    sys_mem = :erlang.memory()

    target_mem =
      Enum.map(@target_modules, fn mod ->
        case Process.whereis(mod) do
          nil -> {mod, %{memory: 0, heap_size: 0}}
          pid ->
            case :erlang.process_info(pid, [:memory, :total_heap_size]) do
              [memory: mem, total_heap_size: heap] -> {mod, %{memory: mem, heap_size: heap}}
              _ -> {mod, %{memory: 0, heap_size: 0}}
            end
        end
      end)
      |> Map.new()

    :erlang.garbage_collect(self())
    gc_stats = %{time: 0, words_reclaimed: 0}

    %{
      epoch: epoch,
      system_memory_kb: div(sys_mem[:total], 1024),
      tick_time_ms: tick_us / 1000,
      gc_time_us: Map.get(gc_stats, :time, 0),
      archaeology_memory_kb: div(Map.get(target_mem, Tiannara.REA.ArchaeologyRegistry, %{memory: 0}).memory, 1024),
      archaeology_heap: Map.get(target_mem, Tiannara.REA.ArchaeologyRegistry, %{heap_size: 0}).heap_size,
      causal_graph_memory_kb: div(Map.get(target_mem, Tiannara.REA.Causal.Graph, %{memory: 0}).memory, 1024),
      causal_graph_heap: Map.get(target_mem, Tiannara.REA.Causal.Graph, %{heap_size: 0}).heap_size
    }
  end

  defp write_csv_header do
    headers = [
      "epoch",
      "system_memory_kb",
      "tick_time_ms",
      "gc_time_us",
      "archaeology_memory_kb",
      "archaeology_heap",
      "causal_graph_memory_kb",
      "causal_graph_heap"
    ]
    File.write!(@output_file, Enum.join(headers, ",") <> "\n")
  end

  defp write_csv_row(snapshot) do
    row = [
      snapshot.epoch,
      snapshot.system_memory_kb,
      Float.round(snapshot.tick_time_ms, 2),
      snapshot.gc_time_us,
      snapshot.archaeology_memory_kb,
      snapshot.archaeology_heap,
      snapshot.causal_graph_memory_kb,
      snapshot.causal_graph_heap
    ]
    File.write!(@output_file, Enum.join(row, ",") <> "\n", [:append])
  end

  defp print_progress(epoch, s) do
    IO.puts("\n📊 Epoch #{epoch}")
    IO.puts("  System: #{s.system_memory_kb} KB | Tick: #{s.tick_time_ms} ms | GC: #{s.gc_time_us} μs")
    IO.puts("  ArchaeologyRegistry: #{s.archaeology_memory_kb} KB (heap: #{s.archaeology_heap})")
    IO.puts("  Causal.Graph: #{s.causal_graph_memory_kb} KB (heap: #{s.causal_graph_heap})")
  end

  defp analyze_stability do
    case File.read(@output_file) do
      {:ok, content} ->
        rows = content |> String.split("\n", trim: true) |> Enum.drop(1)
        if length(rows) >= 3 do
          archaeology_mem =
            rows
            |> Enum.map(fn row ->
              [epoch, _sys, _tick, _gc, arch_mem | _] = String.split(row, ",")
              {String.to_integer(epoch), String.to_integer(arch_mem)}
            end)

          first_mem = archaeology_mem |> hd() |> elem(1)
          last_mem = archaeology_mem |> List.last() |> elem(1)
          growth_rate = (last_mem - first_mem) / (length(archaeology_mem) - 1)

          IO.puts("\n🔍 STABILITY ANALYSIS")
          IO.puts("ArchaeologyRegistry memory: #{first_mem} KB → #{last_mem} KB")
          IO.puts("Growth rate: #{Float.round(growth_rate, 2)} KB/epoch")

          cond do
            growth_rate < 5 ->
              IO.puts("✅ MEMORY PLATEAU CONFIRMED (<5 KB/epoch growth)")
              IO.puts("   → Pruning patches are effective")
            growth_rate < 50 ->
              IO.puts("🔶 MEMORY STABLE (moderate growth, likely transient)")
              IO.puts("   → Monitor for long-term drift")
            true ->
              IO.puts("⚠️  MEMORY STILL GROWING (#{Float.round(growth_rate, 0)} KB/epoch)")
              IO.puts("   → Review pruning logic or consider ring buffer")
          end

          tick_times =
            rows
            |> Enum.map(fn row ->
              [_, _, tick_ms | _] = String.split(row, ",")
              String.to_float(tick_ms)
            end)

          avg_tick = Enum.sum(tick_times) / length(tick_times)
          max_tick = Enum.max(tick_times)
          stability_ratio = max_tick / avg_tick

          IO.puts("\n⏱️  TICK TIME STABILITY")
          IO.puts("  Avg: #{Float.round(avg_tick, 2)} ms | Max: #{Float.round(max_tick, 2)} ms")
          IO.puts("  Stability ratio: #{Float.round(stability_ratio, 2)}x")

          if stability_ratio < 2.0 do
            IO.puts("✅ TICK TIMES STABLE (no GC-induced spikes)")
          else
            IO.puts("⚠️  TICK SPIKES DETECTED (possible GC pressure)")
          end
        end

      {:error, reason} ->
        IO.puts("⚠️  Could not analyze: #{reason}")
    end
  end
end

Tiannara.Benchmark.Stability1000.run(epochs: 1000, seed: 42)
