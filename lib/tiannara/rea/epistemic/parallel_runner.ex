defmodule Tiannara.REA.Epistemic.ParallelRunner do
  @moduledoc """
  Runs three topologies in parallel with identical initial conditions:
  
    :truth     — the original canonical topology (Truth → Epistemic Stability)
    :cohesion  — the M-7 topology (Cohesion → Epistemic Stability)
    :hybrid    — both channels active simultaneously
  
  Compares outcomes across the six audit dimensions.
  Uses a shared RNG seed for fair comparison.
  """
  
  alias Tiannara.REA.{
    UniversalEvolutionEngine
  }
  alias Tiannara.REA.Causal.{Graph, Topology, Channel}
  alias Tiannara.REA.Epistemic.{Audit, EcologicalMemory, ReflexivityObservatory}
  
  @type topology_config :: %{
    id: atom(),
    description: String.t(),
    topology_modifier: (list() -> list())  # modifies base channels
  }
  
  @type comparison_report :: %{
    topologies: %{atom() => [Audit.audit_report()]},
    final_verdicts: %{atom() => atom()},
    winner: atom() | :inconclusive,
    analysis: String.t()
  }
  
  @spec run_comparison(map()) :: comparison_report()
  def run_comparison(config) do
    seed = Map.get(config, :seed, :erlang.phash2(System.system_time()))
    epochs = Map.get(config, :epochs, 20_000)
    snapshot_interval = Map.get(config, :snapshot_interval, 500)
    
    IO.puts("🔬 REA-3.5 Parallel Epistemic Comparison")
    IO.puts("   Seed: #{seed}")
    IO.puts("   Epochs: #{epochs}\n")
    
    # Define three topologies
    topologies = [
      %{
        id: :truth,
        description: "Original: Truth → Epistemic Stability",
        modifier: fn channels -> channels end
      },
      %{
        id: :cohesion,
        description: "M-7 Post-Swap: Cohesion → Epistemic Stability",
        modifier: &cohesion_topology/1
      },
      %{
        id: :hybrid,
        description: "Hybrid: both Truth and Cohesion channels",
        modifier: &hybrid_topology/1
      }
    ]
    
    # Run each topology
    results =
      topologies
      |> Enum.map(fn topo ->
        IO.puts("▶ Running topology: #{topo.id} (#{topo.description})")
        {time, reports} = :timer.tc(fn ->
          run_single_topology(topo, seed, epochs, snapshot_interval)
        end)
        IO.puts("  ✓ completed in #{time / 1000}ms, #{length(reports)} audit snapshots\n")
        {topo.id, reports}
      end)
      |> Map.new()
    
    # Compare
    compare_results(results)
  end
  
  defp run_single_topology(topology, _seed, epochs, snapshot_interval) do
    # Reset all state
    reset_all_state()
    
    # Load modified topology
    base_channels = Topology.default()
    modified = topology.modifier.(base_channels)
    Graph.load_topology(modified)
    
    # Run the simulation, collecting audit reports periodically
    run_with_audits(topology.id, epochs, snapshot_interval)
  end
  
  defp run_with_audits(topology_id, epochs, snapshot_interval) do
    # Initialize universe
    universe = initialize_universe(0)
    
    {_final_universe, reports} = Enum.reduce(1..epochs, {universe, []}, fn epoch, {u, reps} ->
      next_u = UniversalEvolutionEngine.tick(u)
      
      new_reps = if rem(epoch, snapshot_interval) == 0 do
        snapshot = build_snapshot(next_u, epoch)
        report = Audit.run(topology_id, snapshot, epoch)
        [report | reps]
      else
        reps
      end
      
      {next_u, new_reps}
    end)
    
    Enum.reverse(reports)
  end
  
  # ─── Topology Modifiers ─────────────────────────────────────
  
  defp cohesion_topology(channels) do
    # Replace the truth → epistemic_stability channel with cohesion → epistemic_stability
    channels
    |> Enum.reject(&(&1.name == :civilization_truth_to_epistemic_stability))
    |> Enum.concat([
      Channel.new(
        name: :civilization_cohesion_to_epistemic_stability,
        source: %{population: :civilization, signal: :cohesion},
        target: %{population: :epistemology, signal: :symmetry_stability},
        transfer_fn: &Channel.mean/1,
        delay: 2,
        decay: 0.95,
        weight: 1.0
      )
    ])
  end
  
  defp hybrid_topology(channels) do
    # Keep both channels active
    channels ++ [
      Channel.new(
        name: :civilization_cohesion_to_epistemic_stability_hybrid,
        source: %{population: :civilization, signal: :cohesion},
        target: %{population: :epistemology, signal: :symmetry_stability},
        transfer_fn: &Channel.mean/1,
        delay: 2,
        decay: 0.95,
        weight: 0.5
      )
    ]
  end
  
  # ─── Snapshot Builder ───────────────────────────────────────
  
  defp build_snapshot(universe, epoch) do
    %{
      epoch: epoch,
      populations: universe.populations,
      metrics: universe.metrics,
      causal_pressures: collect_causal_pressures(universe),
      predictions: [],  # populated by extended engine if available
      perturbations: [],
      adversarial_windows: [],
      mutation_log: []
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
  
  defp initialize_universe(epoch) do
    %{
      epoch: epoch,
      populations: %{
        civilization: make_pop(:civilization, 40, epoch),
        epistemology: make_pop(:epistemology, 30, epoch),
        law_species: make_pop(:law_species, 25, epoch),
        meta_genome: make_pop(:meta_genome, 15, epoch)
      },
      metrics: %{}
    }
  end
  
  defp make_pop(type, size, epoch) do
    {mod, niche} = case type do
      :civilization -> {Tiannara.Ecology.Civilization, %{fitness_weights: %{economy: 0.3, truth: 0.4, cohesion: 0.3}}}
      :epistemology -> {Tiannara.Sentinel.D2.EpistemologySpecies, %{coherence_weight: 0.5}}
      :law_species -> {Tiannara.SOPL.LawSpecies, %{symmetry_weight: 0.6}}
      :meta_genome -> {Tiannara.SOPL.MetaGenome, %{diversity_weight: 0.5, resilience_weight: 0.5}}
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
  
  defp reset_all_state do
    # Flush causal graph
    case Process.whereis(Tiannara.REA.Causal.Graph) do
      nil -> :ok
      _ -> Graph.flush()
    end
    
    # Reset memory & observatory
    case Process.whereis(EcologicalMemory) do
      nil -> :ok
      _ -> GenServer.call(EcologicalMemory, {:reset})
    end
    
    case Process.whereis(ReflexivityObservatory) do
      nil -> :ok
      _ -> GenServer.call(ReflexivityObservatory, {:reset})
    end
  end
  
  # ─── Comparison ─────────────────────────────────────────────
  
  defp compare_results(results) do
    # Average the last 10 audit reports for each topology (steady-state)
    final_reports =
      results
      |> Enum.map(fn {topo_id, reports} ->
        tail = reports |> Enum.reverse() |> Enum.take(10)
        avg_report = average_reports(tail)
        {topo_id, %{reports: tail, final: avg_report}}
      end)
      |> Map.new()
    
    # Determine winner by epistemic_integrity
    winner =
      final_reports
      |> Enum.max_by(fn {_, %{final: r}} -> r.epistemic_integrity end)
      |> elem(0)
    
    # Check verdicts
    final_verdicts = Enum.map(final_reports, fn {id, %{final: r}} -> {id, r.verdict} end) |> Map.new()
    
    analysis = generate_analysis(final_reports, winner)
    
    %{
      topologies: results,
      final_averages: Enum.map(final_reports, fn {id, %{final: r}} -> {id, r} end) |> Map.new(),
      final_verdicts: final_verdicts,
      winner: winner,
      analysis: analysis
    }
  end
  
  defp average_reports([]), do: nil
  defp average_reports(reports) do
    fields = [:predictive_accuracy, :basin_escape_score, :truth_retention,
              :innovation_yield, :cross_shard_transfer, :constitutional_margin,
              :epistemic_integrity]
    n = length(reports)
    
    base = hd(reports)
    averaged =
      fields
      |> Enum.map(fn f ->
        avg = reports |> Enum.map(&Map.get(&1, f, 0.0)) |> Enum.sum() |> Kernel./(n)
        {f, avg}
      end)
      |> Map.new()
    
    Map.merge(base, averaged)
  end
  
  defp generate_analysis(reports, winner) do
    header = """
    ═══════════════════════════════════════════════════════════
    REA-3.5 EPISTEMIC COMPARISON ANALYSIS
    ═══════════════════════════════════════════════════════════
    
    WINNER BY EPISTEMIC INTEGRITY: #{winner}
    
    Comparative Scores (steady-state average):
    """
    
    body = Enum.map(reports, fn {id, %{final: r}} ->
      """
      
      [#{id}]
        Predictive Accuracy:    #{format(r.predictive_accuracy)}
        Basin Escape:           #{format(r.basin_escape_score)}
        Truth Retention:        #{format(r.truth_retention)}
        Innovation Yield:       #{format(r.innovation_yield)}
        Cross-Shard Transfer:   #{format(r.cross_shard_transfer)}
        Constitutional Margin:  #{format(r.constitutional_margin)}
        ─────────────────────────────────────
        EPISTEMIC INTEGRITY:    #{format(r.epistemic_integrity)}
        Verdict:                #{r.verdict}
      """
    end)
    |> Enum.join("\n")
    
    footer = """
    
    ═══════════════════════════════════════════════════════════
    """
    
    header <> body <> footer
  end
  
  defp format(v) when is_float(v), do: :io_lib.format("~.3f", [v]) |> to_string()
  defp format(v), do: to_string(v)
end
