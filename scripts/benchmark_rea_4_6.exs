# scripts/benchmark_rea_4_6.exs

defmodule Tiannara.Benchmark do
  require Logger

  def run_all do
    IO.puts("═══════════════════════════════════════════════════════════")
    IO.puts("🧪 REA-4.6: DIAGNOSTIC & BENCHMARKING (Phase 1)")
    IO.puts("═══════════════════════════════════════════════════════════\n")

    start_services()

    # Create reports directory if it doesn't exist
    File.mkdir_p!("test_results/benchmarks")
    
    # 2. Run Baseline Benchmarks to map the scaling curve
    IO.puts("\n📊 [Step 2] Running Baseline Benchmarks...")
    run_baseline(100)
    run_baseline(500)
    run_baseline(1000)

    IO.puts("\n✅ Benchmarking Complete. Check test_results/benchmarks/ for data.")
  end

  defp start_services do
    Application.ensure_all_started(:tiannara)
    # The application tree likely already starts these, but if running via mix run, 
    # we'll manually ensure our registries are up if not supervised dynamically.
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

  def profile(epochs) do
    reset_state()
    u = initialize_universe(0)
    
    IO.puts("   Starting :fprof...")
    :fprof.apply(__MODULE__, :run_epochs_for_fprof, [u, epochs])
    :fprof.profile()
    :fprof.analyse(dest: ~c"test_results/benchmarks/profiling_report.txt", totals: true, sort: :own)
    IO.puts("   ✅ Profiling report saved to test_results/benchmarks/profiling_report.txt")
  end

  def run_epochs_for_fprof(universe, epochs) do
    run_epochs(universe, epochs)
  end

  def run_baseline(epochs) do
    reset_state()
    u = initialize_universe(0)

    # Force GC to get clean baseline memory
    :erlang.garbage_collect()
    Process.sleep(100)
    mem_before = :erlang.memory(:processes)

    start_cpu = :os.system_time(:microsecond)
    
    {time_us, epoch_times} = :timer.tc(fn ->
      run_epochs_and_collect_times(u, epochs)
    end)

    mem_after = :erlang.memory(:processes)
    
    wall_time_s = time_us / 1_000_000
    
    # Schedulers
    schedulers = :erlang.system_info(:schedulers_online)
    cpu_time_us = :os.system_time(:microsecond) - start_cpu
    utilization = (cpu_time_us / (time_us * schedulers)) |> Float.round(3)
    mem_delta_mb = (mem_after - mem_before) / 1024 / 1024 |> Float.round(2)
    
    IO.puts("   📈 Epochs: #{epochs} | Wall: #{Float.round(wall_time_s, 2)}s | CPU Util: #{utilization} | Mem Delta: #{mem_delta_mb} MB")

    # Save to JSON
    filename = "test_results/benchmarks/baseline_#{epochs}_epochs.json"
    data = %{
      epochs: epochs,
      wall_time_s: wall_time_s,
      cpu_utilization: utilization,
      memory_delta_mb: mem_delta_mb,
      epoch_times_ms: epoch_times
    }
    File.write!(filename, Jason.encode!(data, pretty: true))
    IO.puts("      💾 Saved curve data to #{filename}")
  end

  defp run_epochs(universe, epochs) do
    Enum.reduce(1..epochs, universe, fn _, acc ->
      Tiannara.REA.UniversalEvolutionEngine.tick(acc)
    end)
  end

  defp run_epochs_and_collect_times(universe, epochs) do
    {_, times} = Enum.reduce(1..epochs, {universe, []}, fn epoch, {acc, times} ->
      {t, next_acc} = :timer.tc(fn -> Tiannara.REA.UniversalEvolutionEngine.tick(acc) end)
      
      # Minimal progress indicator
      if rem(epoch, 200) == 0, do: IO.write(".")
      
      {next_acc, [t / 1000 | times]}
    end)
    IO.write(" ")
    Enum.reverse(times)
  end

  defp reset_state do
    if GenServer.whereis(Tiannara.REA.Causal.Graph) do
      Tiannara.REA.Causal.Graph.flush()
      Tiannara.REA.Causal.Topology.default() |> Tiannara.REA.Causal.Graph.load_topology()
    end
  end

  defp initialize_universe(epoch) do
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

Tiannara.Benchmark.run_all()
